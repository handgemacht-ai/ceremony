#!/bin/sh
# ceremony :: PreToolUse Edit|Write|NotebookEdit|MultiEdit
# Two refusals: writing the record yourself, and writing code before acceptance.
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

# The gate opens on acceptance, not on attendance. A Product Owner that asked a
# question, or whose return could not be read, has accepted nothing.
printf '%s' "$PO" | grep -q '"verdict":"PO-ACCEPT"' 2>/dev/null && exit 0

if [ -n "$PO" ]; then
  VERD=$(printf '%s' "$PO" | sed -n 's/.*"verdict":"\([^"]*\)".*/\1/p' | tail -n 1)
  [ -n "$VERD" ] || VERD=MALFORMED
  deny "The Product Owner was convened for $TICKET and returned $VERD. Only PO-ACCEPT opens this gate; $VERD accepts nothing, so there are still no criteria this edit could be measured against.\\n\\nIf $VERD is PO-CLARIFY, the ticket is not ready: put the Product Owner's question to the user and stop there. If $VERD is MALFORMED, the return could not be read: call the Agent tool again with subagent_type \\\"ceremony:product-owner\\\" and a brief that names the file, the change and the user's words, then edit.\\n\\nIf you do not want the ceremony: run /ceremony:disband to remove .ceremony/, or set CEREMONY_ENFORCE=off in the environment, or turn the hooks off with /hooks."
fi

deny "Ticket $TICKET has no acceptance criteria. The Product Owner has not been convened for this ticket in this session, so there is nothing this edit could be measured against.\\n\\nConvene grooming first: call the Agent tool with subagent_type \\\"ceremony:product-owner\\\", wait for it to return, then edit. Wave A convenes ceremony:engineer and ceremony:product-owner in one message.\\n\\nIf you do not want the ceremony: run /ceremony:disband to remove .ceremony/, or set CEREMONY_ENFORCE=off in the environment, or turn the hooks off with /hooks."
