#!/bin/sh
# ceremony :: PostToolUse Bash
# A shell command that changed the working tree is an implementation too. The
# write gate cannot see it - Bash is ungated on purpose - but the record can,
# and rule D in the sign-off gate needs to know the code moved.
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

ROOT="$CWD/.ceremony"
DIR="$ROOT/$TICKET"

# --- the chair reading the diff ---------------------------------------------
# The third of the four eyes. It is the one participant whose work leaves no
# tool result to record, so it is recorded from the command it ran. Only the
# chair's own reading counts: a subagent reading the diff is doing its own job.
CMD=$(jget command)
if [ -z "$AID" ] && [ -n "$CMD" ]; then
  case "$CMD" in
    *'git diff'*|*'git status'*|*'git show'*|*'git log -p'*)
      mkdir -p "$DIR" 2>/dev/null || exit 0
      [ -f "$ROOT/.gitignore" ] || printf '*\n' > "$ROOT/.gitignore" 2>/dev/null || true
      SHORT=$(printf '%s' "$CMD" | tr '\n' ' ' | cut -c1-80 | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | tr -d '\000-\037')
      RTS=$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null) || RTS=unknown
      printf '{"ts":"%s","session":"%s","ticket":"%s","role":"chair-review","cmd":"%s"}\n' \
        "$RTS" "$SID" "$TICKET" "$SHORT" >> "$DIR/ledger.jsonl" 2>/dev/null || true
      ;;
  esac
fi

# Outside a repository there is nothing to compare against, and guessing is
# worse than not recording. Fail open, quietly, and cheaply.
command -v git >/dev/null 2>&1 || exit 0
git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

# The same pipeline, byte for byte, as the one in turn-state.sh and
# ledger-edit.sh. A different one would compare two different measurements.
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

STAMP=$({ git -C "$CWD" status --porcelain -- "$EPH1" "$EPH2" "$EPH3" 2>/dev/null; git -C "$CWD" diff --numstat HEAD -- "$EPH1" "$EPH2" "$EPH3" 2>/dev/null; } | cksum 2>/dev/null | tr -d ' \t')
[ -n "$STAMP" ] || exit 0

SEEN="$DATA/sessions/$SID.tree"
PREV=$(cat "$SEEN" 2>/dev/null) || PREV=''
printf '%s\n' "$STAMP" > "$SEEN" 2>/dev/null || true

# The baseline is laid down at the start of the turn and refreshed by every
# recorded edit, so what is left here is a change no other hook has seen.
[ -n "$PREV" ] || exit 0
[ "$PREV" = "$STAMP" ] && exit 0

mkdir -p "$DIR" 2>/dev/null || exit 0
[ -f "$ROOT/.gitignore" ] || printf '*\n' > "$ROOT/.gitignore" 2>/dev/null || true

TS=$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null) || TS=unknown

printf '{"ts":"%s","session":"%s","ticket":"%s","role":"implementation","by":"%s","agent_id":"%s","via":"bash","file":"(working tree)"}\n' \
  "$TS" "$SID" "$TICKET" "$BY" "$AID" >> "$DIR/ledger.jsonl" 2>/dev/null || true

exit 0
