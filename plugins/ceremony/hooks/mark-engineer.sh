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
exit 0
