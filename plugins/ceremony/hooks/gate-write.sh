#!/bin/sh
# ceremony :: PreToolUse Edit|Write|NotebookEdit|MultiEdit
# Three refusals: writing the record, writing code before acceptance, and
# writing code as anyone other than the engineer.
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

deny() {
  printf '%s\n' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

FILE=$(jget file_path)
[ -n "$FILE" ] || FILE=$(jget notebook_path)

# --- refusal 1: the record is not written by its participants ---------------
# This one applies to the engineer as well. It has write access to the
# repository and none at all to the record; those are different things.
case "$FILE" in
  .ceremony|.ceremony/*|*/.ceremony|*/.ceremony/*)
    deny "The ceremony record is written by the process, not by its participants. .ceremony/ is appended to by ceremony's hooks from real agent returns. Nothing you write there would be evidence of anything.\\n\\nTo remove the record entirely: /ceremony:disband."
    ;;
esac

SID=$(jget session_id)
[ -n "$SID" ] || exit 0
CWD=$(jget cwd)
[ -n "$CWD" ] || CWD=$(pwd 2>/dev/null) || exit 0

# --- is enforcement armed? --------------------------------------------------
[ -f "$CWD/.ceremony/config.json" ] || exit 0
grep -q '"enforce":[ ]*"on"' "$CWD/.ceremony/config.json" 2>/dev/null || exit 0
[ "${CEREMONY_ENFORCE:-on}" = off ] && exit 0

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || DATA="${TMPDIR:-/tmp}/ceremony-plugin-data"
SENV="$DATA/sessions/$SID.env"
[ -f "$SENV" ] || exit 0
TICKET=$(sed -n 's/^CEREMONY_TICKET=//p' "$SENV" 2>/dev/null | tail -n 1)
[ -n "$TICKET" ] || exit 0

LEDGER="$CWD/.ceremony/$TICKET/ledger.jsonl"
PO=''
[ -f "$LEDGER" ] && PO=$(grep '"session":"'"$SID"'"' "$LEDGER" 2>/dev/null | grep '"role":"product-owner"')

# --- refusal 2: no acceptance, no edit --------------------------------------
# The gate opens on acceptance, not on attendance. A Product Owner that asked a
# question, whose return could not be read, or whose criteria demanded a commit
# this ceremony will never make, has accepted nothing.
if printf '%s' "$PO" | grep -q '"verdict":"PO-ACCEPT"' 2>/dev/null; then
  :
elif [ -n "$PO" ]; then
  VERD=$(printf '%s' "$PO" | sed -n 's/.*"verdict":"\([^"]*\)".*/\1/p' | tail -n 1)
  [ -n "$VERD" ] || VERD=MALFORMED
  deny "The Product Owner was convened for $TICKET and returned $VERD. Only PO-ACCEPT opens this gate; $VERD accepts nothing, so there are still no criteria this edit could be measured against.\\n\\nIf $VERD is PO-CLARIFY, the ticket is not ready: put the Product Owner's question to the user and stop there. If $VERD is PO-ACCEPT-OUT-OF-SCOPE, the criteria asked for a commit, a push or a merge, and this ceremony never commits: convene ceremony:product-owner again with a brief saying that every criterion has to be checkable in the working tree as it stands. If $VERD is MALFORMED, the return could not be read: call the Agent tool again with subagent_type \\\"ceremony:product-owner\\\" and a brief that names the file, the change and the user's words.\\n\\nIf you do not want the ceremony: run /ceremony:disband to remove the record, or set CEREMONY_ENFORCE=off in the environment, or turn the hooks off with /hooks."
else
  deny "Ticket $TICKET has no acceptance criteria. The Product Owner has not been convened for this ticket in this session, so there is nothing this edit could be measured against.\\n\\nConvene grooming first: call the Agent tool with subagent_type \\\"ceremony:product-owner\\\", wait for it to return, then convene ceremony:engineer to make the change. Wave A convenes ceremony:team-member and ceremony:product-owner in one message.\\n\\nIf you do not want the ceremony: run /ceremony:disband to remove the record, or set CEREMONY_ENFORCE=off in the environment, or turn the hooks off with /hooks."
fi

# --- refusal 3: exactly one role writes -------------------------------------
# Who is holding the tool? A hook payload raised inside a subagent carries
# agent_id and agent_type; one raised in the main session carries neither,
# because those keys are dropped when they are undefined. Absent means the chair.
AID=$(jget agent_id)
[ -n "$AID" ] || AID=$(jget agentId)
ATYPE=$(jget agent_type)
[ -n "$ATYPE" ] || ATYPE=$(jget agentType)

if [ -n "$AID" ]; then
  [ "$ATYPE" = "ceremony:engineer" ] && exit 0
  case "$ATYPE" in
    ceremony:*)
      deny "$ATYPE is a reviewing role. It reads the change; it does not make one. Report what you found and return your verdict.\\n\\nThe change on $TICKET belongs to ceremony:engineer, which has already sat or is about to. A finding you applied yourself is a finding nobody can review."
      ;;
    *)
      # A subagent from outside this plugin. Its role is not this gate's
      # business; the acceptance rule above still applied to it.
      exit 0
      ;;
  esac
fi

# No agent_id: the main session, which is the chair. The chair may edit only
# while an engineer subagent is running, and it provably never is - every
# ceremony:* call is rewritten to run_in_background:false by gate-convene.sh,
# and the chair issues no tool calls while a synchronous subagent runs. So this
# branch is a second lock on the same door rather than the door itself, and the
# forced rewrite is what makes it one.
MDIR="$DATA/sessions/$SID.engineer"
if [ -d "$MDIR" ]; then
  # A marker older than half an hour is a stop hook that never fired, not a
  # running engineer. It is deleted rather than trusted: an open write gate is
  # the worse of the two failures.
  find "$MDIR" -type f -mmin +30 -exec rm -f {} + 2>/dev/null || true
  FRESH=$(find "$MDIR" -type f -mmin -30 2>/dev/null | head -n 1)
  [ -n "$FRESH" ] && exit 0
fi

deny "The chair does not edit. $TICKET is groomed, so the change is ready to be made \\u2014 by ceremony:engineer, the only role in this ceremony with write access.\\n\\nCall the Agent tool with subagent_type \\\"ceremony:engineer\\\". Its brief is two lines: the ticket path, and the user's request quoted verbatim. Do not restate the acceptance criteria \\u2014 the engineer reads them from .ceremony/$TICKET/ticket.md, which is the point.\\n\\nWhen it returns, read the diff yourself before you describe it. That reading is the third of the four eyes and the sign-off gate checks for it.\\n\\nTo work without the ceremony: /ceremony:disband, or CEREMONY_ENFORCE=off, or /hooks."
