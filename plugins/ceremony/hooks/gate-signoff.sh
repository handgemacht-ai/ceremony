#!/bin/sh
# ceremony :: Stop
# Thirty-one rules. M and V come first and are outside the correction budget:
# the chair editing and a commit are the two failures worth their own allowance.
# Then A to L and Y, Z, AF, in order, the first one tripped sending the turn
# back. Then N to X and AA to AE plus AG, the chain of four eyes and the loop,
# reported together in one message.
# A turn gets at most two ordinary corrections plus at most two exempt ones.
# Finally, on the pass path only, the backlog is written.
set -u
trap 'exit 0' EXIT

MAXBLOCKS=2

RAW=$(cat 2>/dev/null) || RAW=''

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

FINISH='This is a re-render, not a re-run. Every return act 7 needs is already on the ledger: convene nobody again, call no Agent tool, and rewrite the response from what the record already holds. Do not stop, do not ask which option to take, and do not hand the choice back. Apply the correction, complete the ceremony and deliver the requested work in this same turn.'

# The same instruction for the five corrections whose remedy may need an agent.
# Those cannot also say convene nobody, and a boilerplate that contradicts the
# correction above it is a correction the turn is entitled to ignore.
FINISH2='Re-render from the ledger: every return already recorded is quoted from there rather than collected a second time. The only agent you may call again is the one this correction names, and only where the correction asks for it. Do not stop, do not ask which option to take, and do not hand the choice back. Apply the correction, complete the ceremony and deliver the requested work in this same turn.'

BFILE=''

block() {
  [ -n "$BFILE" ] && printf '%s\n' "$((BN + 1))" > "$BFILE" 2>/dev/null
  printf '%s\n' "{\"decision\":\"block\",\"reason\":\"$1\\n\\n$FINISH\"}"
  exit 0
}

# block(), for a correction whose remedy is one named agent.
blockc() {
  [ -n "$BFILE" ] && printf '%s\n' "$((BN + 1))" > "$BFILE" 2>/dev/null
  printf '%s\n' "{\"decision\":\"block\",\"reason\":\"$1\\n\\n$FINISH2\"}"
  exit 0
}

MSG=$(jget last_assistant_message)
[ -n "$MSG" ] || exit 0

SID=$(jget session_id)
[ -n "$SID" ] || exit 0
CWD=$(jget cwd)
[ -n "$CWD" ] || CWD=$(pwd 2>/dev/null) || exit 0

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || DATA="${TMPDIR:-/tmp}/ceremony-plugin-data"

# The correction budget, spent per turn and reset by the turn-state hook. Two,
# because a turn that opens on the wrong path usually needs one correction to
# reach the right one and a second to get the sign-off right.
BFILE="$DATA/sessions/$SID.corrections"
BN=$(cat "$BFILE" 2>/dev/null) || BN=0
case "$BN" in ''|*[!0-9]*) BN=0 ;; esac

SENV="$DATA/sessions/$SID.env"
[ -f "$SENV" ] || exit 0
TICKET=$(sed -n 's/^CEREMONY_TICKET=//p' "$SENV" 2>/dev/null | tail -n 1)
[ -n "$TICKET" ] || exit 0
[ "${CEREMONY_ENFORCE:-on}" = off ] && exit 0
if [ -f "$CWD/.ceremony/config.json" ]; then
  grep -q '"enforce":[ ]*"on"' "$CWD/.ceremony/config.json" 2>/dev/null || exit 0
fi
TSTART=$(sed -n 's/^CEREMONY_TURN_START=//p' "$SENV" 2>/dev/null | tail -n 1)

LEDGER="$CWD/.ceremony/$TICKET/ledger.jsonl"
MINE=''
[ -f "$LEDGER" ] && MINE=$(grep '"session":"'"$SID"'"' "$LEDGER" 2>/dev/null)

HATCH='If you want none of this: /ceremony:disband removes the record, CEREMONY_ENFORCE=off disarms the gates, /hooks turns the hooks off, /output-style default ends the ceremony.'

# --- act 7, on its own ------------------------------------------------------
# Token rules apply to the sign-off and nowhere else. A response is free to
# quote a gate's own wording, a command file or a ticket note; those are prose
# about the ceremony, not signatures in it.
ACT7=$(printf '%s' "$MSG" | awk '
  index($0, "SIGN-OFF") { f = 1 }
  index($0, "RETROSPECTIVE") { f = 0 }
  f { print }' 2>/dev/null)

# --- act 4, on its own ------------------------------------------------------
# The dispositions are counted here and nowhere else, for the same reason the
# tokens are counted in act 7 and nowhere else.
ACT4=$(printf '%s' "$MSG" | awk '
  index($0, "CHANGE ADVISORY BOARD") { f = 1 }
  index($0, "IMPLEMENTATION") { f = 0 }
  f { print }' 2>/dev/null)

CHECK=$(printf '\342\234\223')

# --- the gate agrees its own nouns ------------------------------------------
# Rule U refuses "<n> thing(s)" in the response, so a gate message that writes
# it is asking for a discipline it does not keep. plu prints the count and the
# noun that agrees with it; every message below uses it.
plu() {
  # <count> <singular> <plural>
  case "$1" in
    1) printf '1 %s' "$2" ;;
    *) printf '%s %s' "$1" "$3" ;;
  esac
}

# --- the backlog, in two halves that land at different moments ---------------
# Exactly two kinds are written and there is no code path for a third, but they
# come from different places and so they are filed at different times.
#
# A restore-verification entry was already minted by the ledger, from an agent
# return, before this hook ran. Nothing the render says can unmake it, so it is
# promoted here - above every rule and above the correction budget - because a
# response that says a ticket was filed while the disk disagrees is the one
# outcome that must be impossible, and the turn most likely to spend its budget
# is the blocked one, which is exactly the turn with something to carry.
#
# A carried-condition is different: it exists only because this render said
# `Disposition: <n> carried`, and a render the gate is about to reject is not a
# statement of what happened. Filing it here would leave an entry behind that
# the corrected render never mentions, and rule AC would then block the
# corrected render for not naming it. So it is written when the turn actually
# ends - on the pass path, and on the budget-exhausted path where the render
# ships as it stands - and never from a turn that was sent back.
#
# Both halves dedupe on identity rather than on wording. What identifies an
# entry is the ticket that opened it and the kind of thing it is - and, for a
# board condition, the number the board itself gave it. Never the summary: the
# summary is prose, it is rewritten every time the response is re-rendered, and
# a key that moves when the wording moves is not a key. That was the defect:
# one broken Docker daemon, two backlog ids, and a correction loop where the
# chair swapped one id for the other until the budget ran out.
#
# The one exception is a board condition filed before this version, which
# carries no number because no version that wrote it had one to give. For those
# rows the wording is all there is, so the wording is what they are keyed on -
# the same fallback file_conditions uses. It matters more here than there: this
# is the half that deletes, and two different conditions from one ticket sharing
# a key would collapse into one and take the other's wording with it, once,
# irreversibly, on the first turn after the upgrade.
#
# `jrow` is the one reader: sh has no JSON, and every attempt to key on a
# substring of the prose is how this went wrong the first time.
jrow='
function fld(s, n,   r) {
  r = ""
  if (match(s, "\"" n "\":\"[^\"]*\"")) {
    r = substr(s, RSTART, RLENGTH)
    sub("\"" n "\":\"", "", r); sub("\"$", "", r)
  }
  return r
}
function num(s, n,   r) {
  r = ""
  if (match(s, "\"" n "\":[0-9]+")) { r = substr(s, RSTART, RLENGTH); sub(".*:", "", r) }
  return r
}
function key(s,   k, o, c) {
  k = fld(s, "kind"); o = fld(s, "opened_by"); c = num(s, "cond")
  if (k == "" || o == "") return ""
  if (k == "carried-condition")
    return o "|" k "|" (c == "" ? "s:" fld(s, "summary") : c)
  return o "|" k
}
function sup(s,   m) {
  if (match(s, "\"superseded\":\\[[^]]*\\],")) return substr(s, RSTART, RLENGTH)
  return ""
}
'

# --- one writer at a time ----------------------------------------------------
# Twenty sessions at once is this user's ordinary day, and two of them blocking
# in one project is not a thought experiment. Both writes below are
# read-modify-write, and two turns that each read the file before either wrote
# it would each rebuild the backlog from a version that is already stale - the
# second rename dropping the first one's row.
#
# `mkdir` is the lock, because it is the one atomic create every shell has;
# `flock` is not on macOS. A lock in a hook is a thing that can be left behind
# by a turn that was killed, so this one is not waited on forever: after a
# minute it is not a holder, it is litter, and it is swept. Nothing sleeps -
# the age check is the wait - and holding it is never required for correctness,
# only for not doing the work twice. Each write is checked against what it read
# regardless, so a swept lock cannot cost a row.
LKD=''
LKHELD=0
lock_take() {
  LKD="$1.lock"
  LKN=0
  while [ "$LKN" -lt 40 ]; do
    LKN=$((LKN + 1))
    if mkdir "$LKD" 2>/dev/null; then LKHELD=1; return 0; fi
    find "$LKD" -maxdepth 0 -mmin +1 -exec rm -rf {} + 2>/dev/null
  done
  LKHELD=0
  return 1
}
lock_drop() {
  [ "$LKHELD" = 1 ] && rmdir "$LKD" 2>/dev/null
  LKHELD=0
  return 0
}

# --- the litter every version that filed before this one left behind ---------
# A project that has already been through the defect holds two rows for one
# blocker, and nothing in either of them says which was meant. They collapse
# onto the oldest id, because that is the one an earlier response is most likely
# to have printed for the user, and the id that loses is recorded on the
# survivor rather than disappearing: a session that quoted it can still find out
# where it went. This runs on every turn, before anything reads the file.
heal_backlog() {
  BLF="$CWD/.ceremony/backlog.jsonl"
  [ -f "$BLF" ] || return 0
  HTMP="$BLF.heal.$$"
  lock_take "$BLF" || :
  HBEFORE=$(cat "$BLF" 2>/dev/null) || HBEFORE=''
  awk "$jrow"'
    { if ($0 == "") next
      order[++n] = $0; k = key($0); rk[n] = k
      if (k == "") next
      if (k in first) { id = fld($0, "id")
        if (id != "") extra[k] = extra[k] (extra[k] == "" ? "" : ",") "\"" id "\""
        order[n] = ""; dropped = 1; next }
      first[k] = n }
    END {
      if (!dropped) exit 3
      for (i = 1; i <= n; i++) {
        row = order[i]
        if (row == "") continue
        k = rk[i]
        if (k != "" && (k in extra)) {
          s = sup(row)
          if (s != "") sub("\"superseded\":\\[", "\"superseded\":[" extra[k] ",", row)
          else sub("\"status\":\"", "\"superseded\":[" extra[k] "],\"status\":\"", row)
        }
        print row
      }
    }' "$BLF" > "$HTMP" 2>/dev/null
  # awk exits 3 when it found nothing to collapse, and then nothing is written.
  # The same check as the promotion below: only replace a file that is still the
  # one this turn read.
  if [ $? -eq 0 ] && [ "$(cat "$BLF" 2>/dev/null)" = "$HBEFORE" ]; then
    mv "$HTMP" "$BLF" 2>/dev/null || rm -f "$HTMP" 2>/dev/null
  else
    rm -f "$HTMP" 2>/dev/null
  fi
  lock_drop
  return 0
}

promote_restore() {
  BLDIR="$CWD/.ceremony"
  [ -d "$BLDIR" ] || return 0
  BLF="$BLDIR/backlog.jsonl"
  PEND="$BLDIR/$TICKET/carry.jsonl"
  [ -f "$PEND" ] || return 0
  PTMP="$BLF.promote.$$"
  # Three things keep this write whole, and the lock above is only the first.
  # The rename is atomic and lands in the same directory, so no reader ever
  # sees half a file. Nothing is written at all when the result matches what is
  # already there, which is the ordinary case - a re-render promotes what it
  # promoted before. And what is written is checked against what was read: if
  # the file moved underneath this turn, the work is redone on the newer
  # version rather than written over it.
  lock_take "$BLF" || :
  # Creating the empty file belongs inside the lock too: it truncates, and a
  # turn that created it a moment after another turn filled it would empty it.
  [ -f "$BLF" ] || : > "$BLF" 2>/dev/null || { lock_drop; return 0; }
  ATT=0
  while [ "$ATT" -lt 5 ]; do
    ATT=$((ATT + 1))
    BEFORE=$(cat "$BLF" 2>/dev/null) || BEFORE=''
    # A pending row whose identity is already filed is the same blocker, whatever
    # either row now calls it. The filed row keeps its id and takes the newer
    # wording, because the newer wording describes the attempt made last. There is
    # no branch here that appends a second row for something already carried.
    awk -v pend="$PEND" "$jrow"'
      { order[++n] = $0; k = key($0); if (k != "") at[k] = n }
      END {
        while ((getline line < pend) > 0) {
          if (line !~ /"kind":"restore-verification"/) continue
          k = key(line); id = fld(line, "id")
          if (k == "" || id == "") continue
          if (k in at) {
            i = at[k]; old = fld(order[i], "id")
            if (old != "" && old != id) sub("\"id\":\"" id "\"", "\"id\":\"" old "\"", line)
            s = sup(order[i])
            if (s != "" && sup(line) == "") sub("\"status\":\"", s "\"status\":\"", line)
            order[i] = line
          } else { order[++n] = line; at[k] = n }
        }
        close(pend)
        for (i = 1; i <= n; i++) if (order[i] != "") print order[i]
      }' "$BLF" > "$PTMP" 2>/dev/null || { rm -f "$PTMP" 2>/dev/null; break; }
    if cmp -s "$PTMP" "$BLF" 2>/dev/null; then
      rm -f "$PTMP" 2>/dev/null
      break
    fi
    NOW=$(cat "$BLF" 2>/dev/null) || NOW=''
    if [ "$NOW" = "$BEFORE" ]; then
      mv "$PTMP" "$BLF" 2>/dev/null || rm -f "$PTMP" 2>/dev/null
      break
    fi
    rm -f "$PTMP" 2>/dev/null
  done
  lock_drop
  return 0
}

file_conditions() {
  BLDIR="$CWD/.ceremony"
  [ -d "$BLDIR" ] || return 0
  BLF="$BLDIR/backlog.jsonl"
  NCARR=$(printf '%s' "$ACT4" | grep -c 'Disposition: *[0-9][0-9]* *carried' 2>/dev/null) || NCARR=0
  case "$NCARR" in ''|*[!0-9]*) NCARR=0 ;; esac
  [ "$NCARR" -gt 0 ] || return 0
  HAVE=''
  [ -f "$BLF" ] && HAVE=$(sed -n 's/.*"id":"\(CER-BL-[0-9]*\)".*/\1/p' "$BLF" 2>/dev/null)
  NEXTN=$(printf '%s' "$HAVE" | sed -n 's/CER-BL-0*\([0-9][0-9]*\)/\1/p' | sort -n | tail -n 1)
  case "$NEXTN" in ''|*[!0-9]*) NEXTN=0 ;; esac
  # Pending carry rows hold ids too, and a condition must not be given one the
  # ledger has already handed out.
  PENDN=$(sed -n 's/.*"id":"CER-BL-0*\([0-9][0-9]*\)".*/\1/p' "$BLDIR"/*/carry.jsonl 2>/dev/null |
    sort -n | tail -n 1)
  case "$PENDN" in ''|*[!0-9]*) PENDN=0 ;; esac
  [ "$PENDN" -gt "$NEXTN" ] && NEXTN=$PENDN
  SPR=$(sed -n 's/^CEREMONY_SPRINT=//p' "$SENV" 2>/dev/null | tail -n 1)
  case "$SPR" in ''|*[!0-9]*) SPR=0 ;; esac
  TSN=$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null) || TSN=unknown
  printf '%s' "$ACT4" | grep 'Disposition: *[0-9][0-9]* *carried' 2>/dev/null |
  while IFS= read -r dline; do
    dn=$(printf '%s' "$dline" | sed -n 's/.*Disposition: *\([0-9][0-9]*\).*/\1/p')
    [ -n "$dn" ] || continue
    # Only a MUST is carried. The board's own line says which it is.
    cline=$(printf '%s' "$ACT4" | grep -F "$dn " 2>/dev/null | grep -E '\[MUST\]' | head -n 1)
    [ -n "$cline" ] || continue
    EMD=$(printf '\342\200\224')
    sum=$(printf '%s' "$dline" | sed "s/.*carried *//; s/^$EMD *//; s/^- *//; s/^: *//" |
      tr -d '\\"' | cut -c1-160)
    [ -n "$sum" ] || sum="board condition $dn carried to the next sprint"
    NEXTN=$((NEXTN + 1))
    cid=$(printf 'CER-BL-%04d' "$NEXTN")
    # Already carried from this ticket? The board's own number is what says so.
    # A ticket can carry two different conditions and they are two entries, so
    # the number is part of the identity and the wording is no part of it at
    # all. A row filed by an earlier version carries no number, and for those
    # rows the wording is the only thing left to recognise them by.
    if [ -f "$BLF" ] && awk -v t="$TICKET" -v c="$dn" -v s="$sum" '
         index($0, "\"kind\":\"carried-condition\"") > 0 {
           if (index($0, "\"opened_by\":\"" t "\"") == 0) next
           if (index($0, "\"cond\":" c ",") > 0) { f = 1; exit }
           if ($0 !~ /"cond":[0-9]+/ && index($0, "\"summary\":\"" s "\"") > 0) { f = 1; exit }
         }
         END { exit f ? 0 : 1 }' "$BLF" 2>/dev/null; then
      continue
    fi
    printf '{"id":"%s","ts":"%s","kind":"carried-condition","cond":%s,"opened_by":"%s","sprint_opened":%s,"summary":"%s","needs":"apply the condition","command":"none","owner":"Change Advisory Board","status":"open"}\n' \
      "$cid" "$TSN" "$dn" "$TICKET" "$SPR" "$sum" >> "$BLF" 2>/dev/null || true
  done
  return 0
}

# The turn is over: whatever this render said, it is what ships.
finish() {
  file_conditions 2>/dev/null || true
  exit 0
}

heal_backlog 2>/dev/null || true
promote_restore 2>/dev/null || true

# ---------------------------------------------------------------------------
# The three exempt rules, checked before everything else and outside the budget.
#
# A budget of two corrections is what makes this hook terminate, and it is kept.
# But it also means the third defect of a turn ships unremarked, and twice now
# that third defect has been a commit: the earlier corrections spent the budget,
# and the rule that would have caught the commit never ran. Three failures are
# worth their own allowance, because each of them is the ceremony reporting work
# it did not govern - the chair writing the code itself, a commit that destroys
# the artifact every signature was about, and the last line of a blocked turn
# handing the user the repair job this whole release exists to stop handing
# them. That last one shipped through a spent budget in testing, in the exact
# words the field report opened with.
#
# Admission to this belt is narrow, and the test is a closed remedy: the
# correction has to be satisfiable by writing one fixed sentence, with no agent
# convened, no measurement taken and no ledger read. Each of the three passes -
# each asks for a literal, and each is false once that literal is on the page,
# so none can fire twice. Rule Z looks similar and does not qualify: clearing it
# means convening QA again, which is a re-run, not a re-render. The exempt
# allowance is itself capped at two, so the worst case stays four blocks.
XFILE="$DATA/sessions/$SID.corrections-exempt"
XN=$(cat "$XFILE" 2>/dev/null) || XN=0
case "$XN" in ''|*[!0-9]*) XN=0 ;; esac

blockx() {
  printf '%s\n' "$((XN + 1))" > "$XFILE" 2>/dev/null
  printf '%s\n' "{\"decision\":\"block\",\"reason\":\"$1\\n\\n$FINISH\"}"
  exit 0
}

if [ "$XN" -lt 2 ]; then
  # --- M: the chair edited --------------------------------------------------
  # Nobody in this ceremony can sign for that. There is no role behind it, no
  # brief it answered and no review that read it as a change.
  CHAIREDIT=''
  if [ -n "$TSTART" ]; then
    for t in $(printf '%s' "$MINE" | grep '"role":"implementation"' 2>/dev/null | grep '"by":"chair"' | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p'); do
      [ "$t" \< "$TSTART" ] || CHAIREDIT=yes
    done
  fi
  if [ -n "$CHAIREDIT" ]; then
    case "$MSG" in
      *'Ceremony has no signature for work the chair did itself'*) ;;
      *) blockx "M \\u00b7 The chair edited. An implementation entry on $TICKET is stamped by:\\\"chair\\\", which means this turn changed a file with its own hands rather than through ceremony:engineer.\\n\\nThere is no signature available for that work: no brief it answered, no criteria it was written against, and no reviewer who read it as a change. Act 7 withholds every line, and the response says so in this exact sentence: The chair edited. Ceremony has no signature for work the chair did itself.\\n\\nThe change stays. It is the signatures that do not.\\n\\n$HATCH" ;;
    esac
  fi

  # --- V: a commit ----------------------------------------------------------
  # The stance is documented, the criteria screen keeps it out of acceptance,
  # and since v2.2.1 the Bash gate refuses the command outright. This is the
  # last of the four, and the only one that runs after the fact: it exists for
  # the case where the gates were off, or the commit came from somewhere they
  # do not reach.
  COMMITTED=''
  THEAD=$(sed -n 's/^CEREMONY_TURN_HEAD=//p' "$SENV" 2>/dev/null | tail -n 1)
  case "$THEAD" in *[!0-9a-f]*) THEAD='' ;; esac
  if [ -n "$THEAD" ] && command -v git >/dev/null 2>&1; then
    NHEAD=$(git -C "$CWD" rev-parse HEAD 2>/dev/null) || NHEAD=''
    case "$NHEAD" in *[!0-9a-f]*) NHEAD='' ;; esac
    [ -n "$NHEAD" ] && [ "$NHEAD" != "$THEAD" ] && COMMITTED=repo
  fi
  case "$MSG" in
    *'Committed: yes'*) COMMITTED=claimed ;;
  esac
  if [ -n "$COMMITTED" ]; then
    case "$MSG" in
      *'no signature in this ceremony covers a commit'*) ;;
      *) blockx "V \\u00b7 A commit was made in this turn. The ceremony never commits, and the reason is not decorum: the working tree is the artifact act 7 signs for, so a commit turns the reviewed thing into history and leaves the user holding something else. The rollback the board wrote down was only true while the change was uncommitted, and committing was the one decision in this process that was never delegated.\\n\\nIt cannot be taken back from here, so it is disclosed. Act 7 withholds every line, and the response carries this exact sentence: A commit was made in this turn; no signature in this ceremony covers a commit.\\n\\nThe closing line still ends Committed: no (the tree is yours) only when nothing was committed. It did not, so say what happened instead, in one line, and leave the decision about the commit with the user.\\n\\n$HATCH" ;;
    esac
  fi
  # --- AF: the closed final-resort line ------------------------------------
  # The whole release is about not handing the user homework. One line carries it,
  # and it is fixed.
  DEC=$(printf '%s' "$MSG" | grep 'Decision required from the user:' 2>/dev/null | head -n 1)
  if [ -n "$DEC" ]; then
    REST=${DEC#*Decision required from the user:}
    REST=${REST#"${REST%%[! ]*}"}
    # Case-folded before the match: a sentence that starts with a capital is the
    # ordinary way to write one, and "None." is the same answer as "none.".
    REST=$(printf '%s' "$REST" | tr 'A-Z' 'a-z')
    case "$REST" in
      none|none.*|none[!a-z]*) ;;
      *)
        blockx "AF \\u00b7 The response asks the user for a decision:\\n  $DEC\\n\\nThat line has one permitted value and it is none. The ceremony was asked to stop escalating its own unfinished business, and this is the line where that shows: by the time the escalation is written, ceremony:devops has already tried the mechanisms this repository defines, the sprint has rolled if a mechanism remained, and what is left is a report.\\n\\nThe line reads exactly:\\n  Decision required from the user: none. This is a report; the ticket stays carried.\\n\\nEverything the user might want to know goes above it - the blocker, the diagnosis with one line per attempt, the mechanisms exhausted, the count of unverified criteria, and the single command from ceremony:devops's CEREMONY-OPS-COMMAND line. Naming that command is not asking for it to be run; it is telling the user what would clear this if they ever want it cleared.\\n\\nThe one thing that legitimately asks the user a question is PO-CLARIFY, and that is about an ambiguous request, not a broken environment.\\n\\n$HATCH" ;;
    esac
  fi
fi

# The budget, spent. Everything from here down is a correction the turn can
# live without; the two above were not.
[ "$BN" -ge "$MAXBLOCKS" ] && finish

# --- A: a token nobody returned --------------------------------------------
# Every token in act 7 is a quotation. Ticked or withheld, it has to have been
# said by an agent that ran, and the ledger is where it was said.
SIGNING='PO-ACCEPT ARCH-RECORDED CAB-APPROVED CAB-APPROVED-WITH-CONDITIONS QA-PASS SC-ALIGNED-WITH-RESERVATIONS REV-MATCHES-CRITERIA'
WITHHOLDING='TEAM-REPORTED PO-CLARIFY PO-ACCEPT-OUT-OF-SCOPE CAB-NOTHING-TO-REVIEW QA-PARTIAL QA-FAIL QA-BLOCKED ENG-IMPLEMENTED ENG-BLOCKED ENG-NO-CHANGE REV-DEVIATES REV-INCOMPLETE REV-NOTHING-TO-REVIEW OPS-RESTORED OPS-BLOCKED OPS-NEEDS-CHANGE OPS-NOTHING-TO-DO MALFORMED'
for tok in $(printf '%s' "$ACT7" | grep -o '[A-Z][A-Z0-9-]*' 2>/dev/null | sort -u); do
  case " $SIGNING $WITHHOLDING " in *" $tok "*) ;; *) continue ;; esac
  if ! printf '%s' "$MINE" | grep -q '"verdict":"'"$tok"'"' 2>/dev/null; then
    block "Act 7 quotes the verdict token $tok, and no agent returned $tok for $TICKET in this session. The ledger .ceremony/$TICKET/ledger.jsonl has no such entry, so that line was written rather than collected.\\n\\nA role with no ledger entry has exactly one permitted act 7 line: <Role> \\u2014 withheld (role not convened). That is the ordinary outcome and it needs no apology. It applies to a withheld line as much as to a ticked one: withheld ($tok) still claims the agent spoke.\\n\\n$HATCH"
  fi
done

# --- B: a tick on a token that withholds ------------------------------------
CHECK=$(printf '\342\234\223')
for tok in $(printf '%s' "$ACT7" | grep -F "$CHECK" 2>/dev/null | grep -o '[A-Z][A-Z0-9]*-[A-Z0-9-]*' 2>/dev/null | sort -u); do
  case "$tok" in CEREMONY-*|SIGN-OFF) continue ;; esac
  case " $SIGNING " in *" $tok "*) continue ;; esac
  block "Act 7 gives a tick to $tok. $tok is not a signing token: it withholds.\\n\\nOnly these seven may carry a tick: PO-ACCEPT, ARCH-RECORDED, CAB-APPROVED, CAB-APPROVED-WITH-CONDITIONS, QA-PASS, SC-ALIGNED-WITH-RESERVATIONS, REV-MATCHES-CRITERIA. Every other token is written as: <Role> \\u2014 withheld ($tok).\\n\\nNo ENG-* token is among them and none ever will be: the Engineer implements and does not approve its own implementation. Its act 7 line is the fourth shape and carries no tick at all - Engineer \\u2014 implemented (ENG-IMPLEMENTED, ceremony:engineer) \\u00b7 <n> files, +<a> -<r>.\\n\\n$HATCH"
done

# --- C: a clock time in act 7 ------------------------------------------------
# Act 7 carries no times. Every time rendered there so far was invented, and a
# fact that is always invented is better removed than checked.
TOKRE=$(printf '%s %s' "$SIGNING" "$WITHHOLDING" | tr ' ' '|')
BADTIME=$(printf '%s' "$ACT7" | grep -E "withheld|$TOKRE" 2>/dev/null | grep -o '[0-9][0-9]:[0-9][0-9]:[0-9][0-9]' 2>/dev/null | head -n 1)
if [ -n "$BADTIME" ]; then
  block "An act 7 line carries the time $BADTIME. Act 7 has no times in it.\\n\\nThe line shapes are exactly: <Role> $CHECK \\u2014 <TOKEN> (<agent_type>) and <Role> \\u2014 withheld (<TOKEN>) and <Role> \\u2014 withheld (role not convened), plus the fixed Release Manager line. The token and the agent type are the checkable parts; a time is not one of them.\\n\\n$HATCH"
fi

# --- D: a turn that changed files, rendered as though it had not -------------
IMPL_NOW=no
if [ -n "$TSTART" ]; then
  for t in $(printf '%s' "$MINE" | grep '"role":"implementation"' 2>/dev/null | sed -n 's/.*\"ts\":\"\([^\"]*\)\".*/\1/p'); do
    [ "$t" \< "$TSTART" ] || IMPL_NOW=yes
  done
fi
if [ "$IMPL_NOW" = yes ]; then
  if printf '%s' "$MSG" | grep -q 'No roles convened on this path' 2>/dev/null; then
    block "This turn changed files on $TICKET, and act 7 was rendered as the Lightweight Ceremony Path. LCP-2 is for a question that changes nothing. A turn that edits a file is never LCP-2, however small the edit.\n\nRe-render the whole response as the standard eight-act path, with act 7 assembled from the ledger: a role with an entry is quoted, a role without one is written as <Role> \u2014 withheld (role not convened).\n\n$HATCH"
  fi
  if ! printf '%s' "$MSG" | grep -q 'SIGN-OFF' 2>/dev/null; then
    block "This turn changed files on $TICKET and the response has no sign-off. The ceremony applies to every turn that changes a file, and the eight acts are how it applies.\n\nRe-render the response as the standard eight-act path, with act 7 assembled from the ledger: a role with an entry is quoted, a role without one is written as <Role> \u2014 withheld (role not convened).\n\n$HATCH"
  fi
fi

# --- E: an unsigned ceremony rendered as a signed one -----------------------
if printf '%s' "$MSG" | grep -q 'SIGN-OFF' 2>/dev/null; then
  if [ -z "$MINE" ]; then
    if ! printf '%s' "$MSG" | grep -q 'role not convened' 2>/dev/null; then
      if ! printf '%s' "$MSG" | grep -q 'No roles convened' 2>/dev/null; then
        blockc "Act 7 was rendered for $TICKET and the ledger for this ticket is empty: no agent was convened in this turn. A sign-off assembled from nothing has to say so.\\n\\nEither convene the roles through the Agent tool and render act 7 from what they return, or rewrite every line of act 7 as: <Role> \\u2014 withheld (role not convened). Then finish the turn.\\n\\n$HATCH"
      fi
    fi
  fi
fi

# --- F: a Definition of Done nobody assessed --------------------------------
if printf '%s' "$MSG" | grep -qF '[x]' 2>/dev/null; then
  if ! printf '%s' "$MINE" | grep -q '"role":"qa"' 2>/dev/null; then
    blockc "Act 6 has ticked boxes and no QA agent was convened for $TICKET in this session. Ticked boxes are claims about checks that ran; the ledger records none.\\n\\nEither convene ceremony:qa through the Agent tool and transcribe its CEREMONY-DOD lines verbatim, or replace act 6 with exactly: No QA agent convened - Definition of Done not assessed. Then finish the turn.\\n\\n$HATCH"
  fi
fi

# --- G: verification that happened before the change ------------------------
LASTIMPL=$(printf '%s' "$MINE" | grep '"role":"implementation"' 2>/dev/null | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
LASTVER=$(printf '%s' "$MINE" | grep -E '"role":"(qa|change-advisory-board)"' 2>/dev/null | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
if [ -n "$LASTIMPL" ] && [ -n "$LASTVER" ]; then
  if [ "$LASTVER" \< "$LASTIMPL" ]; then
    blockc "The last verification of $TICKET ran at $LASTVER and the last change to the code landed at $LASTIMPL. Verification that precedes the change verified the previous state of the repository.\\n\\nConvene ceremony:qa again through the Agent tool, on the code as it stands now, and render act 6 and act 7 from what it returns. The convening gate allows a re-convening once the code has moved.\\n\\n$HATCH"
  fi
fi

# --- I: an act headed by an agent that never ran ----------------------------
# An act heading that names a ceremony agent claims that agent produced the act.
# Only heading lines are read, so quoting an agent type in prose costs nothing.
for at in $(printf '%s' "$MSG" | grep '^[^A-Za-z]*[1-8] ' 2>/dev/null | grep -o 'ceremony:[a-z-]*' 2>/dev/null | sort -u); do
  r=${at#ceremony:}
  case "$r" in team-member|engineer|reviewer|product-owner|architect|change-advisory-board|qa|steering-committee) ;; *) continue ;; esac
  printf '%s' "$MINE" | grep -q '"role":"'"$r"'"' 2>/dev/null && continue
  blockc "An act is headed $at, and $at did not run this turn. The ledger .ceremony/$TICKET/ledger.jsonl holds no entry for it, so whatever that act says - acceptance criteria, an estimate, a question to put to the user - was composed rather than collected.\\n\\nAn act whose agent was not convened is emitted with its number and heading and one line saying so, and the heading does not name an agent. An open question only stops the turn when the Product Owner really returned PO-CLARIFY and the ledger says so; an invented one stops the work for nothing.\\n\\nEither convene $at through the Agent tool and transcribe what comes back, or render that act as not convened and carry on with the work.\\n\\n$HATCH"
done

# --- J: a placeholder where the estimate goes -------------------------------
HDR=$(printf '%s' "$MSG" | grep 'CEREMONY ' 2>/dev/null | head -n 1)
case "$HDR" in
  *'TBD'*|*'? pts'*|*'?pts'*|*'pending pts'*|*'N/A pts'*)
    block "The header carries a placeholder where the points go. There is nothing to reserve a space for: the header is composed last, after the agents have returned, so the number is known by the time it is written.\\n\\nThe points value is the Product Owner's estimate, written the same way act 2 writes it. If the Product Owner was not convened at all, the header reads 0 pts (not estimated) and act 2 says the same.\\n\\n$HATCH"
    ;;
esac

# --- K: a condition the board raised and act 4 did not answer ---------------
# The board's conditions were decoration for as long as nothing had to answer
# them. One disposition per condition is what stops that.
NCOND=0
for c in $(printf '%s' "$MINE" | grep '"role":"change-advisory-board"' 2>/dev/null | sed -n 's/.*"conditions":\([0-9][0-9]*\).*/\1/p'); do
  NCOND=$((NCOND + c))
done
if [ "$NCOND" -gt 0 ]; then
  NDISP=$(printf '%s' "$ACT4" | grep -c 'Disposition: *[0-9]' 2>/dev/null) || NDISP=0
  case "$NDISP" in ''|*[!0-9]*) NDISP=0 ;; esac
  if [ "$NDISP" -lt "$NCOND" ]; then
    blockc "The Change Advisory Board raised $(plu "$NCOND" condition conditions) for $TICKET and act 4 carries $(plu "$NDISP" 'disposition line' 'disposition lines'). A condition nobody answered is decoration, and this ceremony is meant to be something other than decoration.\\n\\nEvery condition gets one line in act 4, numbered to match, in one of exactly three shapes:\\n  Disposition: <n> applied - <what was done>\\n  Disposition: <n> waived - <reason>\\n  Disposition: <n> carried - action item recorded (owner: <who> - due: <when>)\\n\\nA NICE condition may be waived in a few words. A MUST or SHOULD needs a reason with something in it. A carried condition also appears as an act 8 action item, with the same owner and the same due date. If you apply one, the code has moved since the board looked, so convene ceremony:qa again on the code as it now stands and render act 6 from that return.\\n\\n$HATCH"
  fi
fi

# --- what verification says now ---------------------------------------------
# The last QA entry, not the worst one. A ticket whose blocked checks were
# restored and then really re-run has a first QA entry full of BLOCKED lines and
# a second one that passed, and it is the second that describes the repository
# the user is being handed. Reading the maximum instead would demand an
# escalation on exactly the turns where the loop worked.
QALAST=$(printf '%s' "$MINE" | grep '"role":"qa"' 2>/dev/null | tail -n 1)
NBLK=0
if [ -n "$QALAST" ]; then
  NBLK=$(printf '%s' "$QALAST" | sed -n 's/.*"blocked":\([0-9][0-9]*\).*/\1/p' | head -n 1)
  case "$NBLK" in ''|*[!0-9]*) NBLK=0 ;; esac
  case "$QALAST" in *'"verdict":"QA-BLOCKED"'*) [ "$NBLK" -eq 0 ] && NBLK=1 ;; esac
fi
HASESC=no
printf '%s' "$MSG" | grep -q 'ESCALATION' 2>/dev/null && HASESC=yes

OPSANY=$(printf '%s' "$MINE" | grep '"role":"devops"' 2>/dev/null)
OPSLAST=$(printf '%s' "$OPSANY" | tail -n 1)
OPSV=$(printf '%s' "$OPSLAST" | sed -n 's/.*"verdict":"\([^"]*\)".*/\1/p')

# --- Y: the user asked to solve the ceremony's own problem ------------------
# The defect the field report found, and the reason this version exists. QA came
# back blocked, and the response took that to the user as a decision to make.
# The ceremony has a role for a blocked toolchain, and asking before convening
# it is asking the user to do the work of a role that was standing right there.
if [ "$NBLK" -gt 0 ] && [ -z "$OPSANY" ]; then
  blockc "Y \\u00b7 QA could not run $(plu "$NBLK" check checks) on $TICKET, and ceremony:devops was never convened. The ceremony has a role for exactly this and it did not sit.\\n\\nA blocked check is an environment problem before it is a user problem: a toolchain that is not installed, a service that is not up, a dependency the project declares and does not have. ceremony:devops is the role that tries to restore it, and it is bounded so that trying cannot run away with the turn - it works only through mechanisms the repository itself defines, it has no write tools at all, it may not kill a process or install a system package, and it stops after 8 commands or 300 seconds whichever comes first.\\n\\nConvene ceremony:devops with the ticket id. Render its return as act 6a \\u00b7 RESTORATION inside act 6. Then:\\n  OPS-RESTORED \\u2192 convene ceremony:qa again so the blocked checks actually run. What ops reports is a claim until QA re-runs it.\\n  OPS-BLOCKED or OPS-NEEDS-CHANGE \\u2192 the plugin decides whether the sprint rolls, and the escalation that reaches the user carries a diagnosis rather than a question.\\n\\nThe user is told what happened. The user is not asked to fix it.\\n\\n$HATCH"
fi

# --- Z: a restoration nobody re-verified ------------------------------------
# OPS-RESTORED is the ops agent's own account of what it did. It is not a check
# that ran, and the whole design turns on the difference.
if [ -n "$OPSANY" ] && printf '%s' "$OPSANY" | grep -q '"verdict":"OPS-RESTORED"' 2>/dev/null; then
  LASTREST=$(printf '%s' "$OPSANY" | grep '"verdict":"OPS-RESTORED"' | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
  LASTQA=$(printf '%s' "$MINE" | grep '"role":"qa"' 2>/dev/null | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
  if [ -z "$LASTQA" ] || [ "$LASTQA" \< "$LASTREST" ]; then
    blockc "Z \\u00b7 ceremony:devops returned OPS-RESTORED at $LASTREST and no QA entry on $TICKET postdates it. A restoration nobody re-verified is a claim, not a fact.\\n\\nThe ops agent did not run the checks - it is not allowed to, and it would be marking its own work if it did. Convene ceremony:qa again with the blocked items as its scope, let it re-execute them for real, and render act 6 from that second return. The convening gate opens for QA precisely because OPS-RESTORED is on the record.\\n\\nIf the re-run comes back blocked again, that is an honest outcome and the loop carries on from there. What is not available is a sign-off resting on the word restored.\\n\\n$HATCH"
  fi
fi

# --- L: a blocked verification that was not escalated -----------------------
# The user's standing rule is to report a blocked toolchain rather than debug
# it. A turn that absorbed the blockage quietly did neither.
if [ "$NBLK" -gt 0 ]; then
  if [ "$HASESC" = no ]; then
    block "L \\u00b7 QA could not run $(plu "$NBLK" check checks) for $TICKET at all - they came back BLOCKED - and the response closes without saying so. A blocked check is not a passed check: an acceptance criterion is currently unverifiable, and the record has to carry that.\\n\\nceremony:devops has already sat on this and the mechanisms it could reach are exhausted, so what goes between act 8 and the closing line is the final-resort escalation, in this shape:\\n\\n\\u2501\\u2501\\u2501 ESCALATION - verification blocked, ceremony exhausted \\u2501\\u2501\\u2501\\nBlocker: <what is missing, in one line>\\nDiagnosis: <why, in one line>\\n  Sprint <n> \\u00b7 DevOps Engineer: <the command> - <what happened>\\nMechanisms exhausted: <the ones tried>. <what remains, or None remaining.>\\nUnverified: $(plu "$NBLK" 'acceptance check' 'acceptance checks'), all [ ] in act 6.\\nThe one command that would clear this:\\n  <the CEREMONY-OPS-COMMAND line, verbatim>\\nBacklog: <CER-BL-id> stays open until it does.\\nDecision required from the user: none. This is a report; the ticket stays carried.\\n\\nOne diagnosis line per ops attempt, quoting the command from its CEREMONY-OPS-TRIED line rather than a paraphrase. Then the closing line carries the verification clause: Work delivered: yes - Verification: blocked (escalated).\\n\\nThis is a report, not a stop and not a question. The work stays delivered, the blocker stays unrepaired, the ticket stays carried, and the turn ends without waiting for anything.\\n\\n$HATCH"
  fi
  case "$MSG" in
    *'Verification: blocked'*) ;;
    *) block "The response escalates a blocked verification and its closing line still reads as though everything was checked. With $(plu "$NBLK" 'blocked check' 'blocked checks') on the record, the closing line ends: Work delivered: yes - Verification: blocked (escalated).\\n\\nThe work may well be delivered. It is the verification that is missing, and the closing line is where that is said.\\n\\n$HATCH" ;;
  esac
elif [ "$HASESC" = yes ]; then
  block "The response carries an escalation block for $TICKET and nothing on the ledger is blocked: QA recorded no BLOCKED check this turn. An escalation with nothing to escalate asks the user for a decision they do not have to make.\\n\\nRemove the escalation block and the Verification clause from the closing line. The closing line keeps its four clauses, ending Work delivered: yes.\\n\\n$HATCH"
fi

# ---------------------------------------------------------------------------
# Rules N to X: the four eyes.
#
# These are checked together and reported together. Nine separate corrections
# against a budget of two would mean seven of them never being seen, so what
# the turn gets back is one message listing everything wrong with the chain at
# once. The budget stays at two because the budget is what makes this hook
# terminate. M and V are checked further up and outside it.
# ---------------------------------------------------------------------------

NOTES=''
note() {
  if [ -z "$NOTES" ]; then NOTES="$1"; else NOTES="$NOTES\\n\\n$1"; fi
}

ACT5=$(printf '%s' "$MSG" | awk '
  index($0, "IMPLEMENTATION") { f = 1 }
  index($0, "DEFINITION OF DONE") { f = 0 }
  f { print }' 2>/dev/null)

led_num() {
  # last value of a numeric field on the last ledger line for a role
  printf '%s' "$MINE" | grep '"role":"'"$1"'"' 2>/dev/null | tail -n 1 |
    sed -n 's/.*"'"$2"'":\([0-9][0-9]*\).*/\1/p' | head -n 1
}
num_or_zero() {
  case "${1:-}" in ''|*[!0-9]*) printf '0' ;; *) printf '%s' "$1" ;; esac
}
# The wording the Engineer line takes, from the verdict. Rules P and X both name
# that line and each used to carry its own copy of the mapping. They disagreed on
# ENG-NO-CHANGE: P dictated a line X was certain to reject, and the turn spent its
# whole budget writing the line one rule demanded and the other refused. One
# mapping, read by both, is what makes that impossible rather than merely fixed.
eng_shape() {
  case "$1" in
    ENG-IMPLEMENTED) printf 'implemented' ;;
    ENG-BLOCKED)     printf 'not implemented' ;;
    ENG-NO-CHANGE)   printf 'nothing to implement' ;;
  esac
}
# And the whole line, for a verdict and a measurement. O and P both have to name
# it and X is the rule that refuses it, so one builder is what keeps the three of
# them saying the same thing. Counts belong to the implemented shape alone: an
# engineer that moved files and then hit a blocker still signs 0 files, because
# what the line reports is what its verdict delivered and not what is in the tree.
eng_line() {
  ESHAPE=$(eng_shape "$1")
  if [ -z "$ESHAPE" ]; then
    printf 'Engineer \\u2014 withheld (%s)' "${1:-role not convened}"
  elif [ "$1" = ENG-IMPLEMENTED ]; then
    printf 'Engineer \\u2014 %s (%s, ceremony:engineer) \\u00b7 %s, +%s \\u2212%s' \
      "$ESHAPE" "$1" "$(plu "$2" file files)" "$3" "$4"
  else
    printf 'Engineer \\u2014 %s (%s, ceremony:engineer) \\u00b7 0 files' "$ESHAPE" "$1"
  fi
}

ENGV=$(printf '%s' "$MINE" | grep '"role":"engineer"' 2>/dev/null | tail -n 1 | sed -n 's/.*"verdict":"\([^"]*\)".*/\1/p')
REVV=$(printf '%s' "$MINE" | grep '"role":"reviewer"' 2>/dev/null | tail -n 1 | sed -n 's/.*"verdict":"\([^"]*\)".*/\1/p')
POV=$(printf '%s' "$MINE" | grep '"role":"product-owner"' 2>/dev/null | tail -n 1 | sed -n 's/.*"verdict":"\([^"]*\)".*/\1/p')

IMPLLINE=$(printf '%s' "$MINE" | grep '"role":"implementation"' 2>/dev/null | grep '"by":"engineer"' | tail -n 1)
MFILES=$(num_or_zero "$(printf '%s' "$IMPLLINE" | sed -n 's/.*"files":\([0-9][0-9]*\).*/\1/p')")
MADDED=$(num_or_zero "$(printf '%s' "$IMPLLINE" | sed -n 's/.*"added":\([0-9][0-9]*\).*/\1/p')")
MREMOVED=$(num_or_zero "$(printf '%s' "$IMPLLINE" | sed -n 's/.*"removed":\([0-9][0-9]*\).*/\1/p')")

# --- N: a diff nobody read --------------------------------------------------
LASTIMPL2=$(printf '%s' "$MINE" | grep '"role":"implementation"' 2>/dev/null | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
LASTREAD=$(printf '%s' "$MINE" | grep '"role":"chair-review"' 2>/dev/null | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
if [ -n "$LASTIMPL2" ]; then
  if [ -z "$LASTREAD" ] || [ "$LASTREAD" \< "$LASTIMPL2" ]; then
    note "N \\u00b7 Act 5 describes a diff nobody read. The last change to $TICKET landed at $LASTIMPL2 and the ledger holds no reading of the working tree after it.\\n\\nRun git diff and git status --porcelain, read what comes back, and render act 5 from that. This is the third of the four eyes and it is the only one that is yours: the Product Owner wrote the criteria, the Engineer wrote the code, the Reviewer checks it against the criteria, and you look at what actually changed before you describe it to the user. A summary of a summary is not a reading."
  fi
fi

# --- O: numbers that disagree with the measurement --------------------------
# The implementation entry is written whenever the tree moved, whatever the
# engineer then returned, so this rule fires on blocked turns too. It used to
# answer them with "implemented ($ENGV) - 2 files", which X refuses twice over:
# wrong verb, and counts on a line that may not carry them. The two rules sent
# the render between them until the budget ran out. O quotes X's line now.
if [ -n "$IMPLLINE" ]; then
  OLINE=$(eng_line "$ENGV" "$MFILES" "$MADDED" "$MREMOVED")
  CLAIM=$(printf '%s' "$ACT7" | grep -E '[0-9] +files?' 2>/dev/null | grep -F '+' | head -n 1)
  [ -n "$CLAIM" ] || CLAIM=$(printf '%s' "$ACT5" | grep -E '[0-9] +files?' 2>/dev/null | grep -F '+' | head -n 1)
  if [ -n "$CLAIM" ]; then
    CN=$(printf '%s' "$CLAIM" | grep -o '[0-9][0-9]*' 2>/dev/null | tr '\n' ' ')
    C1=$(num_or_zero "$(printf '%s' "$CN" | cut -d' ' -f1)")
    C2=$(num_or_zero "$(printf '%s' "$CN" | cut -d' ' -f2)")
    C3=$(num_or_zero "$(printf '%s' "$CN" | cut -d' ' -f3)")
    if [ "$C1" != "$MFILES" ] || [ "$C2" != "$MADDED" ] || [ "$C3" != "$MREMOVED" ]; then
      note "O \\u00b7 The response reports the size of the change as $(plu "$C1" file files), +$C2 -$C3. The ledger measured $(plu "$MFILES" file files), +$MADDED -$MREMOVED, counted from the tool calls the engineer actually made rather than from its description of them.\\n\\nQuote the ledger's numbers in act 5, and give the act 7 engineer line the shape its own verdict takes:\\n\\n  $OLINE\\n\\nWhere the engineer's own CEREMONY-DIFF line disagrees with the measurement, the measurement is what is written and the disagreement is worth a sentence in act 5."
    fi
  elif [ "$MFILES" -gt 0 ]; then
    # The other direction. A render that prints no counts at all is not a
    # cautious render: the measurement exists, act 5 and act 7 are where it is
    # quoted, and leaving it out is the same defect as inventing one.
    note "O \\u00b7 The ledger measured $(plu "$MFILES" file files), +$MADDED -$MREMOVED on $TICKET and the response quotes no counts anywhere in act 5 or act 7.\\n\\nThe numbers are not optional and they are not yours to compose. Act 5 carries: Changed: $(plu "$MFILES" file files), +$MADDED \\u2212$MREMOVED, which the plugin measured by diffing the working tree before and after the engineer ran. The act 7 engineer line takes the shape its own verdict picks:\\n\\n  $OLINE"
  fi
fi

# --- P: no signature under an implementation that did not happen ------------
# Only ticked lines are read. A blocked turn still has a Product Owner that
# legitimately returned PO-ACCEPT, and its line is written the ordinary way -
# withheld, with its own token in the brackets. Reading the token rather than
# the tick used to make that honest line a defect, and burned a correction on
# every blocked turn.
case "$ENGV" in
  ENG-BLOCKED|ENG-NO-CHANGE|MALFORMED)
    SIGNED=''
    for tok in $(printf '%s' "$ACT7" | grep -F "$CHECK" 2>/dev/null | grep -o '[A-Z][A-Z0-9-]*' 2>/dev/null | sort -u); do
      case " $SIGNING " in *" $tok "*) SIGNED="$SIGNED $tok" ;; esac
    done
    if [ -n "$SIGNED" ]; then
      ELINE=$(eng_line "$ENGV")
      note "P \\u00b7 ceremony:engineer returned $ENGV on $TICKET and act 7 still ticks:$SIGNED.\\n\\nNothing was delivered for those signatures to be about. Every line in act 7 withholds on this turn, each with its own token in the brackets - a Product Owner that accepted the criteria still reads Product Owner \\u2014 withheld (PO-ACCEPT), because accepting criteria is not the same as signing off a change that was never made. The engineer line is the one that quotes its own outcome instead, in the wording its verdict picks:\\n\\n  $ELINE\\n\\nSay plainly, in act 5, what was asked for and what stopped it."
    fi
    ;;
esac

# --- Q: an engineer return that could not be read, on files that moved ------
if [ "$ENGV" = MALFORMED ]; then
  EEDITS=$(num_or_zero "$(led_num engineer edits)")
  if [ "$EEDITS" -gt 0 ]; then
    case "$MSG" in
      *"The engineer's return could not be read."*) ;;
      *) note "Q \\u00b7 ceremony:engineer's return could not be read - its closing line was not one of ENG-IMPLEMENTED, ENG-BLOCKED or ENG-NO-CHANGE - and it changed $(plu "$EEDITS" file files) before returning. The change is in the tree; the account of it is not on the record.\\n\\nAct 5 carries this line, exactly: The engineer's return could not be read. It changed $(plu "$EEDITS" file files); what was intended is not on the record.\\n\\nThen describe the diff you read yourself. Do not reconstruct the engineer's intent from the code; the point of the line is that it is unknown." ;;
    esac
  fi
fi

# --- R: a review that found deviations, rendered as though it had not -------
RUNMET=$(num_or_zero "$(led_num reviewer unmet)")
REXTRA=$(num_or_zero "$(led_num reviewer extra)")
RDEV=$((RUNMET + REXTRA))
if [ "$REVV" = REV-DEVIATES ] || [ "$REVV" = REV-INCOMPLETE ] || [ "$RDEV" -gt 0 ]; then
  NDEV=$(printf '%s' "$ACT5" | grep -cE 'UNMET|EXTRA' 2>/dev/null) || NDEV=0
  NDEV=$(num_or_zero "$NDEV")
  HASDEV=no
  DEVSAY='is missing'
  if printf '%s' "$ACT5" | grep -q 'Deviations' 2>/dev/null; then HASDEV=yes; DEVSAY='is present'; fi
  if [ "$HASDEV" = no ] || [ "$NDEV" -lt "$RDEV" ]; then
    note "R \\u00b7 ceremony:reviewer returned $REVV on $TICKET: $(plu "$RUNMET" criterion criteria) unmet and $(plu "$REXTRA" change changes) nothing asked for. Act 5 carries $NDEV of those $(plu "$RDEV" line lines), and the Deviations subsection $DEVSAY.\\n\\nAct 5 ends with a Deviations subsection, one line per finding, quoting the reviewer's own CEREMONY-CRIT lines:\\n  - <n> UNMET \\u00b7 <the criterion> \\u2014 <what is missing>\\n  - <n> EXTRA \\u00b7 <what was changed> \\u2014 <file:line>\\n\\nAn EXTRA is not an accusation and an UNMET is not a failure of the turn; both are the record saying what the diff does that the ticket did not ask for, or does not do that it did. And while any of them stands, the Product Owner line in act 7 withholds: the criteria are the Product Owner's, and they have not all been met."
  fi
fi

# --- T: the Product Owner's tick now needs the reviewer ---------------------
# The substantive change of this version. Acceptance was one agent reading the
# request; it is now one agent writing the criteria and a second, independent
# one confirming the diff answers them.
POLINE=$(printf '%s' "$ACT7" | grep 'Product Owner' 2>/dev/null | head -n 1)
if [ "$POV" = PO-ACCEPT-OUT-OF-SCOPE ]; then
  case "$MSG" in
    *'re-scoped'*) ;;
    *) note "T \\u00b7 The ledger records PO-ACCEPT-OUT-OF-SCOPE for $TICKET. The Product Owner's acceptance criteria asked for a commit, a push or a merge, and this ceremony never commits: the working tree is the artifact the last three eyes review, and a commit destroys it before they can.\\n\\nThe act 7 line reads: Product Owner \\u2014 withheld (PO-ACCEPT-OUT-OF-SCOPE). Act 2 says that the criteria demanded a commit and were re-scoped to what can be checked in the working tree as it stands, and the closing line ends Committed: no (the tree is yours). Committing remains the user's decision and it is taken outside the ceremony." ;;
  esac
elif printf '%s' "$POLINE" | grep -qF "$CHECK" 2>/dev/null; then
  if [ "$POV" != PO-ACCEPT ] || [ "$REVV" != REV-MATCHES-CRITERIA ]; then
    note "T \\u00b7 The Product Owner line in act 7 carries a tick. That tick now rests on two returns, and the ledger has product-owner=${POV:-not convened} and reviewer=${REVV:-not convened}.\\n\\nThe Product Owner writes the criteria; it never sees the diff. The Reviewer reads the diff against those criteria and is the one that can say they were met. So the line is ticked only when both are on the record, and it quotes both:\\n  Product Owner \\u2713 \\u2014 PO-ACCEPT + REV-MATCHES-CRITERIA (ceremony:product-owner, ceremony:reviewer)\\n\\nWith either one missing or dissenting, the line withholds with the Product Owner's own token in the brackets, and the Reviewer keeps its own separate line."
  fi
fi

# --- S: a review that answered some of the criteria -------------------------
if [ -n "$REVV" ] && [ "$REVV" != REV-NOTHING-TO-REVIEW ]; then
  NAC=$(num_or_zero "$(led_num product-owner ac)")
  NCRIT=$(num_or_zero "$(led_num reviewer crit)")
  if [ "$NAC" -gt 0 ] && [ "$NCRIT" -lt "$NAC" ]; then
    note "S \\u00b7 The reviewer answered $NCRIT of $NAC criteria. The Product Owner recorded $NAC CEREMONY-AC lines on $TICKET and ceremony:reviewer returned $NCRIT CEREMONY-CRIT lines against them, so $(plu "$((NAC - NCRIT))" criterion criteria) went unexamined.\\n\\nEither convene ceremony:reviewer again with a brief naming the criteria it did not answer, or withhold its line and the Product Owner's: an unexamined criterion is not a met one. Whichever you choose, act 5a says how many of the criteria were actually reviewed."
  fi
fi

# --- W: act 7 is ten lines, and the same ten every time ---------------------
# The DevOps Engineer line is rule AA's, because it is the new one and a turn
# that dropped it deserves to be told which line and why.
# A missing line is not a smaller sign-off. Every role in the chain is named on
# every turn, including the ones that did not sit, because "withheld (role not
# convened)" is the finding and leaving the line out hides it.
#
# The nine lines belong to the standard path. LCP-2's act 7 is two fixed lines
# saying nothing was convened, and demanding nine there would correct a correct
# render into a wrong one.
LCP=no
case "$MSG" in
  *'No roles convened on this path'*) LCP=yes ;;
  *'LCP-2 '*) LCP=yes ;;
  *'no ticket raised'*) LCP=yes ;;
esac
if [ "$LCP" = no ] && printf '%s' "$MSG" | grep -q 'SIGN-OFF' 2>/dev/null; then
  MISSING=''
  for lab in 'Team member' 'Product Owner' 'Architect' 'Engineer' 'Reviewer' \
             'Change Advisory Board' 'QA Sign-off Officer' 'Release Manager' 'Scrum Master'; do
    printf '%s' "$ACT7" | grep -q "$lab" 2>/dev/null || MISSING="$MISSING, $lab"
  done
  MISSING=${MISSING#, }
  if [ -n "$MISSING" ]; then
    note "W \\u00b7 Act 7 is missing a line for: $MISSING.\\n\\nThe sign-off is ten lines and it is the same ten on every turn, in this order: Team member, Product Owner, Architect, Engineer, Reviewer, Change Advisory Board, QA Sign-off Officer, DevOps Engineer, Release Manager, Scrum Master. A role that did not sit is written out in full as <Role> \\u2014 withheld (role not convened), because that is a finding about the turn and a line left out is not.\\n\\nAbove them all, the chain line, which is fixed too: Chain: PO(criteria) \\u2192 Engineer(author) \\u2192 Chair(diff) \\u2192 Reviewer(criteria) \\u2192 CAB(risk) \\u2192 QA(execution)."
  fi
fi

# --- X: the Engineer line says what the Engineer's verdict says -------------
# Three shapes, one per verdict, and they are not interchangeable. A line
# reading "implemented (ENG-BLOCKED) - 1 file, +1 -1" says two opposite things
# at once, and the one a reader believes is the first half. Observed on a
# standalone /ceremony:signoff, where the render was assembled from the ledger's
# numbers and the wrong sentence around them.
ENGLINE=$(printf '%s' "$ACT7" | grep '^Engineer' 2>/dev/null | head -n 1)
if [ -n "$ENGLINE" ]; then
  SHAPE=''
  case "$ENGLINE" in
    *'not implemented'*)       SHAPE='not implemented' ;;
    *'nothing to implement'*)  SHAPE='nothing to implement' ;;
    *implemented*)             SHAPE=implemented ;;
  esac
  ETOK=''
  case "$ENGLINE" in
    *ENG-IMPLEMENTED*) ETOK=ENG-IMPLEMENTED ;;
    *ENG-BLOCKED*)     ETOK=ENG-BLOCKED ;;
    *ENG-NO-CHANGE*)   ETOK=ENG-NO-CHANGE ;;
  esac
  WANT=$(eng_shape "$ETOK")
  if [ -n "$ETOK" ] && [ -n "$SHAPE" ] && [ "$SHAPE" != "$WANT" ]; then
    note "X \\u00b7 The Engineer line reads \\\"$SHAPE\\\" and quotes $ETOK, and those are two different outcomes. The line is one of exactly three, and the verdict picks which:\\n\\n  Engineer \\u2014 implemented (ENG-IMPLEMENTED, ceremony:engineer) \\u00b7 <n> files, +<a> \\u2212<r>\\n  Engineer \\u2014 not implemented (ENG-BLOCKED, ceremony:engineer) \\u00b7 0 files\\n  Engineer \\u2014 nothing to implement (ENG-NO-CHANGE, ceremony:engineer) \\u00b7 0 files\\n\\n$ETOK takes the line that reads \\\"$WANT\\\". Counts belong to the first shape only: a blocked engineer wrote nothing, so its line carries 0 files and no line counts, whatever else is in the working tree."
  fi
  if [ "$ETOK" = ENG-BLOCKED ] || [ "$ETOK" = ENG-NO-CHANGE ]; then
    case "$ENGLINE" in
      *'0 files'*) ;;
      *[0-9]' file'*|*'+'[0-9]*)
        note "X \\u00b7 The Engineer line quotes $ETOK and then reports a count of files or lines: $ENGLINE\\n\\n$ETOK means nothing was written. Its line ends \\u00b7 0 files and carries no +<a> \\u2212<r> at all. If the working tree does hold a change, it was not this engineer's, and act 1 reports it under Inherited instead." ;;
    esac
  fi
fi

# --- the reviewer had something to read after all ---------------------------
# REV-NOTHING-TO-REVIEW is correct at zero implementation entries and at no
# other count. A non-git directory and a gitignored target both leave the
# plugin unable to write implementation.diff, and a reviewer that reads the
# absent file as an absent change reports nothing to review on work that was
# really done. The ledger still names the files; they are what it reads.
NIMPL=$(printf '%s' "$MINE" | grep -c '"role":"implementation"' 2>/dev/null) || NIMPL=0
NIMPL=$(num_or_zero "$NIMPL")
if [ "$REVV" = REV-NOTHING-TO-REVIEW ] && [ "$NIMPL" -gt 0 ]; then
  note "AH \\u00b7 ceremony:reviewer returned REV-NOTHING-TO-REVIEW and the ledger holds $(plu "$NIMPL" 'implementation entry' 'implementation entries') for $TICKET. Those two cannot both be true: something was written, and the review says there was nothing to read.\\n\\nWhat is usually missing is the measurement rather than the change. .ceremony/$TICKET/implementation.diff is written from two git tree snapshots, so it does not exist in a directory that is not a git repository, and it does not exist when the file the engineer wrote is gitignored. Neither of those means nothing happened.\\n\\nConvene ceremony:reviewer again and tell it, in its brief, that implementation.diff is unavailable and that the files are named on the implementation entries of .ceremony/$TICKET/ledger.jsonl. It reviews those files against the criteria and returns an ordinary verdict. REV-NOTHING-TO-REVIEW is correct at zero implementation entries and at no other count."
fi

# --- AA: act 7 is ten lines now ---------------------------------------------
if [ "$LCP" = no ] && printf '%s' "$MSG" | grep -q 'SIGN-OFF' 2>/dev/null; then
  if ! printf '%s' "$ACT7" | grep -q 'DevOps' 2>/dev/null; then
    note "AA \\u00b7 Act 7 has no DevOps Engineer line. The sign-off is ten lines now and it is the same ten on every turn, in this order: Team member, Product Owner, Architect, Engineer, Reviewer, Change Advisory Board, QA Sign-off Officer, DevOps Engineer, Release Manager, Scrum Master.\\n\\nThe ops lane sits between QA and the Release Manager, and on the great majority of turns its line reads: DevOps Engineer \\u2014 withheld (role not convened). That is the ordinary outcome - nothing was blocked, so nothing needed restoring - and it is written out in full for the same reason every other unconvened role is."
  fi
fi

# --- AB: the DevOps line says what the DevOps verdict says -------------------
OPSLINE=$(printf '%s' "$ACT7" | grep 'DevOps' 2>/dev/null | head -n 1)
if [ -n "$OPSLINE" ]; then
  OSHAPE=''
  case "$OPSLINE" in
    *'not restored'*)       OSHAPE='not restored' ;;
    *'change required'*)    OSHAPE='change required' ;;
    *'nothing to restore'*) OSHAPE='nothing to restore' ;;
    *restored*)             OSHAPE=restored ;;
  esac
  OTOK=''
  case "$OPSLINE" in
    *OPS-NOTHING-TO-DO*) OTOK=OPS-NOTHING-TO-DO ;;
    *OPS-NEEDS-CHANGE*)  OTOK=OPS-NEEDS-CHANGE ;;
    *OPS-RESTORED*)      OTOK=OPS-RESTORED ;;
    *OPS-BLOCKED*)       OTOK=OPS-BLOCKED ;;
  esac
  OWANT=''
  case "$OTOK" in
    OPS-RESTORED)      OWANT=restored ;;
    OPS-BLOCKED)       OWANT='not restored' ;;
    OPS-NEEDS-CHANGE)  OWANT='change required' ;;
    OPS-NOTHING-TO-DO) OWANT='nothing to restore' ;;
  esac
  if [ -n "$OTOK" ] && [ -n "$OSHAPE" ] && [ "$OSHAPE" != "$OWANT" ]; then
    note "AB \\u00b7 The DevOps Engineer line reads \\\"$OSHAPE\\\" and quotes $OTOK, and those are two different outcomes. The line is one of exactly five, and the verdict picks which:\\n\\n  DevOps Engineer \\u2014 restored (OPS-RESTORED, ceremony:devops) \\u00b7 <n> mechanisms\\n  DevOps Engineer \\u2014 not restored (OPS-BLOCKED, ceremony:devops) \\u00b7 <n> attempted\\n  DevOps Engineer \\u2014 change required (OPS-NEEDS-CHANGE, ceremony:devops) \\u00b7 <file> proposed\\n  DevOps Engineer \\u2014 nothing to restore (OPS-NOTHING-TO-DO, ceremony:devops) \\u00b7 0 attempted\\n  DevOps Engineer \\u2014 withheld (role not convened)\\n\\n$OTOK takes the line that reads \\\"$OWANT\\\". The angle-bracket slots are filled from the ledger and the nouns agree with what fills them: 1 mechanism, 2 mechanisms, and the file named on ceremony:devops's CEREMONY-OPS-CHANGE line. None of the five carries a tick, on any turn: ops restores, it does not approve, and the signature that matters after a restoration is QA's."
  fi
  case "$OPSLINE" in
    *"$CHECK"*)
      note "AB \\u00b7 The DevOps Engineer line in act 7 carries a tick. No OPS- token signs, and none ever will: the ops lane makes verification possible and QA is the role that then performs it. A restoration signed by the agent that performed it is the same defect as an engineer approving its own diff.\\n\\nThe line carries no tick at all. Its five shapes are printed in the output style, and the one to use is chosen by the verdict on the ledger." ;;
  esac
fi

# --- AC: a backlog id in the render, and one on disk -------------------------
BLROOT="$CWD/.ceremony/backlog.jsonl"
BLPEND="$CWD/.ceremony/$TICKET/carry.jsonl"
# Only what this ticket opened. The backlog is the project's and holds every
# ticket's rows, so an unfiltered read demanded that this render name a blocker
# some other ticket carried - under a sentence that says it was filed for this
# one. Both sources are scoped the same way ceremony:devops scopes its reuse
# check: the row belongs to the ticket named on it.
ONDISK=$(cat "$BLROOT" "$BLPEND" 2>/dev/null |
  grep -F '"opened_by":"'"$TICKET"'"' 2>/dev/null |
  sed -n 's/.*"id":"\(CER-BL-[0-9]*\)".*/\1/p' | sort -u)
INTEXT=$(printf '%s' "$MSG" | grep -o 'CER-BL-[0-9][0-9]*' 2>/dev/null | sort -u)
GHOST=''
for b in $INTEXT; do
  case " $(printf '%s' "$ONDISK" | tr '\n' ' ') " in *" $b "*) ;; *) GHOST="$GHOST $b" ;; esac
done
MISSED=''
for b in $ONDISK; do
  case " $(printf '%s' "$INTEXT" | tr '\n' ' ') " in *" $b "*) ;; *) MISSED="$MISSED $b" ;; esac
done
# Both directions in one correction. They used to be two notes, and a response
# that named one id while the disk held another satisfied whichever note it was
# shown: the chair replaced the id it had with the id the message quoted, which
# turned the missing half into the invented half and came straight back. The
# only correction that terminates is the one that shows the whole disagreement
# and says which way to move.
if [ -n "$GHOST" ] || [ -n "$MISSED" ]; then
  ACMSG="AC \\u00b7 The backlog on disk and the backlog ids in the response do not agree. Everything found is listed here, and it is one correction rather than several."
  [ -n "$MISSED" ] && ACMSG="$ACMSG\\n\\nFiled for $TICKET, and the response never mentions it:$MISSED"
  [ -n "$GHOST" ] && ACMSG="$ACMSG\\n\\nNamed in the response, and on disk nowhere:$GHOST"
  ACMSG="$ACMSG\\n\\nAdd what is missing beside what is already there. Do not turn one id into another: an id the plugin filed and an id the response composed are opposite defects, and swapping the first for the second only changes which half is wrong. A re-render that adds every filed id and removes every composed one clears this in a single pass."
  ACMSG="$ACMSG\\n\\nA filed id belongs on the Carried line of the sprint-roll block if the sprint rolled, in the escalation as Backlog: <id> stays open until it does, and in act 8 as the action item it is. One mention of each is enough; none is not. An id nothing carries was written rather than minted - the plugin mints them when a blocker is really carried, and it hands the id back the moment ceremony:devops returns. Quote that one, or propose a follow-up in words and file nothing."
  note "$ACMSG"
fi

# --- AD: only two kinds are ever carried ------------------------------------
# The scope discipline, made mechanical. A process that can file its own tickets
# and also decide what they are about is the failure mode this plugin is a joke
# about, so the set of things it may file is closed at two.
# Every offending line, not the first of them. A correction that shows one of
# three sends the same turn back three times, and the budget is two.
BADKIND=$(printf '%s' "$MSG" | grep '^Carried:' 2>/dev/null |
  grep -v 'restore-verification' | grep -v 'carried-condition' |
  awk '{ printf "%s  %s", (NR > 1 ? "\\n" : ""), $0 }')
if [ -n "$BADKIND" ]; then
  note "AD \\u00b7 A Carried line names something outside the two kinds the backlog holds:\\n$BADKIND\\n\\nExactly two things may ever be carried into a following sprint, and there is no third:\\n  restore-verification \\u00b7 a blocker that stops the user's request being verified\\n  carried-condition \\u00b7 a Change Advisory Board MUST that was not applied this turn\\n\\nEverything else - a SHOULD, a NICE, a reviewer's nice-to-have, a retrospective action item, something ops noticed about the repository - is rendered under Proposed backlog (not filed) and written nowhere. It never becomes a ticket and it is never picked up by a later sprint. The loop converges on delivering what the user asked for; it has no mechanism for widening, and that is deliberate."
fi
CARRSN=$(printf '%s' "$MSG" | grep '^Carried:' 2>/dev/null | grep -E '\[SHOULD\]|\[NICE\]' |
  awk '{ printf "%s  %s", (NR > 1 ? "\\n" : ""), $0 }')
if [ -n "$CARRSN" ]; then
  note "AD \\u00b7 A SHOULD or NICE condition is rendered as carried:\\n$CARRSN\\n\\nOnly a MUST is carried. A SHOULD or a NICE that was not applied is disposed of in act 4 - waived, with the reason that is the point of the line - and if it is worth doing later it goes under Proposed backlog (not filed), where it is a suggestion to the user and not a commitment by the process."
fi

# --- AE: the roll on the page and the roll on disk --------------------------
CARRIED=$(sed -n 's/^CEREMONY_CARRIED=//p' "$SENV" 2>/dev/null | tail -n 1)
ROLLED=$(sed -n 's/^CEREMONY_ROLLED=//p' "$SENV" 2>/dev/null | tail -n 1)
[ "$ROLLED" = yes ] || ROLLED=no
SHOWN=no
printf '%s' "$MSG" | grep -qE 'SPRINT [0-9]+ CLOSED|opened in session' 2>/dev/null && SHOWN=yes
if [ "$ROLLED" = yes ] && [ "$SHOWN" = no ]; then
  note "AE \\u00b7 The sprint rolled and the response does not say so. The plugin incremented .ceremony/sprint-offset this turn and minted $CARRIED, because ceremony:devops named a mechanism nobody had tried.\\n\\nRender the roll between act 8 and the closing line, in this shape:\\n\\n\\u2501\\u2501\\u2501 SPRINT <n> CLOSED \\u00b7 carried \\u2501\\u2501\\u2501\\nCarried: $CARRIED \\u00b7 restore-verification \\u00b7 <the blocker in one line>\\nVerification withheld: $(plu "$NBLK" check checks). QA-BLOCKED stands; no signature was invented.\\n\\n\\u2501\\u2501\\u2501 SPRINT <n+1> \\u00b7 opened in session \\u00b7 day 1 of 14 \\u2501\\u2501\\u2501\\nPlanning: $CARRIED (<n> pts) - the only item. Scope unchanged from $TICKET.\\nDevOps Engineer \\u00b7 attempt 2 \\u00b7 mechanism: <the one named next> - <its verdict>\\nQA Sign-off Officer \\u00b7 re-run \\u00b7 <what came back>\\nSprint <n+1> closed. <whether a mechanism remains>\\n\\nThe next sprint is one iteration of the loop, not a second ceremony: ops attempt 2 and a QA re-run, and not eight more acts."
fi
if [ "$ROLLED" = no ] && [ "$SHOWN" = yes ]; then
  note "AE \\u00b7 The response renders a sprint roll and no roll happened. .ceremony/sprint-offset was not incremented on this turn, so the sprint number in the header is the one the ceremony is really on and there is no closed sprint to report.\\n\\nThe loop advances only on a mechanism nobody has tried. The plugin decides that, from ceremony:devops's CEREMONY-OPS-NEXT line, and it writes the offset itself: a roll you narrate is a sprint number that exists only in the prose, and the next turn will not agree with it. With CEREMONY-OPS-NEXT: none there is no roll - the escalation goes to the user as a report and the ticket stays carried where it is."
fi

# --- AG: a re-run that re-ran nothing ---------------------------------------
if [ -n "$QALAST" ]; then
  QATT=$(num_or_zero "$(printf '%s' "$QALAST" | sed -n 's/.*"attempt":\([0-9][0-9]*\).*/\1/p' | head -n 1)")
  QBASH=$(num_or_zero "$(printf '%s' "$QALAST" | sed -n 's/.*"bash":\([0-9][0-9]*\).*/\1/p' | head -n 1)")
  if [ "$QATT" -ge 2 ] && [ "$QBASH" -eq 0 ]; then
    note "AG \\u00b7 QA attempt $QATT ran no commands at all. The platform counted 0 Bash calls on that return, and a Definition of Done assessed without running anything is a reading of the previous run.\\n\\nA re-run after OPS-RESTORED exists to execute the checks that were BLOCKED, with the environment as it now stands. If they were re-executed the tool statistics would say so. Convene ceremony:qa again with the blocked items named as its scope and the instruction that the earlier run's results are not to be reused, and render act 6 from what comes back.\\n\\nIf the checks genuinely cannot be run even now, that is QA-BLOCKED with a command and a failure beside each item, which is a different answer and an honest one."
  fi
fi

# --- AI: an execution failure that reached the record as something else -----
# The ops lane opens on the blocked count and on nothing else, so the count is
# load-bearing: an environment failure written as FAIL, or as an unticked skip,
# closes the one lane that could have repaired it. QA is given a mechanical
# rule - a check that could not execute is BLOCKED - and this is the same rule
# read off the render. The markers are quoted from the tool output, so a body
# that carries one while the ledger counts no blocked check is the two
# disagreeing about what happened.
if [ -n "$QALAST" ] && [ "$NBLK" -eq 0 ]; then
  # Act 6 alone, closed at both ends. Act 6a exists to report the commands that
  # failed - "Attempted: mise install - command not found" is its own template -
  # so a window that ran to the end of the message read a successful restoration
  # as QA mis-classifying, and fired on the one path this release exists to
  # make work. The same shape as the act 4 and act 7 windows above.
  ACT6=$(printf '%s' "$MSG" | awk '
    index(tolower($0), "definition of done") { f = 1 }
    index(tolower($0), "restoration") || index(tolower($0), "sign-off") { f = 0 }
    f { print }' 2>/dev/null)
  EXFAIL=$(printf '%s' "$ACT6" |
    grep -oiE 'command not found|no such file or directory|connection refused|failed to connect|couldn.t connect|no version is set|address already in use|permission denied|modulenotfounderror|cannot find module|could not find a mix.project|exit (code |status )?12[67]' 2>/dev/null |
    tr 'A-Z' 'a-z' | sort -u | tr '\n' '@' | sed 's/@$//; s/@/, /g')
  if [ -n "$EXFAIL" ]; then
    note "AI \\u00b7 Act 6 quotes an execution failure and the ledger records no blocked check. The evidence carries: $EXFAIL. QA returned blocked: 0.\\n\\nThose are two different claims about the same run. The line between them is mechanical and it is not a matter of phrasing: BLOCKED means the check could not execute, FAIL means it executed and the result contradicts the criterion. A missing command, a refused connection, a version manager with nothing selected, a port already held - none of them produced a statement about the code, so none of them is a FAIL and none of them is a skip.\\n\\nIt matters because ceremony:devops is convened on the blocked count and on nothing else. Recorded as anything else, an environment failure closes the one lane that could have repaired it, and the turn goes to the user with a verdict about code that was never run.\\n\\nConvene ceremony:qa again and tell it, in the brief, that a check which could not execute is BLOCKED with the command and the failure beside it. Render act 6 from that return. If the blocked count then rises above zero, the ops lane opens on its own and the rest follows."
  fi
fi

# --- AJ: a signature disclaimed for no reason on the record -----------------
# Rule A reads tokens in both directions and rule B reads the ticked ones, so
# the one shape neither judges is a signing token inside a withheld bracket.
# It is often correct - a blocked engineer withholds every line, a reviewer's
# deviation withholds the Product Owner's - so this fires only on the turn
# where nothing at all explains it: implemented, reviewed clean, verified, no
# condition carried. On that turn a withheld signature is either a line copied
# from the wrong shape or a signature the record supports and the render denies,
# and both are worth one sentence.
QAV=$(printf '%s' "$QALAST" | sed -n 's/.*"verdict":"\([^"]*\)".*/\1/p' | head -n 1)
if [ "$ENGV" = ENG-IMPLEMENTED ] && [ "$RDEV" -eq 0 ] && [ "$NBLK" -eq 0 ] &&
   [ "$QAV" = QA-PASS ] && [ "$REVV" = REV-MATCHES-CRITERIA ] &&
   ! printf '%s' "$ACT4" | grep -q 'Disposition: *[0-9]* *carried' 2>/dev/null; then
  DISC=''
  for tok in $SIGNING; do
    printf '%s' "$ACT7" | grep 'withheld' 2>/dev/null | grep -q "($tok)" 2>/dev/null &&
      DISC="$DISC $tok"
  done
  if [ -n "$DISC" ]; then
    note "AJ \\u00b7 Act 7 withholds a line and quotes a signing token in its brackets:$DISC.\\n\\nThe agent returned that token, so the token is real; what the line then says is that the ceremony is declining to stand behind it. On this turn nothing on the record supports that. The engineer implemented, the reviewer found no deviation, QA returned QA-PASS and no condition was carried, so there is nothing left for the signature to be waiting on.\\n\\nA withheld line quotes the token that withholds - PO-CLARIFY, REV-DEVIATES, QA-FAIL, ENG-BLOCKED and their kind - or reads withheld (role not convened) when the role did not sit. A ticked line quotes the token that signs. What does not exist is a line that quotes a signing token and then refuses it: either the tick belongs there, or something on the record says why it does not and that reason is written in the act it belongs to."
  fi
fi

# --- U: the header, the placeholders, and the plurals that are always wrong -
case "$MSG" in
  *'1 pts'*|*'1 points'*)
    note "U \\u00b7 The response writes 1 pts. One point is 1 pt, in the header and in act 2 alike. Every other value is pts: 2 pts, 3 pts, 5 pts." ;;
esac
case "$MSG" in
  *'1 files'*|*'1 tickets'*|*'1 entries'*|*'1 criteria'*)
    note "U \\u00b7 The response writes a plural after 1: one of 1 files, 1 tickets, 1 entries or 1 criteria. Singular after one, every time - 1 file, 1 ticket, 1 entry, 1 criterion - and the plural from two upwards." ;;
esac
# The hedged plural. Agent templates carry <n> file(s) because they do not know
# the number yet; the render does know it, so it commits to one form or the
# other. This is the same rule as the one above, caught one line later.
HEDGE=$(printf '%s' "$MSG" | grep -oE '[0-9]+ [a-z]+\(s\)' 2>/dev/null | sort -u | tr '\n' ' ')
if [ -n "$HEDGE" ]; then
  note "U \\u00b7 The response leaves a hedged plural standing: $HEDGE.\\n\\nThe (s) belongs to the agent templates, which are written before the count is known. By the time the response is rendered the count is on the ledger, so the noun agrees with it: 1 file, 2 files, 1 criterion, 4 criteria. Act 4's blast radius and act 5's counts are the two that most often keep the brackets."
fi
# Multi-word lowercase slots and a closed list of single-word ones. An HTML tag
# is either one word or carries attributes with = and quotes in it, so neither
# shape reaches this: a turn about <button> is about a button.
PLACE=$(printf '%s' "$MSG" | grep -oE '<[a-z]+( [a-z]+)+>|<pts>|<n>|<role>|<ticket>|<token>|<path>|<file>|ADR-NNNN|ADR-0000|CHG-NNNN|CHG-NNNNNNNN|CER-NNN' 2>/dev/null | sort -u | tr '\n' ' ')
if [ -n "$PLACE" ]; then
  note "U \\u00b7 The response ships a template placeholder it never filled in: $PLACE.\\n\\nEvery angle-bracket slot in the format is a hole for a real value, and a response that prints the hole is describing the format instead of using it. The ADR number is the next unused one under docs/adr/ or ADR-0001 when there are none; the change reference is on the record in the turn state; the decision title is the decision. If a value genuinely is not available, say so in words - there is no placeholder that means unknown."
fi
EXPECT=$(cat "$DATA/sessions/$SID.header" 2>/dev/null) || EXPECT=''
if [ -n "$EXPECT" ] && [ -n "$HDR" ]; then
  case "$HDR" in
    *'no ticket raised'*) ;;
    *)
      # Everything up to and including the ticket id is derived, not composed.
      PREFIX=${EXPECT%%"$TICKET"*}"$TICKET"
      case "$HDR" in
        "$PREFIX"*) ;;
        *) note "U \\u00b7 The header does not match the one the turn state handed over. It reads:\\n  $HDR\\nand the line to copy was:\\n  $EXPECT\\n\\nEverything up to the points clause is already filled in and is copied character for character - the sprint number and the ticket id are derived once, by a hook, before you were called. The slot after the sprint holds $TICKET and never a command name, a file name or a description of the request. Only <pts> is yours to fill in, from the Product Owner's estimate." ;;
      esac
      ;;
  esac
fi

if [ -n "$NOTES" ]; then
  blockc "The chain of four eyes is not complete on this turn. Everything below is wrong with it; fix all of it in one re-render.\\n\\n$NOTES\\n\\nThe chain, for reference: PO(criteria) \\u2192 Engineer(author) \\u2192 Chair(diff) \\u2192 Reviewer(criteria) \\u2192 CAB(risk) \\u2192 QA(execution). Each of the six looks at something the one before it could not.\\n\\n$HATCH"
fi

# --- H: the request handed back instead of answered -------------------------
# A response with no ceremony bar anywhere, listing the ways out of the plugin,
# ending on a question. That shape is the request being returned to the sender.
if ! printf '%s' "$MSG" | grep -q 'CEREMONY ' 2>/dev/null; then
  if printf '%s' "$MSG" | grep -qE '/output-style default|/ceremony:disband|CEREMONY_ENFORCE|plugin uninstall' 2>/dev/null; then
    case "$(printf '%s' "$MSG" | tr -d ' \n\t' | tail -c 2)" in
      *'?'*)
        block "This response has no ceremony header, lists the ways to switch the plugin off, and ends by asking the user to choose. That is the request being handed back rather than answered.\\n\\nSay the ways out once if they are relevant, then do the work in the same turn and render it on the path the turn belongs to. If the user asked to skip the ceremony, that is an ordinary request around ordinary work: the work is delivered on the standard eight-act path and nothing is said about having complied or not. If the user is genuinely confused or distressed, keep the plain-language explanation and put the ceremony below it - the explanation and the work are not alternatives."
        ;;
    esac
  fi
fi

finish
