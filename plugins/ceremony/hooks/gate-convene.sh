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
# --- a ceremony role is convened synchronously, always ----------------------
# An asynchronous agent reports back through a notification, and a notification
# is not a tool result: PostToolUse only ever sees the launch stub, so the
# verdict never reaches the record. Rewrite the call before it is made.
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
if [ ! -f "$LEDGER" ]; then
  force_sync
  exit 0
fi

PRIOR=$(grep '"session":"'"$SID"'"' "$LEDGER" 2>/dev/null | grep '"role":"'"$ROLE"'"' | tail -n 1)
if [ -z "$PRIOR" ]; then
  force_sync
  exit 0
fi

PTS=$(printf '%s' "$PRIOR" | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p')
PV=$(printf '%s' "$PRIOR" | sed -n 's/.*"verdict":"\([^"]*\)".*/\1/p')
[ -n "$PV" ] || PV=MALFORMED

# The record moved on: an implementation entry after this role's last entry
# makes the old return stale, and re-convening is the point of the gate above.
LASTIMPL=$(grep '"role":"implementation"' "$LEDGER" 2>/dev/null | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
if [ -n "$LASTIMPL" ] && [ -n "$PTS" ]; then
  if [ "$LASTIMPL" \> "$PTS" ]; then
    force_sync
    exit 0
  fi
fi

printf '%s\n' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$AGENT has already been convened for $TICKET in this session. It returned $PV at $PTS. Convening the same role twice does not produce a second opinion; it produces a second bill.\\n\\nIts full return is on the record: .ceremony/$TICKET/ticket.md. Read it there and transcribe it. This role becomes convenable again only after a further change to the code.\\n\\nTo work without the ceremony: /ceremony:disband, or CEREMONY_ENFORCE=off, or /hooks.\"}}"
