#!/bin/sh
# ceremony :: PreToolUse Agent|Task
# One convening per role per ticket, unless the code moved underneath it.
set -u
trap 'exit 0' EXIT

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

AGENT=$(jget subagent_type)
case "$AGENT" in
  ceremony:*) ROLE=${AGENT#ceremony:} ;;
  *) exit 0 ;;
esac
case "$ROLE" in
  *[!a-z-]*|'') exit 0 ;;
esac

SID=$(jget session_id)
[ -n "$SID" ] || exit 0
CWD=$(jget cwd)
[ -n "$CWD" ] || CWD=$(pwd 2>/dev/null) || exit 0

# A disbanded ceremony gates nothing at all.
if [ -f "$CWD/.ceremony/config.json" ]; then
  grep -q '"enforce":[ ]*"on"' "$CWD/.ceremony/config.json" 2>/dev/null || exit 0
fi

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || DATA="${TMPDIR:-/tmp}/ceremony-plugin-data"

# --- a disband turn convenes nobody ------------------------------------------
if [ -f "$DATA/sessions/$SID.disbanding" ]; then
  printf '%s\n' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"This turn is a /ceremony:disband. It convenes nobody: zero agents, no standup, no grooming, no board. Convening a role here would write the record the user just asked to have removed.\\n\\nRun the removal command from the command file, read the config back, and report what is gone. Act 7 is six withheld lines and the fixed Release Manager line, and every one of them is correct.\"}}"
  exit 0
fi

# --- a ceremony role is convened synchronously, always ----------------------
# An asynchronous agent reports back through a notification, and a notification
# is not a tool result: PostToolUse only ever sees the launch stub, so the
# verdict never reaches the record. Rewrite the call before it is made.
#
# This rewrite is load-bearing for the write gate as well, and must not be
# relaxed. Because every ceremony:* agent runs synchronously, the chair cannot
# issue a tool call while one is running - so a live ceremony:engineer marker
# means the editor is the engineer and can mean nothing else. Let a ceremony
# agent run in the background and that equivalence breaks: the chair would be
# free to edit under a marker it did not earn.
force_sync() {
  TI=$(printf '%s' "$RAW" | awk '
    BEGIN { RS = "\1" }
    {
      k = "\"tool_input\":"
      i = index($0, k)
      if (i == 0) exit
      j = i + length(k)
      while (substr($0, j, 1) == " ") j++
      if (substr($0, j, 1) != "{") exit
      start = j; depth = 0; instr = 0; esc = 0; n = length($0)
      for (; j <= n; j++) {
        c = substr($0, j, 1)
        if (esc) { esc = 0; continue }
        if (instr) {
          if (c == "\\") esc = 1
          else if (c == "\"") instr = 0
          continue
        }
        if (c == "\"") { instr = 1; continue }
        if (c == "{") depth++
        else if (c == "}") {
          depth--
          if (depth == 0) { printf "%s", substr($0, start, j - start + 1); exit }
        }
      }
    }' 2>/dev/null)
  case "$TI" in
    '') return 1 ;;
    *'"run_in_background":true'*|*'"run_in_background": true'*) ;;
    *) return 1 ;;
  esac
  TI=$(printf '%s' "$TI" | sed 's/"run_in_background":[ ]*true/"run_in_background":false/')
  printf '%s\n' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"updatedInput\":$TI}}"
  return 0
}

SENV="$DATA/sessions/$SID.env"
if [ ! -f "$SENV" ]; then
  force_sync
  exit 0
fi
TICKET=$(sed -n 's/^CEREMONY_TICKET=//p' "$SENV" 2>/dev/null | tail -n 1)
if [ -z "$TICKET" ]; then
  force_sync
  exit 0
fi

LEDGER="$CWD/.ceremony/$TICKET/ledger.jsonl"
MINE=''
[ -f "$LEDGER" ] && MINE=$(grep '"session":"'"$SID"'"' "$LEDGER" 2>/dev/null)

deny() {
  printf '%s\n' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

# --- a command turn convenes no engineer ------------------------------------
# The commands report on work; they are not a way to order it. Without this a
# /ceremony:audit can raise a ticket, groom it and have the engineer implement
# a tool nobody asked for, and the audit that was asked for is never written.
if [ "$ROLE" = engineer ] && [ -f "$DATA/sessions/$SID.standalone" ]; then
  deny "This turn is a ceremony command, and a ceremony command reports; it does not perform work. ceremony:engineer is not convenable here, and nothing on this turn may be edited by anyone.\\n\\nRender what the command file asks for, from the record and from what you can read, and end the turn there. If work is wanted, ask for it in a plain request: that turn raises a ticket, grooms it, convenes the engineer and reviews the result.\\n\\nTo work without the ceremony: /ceremony:disband, or CEREMONY_ENFORCE=off, or /hooks."
fi

# --- the engineer implements against criteria, so the criteria come first ----
if [ "$ROLE" = engineer ]; then
  if ! printf '%s' "$MINE" | grep '"role":"product-owner"' 2>/dev/null | grep -q '"verdict":"PO-ACCEPT"' 2>/dev/null; then
    deny "There is nothing for ceremony:engineer to implement yet. Its brief is the ticket path, and $TICKET has no accepted acceptance criteria on it: the Product Owner has not returned PO-ACCEPT for this ticket in this session.\\n\\nRun Wave A first - ceremony:team-member and ceremony:product-owner, both Agent calls in one message - and convene the engineer once the criteria are on the record. An engineer briefed from your summary of the request instead of from the record is the paraphrase this design exists to remove.\\n\\nTo work without the ceremony: /ceremony:disband, or CEREMONY_ENFORCE=off, or /hooks."
  fi
fi

# --- the reviewing roles need something to review ---------------------------
# Wave D sits on a change. An engineer that returned ENG-BLOCKED or
# ENG-NO-CHANGE counts: it sat, it spoke, and the reviewers are entitled to say
# there was nothing to look at. A standalone /ceremony:* command is exempt -
# there the user asked for one role, on the tree as it stands.
if [ ! -f "$DATA/sessions/$SID.standalone" ]; then
  case "$ROLE" in
    reviewer|change-advisory-board|qa)
      HASWORK=no
      printf '%s' "$MINE" | grep -q '"role":"implementation"' 2>/dev/null && HASWORK=yes
      printf '%s' "$MINE" | grep -q '"role":"engineer"' 2>/dev/null && HASWORK=yes
      if [ "$HASWORK" = no ]; then
        deny "Wave D reviews a change. There isn't one yet: $TICKET has no implementation entry and no return from ceremony:engineer on its ledger.\\n\\nConvene ceremony:engineer first. When it returns, read the diff yourself, and then convene ceremony:reviewer, ceremony:change-advisory-board and ceremony:qa in one message so the three of them look at the same tree at the same time.\\n\\nIf you want this role on its own, on the working tree as it stands, that is what the standalone commands are for: /ceremony:review, /ceremony:cab, /ceremony:signoff.\\n\\nTo work without the ceremony: /ceremony:disband, or CEREMONY_ENFORCE=off, or /hooks."
      fi
      ;;
  esac
fi

# --- the ops lane opens on a blocked check and on nothing else ---------------
# ceremony:devops is Bash-capable and has standing motive to make things work.
# It is convened for one reason: QA could not run a check. Without that on the
# record it is a general-purpose shell with a role name on it, which is the one
# thing this plugin cannot ship.
if [ "$ROLE" = devops ]; then
  QABLK=no
  for b in $(printf '%s' "$MINE" | grep '"role":"qa"' 2>/dev/null | sed -n 's/.*"blocked":\([0-9][0-9]*\).*/\1/p'); do
    [ "$b" -gt 0 ] && QABLK=yes
  done
  printf '%s' "$MINE" | grep '"role":"qa"' 2>/dev/null | grep -q '"verdict":"QA-BLOCKED"' 2>/dev/null && QABLK=yes
  if [ "$QABLK" = no ]; then
    deny "ceremony:devops is convened when verification is blocked, and nothing on $TICKET is blocked: the ledger holds no QA entry with a BLOCKED check on it.\\n\\nThe ops lane exists for one situation - QA ran a check and the environment was not there, so the check could not run at all. Convene ceremony:qa first. The lane opens on the blocked count and on nothing else: any QA return carrying a BLOCKED line allows this call, QA-BLOCKED and QA-PARTIAL alike, and a return with none of them does not, whatever its verdict says.\\n\\nA failing check is not a blocked one, and it is not the ops lane's business either: a test that runs and fails is a finding about the code, which is what act 6 is for. A check that could not execute - a command not found, a connection refused, a toolchain with no version selected - is BLOCKED, and that is the one this lane is for.\\n\\nTo work without the ceremony: /ceremony:disband, or CEREMONY_ENFORCE=off, or /hooks."
  fi
fi

# --- the loop is bounded, and the bound is a count ---------------------------
# Two roles can legitimately be convened more than once on one ticket: QA, when
# the code or the environment moved under it, and devops, on the second sprint
# of a roll. Neither is unbounded. The caps are what stop a turn that keeps
# trying from becoming a turn that never ends.
case "$ROLE" in
  qa|devops)
    case "$ROLE" in qa) CAP=3 ;; *) CAP=2 ;; esac
    SEEN=$(printf '%s' "$MINE" | grep -c '"role":"'"$ROLE"'"' 2>/dev/null) || SEEN=0
    case "$SEEN" in ''|*[!0-9]*) SEEN=0 ;; esac
    if [ "$SEEN" -ge "$CAP" ]; then
      case "$SEEN" in 1) TIMES='once' ;; 2) TIMES='twice' ;; *) TIMES="$SEEN times" ;; esac
      deny "$AGENT has been convened $TIMES on $TICKET and the cap for this role is $CAP. The loop advances on a mechanism nobody has tried; it does not advance by asking the same role again.\\n\\nRender what is already on the record. If verification is still blocked, that is the final-resort escalation: the diagnosis, the mechanisms that were exhausted, the one command that would clear it, and the closing line 'Decision required from the user: none.' The ticket stays carried in the backlog and the user is told, not asked.\\n\\nTo work without the ceremony: /ceremony:disband, or CEREMONY_ENFORCE=off, or /hooks."
    fi
    ;;
esac

if [ ! -f "$LEDGER" ]; then
  force_sync
  exit 0
fi

PRIOR=$(printf '%s' "$MINE" | grep '"role":"'"$ROLE"'"' 2>/dev/null | tail -n 1)
if [ -z "$PRIOR" ]; then
  force_sync
  exit 0
fi

PTS=$(printf '%s' "$PRIOR" | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p')
PV=$(printf '%s' "$PRIOR" | sed -n 's/.*"verdict":"\([^"]*\)".*/\1/p')
[ -n "$PV" ] || PV=MALFORMED

# A return nobody can use is not a return this gate protects. Two cases, and
# both would otherwise deadlock the turn: a Product Owner that did not accept
# leaves the write gate shut and the engineer unconvenable, and every other
# gate's advice is to convene it again; and a return that could not be read
# recorded nothing to transcribe. Re-convening here is the first opinion being
# made usable, not a second one being shopped for.
case "$PV" in
  MALFORMED)
    force_sync
    exit 0
    ;;
esac
if [ "$ROLE" = product-owner ] && [ "$PV" != PO-ACCEPT ]; then
  force_sync
  exit 0
fi

# The record moved on: an implementation entry after this role's last entry
# makes the old return stale, and re-convening is the point of the gate above.
#
# The code is not the only thing that can move. A restored toolchain moves the
# environment, and a check that was BLOCKED because the environment was not
# there is exactly as stale as a check that ran against an older diff. So an
# OPS-RESTORED entry after this role's last entry re-opens it the same way an
# implementation entry does - and that, not the ops agent's own word, is what
# lets QA run the blocked checks again. The claim is only closed when QA does.
MOVED=''
LASTIMPL=$(grep '"role":"implementation"' "$LEDGER" 2>/dev/null | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
[ -n "$LASTIMPL" ] && MOVED=$LASTIMPL
LASTOPS=$(grep '"role":"devops"' "$LEDGER" 2>/dev/null | grep '"verdict":"OPS-RESTORED"' | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
if [ -n "$LASTOPS" ]; then
  [ -z "$MOVED" ] && MOVED=$LASTOPS
  [ "$LASTOPS" \> "$MOVED" ] && MOVED=$LASTOPS
fi
if [ -n "$MOVED" ] && [ -n "$PTS" ]; then
  if [ "$MOVED" \> "$PTS" ]; then
    force_sync
    exit 0
  fi
fi

printf '%s\n' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$AGENT has already been convened for $TICKET in this session. It returned $PV at $PTS. Convening the same role twice does not produce a second opinion; it produces a second bill.\\n\\nIts full return is on the record: .ceremony/$TICKET/ticket.md. Read it there and transcribe it. This role becomes convenable again only after a further change to the code.\\n\\nTo work without the ceremony: /ceremony:disband, or CEREMONY_ENFORCE=off, or /hooks.\"}}"
