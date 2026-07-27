#!/bin/sh
# ceremony :: SubagentStart (matcher ceremony:engineer) and SubagentStop (all)
# Says whether an engineer subagent is running right now.
#
# The write gate needs to tell two editors apart that look identical to it: the
# chair, which may not edit, and ceremony:engineer, which may. A main-session
# hook payload carries no agent_id at all, so the gate cannot read the actor off
# the call. This marker supplies it from the one place that knows: the lifecycle
# of the subagent itself.
set -u
trap 'exit 0' EXIT

MODE=${1:-}
case "$MODE" in start|stop) ;; *) exit 0 ;; esac

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
case "$SID" in *[!A-Za-z0-9._-]*) exit 0 ;; esac

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || DATA="${TMPDIR:-/tmp}/ceremony-plugin-data"
MDIR="$DATA/sessions/$SID.engineer"

# The working tree as it stands, written as a git tree object, so that what the
# engineer did can be measured later by diffing against it.
#
# toolStats.linesAdded counts the lines each edit call touched, which is not the
# same number as the diff: two edits to the same lines are counted twice, and a
# line rewritten and rewritten again is counted twice more. Acts 5 and 7 quote a
# diff, so a diff is what has to be measured.
#
# GIT_INDEX_FILE points the staging area at a scratch file, so the user's own
# index is not touched and nothing is staged. Ignored paths stay out, which
# keeps .ceremony/ out of the measurement.
#
# Ephemera are excluded from both ends of the measurement. An engineer that runs
# the test suite leaves bytecode behind, and a bytecode file is not a change to
# the ticket: counted, it inflates the very numbers the diff measurement exists
# to get right. node_modules is deliberately not on the list - it is ignored
# everywhere it appears, so it never reaches this command anyway, and it is the
# one path where excluding it could hide a change somebody meant to make.
# The pathspec forms matter: :(exclude)**/__pycache__/** misses a __pycache__
# directory at the repository root on git 2.43, and *__pycache__/* does not.
EPH1=':(exclude)*__pycache__/*'
EPH2=':(exclude)*.pyc'
EPH3=':(exclude)*.DS_Store'

snap_tree() {
  command -v git >/dev/null 2>&1 || return 1
  git -C "$1" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
  IDX="$2.idx"
  rm -f "$IDX" 2>/dev/null || true
  GIT_INDEX_FILE="$IDX" git -C "$1" read-tree --empty >/dev/null 2>&1 || { rm -f "$IDX"; return 1; }
  GIT_INDEX_FILE="$IDX" git -C "$1" add -A -- "$EPH1" "$EPH2" "$EPH3" >/dev/null 2>&1 || { rm -f "$IDX"; return 1; }
  T=$(GIT_INDEX_FILE="$IDX" git -C "$1" write-tree 2>/dev/null)
  rm -f "$IDX" 2>/dev/null || true
  case "$T" in ''|*[!0-9a-f]*) return 1 ;; esac
  printf '%s\n' "$T" > "$2" 2>/dev/null || return 1
  return 0
}

AGENT=$(jget agent_type)
[ -n "$AGENT" ] || AGENT=$(jget subagent_type)

AID=$(jget agent_id)
[ -n "$AID" ] || AID=$(jget agentId)
case "$AID" in
  ''|*[!A-Za-z0-9._-]*) AID=unknown ;;
esac

# SubagentStop takes no matcher, so it fires for every subagent in the session.
# Only the engineer's own stop clears the engineer's marker.
if [ "$MODE" = stop ]; then
  [ "$AGENT" = "ceremony:engineer" ] || exit 0
  rm -f "$MDIR/$AID" 2>/dev/null || true
  # The baseline is deliberately not removed here. This hook and the one that
  # records the return race, and the measurement needs the baseline more than
  # the directory needs tidying; the turn-state hook clears it next prompt.
  # An engineer that stopped without an id of its own leaves nothing to name, so
  # the marker directory is cleared entirely. Leaving one behind would hold the
  # write gate open for the chair, and that failure is worse than a spurious
  # denial.
  [ "$AID" = unknown ] && rm -f "$MDIR"/* 2>/dev/null
  rmdir "$MDIR" 2>/dev/null || true
  exit 0
fi

# SubagentStart is matched on the agent type, so this hook only runs for
# ceremony:engineer. The check is repeated anyway: a matcher is configuration,
# and configuration is the thing most likely to be edited by hand.
case "$AGENT" in
  ''|ceremony:engineer) ;;
  *) exit 0 ;;
esac

mkdir -p "$MDIR" 2>/dev/null || exit 0

# A marker older than half an hour is not a running engineer, it is a stop hook
# that never fired. The gate ignores those; they are cleared here so the
# directory does not accumulate them.
find "$MDIR" -type f -mmin +30 -exec rm -f {} + 2>/dev/null || true

: > "$MDIR/$AID" 2>/dev/null || true

CWD=$(jget cwd)
[ -n "$CWD" ] || CWD=$(sed -n 's/^CEREMONY_CWD=//p' "$DATA/sessions/$SID.env" 2>/dev/null | tail -n 1)
[ -n "$CWD" ] || exit 0
snap_tree "$CWD" "$DATA/sessions/$SID.base.$AID" || true

exit 0
