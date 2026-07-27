#!/bin/sh
# ceremony :: PostToolUse Agent|Task
# The only writer of the ticket record. The model never touches this path.
set -u
trap 'exit 0' EXIT

TMPIN=$(mktemp 2>/dev/null) || exit 0
cat > "$TMPIN" 2>/dev/null || { rm -f "$TMPIN"; exit 0; }
RAW=$(cat "$TMPIN" 2>/dev/null) || RAW=''

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

int() {
  case "${1:-}" in ''|*[!0-9]*) printf '0' ;; *) printf '%s' "$1" ;; esac
}

AGENT=$(jget subagent_type)
case "$AGENT" in
  ceremony:*) ROLE=${AGENT#ceremony:} ;;
  *) rm -f "$TMPIN"; exit 0 ;;
esac
case "$ROLE" in
  *[!a-z-]*|'') rm -f "$TMPIN"; exit 0 ;;
esac

# An asynchronous launch stub is not a return. The agent has not spoken yet,
# and PostToolUse will not fire again when it does, so there is nothing here to
# record and nothing here to call malformed.
case "$RAW" in
  *'"status":"async_launched"'*|*'"status": "async_launched"'*|*'"isAsync":true'*|*'"isAsync": true'*)
    rm -f "$TMPIN"; exit 0 ;;
esac

SID=$(jget session_id)
[ -n "$SID" ] || { rm -f "$TMPIN"; exit 0; }
CWD=$(jget cwd)
[ -n "$CWD" ] || CWD=$(pwd 2>/dev/null) || { rm -f "$TMPIN"; exit 0; }

# A disbanded ceremony keeps no record, and never re-arms itself by writing one.
if [ -f "$CWD/.ceremony/config.json" ]; then
  grep -q '"enforce":[ ]*"on"' "$CWD/.ceremony/config.json" 2>/dev/null || { rm -f "$TMPIN"; exit 0; }
fi

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || DATA="${TMPDIR:-/tmp}/ceremony-plugin-data"

# A turn that asked to disband may not arm anything, whatever it does with the
# record on disk. The marker is set by the turn-state hook from the prompt
# itself, so it holds even if the removal command is mistyped or cut short.
[ -f "$DATA/sessions/$SID.disbanding" ] && { rm -f "$TMPIN"; exit 0; }

SENV="$DATA/sessions/$SID.env"
TICKET=''
[ -f "$SENV" ] && TICKET=$(sed -n 's/^CEREMONY_TICKET=//p' "$SENV" 2>/dev/null | tail -n 1)
[ -n "$TICKET" ] || { rm -f "$TMPIN"; exit 0; }

# --- the agent's return, decoded --------------------------------------------
BODY=$(printf '%s' "$RAW" | awk '
  BEGIN { RS = "\1" }
  {
    key = "\"content\":[{\"type\":\"text\",\"text\":\""
    i = index($0, key)
    if (i == 0) { key = "\"text\":\""; i = index($0, key) }
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
  }' 2>/dev/null)

# Nothing came back at all: there is no return to file. MALFORMED is reserved
# for an agent that spoke and got its own closing line wrong.
[ -n "$BODY" ] || { rm -f "$TMPIN"; exit 0; }

TOKEN=$(printf '%s' "$BODY" | grep -o 'CEREMONY-VERDICT: [A-Z][A-Z-]*' 2>/dev/null | tail -n 1 | sed 's/^CEREMONY-VERDICT: //')
[ -n "$TOKEN" ] || TOKEN=MALFORMED

case "$ROLE" in
  team-member)            SET='TEAM-REPORTED'; ACT='1 \302\267 STANDUP' ;;
  product-owner)          SET='PO-ACCEPT PO-CLARIFY'; ACT='2 \302\267 GROOMING' ;;
  architect)              SET='ARCH-RECORDED'; ACT='3 \302\267 ADR' ;;
  change-advisory-board)  SET='CAB-APPROVED CAB-APPROVED-WITH-CONDITIONS CAB-NOTHING-TO-REVIEW'; ACT='4 \302\267 CHANGE ADVISORY BOARD' ;;
  engineer)               SET='ENG-IMPLEMENTED ENG-BLOCKED ENG-NO-CHANGE'; ACT='5 \302\267 IMPLEMENTATION' ;;
  reviewer)               SET='REV-MATCHES-CRITERIA REV-DEVIATES REV-INCOMPLETE REV-NOTHING-TO-REVIEW'; ACT='5a \302\267 CONFORMANCE REVIEW' ;;
  qa)                     SET='QA-PASS QA-PARTIAL QA-FAIL QA-BLOCKED'; ACT='6 \302\267 DEFINITION OF DONE' ;;
  steering-committee)     SET='SC-ALIGNED-WITH-RESERVATIONS'; ACT='- \302\267 STEERING COMMITTEE' ;;
  *)                      SET=''; ACT='- \302\267 UNRECOGNISED ROLE' ;;
esac

OK=no
for t in $SET; do
  [ "$TOKEN" = "$t" ] && OK=yes && break
done
[ "$OK" = yes ] || TOKEN=MALFORMED

# --- runtime facts, measured by the platform rather than claimed by the agent
AGENTID=$(jget agentId)
[ -n "$AGENTID" ] || AGENTID=$(jget agent_id)
case "$AGENTID" in *[!A-Za-z0-9._-]*) AGENTID='' ;; esac

STATUS=$(printf '%s' "$RAW" | sed -n 's/.*"status":"\([a-z_]*\)".*/\1/p' | tail -n 1)
case "$STATUS" in ''|*[!a-z_]*) STATUS=unknown ;; esac

STATS=$(printf '%s' "$RAW" | sed -n 's/.*"toolStats":{\([^}]*\)}.*/\1/p' | head -n 1)
stat_of() { printf '%s' "$STATS" | sed -n 's/.*"'"$1"'":\([0-9][0-9]*\).*/\1/p' | head -n 1; }
EDITS=$(int "$(stat_of editFileCount)")
SADDED=$(int "$(stat_of linesAdded)")
SREMOVED=$(int "$(stat_of linesRemoved)")

# --- the diff, measured -----------------------------------------------------
# toolStats counts the lines every edit call touched. That is a record of
# effort, not of change: edit the same line twice and it is counted twice, and
# a paragraph rewritten in three passes is counted three times. Acts 5 and 7
# quote a diff, so the numbers on the record are a diff - taken against the
# tree snapshot the subagent-start hook wrote before the engineer began.
#
# Ephemera are excluded from both trees. A test run leaves bytecode behind and
# bytecode is not a change to the ticket; counted, it inflates the numbers this
# measurement exists to get right. node_modules is deliberately not excluded: it
# is ignored everywhere it appears, so it never reaches here, and it is the one
# path where an exclusion could hide a change somebody meant to make. The
# pathspec forms matter - :(exclude)**/__pycache__/** misses a root-level
# __pycache__ on git 2.43, and *__pycache__/* does not.
EPH1=':(exclude)*__pycache__/*'
EPH2=':(exclude)*.pyc'
EPH3=':(exclude)*.DS_Store'

MEASURED=toolstats
GFILES=0; GADDED=0; GREMOVED=0
EBASE=''; ENOW=''
if [ "$ROLE" = engineer ] && [ -n "$AGENTID" ]; then
  BASE=$(cat "$DATA/sessions/$SID.base.$AGENTID" 2>/dev/null) || BASE=''
  case "$BASE" in *[!0-9a-f]*) BASE='' ;; esac
  if [ -n "$BASE" ] && command -v git >/dev/null 2>&1 &&
     git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    NIDX="$DATA/sessions/$SID.base.$AGENTID.now"
    rm -f "$NIDX" 2>/dev/null || true
    NOW=''
    if GIT_INDEX_FILE="$NIDX" git -C "$CWD" read-tree --empty >/dev/null 2>&1 &&
       GIT_INDEX_FILE="$NIDX" git -C "$CWD" add -A -- "$EPH1" "$EPH2" "$EPH3" >/dev/null 2>&1; then
      NOW=$(GIT_INDEX_FILE="$NIDX" git -C "$CWD" write-tree 2>/dev/null)
    fi
    rm -f "$NIDX" 2>/dev/null || true
    case "$NOW" in *[!0-9a-f]*) NOW='' ;; esac
    if [ -n "$NOW" ]; then
      NUMSTAT=$(git -C "$CWD" diff --numstat "$BASE" "$NOW" 2>/dev/null)
      if [ $? -eq 0 ]; then
        MEASURED=git
        EBASE=$BASE; ENOW=$NOW
        set -- $(printf '%s\n' "$NUMSTAT" | awk '
          NF >= 3 { f++; if ($1 != "-") a += $1; if ($2 != "-") r += $2 }
          END { printf "%d %d %d", f + 0, a + 0, r + 0 }')
        GFILES=$(int "${1:-0}"); GADDED=$(int "${2:-0}"); GREMOVED=$(int "${3:-0}")
      fi
    fi
  fi
fi

if [ "$MEASURED" = git ]; then
  ADDED=$GADDED
  REMOVED=$GREMOVED
else
  ADDED=$SADDED
  REMOVED=$SREMOVED
fi

# --- the record ------------------------------------------------------------
ROOT="$CWD/.ceremony"
DIR="$ROOT/$TICKET"
mkdir -p "$DIR/evidence" 2>/dev/null || { rm -f "$TMPIN"; exit 0; }
[ -f "$ROOT/.gitignore" ] || printf '*\n' > "$ROOT/.gitignore" 2>/dev/null || true
[ -f "$ROOT/config.json" ] || printf '{"version":"2.2.2","enforce":"on"}\n' > "$ROOT/config.json" 2>/dev/null || true

N=$(ls "$DIR/evidence" 2>/dev/null | wc -l | tr -d ' ')
case "$N" in ''|*[!0-9]*) N=0 ;; esac
N=$((N + 1))
NNN=$(printf '%03d' "$N")
EV="evidence/$NNN-$ROLE.json"
cp "$TMPIN" "$DIR/$EV" 2>/dev/null || true
rm -f "$TMPIN"

TS=$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null) || TS=unknown
LED="$DIR/ledger.jsonl"

# --- the hunks this ticket's engineer produced ------------------------------
# git diff over the working tree cannot separate what the engineer wrote from
# what was already there, and a file that is both - dirty before the ticket and
# edited during it - is where that bites: the reviewer reads somebody else's
# hunks as changes nobody asked for, raises them as EXTRA, and the acceptance
# is withheld over work this ceremony did not do. The two tree stamps do
# separate them, so the diff between them is written out and the reviewing
# roles read that instead of guessing.
if [ -n "$EBASE" ] && [ -n "$ENOW" ] && [ "$EBASE" != "$ENOW" ]; then
  {
    printf '# %s \342\200\224 %s \342\200\224 the hunks ceremony:engineer produced\n' "$TICKET" "$TS"
    printf '# Everything here was written during this ticket. Anything in git diff\n'
    printf '# that is not here was already in the working tree and belongs to nobody\n'
    printf '# in this ceremony.\n'
    git -C "$CWD" diff "$EBASE" "$ENOW" 2>/dev/null
    printf '\n'
  } >> "$DIR/implementation.diff" 2>/dev/null || true
fi

# Counts the sign-off gate holds the turn to, taken here because this is where
# the agent's own words are still in hand.
COND=0
BLOCKED=0
CRIT=0
UNMET=0
EXTRA=0
AC=0
case "$ROLE" in
  product-owner)
    AC=$(printf '%s' "$BODY" | grep -c '^CEREMONY-AC: ' 2>/dev/null) || AC=0 ;;
  change-advisory-board)
    COND=$(printf '%s' "$BODY" | grep -c '^CEREMONY-CONDITION: ' 2>/dev/null) || COND=0 ;;
  qa)
    BLOCKED=$(printf '%s' "$BODY" | grep -c '^CEREMONY-DOD: [0-9][0-9]* BLOCKED ' 2>/dev/null) || BLOCKED=0 ;;
  reviewer)
    CRIT=$(printf '%s' "$BODY" | grep -c '^CEREMONY-CRIT: ' 2>/dev/null) || CRIT=0
    UNMET=$(printf '%s' "$BODY" | grep -c '^CEREMONY-CRIT: [0-9][0-9]* UNMET ' 2>/dev/null) || UNMET=0
    EXTRA=$(printf '%s' "$BODY" | grep -c '^CEREMONY-CRIT: [0-9][0-9]* EXTRA ' 2>/dev/null) || EXTRA=0 ;;
esac
COND=$(int "$COND"); BLOCKED=$(int "$BLOCKED"); AC=$(int "$AC")
CRIT=$(int "$CRIT"); UNMET=$(int "$UNMET"); EXTRA=$(int "$EXTRA")
[ "$TOKEN" = QA-BLOCKED ] && [ "$BLOCKED" -eq 0 ] && BLOCKED=1

# The reviewer answers criteria, not EXTRA lines. Only the answers are counted
# against the Product Owner's list.
CRIT=$((CRIT - EXTRA))
[ "$CRIT" -lt 0 ] && CRIT=0

# --- the commit screen ------------------------------------------------------
# This ceremony never commits: the working tree is the artifact the last three
# eyes review, and a commit destroys it. So a criterion that demands one cannot
# be met by any role here, and accepting it would open the write gate on a
# promise nobody in this process can keep.
if [ "$ROLE" = product-owner ] && [ "$TOKEN" = PO-ACCEPT ]; then
  ACLINES=$(printf '%s' "$BODY" | grep '^CEREMONY-AC: ' 2>/dev/null)
  # The boundaries are not decoration: "Emergency" contains "merge", and a
  # button that has to turn red is not a request to merge anything.
  if printf '%s' "$ACLINES" | grep -qiE '(^|[^A-Za-z])(commit|committed|commits|committing|push|pushed|pushes|merge|merged|merges|merging|rebase|rebased|pull request|pull-request|PR)([^A-Za-z]|$)' 2>/dev/null; then
    TOKEN=PO-ACCEPT-OUT-OF-SCOPE
  fi
fi

# --- the diff claim, against the measurement --------------------------------
# Only ever raised against a measurement that is itself a diff. Comparing the
# engineer's diff against a count of edit calls accuses an honest engineer of
# arithmetic the plugin got wrong, which is what this check is for the opposite
# of.
MISMATCH=false
if [ "$ROLE" = engineer ] && [ "$MEASURED" = git ]; then
  DL=$(printf '%s' "$BODY" | grep '^CEREMONY-DIFF: ' 2>/dev/null | tail -n 1)
  if [ -n "$DL" ]; then
    NUMS=$(printf '%s' "$DL" | grep -o '[0-9][0-9]*' 2>/dev/null | tr '\n' ' ')
    CA=$(int "$(printf '%s' "$NUMS" | cut -d' ' -f2)")
    CR=$(int "$(printf '%s' "$NUMS" | cut -d' ' -f3)")
    D1=$((CA - ADDED)); [ "$D1" -lt 0 ] && D1=$((-D1))
    D2=$((CR - REMOVED)); [ "$D2" -lt 0 ] && D2=$((-D2))
    { [ "$D1" -gt 2 ] || [ "$D2" -gt 2 ]; } && MISMATCH=true
  fi
fi

printf '{"ts":"%s","session":"%s","ticket":"%s","role":"%s","agent_type":"%s","agent_id":"%s","status":"%s","verdict":"%s","ac":%s,"conditions":%s,"blocked":%s,"crit":%s,"unmet":%s,"extra":%s,"edits":%s,"added":%s,"removed":%s,"measured":"%s","stat_added":%s,"stat_removed":%s,"diff_mismatch":%s,"evidence":"%s"}\n' \
  "$TS" "$SID" "$TICKET" "$ROLE" "$AGENT" "$AGENTID" "$STATUS" "$TOKEN" \
  "$AC" "$COND" "$BLOCKED" "$CRIT" "$UNMET" "$EXTRA" "$EDITS" "$ADDED" "$REMOVED" \
  "$MEASURED" "$SADDED" "$SREMOVED" "$MISMATCH" "$EV" >> "$LED" 2>/dev/null || true

# --- the implementation entry, from what the engineer actually did ----------
# Written from the platform's own measurement rather than the engineer's
# summary of it. This is the entry the chair's reading has to postdate, and the
# one acts 5 and 7 quote their numbers from.
if [ "$ROLE" = engineer ]; then
  MOVED=no
  [ "$EDITS" -gt 0 ] && MOVED=yes
  [ "$MEASURED" = git ] && [ "$GFILES" -gt 0 ] && MOVED=yes
  # Measured by git and nothing changed: the engineer touched files and put
  # them back as they were. That is not an implementation, whatever the edit
  # counter says, and filing one would give the reviewers a diff to read that
  # does not exist.
  [ "$MEASURED" = git ] && [ "$GFILES" -eq 0 ] && MOVED=no
  if command -v git >/dev/null 2>&1 && git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    NOWTREE=$({ git -C "$CWD" status --porcelain -- "$EPH1" "$EPH2" "$EPH3" 2>/dev/null; git -C "$CWD" diff --numstat HEAD -- "$EPH1" "$EPH2" "$EPH3" 2>/dev/null; } | cksum 2>/dev/null | tr -d ' \t')
    PREVTREE=$(cat "$DATA/sessions/$SID.tree" 2>/dev/null) || PREVTREE=''
    [ -n "$NOWTREE" ] && [ -n "$PREVTREE" ] && [ "$NOWTREE" != "$PREVTREE" ] && MOVED=yes
    [ -n "$NOWTREE" ] && printf '%s\n' "$NOWTREE" > "$DATA/sessions/$SID.tree" 2>/dev/null || true
  fi

  if [ "$MOVED" = yes ]; then
    # Measured by git, the file count is the number of paths the diff names.
    # Without it, editFileCount is the only thing left, and it counts edit
    # calls rather than files: three edits to one file is three. The paths the
    # write recorder saw are the better fallback. "(working tree)" is the shell
    # recorder's placeholder for a change it saw without a path, and is not a
    # file.
    FILES=0
    if [ "$MEASURED" = git ]; then
      FILES=$GFILES
    else
      if [ -n "$AGENTID" ] && [ -f "$LED" ]; then
        FILES=$(grep '"role":"implementation"' "$LED" 2>/dev/null | grep '"agent_id":"'"$AGENTID"'"' | sed -n 's/.*"file":"\([^"]*\)".*/\1/p' | grep -v '^(working tree)$' | sort -u | wc -l | tr -d ' ')
      fi
      FILES=$(int "$FILES")
      [ "$FILES" -eq 0 ] && FILES=$EDITS
    fi
    printf '{"ts":"%s","session":"%s","ticket":"%s","role":"implementation","by":"engineer","agent_id":"%s","via":"agent","measured":"%s","files":%s,"added":%s,"removed":%s,"edits":%s}\n' \
      "$TS" "$SID" "$TICKET" "$AGENTID" "$MEASURED" "$FILES" "$ADDED" "$REMOVED" "$EDITS" >> "$LED" 2>/dev/null || true
  fi
fi

# --- what was already dirty, written where the roles will read it ------------
# The reviewing roles read the ticket, not the session state, so the inherited
# paths have to be on the ticket. Without them a file somebody edited yesterday
# comes back as an EXTRA the reviewer raises, a "no unrelated files" QA marks
# failed, and a board condition about work nobody in this ceremony did.
if [ ! -f "$DIR/ticket.md" ]; then
  BASEF="$DATA/sessions/$SID.baseline"
  {
    printf '# %s\n\n' "$TICKET"
    if [ -f "$BASEF" ] && grep -q '^file: ' "$BASEF" 2>/dev/null; then
      printf 'Inherited paths (already modified when this session opened - not this\n'
      printf "ticket's work, not this ticket's scope, and no signature covers them):\n\n"
      sed -n 's/^file: //p' "$BASEF" 2>/dev/null | sed 's/^[ \t]*/- /'
      printf '\n'
    else
      printf 'Inherited paths: none. The working tree was clean when this session\nopened, so everything in the diff belongs to this session.\n\n'
    fi
  } > "$DIR/ticket.md" 2>/dev/null || true
fi

{
  printf '\n## '
  printf "$ACT"
  printf ' \342\200\224 %s \342\200\224 %s \342\200\224 %s\n\n' "$AGENT" "$TS" "$TOKEN"
  printf '%s\n' "$BODY"
} >> "$DIR/ticket.md" 2>/dev/null || true

exit 0
