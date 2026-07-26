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

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || DATA="${TMPDIR:-/tmp}/ceremony-plugin-data"
SENV="$DATA/sessions/$SID.env"
[ -f "$SENV" ] || exit 0
TICKET=$(sed -n 's/^CEREMONY_TICKET=//p' "$SENV" 2>/dev/null | tail -n 1)
[ -n "$TICKET" ] || exit 0

LEDGER="$CWD/.ceremony/$TICKET/ledger.jsonl"
[ -f "$LEDGER" ] || exit 0

PRIOR=$(grep '"session":"'"$SID"'"' "$LEDGER" 2>/dev/null | grep '"role":"'"$ROLE"'"' | tail -n 1)
[ -n "$PRIOR" ] || exit 0

PTS=$(printf '%s' "$PRIOR" | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p')
PV=$(printf '%s' "$PRIOR" | sed -n 's/.*"verdict":"\([^"]*\)".*/\1/p')
[ -n "$PV" ] || PV=MALFORMED

# The record moved on: an implementation entry after this role's last entry
# makes the old return stale, and re-convening is the point of the gate above.
LASTIMPL=$(grep '"role":"implementation"' "$LEDGER" 2>/dev/null | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
if [ -n "$LASTIMPL" ] && [ -n "$PTS" ]; then
  if [ "$LASTIMPL" \> "$PTS" ]; then
    exit 0
  fi
fi

printf '%s\n' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$AGENT has already been convened for $TICKET in this session. It returned $PV at $PTS. Convening the same role twice does not produce a second opinion; it produces a second bill.\\n\\nIts full return is on the record: .ceremony/$TICKET/ticket.md. Read it there and transcribe it. This role becomes convenable again only after a further change to the code.\\n\\nTo work without the ceremony: /ceremony:disband, or CEREMONY_ENFORCE=off, or /hooks.\"}}"
