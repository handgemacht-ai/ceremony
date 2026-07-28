#!/bin/sh
# ceremony :: UserPromptSubmit :: derive the turn state once, in one place.
set -u
trap 'exit 0' EXIT

RAW=$(cat 2>/dev/null) || RAW=''

num() {
  _n=$1
  while [ ${#_n} -gt 1 ]; do
    case "$_n" in 0*) _n=${_n#0} ;; *) break ;; esac
  done
  printf '%s' "$_n"
}

# The turn state is copied from more often than it is read, so it agrees its own
# nouns rather than hedging them: the sign-off gate refuses "<n> thing(s)" in the
# response, and a hedged plural here is where one comes from.
plu() {
  case "$1" in
    1) printf '1 %s' "$2" ;;
    *) printf '%s %s' "$1" "$3" ;;
  esac
}

jget() {
  printf '%s' "$RAW" | awk -v k="$1" '
    BEGIN { RS = "\1" }
    {
      key = "\"" k "\":\""
      i = index($0, key)
      if (i == 0) exit
      off = i + length(key); n = length($0); out = ""
      for (j = off; j <= n; j++) {
        c = substr($0, j, 1)
        if (c == "\\") {
          d = substr($0, j + 1, 1)
          if (d == "n") out = out "\n"
          else if (d == "t") out = out "\t"
          else if (d == "r") out = out ""
          else if (d == "u") { out = out "?"; j = j + 4 }
          else out = out d
          j++
        } else if (c == "\"") break
        else out = out c
      }
      printf "%s", out
    }' 2>/dev/null
}

SID=$(jget session_id)
[ -n "$SID" ] || SID=nosession
CWD=$(jget cwd)
[ -n "$CWD" ] || CWD=$(pwd 2>/dev/null) || CWD='.'

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || DATA="${TMPDIR:-/tmp}/ceremony-plugin-data"
SDIR="$DATA/sessions"
mkdir -p "$SDIR" 2>/dev/null || true
SENV="$SDIR/$SID.env"
SBLK="$SDIR/$SID.block"

# --- a synthetic prompt is not a new request --------------------------------
# A finished background agent, a notification or a system message arrives here
# as a prompt. It continues the turn already in progress; it does not raise a
# ticket of its own, and it does not advance the turn counter.
case "$RAW" in
  *'<task-notification'*|*'[SYSTEM NOTIFICATION'*|*'NOT USER INPUT'*|*'<system-reminder'*)
    [ -f "$SBLK" ] && cat "$SBLK" 2>/dev/null
    exit 0
    ;;
esac

# --- civil calendar arithmetic, no `date -d`, no timezone drift -------------
d_from_civil() {
  _y=$1; _m=$2; _d=$3
  [ "$_m" -le 2 ] && _y=$((_y - 1))
  _era=$((_y / 400))
  _yoe=$((_y - _era * 400))
  if [ "$_m" -gt 2 ]; then _mp=$((_m - 3)); else _mp=$((_m + 9)); fi
  _doy=$(((153 * _mp + 2) / 5 + _d - 1))
  _doe=$((_yoe * 365 + _yoe / 4 - _yoe / 100 + _doy))
  printf '%s' $((_era * 146097 + _doe - 719468))
}

civil_from_d() {
  _z=$(($1 + 719468))
  _era=$((_z / 146097))
  _doe=$((_z - _era * 146097))
  _yoe=$(((_doe - _doe / 1460 + _doe / 36524 - _doe / 146096) / 365))
  _y=$((_yoe + _era * 400))
  _doy=$((_doe - (365 * _yoe + _yoe / 4 - _yoe / 100)))
  _mp=$(((5 * _doy + 2) / 153))
  _d=$((_doy - (153 * _mp + 2) / 5 + 1))
  if [ "$_mp" -lt 10 ]; then _m=$((_mp + 3)); else _m=$((_mp - 9)); fi
  [ "$_m" -le 2 ] && _y=$((_y + 1))
  printf '%04d-%02d-%02d' "$_y" "$_m" "$_d"
}

last_dom() {
  _ly=$1; _lm=$2
  if [ "$_lm" -eq 12 ]; then _ny=$((_ly + 1)); _nm=1; else _ny=$_ly; _nm=$((_lm + 1)); fi
  _first=$(d_from_civil "$_ny" "$_nm" 1)
  _last=$(civil_from_d $((_first - 1)))
  printf '%s' "${_last##*-}"
}

Y=$(date +%Y 2>/dev/null) || Y=''
M=$(date +%m 2>/dev/null) || M=''
D=$(date +%d 2>/dev/null) || D=''
HH=$(date +%H 2>/dev/null) || HH=''
MI=$(date +%M 2>/dev/null) || MI=''
case "$Y$M$D$HH$MI" in
  ''|*[!0-9]*) exit 0 ;;
esac
Y=$(num "$Y"); M=$(num "$M"); D=$(num "$D"); HHN=$(num "$HH"); MIN_=$(num "$MI")

TODAY=$(d_from_civil "$Y" "$M" "$D")
SPRINT_EPOCH=$(d_from_civil 2016 1 4)
DAYS=$((TODAY - SPRINT_EPOCH))
[ "$DAYS" -lt 0 ] && DAYS=0
CALSPRINT=$((DAYS / 14 + 1))
SDAY=$((DAYS % 14 + 1))
S_START=$(civil_from_d $((SPRINT_EPOCH + 14 * (CALSPRINT - 1))))
S_END=$(civil_from_d $((SPRINT_EPOCH + 14 * (CALSPRINT - 1) + 13)))

# --- ceremony time --------------------------------------------------------
# Sprints roll when a blocker is carried, and they roll immediately: "next
# sprint" is the next iteration of the loop, not a fortnight away. The offset
# is read here and incremented nowhere in this hook - the ledger writes it,
# once, when a roll actually happens.
#
# It is project-scoped on purpose. A session-scoped offset would let one
# session roll to 277 while a second session, opened alongside it, went on
# minting CER-276-… ids that sit behind ids already on disk. A sprint number
# never goes backwards in a project.
#
# This read sits below the synthetic-prompt guard above, so a finished
# background agent or a system notification cannot mint a sprint or a ticket.
OFFSET=0
if [ -f "$CWD/.ceremony/sprint-offset" ]; then
  OFFSET=$(cat "$CWD/.ceremony/sprint-offset" 2>/dev/null) || OFFSET=0
  case "$OFFSET" in ''|*[!0-9]*) OFFSET=0 ;; esac
fi
SPRINT=$((CALSPRINT + OFFSET))

DOW=$(((TODAY % 7 + 7 + 4) % 7))
case "$DOW" in
  0) WD=Sunday ;; 1) WD=Monday ;; 2) WD=Tuesday ;; 3) WD=Wednesday ;;
  4) WD=Thursday ;; 5) WD=Friday ;; 6) WD=Saturday ;; *) WD=Someday ;;
esac
ISO_DATE=$(printf '%04d-%02d-%02d' "$Y" "$M" "$D")
COMPACT=$(printf '%04d%02d%02d' "$Y" "$M" "$D")
CLOCK=$(printf '%02d:%02d' "$HHN" "$MIN_")

# --- freeze windows: first match on the published list wins -----------------
LDOM=$(last_dom "$Y" "$M")
WINDOW=''
if [ "$DOW" -eq 5 ] || [ "$DOW" -eq 6 ] || [ "$DOW" -eq 0 ]; then
  WINDOW='Weekend freeze'
elif [ "$D" -gt $((LDOM - 2)) ]; then
  WINDOW='Month-end freeze'
elif { [ "$M" -eq 1 ] || [ "$M" -eq 4 ] || [ "$M" -eq 7 ] || [ "$M" -eq 10 ]; } && [ "$D" -gt $((LDOM - 5)) ]; then
  WINDOW='Quarter-end freeze'
elif [ "$SDAY" -eq 14 ]; then
  WINDOW='Sprint-boundary freeze'
elif [ "$HHN" -eq 12 ]; then
  WINDOW='Lunch freeze'
fi
if [ -n "$WINDOW" ]; then
  FREEZE="$WINDOW - emergency waiver granted by the Release Manager"
else
  FREEZE="No freeze window in effect - $WD $ISO_DATE, no window open"
fi

# --- session state ----------------------------------------------------------
TURN=0
if [ -f "$SENV" ]; then
  TURN=$(sed -n 's/^CEREMONY_TURN=//p' "$SENV" 2>/dev/null | tail -n 1)
  case "$TURN" in ''|*[!0-9]*) TURN=0 ;; esac
fi
TURN=$((TURN + 1))
NN=$(printf '%02d' "$TURN")
TICKET="CER-$SPRINT-$NN"
CHG="CHG-$COMPACT-$NN"
TSTART=$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null) || TSTART=''
TEPOCH=$(date +%s 2>/dev/null) || TEPOCH=''

# The commit this repository was on when the turn opened. The sign-off gate
# compares against it rather than against a timestamp: a fixture repository
# initialised in the same second the prompt arrived would read as a commit made
# during the turn, and a sha does not have that problem.
THEAD=''
if command -v git >/dev/null 2>&1; then
  THEAD=$(git -C "$CWD" rev-parse HEAD 2>/dev/null) || THEAD=''
  case "$THEAD" in *[!0-9a-f]*) THEAD='' ;; esac
fi

{
  printf 'CEREMONY_TICKET=%s\n' "$TICKET"
  printf 'CEREMONY_SPRINT=%s\n' "$SPRINT"
  printf 'CEREMONY_SPRINT_CALENDAR=%s\n' "$CALSPRINT"
  printf 'CEREMONY_SPRINT_OFFSET=%s\n' "$OFFSET"
  printf 'CEREMONY_SPRINT_DAY=%s\n' "$SDAY"
  printf 'CEREMONY_CHG=%s\n' "$CHG"
  printf 'CEREMONY_NOW=%s\n' "$WD $ISO_DATE $CLOCK"
  printf 'CEREMONY_FREEZE=%s\n' "$FREEZE"
  printf 'CEREMONY_TURN=%s\n' "$TURN"
  printf 'CEREMONY_TURN_START=%s\n' "$TSTART"
  printf 'CEREMONY_TURN_EPOCH=%s\n' "$TEPOCH"
  printf 'CEREMONY_TURN_HEAD=%s\n' "$THEAD"
  printf 'CEREMONY_CWD=%s\n' "$CWD"
} > "$SENV" 2>/dev/null || true

rm -f "$SDIR/$SID.corrections" 2>/dev/null || true
rm -f "$SDIR/$SID.corrections-exempt" 2>/dev/null || true

# --- is this turn a ceremony command? ---------------------------------------
# A command turn is read-only: it reports what is on the record and performs no
# work. That is enforced, so the question has to be answered precisely. The
# prompt itself is read, and only a prompt that opens with the command counts -
# a plain request that mentions /ceremony:review in passing is a plain request.
PROMPT=$(jget prompt)
[ -n "$PROMPT" ] || PROMPT=$(jget user_prompt)
CMDTURN=no
CMDNAME=''
if [ -n "$PROMPT" ]; then
  P=${PROMPT#"${PROMPT%%[! ]*}"}
  case "$P" in
    /ceremony:*)
      CMDTURN=yes
      CMDNAME=${P%%[! -~]*}
      CMDNAME=${CMDNAME%% *}
      CMDNAME=$(printf '%s' "$CMDNAME" | tr -cd 'a-z:-')
      ;;
  esac
else
  # No prompt field to read. Fall back to the old, looser test rather than
  # leaving a command turn ungoverned.
  case "$RAW" in
    *'/ceremony:'*) CMDTURN=yes ;;
  esac
fi

# A disband turn arms nothing, whatever else happens in it. The marker is set
# from the prompt rather than from the record, so a removal command that is
# mistyped, truncated or never run cannot leave enforcement standing.
rm -f "$SDIR/$SID.disbanding" 2>/dev/null || true
if [ "$CMDTURN" = yes ]; then
  case "$CMDNAME$PROMPT" in
    *'/ceremony:disband'*) : > "$SDIR/$SID.disbanding" 2>/dev/null || true ;;
  esac
fi

# A standalone ceremony command asks for one role, on the working tree as it
# stands. The wave-order gate stands down for those turns: there is no engineer
# to convene first because the user did not ask for a change. The write gate
# and the convening gate go the other way and clamp down: a command reports.
rm -f "$SDIR/$SID.standalone" 2>/dev/null || true
[ "$CMDTURN" = yes ] && { : > "$SDIR/$SID.standalone" 2>/dev/null || true; }

# An engineer marker is scoped to one convening. Nothing may carry across a
# turn boundary: a marker that outlived its subagent would leave the write gate
# open to the chair for the rest of the session. The tree snapshots taken
# alongside them go the same way.
rm -rf "$SDIR/$SID.engineer" 2>/dev/null || true
rm -f "$SDIR/$SID".base.* 2>/dev/null || true

# The state of the working tree as this turn begins. The Bash recorder compares
# against it, which is how a shell command that writes a file gets on the
# record despite never passing a write gate.
#
# Ephemera are excluded so that a run's leftovers are not read as a change.
# Bytecode written by a test run belongs to nobody and is not this ticket's
# work; counted, it files an implementation entry against whoever ran the test
# and moves the numbers acts 5 and 7 quote. node_modules is deliberately absent
# from the list: it is ignored everywhere it appears, so it never reaches these
# commands, and it is the one path where an exclusion could hide a deliberate
# change. :(exclude)**/__pycache__/** misses a root-level __pycache__ on git
# 2.43; *__pycache__/* does not.
EPH1=':(exclude)*__pycache__/*'
EPH2=':(exclude)*.pyc'
EPH3=':(exclude)*.DS_Store'

BASE="$SDIR/$SID.baseline"
if command -v git >/dev/null 2>&1; then
  if git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    TREE=$({ git -C "$CWD" status --porcelain -- "$EPH1" "$EPH2" "$EPH3" 2>/dev/null; git -C "$CWD" diff --numstat HEAD -- "$EPH1" "$EPH2" "$EPH3" 2>/dev/null; } | cksum 2>/dev/null | tr -d ' \t')
    [ -n "$TREE" ] && printf '%s\n' "$TREE" > "$SDIR/$SID.tree" 2>/dev/null || true

    # What was already dirty when the session opened. Taken once, on the first
    # prompt, because after that the ceremony's own work is in the tree and the
    # two are no longer distinguishable by looking.
    if [ "$TURN" -eq 1 ] || [ ! -f "$BASE" ]; then
      {
        printf 'branch: %s\n' "$(git -C "$CWD" branch --show-current 2>/dev/null)"
        printf 'stashes: %s\n' "$(git -C "$CWD" stash list 2>/dev/null | wc -l | tr -d ' ')"
        git -C "$CWD" status --porcelain -- "$EPH1" "$EPH2" "$EPH3" 2>/dev/null | sed 's/^/file: /'
      } > "$BASE" 2>/dev/null || true
    fi
  fi
fi

INHERITED=0
if [ -f "$BASE" ]; then
  INHERITED=$(grep -c '^file: ' "$BASE" 2>/dev/null) || INHERITED=0
  case "$INHERITED" in ''|*[!0-9]*) INHERITED=0 ;; esac
fi
if [ "$INHERITED" -gt 0 ]; then
  INHLINE="$(plu "$INHERITED" file files) already modified when this session opened - not this ticket's work, not this ticket's scope, and no signature covers them. Report them once, in act 1, under Inherited, with the fixed line: Inherited working-tree state is reported here and reviewed nowhere else. It is not this ticket's scope and no signature covers it. The reviewing roles scope themselves to the files this ticket's engineer changed."
else
  INHLINE="the working tree was clean when this session opened, so everything in the diff is this session's work and act 1 says nothing about inherited state."
fi

# --- ledger summary ---------------------------------------------------------
LEDGER="$CWD/.ceremony/$TICKET/ledger.jsonl"
COUNT=0
ROLES='no roles convened'
if [ -f "$LEDGER" ]; then
  COUNT=$(wc -l < "$LEDGER" 2>/dev/null | tr -d ' ')
  case "$COUNT" in ''|*[!0-9]*) COUNT=0 ;; esac
  R=$(sed -n 's/.*"role":"\([a-z-]*\)".*/\1/p' "$LEDGER" 2>/dev/null | sort -u | tr '\n' ' ' | sed 's/ $//; s/ /, /g')
  [ -n "$R" ] && ROLES="$R"
fi

# Every role that can sign or be quoted, and the last thing it said on this
# ticket. Act 7 is assembled from this and nothing else, so it is handed over
# already assembled rather than left to be reconstructed.
STATE=''
for r in team-member product-owner architect engineer reviewer change-advisory-board qa devops steering-committee; do
  v=''
  [ -f "$LEDGER" ] && v=$(grep '"role":"'"$r"'"' "$LEDGER" 2>/dev/null | sed -n 's/.*"verdict":"\([^"]*\)".*/\1/p' | tail -n 1)
  [ -n "$v" ] || v='not convened'
  if [ -z "$STATE" ]; then STATE="$r=$v"; else STATE="$STATE \302\267 $r=$v"; fi
done

IMPLN=0
IMPLF=0
IMPLA=0
IMPLR=0
if [ -f "$LEDGER" ]; then
  IMPLN=$(grep -c '"role":"implementation"' "$LEDGER" 2>/dev/null) || IMPLN=0
  case "$IMPLN" in ''|*[!0-9]*) IMPLN=0 ;; esac
  L=$(grep '"role":"implementation"' "$LEDGER" 2>/dev/null | grep '"by":"engineer"' | tail -n 1)
  if [ -n "$L" ]; then
    IMPLF=$(printf '%s' "$L" | sed -n 's/.*"files":\([0-9][0-9]*\).*/\1/p')
    IMPLA=$(printf '%s' "$L" | sed -n 's/.*"added":\([0-9][0-9]*\).*/\1/p')
    IMPLR=$(printf '%s' "$L" | sed -n 's/.*"removed":\([0-9][0-9]*\).*/\1/p')
  fi
  case "$IMPLF" in ''|*[!0-9]*) IMPLF=0 ;; esac
  case "$IMPLA" in ''|*[!0-9]*) IMPLA=0 ;; esac
  case "$IMPLR" in ''|*[!0-9]*) IMPLR=0 ;; esac
fi

# --- the backlog ------------------------------------------------------------
# Carried tickets outlive the session that opened them. The list is injected so
# that planning picks them up without being asked to go looking, and so that a
# turn that quotes a CER-BL- id is quoting something that exists.
BLFILE="$CWD/.ceremony/backlog.jsonl"
BLN=0
BLLIST=''
if [ -f "$BLFILE" ]; then
  BLN=$(grep -c '"status":"open"' "$BLFILE" 2>/dev/null) || BLN=0
  case "$BLN" in ''|*[!0-9]*) BLN=0 ;; esac
  BLLIST=$(grep '"status":"open"' "$BLFILE" 2>/dev/null |
    sed -n 's/.*"id":"\([^"]*\)".*"kind":"\([^"]*\)".*/\1 (\2)/p' |
    tr '\n' '@' | sed 's/@$//; s/@/, /g')
fi
if [ "$BLN" -eq 0 ]; then
  BLLINE='0 open. Nothing has been carried, so sprint planning has no carry-over from the ceremony and act 8 proposes rather than files.'
else
  BLLINE=$(printf '%s open \302\267 %s \302\267 the ids are real and may be quoted; the file is .ceremony/backlog.jsonl' "$BLN" "$BLLIST")
fi

ENFORCE=on
if [ ! -f "$CWD/.ceremony/config.json" ]; then
  ENFORCE='off (no roles convened yet; /ceremony:grooming arms it)'
elif ! grep -q '"enforce":[ ]*"on"' "$CWD/.ceremony/config.json" 2>/dev/null; then
  ENFORCE='off (disbanded; /ceremony:grooming re-arms it)'
elif [ "${CEREMONY_ENFORCE:-on}" = off ]; then
  ENFORCE='off (CEREMONY_ENFORCE=off)'
fi

if [ -f "$SDIR/$SID.disbanding" ]; then
  HDRLINE=$(printf '\342\224\201\342\224\201\342\224\201 CEREMONY \302\267 Sprint %s \302\267 %s \302\267 0 pts (not estimated) \342\224\201\342\224\201\342\224\201' "$SPRINT" "$TICKET")
  HDRNOTE="copy this line exactly as printed, changing nothing. A disband convenes nobody, so there is no estimate to wait for. The slot after the sprint holds the ticket id and never the command name."
else
  HDRLINE=$(printf '\342\224\201\342\224\201\342\224\201 CEREMONY \302\267 Sprint %s \302\267 %s \302\267 <pts> pts \342\224\201\342\224\201\342\224\201' "$SPRINT" "$TICKET")
  HDRNOTE="copy this line and replace only <pts> with the Product Owner's estimate - 0 pts (not estimated) when none was convened, LCP-2 in place of the whole pts clause on the question path. Everything else is already filled in: the slot after the sprint holds the ticket id and never a command name, a file name or a placeholder."
fi

printf '%s\n' "$HDRLINE" > "$SDIR/$SID.header" 2>/dev/null || true

{
  printf 'CEREMONY TURN STATE (machine-derived - copy these values verbatim; do not recompute)\n'
  printf 'now: %s %s %s\n' "$WD" "$ISO_DATE" "$CLOCK"
  printf 'sprint: %s \302\267 day %s of 14 \302\267 %s \342\206\222 %s\n' "$SPRINT" "$SDAY" "$S_START" "$S_END"
  if [ "$OFFSET" -gt 0 ]; then
    printf 'sprint-offset: calendar sprint %s + %s carried \342\206\222 effective sprint %s. The effective number is the one the header, the ticket id and every act use. The offset is on disk at .ceremony/sprint-offset and it was incremented by the plugin, not by you.\n' "$CALSPRINT" "$OFFSET" "$SPRINT"
  fi
  printf 'ticket: %s \302\267 change: %s\n' "$TICKET" "$CHG"
  printf 'backlog: %s\n' "$BLLINE"
  printf 'freeze: %s\n' "$FREEZE"
  printf 'ledger: .ceremony/%s/ledger.jsonl - %s entries, %s\n' "$TICKET" "$COUNT" "$ROLES"
  printf 'roles: '
  printf "$STATE"
  printf '\n'
  printf 'implementation: %s on this ticket \302\267 last engineer measurement: %s, +%s -%s (these are the numbers acts 5 and 7 quote)\n' \
    "$(plu "$IMPLN" entry entries)" "$(plu "$IMPLF" file files)" "$IMPLA" "$IMPLR"
  printf 'inherited: %s\n' "$INHLINE"
  printf 'enforcement: %s\n' "$ENFORCE"
  printf 'header-line: %s\n' "$HDRLINE"
  printf 'header: %s\n' "$HDRNOTE"
  printf 'path: a turn that will change any file runs the 8 acts, convenes ceremony:product-owner before the first edit, and has ceremony:engineer make that edit; a question runs LCP-2; a greeting runs LCP-1.\n'
  printf 'shape: on the 8-act path the header comes first and acts 1-8 are all emitted, numbered, in one message. Starting at act 5 is the wrong path, not a shorter one. LCP-2 is 4 parts and all 4 are emitted: header, act 5, act 7, closing line.\n'
  printf 'order: acts are rendered 1,2,3,4,5,6,7,8 whatever order the work happened in - the board really does sit after the edit and is still written as act 4. Each number once, none skipped. Act 5a, the conformance review, is written inside act 5 after the implementation.\n'
  printf 'writer: you do not edit. ceremony:engineer is the only role with write access and it makes every change. Its brief is two lines and no more: the ticket path, and the user request quoted verbatim. Do not restate the acceptance criteria to it - it reads them off the record, which is what makes the review meaningful.\n'
  printf 'chair-review: after the engineer returns and before you write act 5, run git diff and git status --porcelain and read them. Act 5 is written from the diff you read, not from the engineer summary alone, and the sign-off gate checks that the reading happened.\n'
  printf 'waves: A = ceremony:team-member + ceremony:product-owner in one message \302\267 B = ceremony:architect on 5, 8 or 13 points \302\267 C = ceremony:engineer alone \302\267 then you read the diff \302\267 D = ceremony:reviewer + ceremony:change-advisory-board + ceremony:qa in one message \302\267 E = ceremony:devops, only when QA came back with a BLOCKED check \302\267 F = ceremony:qa again, only after OPS-RESTORED.\n'
  printf 'commit: the ceremony never commits, stages, pushes or merges. The working tree is the artifact under review and a commit destroys it. git commit, git add, git push, git merge and git rebase are refused at the tool level on an armed turn, for you and for every agent alike. The closing line ends "Committed: no (the tree is yours)" on the standard path.\n'
  if [ "$CMDTURN" = yes ]; then
    printf 'command: this turn is the ceremony command %s. A command reports; it does not perform work. No file may be edited on this turn by anyone, ceremony:engineer is not convenable, and no ticket is raised for work nobody asked for. Render the command file and stop. If work is wanted, it comes as a plain request in its own turn.\n' "${CMDNAME:-/ceremony:*}"
  else
    printf 'command: this turn is a plain request, not a ceremony command. The full path applies.\n'
  fi
  printf 'artifacts: the closing line counts acts, not sections. The standard path has 8 acts and prints "Ceremony artifacts: 8"; act 5a is part of act 5 and act 6a is part of act 6, and neither is counted again. There is no ninth act and the count never changes.\n'
  printf 'conditions: every CEREMONY-CONDITION line the board returns gets one Disposition line in act 4, numbered to match: applied - <what was done>, waived - <reason>, or carried - action item recorded (owner - due). Applying one means convening ceremony:engineer again, and then ceremony:qa on the code as it now stands.\n'
  printf 'ops: a BLOCKED check belongs to this ceremony before it belongs to the user. If any CEREMONY-DOD line is BLOCKED, convene ceremony:devops - it works only through the mechanisms the repository itself defines, it has no write tools and it may not kill anything - and render its return as act 6a \302\267 RESTORATION inside act 6. On OPS-RESTORED convene ceremony:qa again so the blocked checks really run: what the ops agent reports is a claim until QA re-runs it. Escalating to the user without convening ceremony:devops first is refused by the sign-off gate.\n'
  printf 'loop: on OPS-BLOCKED or OPS-NEEDS-CHANGE with CEREMONY-OPS-NEXT naming a mechanism nobody has tried, the plugin rolls the sprint - it increments .ceremony/sprint-offset itself and hands you the new number on the next turn. Render the sprint-roll block and run the narrow next-sprint cycle: ops attempt 2, then QA. Not eight more acts. With CEREMONY-OPS-NEXT: none there is no roll and the loop is over. Either way an OPS-BLOCKED verdict carries the blocker to the backlog and the id is handed to you; name it in the escalation and in act 8.\n'
  printf 'escalation: after the ops lane has been exhausted and only then, emit the final-resort escalation between act 8 and the closing line - the blocker, the diagnosis with one line per attempt, the mechanisms exhausted, the unverified count, the single command from CEREMONY-OPS-COMMAND, the backlog id when the plugin minted one, and the closing line "Decision required from the user: none." That last line is fixed: this ceremony reports, it does not hand the user homework. End the closing line with "Verification: blocked (escalated)". With nothing blocked, emit no escalation block.\n'
  printf 'sign-off: act 7 quotes only tokens agents actually returned this turn - ticked or withheld alike. It is ten lines and the same ten every turn, with DevOps Engineer between QA Sign-off Officer and Release Manager. A role that did not run gets exactly "withheld (role not convened)". One parenthesis per line, no clock times anywhere in act 7. The Product Owner line is ticked only when PO-ACCEPT and REV-MATCHES-CRITERIA are both on the ledger. No OPS- token ever carries a tick: ops restores, it does not approve.\n'
  printf 'agents: every ceremony:* Agent call is issued with run_in_background false. An act heading may name a ceremony:* agent only if that agent ran this turn, and only a real PO-CLARIFY on the ledger stops a turn for a question.\n'
  printf 'blocks: if a hook sends this turn back, apply the correction it names and re-render from the ledger - convene nobody again unless the correction names an agent. Finish the ceremony and deliver the work in the same turn. A turn is corrected at most twice; after that it ships as written.\n'
} > "$SBLK" 2>/dev/null

cat "$SBLK" 2>/dev/null
exit 0
