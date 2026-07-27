#!/bin/sh
# ceremony :: PostToolUse Edit|Write|NotebookEdit|MultiEdit
# Records that the code moved, and when, so ordering is checkable.
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

SID=$(jget session_id)
[ -n "$SID" ] || exit 0
CWD=$(jget cwd)
[ -n "$CWD" ] || CWD=$(pwd 2>/dev/null) || exit 0

if [ -f "$CWD/.ceremony/config.json" ]; then
  grep -q '"enforce":[ ]*"on"' "$CWD/.ceremony/config.json" 2>/dev/null || exit 0
fi

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || DATA="${TMPDIR:-/tmp}/ceremony-plugin-data"
SENV="$DATA/sessions/$SID.env"
[ -f "$SENV" ] || exit 0
TICKET=$(sed -n 's/^CEREMONY_TICKET=//p' "$SENV" 2>/dev/null | tail -n 1)
[ -n "$TICKET" ] || exit 0

# The edit is recorded even when no role has been convened yet: an unceremonious
# turn is exactly the one the sign-off gate needs to know about. The ledger is
# created here; config.json is not, so this never arms the write gate from
# behind - only an agent return does that.
ROOT="$CWD/.ceremony"
DIR="$ROOT/$TICKET"
mkdir -p "$DIR" 2>/dev/null || exit 0
[ -f "$ROOT/.gitignore" ] || printf '*\n' > "$ROOT/.gitignore" 2>/dev/null || true

FILE=$(jget file_path)
[ -n "$FILE" ] || FILE=$(jget notebook_path)
[ -n "$FILE" ] || FILE='(unnamed)'
FILE=$(printf '%s' "$FILE" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\000-\037')

TS=$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null) || TS=unknown

# Who made this edit. A payload raised inside a subagent carries agent_id and
# agent_type; one raised in the main session carries neither. So an entry
# stamped by:"chair" is an edit the chair made itself, and the sign-off gate
# reads it as exactly that. Nothing here hides it.
AID=$(jget agent_id)
[ -n "$AID" ] || AID=$(jget agentId)
ATYPE=$(jget agent_type)
[ -n "$ATYPE" ] || ATYPE=$(jget agentType)
case "$AID" in *[!A-Za-z0-9._-]*) AID='' ;; esac

if [ -z "$AID" ]; then
  BY=chair
elif [ "$ATYPE" = "ceremony:engineer" ]; then
  BY=engineer
elif [ -n "$ATYPE" ]; then
  BY="agent:$ATYPE"
else
  BY=subagent
fi
BY=$(printf '%s' "$BY" | tr -cd 'A-Za-z0-9:._-')

printf '{"ts":"%s","session":"%s","ticket":"%s","role":"implementation","by":"%s","agent_id":"%s","file":"%s"}\n' \
  "$TS" "$SID" "$TICKET" "$BY" "$AID" "$FILE" >> "$DIR/ledger.jsonl" 2>/dev/null || true

# This change is now on the record, so it is the new baseline. Without this the
# Bash recorder would see the same change again and file it a second time.
if command -v git >/dev/null 2>&1; then
  if git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ST=$({ git -C "$CWD" status --porcelain 2>/dev/null; git -C "$CWD" diff --numstat HEAD 2>/dev/null; } | cksum 2>/dev/null | tr -d ' \t')
    [ -n "$ST" ] && printf '%s\n' "$ST" > "$DATA/sessions/$SID.tree" 2>/dev/null || true
  fi
fi

exit 0
