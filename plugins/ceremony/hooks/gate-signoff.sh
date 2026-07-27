#!/bin/sh
# ceremony :: Stop
# Twenty-three rules. M and V come first and are outside the correction budget:
# the chair editing and a commit are the two failures worth their own allowance.
# Then A to L, in order, the first one tripped sending the turn back. Then N to
# W, the chain of four eyes, reported together in one message.
# A turn gets at most two ordinary corrections plus at most two exempt ones.
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

# ---------------------------------------------------------------------------
# The two exempt rules, checked before everything else and outside the budget.
#
# A budget of two corrections is what makes this hook terminate, and it is kept.
# But it also means the third defect of a turn ships unremarked, and twice now
# that third defect has been a commit: the earlier corrections spent the budget,
# and the rule that would have caught the commit never ran. Two failures are
# worth their own allowance, because both of them are the ceremony reporting
# work it did not govern - the chair writing the code itself, and a commit that
# destroys the artifact every signature was about.
#
# Termination is preserved twice over: each rule fires at most once, because the
# correction asks for a sentence whose presence stops it firing again, and the
# exempt allowance is itself capped at two.
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
fi

# The budget, spent. Everything from here down is a correction the turn can
# live without; the two above were not.
[ "$BN" -ge "$MAXBLOCKS" ] && exit 0

# --- A: a token nobody returned --------------------------------------------
# Every token in act 7 is a quotation. Ticked or withheld, it has to have been
# said by an agent that ran, and the ledger is where it was said.
SIGNING='PO-ACCEPT ARCH-RECORDED CAB-APPROVED CAB-APPROVED-WITH-CONDITIONS QA-PASS SC-ALIGNED-WITH-RESERVATIONS REV-MATCHES-CRITERIA'
WITHHOLDING='TEAM-REPORTED PO-CLARIFY PO-ACCEPT-OUT-OF-SCOPE CAB-NOTHING-TO-REVIEW QA-PARTIAL QA-FAIL QA-BLOCKED ENG-IMPLEMENTED ENG-BLOCKED ENG-NO-CHANGE REV-DEVIATES REV-INCOMPLETE REV-NOTHING-TO-REVIEW MALFORMED'
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
    blockc "The Change Advisory Board raised $NCOND condition(s) for $TICKET and act 4 carries $NDISP disposition line(s). A condition nobody answered is decoration, and this ceremony is meant to be something other than decoration.\\n\\nEvery condition gets one line in act 4, numbered to match, in one of exactly three shapes:\\n  Disposition: <n> applied - <what was done>\\n  Disposition: <n> waived - <reason>\\n  Disposition: <n> carried - action item recorded (owner: <who> - due: <when>)\\n\\nA NICE condition may be waived in a few words. A MUST or SHOULD needs a reason with something in it. A carried condition also appears as an act 8 action item, with the same owner and the same due date. If you apply one, the code has moved since the board looked, so convene ceremony:qa again on the code as it now stands and render act 6 from that return.\\n\\n$HATCH"
  fi
fi

# --- L: a blocked verification that was not escalated -----------------------
# The user's standing rule is to report a blocked toolchain rather than debug
# it. A turn that absorbed the blockage quietly did neither.
NBLK=0
for b in $(printf '%s' "$MINE" | grep '"role":"qa"' 2>/dev/null | sed -n 's/.*"blocked":\([0-9][0-9]*\).*/\1/p'); do
  [ "$b" -gt "$NBLK" ] && NBLK=$b
done
if [ "$NBLK" -eq 0 ]; then
  printf '%s' "$MINE" | grep '"role":"qa"' 2>/dev/null | grep -q '"verdict":"QA-BLOCKED"' 2>/dev/null && NBLK=1
fi
HASESC=no
printf '%s' "$MSG" | grep -q 'ESCALATION.*verification blocked' 2>/dev/null && HASESC=yes
if [ "$NBLK" -gt 0 ]; then
  if [ "$HASESC" = no ]; then
    block "QA could not run $NBLK check(s) for $TICKET at all - they came back BLOCKED - and the response closes without escalating them. A blocked check is not a passed check: an acceptance criterion is currently unverifiable and only the user can change that.\\n\\nBetween act 8 and the closing line, emit exactly this:\\n\\n\\u2501\\u2501\\u2501 ESCALATION - verification blocked \\u2501\\u2501\\u2501\\n- <the item> - attempted: <the exact command QA ran> - failed: <how it failed>\\nDecision required from the user: <the closed ask>\\n\\nOne bullet per blocked item, quoting QA's own command from its evidence rather than a paraphrase. Then the closing line carries the verification clause: Work delivered: yes - Verification: blocked (escalated).\\n\\nThis is a report, not a stop. The work stays delivered, the blocker stays unrepaired, and the turn ends without waiting for an answer.\\n\\n$HATCH"
  fi
  case "$MSG" in
    *'Verification: blocked'*) ;;
    *) block "The response escalates a blocked verification and its closing line still reads as though everything was checked. With $NBLK blocked check(s) on the record, the closing line ends: Work delivered: yes - Verification: blocked (escalated).\\n\\nThe work may well be delivered. It is the verification that is missing, and the closing line is where that is said.\\n\\n$HATCH" ;;
  esac
elif [ "$HASESC" = yes ]; then
  block "The response carries an escalation block for $TICKET and nothing on the ledger is blocked: QA recorded no BLOCKED check this turn. An escalation with nothing to escalate asks the user for a decision they do not have to make.\\n\\nRemove the escalation block and the Verification clause from the closing line. The closing line keeps its four clauses, ending Work delivered: yes.\\n\\n$HATCH"
fi

# ---------------------------------------------------------------------------
# Rules N to W: the four eyes.
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
if [ -n "$IMPLLINE" ]; then
  CLAIM=$(printf '%s' "$ACT7" | grep -E '[0-9] +files?' 2>/dev/null | grep -F '+' | head -n 1)
  [ -n "$CLAIM" ] || CLAIM=$(printf '%s' "$ACT5" | grep -E '[0-9] +files?' 2>/dev/null | grep -F '+' | head -n 1)
  if [ -n "$CLAIM" ]; then
    CN=$(printf '%s' "$CLAIM" | grep -o '[0-9][0-9]*' 2>/dev/null | tr '\n' ' ')
    C1=$(num_or_zero "$(printf '%s' "$CN" | cut -d' ' -f1)")
    C2=$(num_or_zero "$(printf '%s' "$CN" | cut -d' ' -f2)")
    C3=$(num_or_zero "$(printf '%s' "$CN" | cut -d' ' -f3)")
    if [ "$C1" != "$MFILES" ] || [ "$C2" != "$MADDED" ] || [ "$C3" != "$MREMOVED" ]; then
      note "O \\u00b7 The response reports the size of the change as $C1 file(s), +$C2 -$C3. The ledger measured $MFILES file(s), +$MADDED -$MREMOVED, counted from the tool calls the engineer actually made rather than from its description of them.\\n\\nQuote the ledger's numbers, in act 5 and on the act 7 engineer line: Engineer \\u2014 implemented ($ENGV, ceremony:engineer) \\u00b7 $MFILES files, +$MADDED -$MREMOVED. Where the engineer's own CEREMONY-DIFF line disagrees with the measurement, the measurement is what is written and the disagreement is worth a sentence in act 5."
    fi
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
      note "P \\u00b7 ceremony:engineer returned $ENGV on $TICKET and act 7 still ticks:$SIGNED.\\n\\nNothing was delivered for those signatures to be about. Every line in act 7 withholds on this turn, each with its own token in the brackets - a Product Owner that accepted the criteria still reads Product Owner \\u2014 withheld (PO-ACCEPT), because accepting criteria is not the same as signing off a change that was never made. The engineer line reads: Engineer \\u2014 not implemented ($ENGV, ceremony:engineer) \\u00b7 0 files. Say plainly, in act 5, what was asked for and what stopped it."
    fi
    ;;
esac

# --- Q: an engineer return that could not be read, on files that moved ------
if [ "$ENGV" = MALFORMED ]; then
  EEDITS=$(num_or_zero "$(led_num engineer edits)")
  if [ "$EEDITS" -gt 0 ]; then
    case "$MSG" in
      *"The engineer's return could not be read."*) ;;
      *) note "Q \\u00b7 ceremony:engineer's return could not be read - its closing line was not one of ENG-IMPLEMENTED, ENG-BLOCKED or ENG-NO-CHANGE - and it changed $EEDITS file(s) before returning. The change is in the tree; the account of it is not on the record.\\n\\nAct 5 carries this line, exactly: The engineer's return could not be read. $EEDITS file(s) were changed by it; what was intended is not on the record.\\n\\nThen describe the diff you read yourself. Do not reconstruct the engineer's intent from the code; the point of the line is that it is unknown." ;;
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
    note "R \\u00b7 ceremony:reviewer returned $REVV on $TICKET: $RUNMET criterion/criteria unmet and $REXTRA change(s) nothing asked for. Act 5 carries $NDEV of those $RDEV line(s), and the Deviations subsection $DEVSAY.\\n\\nAct 5 ends with a Deviations subsection, one line per finding, quoting the reviewer's own CEREMONY-CRIT lines:\\n  - <n> UNMET \\u00b7 <the criterion> \\u2014 <what is missing>\\n  - <n> EXTRA \\u00b7 <what was changed> \\u2014 <file:line>\\n\\nAn EXTRA is not an accusation and an UNMET is not a failure of the turn; both are the record saying what the diff does that the ticket did not ask for, or does not do that it did. And while any of them stands, the Product Owner line in act 7 withholds: the criteria are the Product Owner's, and they have not all been met."
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
    note "S \\u00b7 The reviewer answered $NCRIT of $NAC criteria. The Product Owner recorded $NAC CEREMONY-AC lines on $TICKET and ceremony:reviewer returned $NCRIT CEREMONY-CRIT lines against them, so $((NAC - NCRIT)) criterion/criteria went unexamined.\\n\\nEither convene ceremony:reviewer again with a brief naming the criteria it did not answer, or withhold its line and the Product Owner's: an unexamined criterion is not a met one. Whichever you choose, act 5a says how many of the criteria were actually reviewed."
  fi
fi

# --- W: act 7 is nine lines, and the same nine every time -------------------
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
    note "W \\u00b7 Act 7 is missing a line for: $MISSING.\\n\\nThe sign-off is nine lines and it is the same nine on every turn, in this order: Team member, Product Owner, Architect, Engineer, Reviewer, Change Advisory Board, QA Sign-off Officer, Release Manager, Scrum Master. A role that did not sit is written out in full as <Role> \\u2014 withheld (role not convened), because that is a finding about the turn and a line left out is not.\\n\\nAbove them all, the chain line, which is fixed too: Chain: PO(criteria) \\u2192 Engineer(author) \\u2192 Chair(diff) \\u2192 Reviewer(criteria) \\u2192 CAB(risk) \\u2192 QA(execution)."
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
# Multi-word lowercase slots and a closed list of single-word ones. An HTML tag
# is either one word or carries attributes with = and quotes in it, so neither
# shape reaches this: a turn about <button> is about a button.
PLACE=$(printf '%s' "$MSG" | grep -oE '<[a-z]+( [a-z]+)+>|<pts>|<n>|<role>|<ticket>|<token>|<path>|ADR-NNNN|ADR-0000|CHG-NNNN|CHG-NNNNNNNN|CER-NNN' 2>/dev/null | sort -u | tr '\n' ' ')
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

exit 0
