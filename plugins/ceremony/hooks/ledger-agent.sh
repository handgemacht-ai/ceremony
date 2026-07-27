#!/bin/sh
# ceremony :: PostToolUse Agent|Task
# The only writer of the ticket record. The model never touches this path.
set -u
trap 'exit 0' EXIT

TMPIN=$(mktemp 2>/dev/null) || exit 0
cat > "$TMPIN" 2>/dev/null || { rm -f "$TMPIN"; exit 0; }
RAW=$(cat "$TMPIN" 2>/dev/null) || RAW=''

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

int() {
  case "${1:-}" in ''|*[!0-9]*) printf '0' ;; *) printf '%s' "$1" ;; esac
}

AGENT=$(jget subagent_type)
case "$AGENT" in
  ceremony:*) ROLE=${AGENT#ceremony:} ;;
  *) rm -f "$TMPIN"; exit 0 ;;
esac
case "$ROLE" in
  *[!a-z-]*|'') rm -f "$TMPIN"; exit 0 ;;
esac

# An asynchronous launch stub is not a return. The agent has not spoken yet,
# and PostToolUse will not fire again when it does, so there is nothing here to
# record and nothing here to call malformed.
case "$RAW" in
  *'"status":"async_launched"'*|*'"status": "async_launched"'*|*'"isAsync":true'*|*'"isAsync": true'*)
    rm -f "$TMPIN"; exit 0 ;;
esac

SID=$(jget session_id)
[ -n "$SID" ] || { rm -f "$TMPIN"; exit 0; }
CWD=$(jget cwd)
[ -n "$CWD" ] || CWD=$(pwd 2>/dev/null) || { rm -f "$TMPIN"; exit 0; }

# A disbanded ceremony keeps no record, and never re-arms itself by writing one.
if [ -f "$CWD/.ceremony/config.json" ]; then
  grep -q '"enforce":[ ]*"on"' "$CWD/.ceremony/config.json" 2>/dev/null || { rm -f "$TMPIN"; exit 0; }
fi

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || DATA="${TMPDIR:-/tmp}/ceremony-plugin-data"

# A turn that asked to disband may not arm anything, whatever it does with the
# record on disk. The marker is set by the turn-state hook from the prompt
# itself, so it holds even if the removal command is mistyped or cut short.
[ -f "$DATA/sessions/$SID.disbanding" ] && { rm -f "$TMPIN"; exit 0; }

SENV="$DATA/sessions/$SID.env"
TICKET=''
[ -f "$SENV" ] && TICKET=$(sed -n 's/^CEREMONY_TICKET=//p' "$SENV" 2>/dev/null | tail -n 1)
[ -n "$TICKET" ] || { rm -f "$TMPIN"; exit 0; }

# --- the agent's return, decoded --------------------------------------------
BODY=$(printf '%s' "$RAW" | awk '
  BEGIN { RS = "\1" }
  {
    key = "\"content\":[{\"type\":\"text\",\"text\":\""
    i = index($0, key)
    if (i == 0) { key = "\"text\":\""; i = index($0, key) }
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
  }' 2>/dev/null)

# Nothing came back at all: there is no return to file. MALFORMED is reserved
# for an agent that spoke and got its own closing line wrong.
[ -n "$BODY" ] || { rm -f "$TMPIN"; exit 0; }

TOKEN=$(printf '%s' "$BODY" | grep -o 'CEREMONY-VERDICT: [A-Z][A-Z-]*' 2>/dev/null | tail -n 1 | sed 's/^CEREMONY-VERDICT: //')
[ -n "$TOKEN" ] || TOKEN=MALFORMED

case "$ROLE" in
  team-member)            SET='TEAM-REPORTED'; ACT='1 \302\267 STANDUP' ;;
  product-owner)          SET='PO-ACCEPT PO-CLARIFY'; ACT='2 \302\267 GROOMING' ;;
  architect)              SET='ARCH-RECORDED'; ACT='3 \302\267 ADR' ;;
  change-advisory-board)  SET='CAB-APPROVED CAB-APPROVED-WITH-CONDITIONS CAB-NOTHING-TO-REVIEW'; ACT='4 \302\267 CHANGE ADVISORY BOARD' ;;
  engineer)               SET='ENG-IMPLEMENTED ENG-BLOCKED ENG-NO-CHANGE'; ACT='5 \302\267 IMPLEMENTATION' ;;
  reviewer)               SET='REV-MATCHES-CRITERIA REV-DEVIATES REV-INCOMPLETE REV-NOTHING-TO-REVIEW'; ACT='5a \302\267 CONFORMANCE REVIEW' ;;
  qa)                     SET='QA-PASS QA-PARTIAL QA-FAIL QA-BLOCKED'; ACT='6 \302\267 DEFINITION OF DONE' ;;
  steering-committee)     SET='SC-ALIGNED-WITH-RESERVATIONS'; ACT='- \302\267 STEERING COMMITTEE' ;;
  *)                      SET=''; ACT='- \302\267 UNRECOGNISED ROLE' ;;
esac

OK=no
for t in $SET; do
  [ "$TOKEN" = "$t" ] && OK=yes && break
done
[ "$OK" = yes ] || TOKEN=MALFORMED

# --- runtime facts, measured by the platform rather than claimed by the agent
AGENTID=$(jget agentId)
[ -n "$AGENTID" ] || AGENTID=$(jget agent_id)
case "$AGENTID" in *[!A-Za-z0-9._-]*) AGENTID='' ;; esac

STATUS=$(printf '%s' "$RAW" | sed -n 's/.*"status":"\([a-z_]*\)".*/\1/p' | tail -n 1)
case "$STATUS" in ''|*[!a-z_]*) STATUS=unknown ;; esac

STATS=$(printf '%s' "$RAW" | sed -n 's/.*"toolStats":{\([^}]*\)}.*/\1/p' | head -n 1)
stat_of() { printf '%s' "$STATS" | sed -n 's/.*"'"$1"'":\([0-9][0-9]*\).*/\1/p' | head -n 1; }
EDITS=$(int "$(stat_of editFileCount)")
ADDED=$(int "$(stat_of linesAdded)")
REMOVED=$(int "$(stat_of linesRemoved)")

# --- the record ------------------------------------------------------------
ROOT="$CWD/.ceremony"
DIR="$ROOT/$TICKET"
mkdir -p "$DIR/evidence" 2>/dev/null || { rm -f "$TMPIN"; exit 0; }
[ -f "$ROOT/.gitignore" ] || printf '*\n' > "$ROOT/.gitignore" 2>/dev/null || true
[ -f "$ROOT/config.json" ] || printf '{"version":"2.2.0","enforce":"on"}\n' > "$ROOT/config.json" 2>/dev/null || true

N=$(ls "$DIR/evidence" 2>/dev/null | wc -l | tr -d ' ')
case "$N" in ''|*[!0-9]*) N=0 ;; esac
N=$((N + 1))
NNN=$(printf '%03d' "$N")
EV="evidence/$NNN-$ROLE.json"
cp "$TMPIN" "$DIR/$EV" 2>/dev/null || true
rm -f "$TMPIN"

TS=$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null) || TS=unknown
LED="$DIR/ledger.jsonl"

# Counts the sign-off gate holds the turn to, taken here because this is where
# the agent's own words are still in hand.
COND=0
BLOCKED=0
CRIT=0
UNMET=0
EXTRA=0
AC=0
case "$ROLE" in
  product-owner)
    AC=$(printf '%s' "$BODY" | grep -c '^CEREMONY-AC: ' 2>/dev/null) || AC=0 ;;
  change-advisory-board)
    COND=$(printf '%s' "$BODY" | grep -c '^CEREMONY-CONDITION: ' 2>/dev/null) || COND=0 ;;
  qa)
    BLOCKED=$(printf '%s' "$BODY" | grep -c '^CEREMONY-DOD: [0-9][0-9]* BLOCKED ' 2>/dev/null) || BLOCKED=0 ;;
  reviewer)
    CRIT=$(printf '%s' "$BODY" | grep -c '^CEREMONY-CRIT: ' 2>/dev/null) || CRIT=0
    UNMET=$(printf '%s' "$BODY" | grep -c '^CEREMONY-CRIT: [0-9][0-9]* UNMET ' 2>/dev/null) || UNMET=0
    EXTRA=$(printf '%s' "$BODY" | grep -c '^CEREMONY-CRIT: [0-9][0-9]* EXTRA ' 2>/dev/null) || EXTRA=0 ;;
esac
COND=$(int "$COND"); BLOCKED=$(int "$BLOCKED"); AC=$(int "$AC")
CRIT=$(int "$CRIT"); UNMET=$(int "$UNMET"); EXTRA=$(int "$EXTRA")
[ "$TOKEN" = QA-BLOCKED ] && [ "$BLOCKED" -eq 0 ] && BLOCKED=1

# The reviewer answers criteria, not EXTRA lines. Only the answers are counted
# against the Product Owner's list.
CRIT=$((CRIT - EXTRA))
[ "$CRIT" -lt 0 ] && CRIT=0

# --- the commit screen ------------------------------------------------------
# This ceremony never commits: the working tree is the artifact the last three
# eyes review, and a commit destroys it. So a criterion that demands one cannot
# be met by any role here, and accepting it would open the write gate on a
# promise nobody in this process can keep.
if [ "$ROLE" = product-owner ] && [ "$TOKEN" = PO-ACCEPT ]; then
  ACLINES=$(printf '%s' "$BODY" | grep '^CEREMONY-AC: ' 2>/dev/null)
  # The boundaries are not decoration: "Emergency" contains "merge", and a
  # button that has to turn red is not a request to merge anything.
  if printf '%s' "$ACLINES" | grep -qiE '(^|[^A-Za-z])(commit|committed|commits|committing|push|pushed|pushes|merge|merged|merges|merging|rebase|rebased|pull request|pull-request|PR)([^A-Za-z]|$)' 2>/dev/null; then
    TOKEN=PO-ACCEPT-OUT-OF-SCOPE
  fi
fi

# --- the diff claim, against the measurement --------------------------------
MISMATCH=false
if [ "$ROLE" = engineer ]; then
  DL=$(printf '%s' "$BODY" | grep '^CEREMONY-DIFF: ' 2>/dev/null | tail -n 1)
  if [ -n "$DL" ]; then
    NUMS=$(printf '%s' "$DL" | grep -o '[0-9][0-9]*' 2>/dev/null | tr '\n' ' ')
    CA=$(int "$(printf '%s' "$NUMS" | cut -d' ' -f2)")
    CR=$(int "$(printf '%s' "$NUMS" | cut -d' ' -f3)")
    D1=$((CA - ADDED)); [ "$D1" -lt 0 ] && D1=$((-D1))
    D2=$((CR - REMOVED)); [ "$D2" -lt 0 ] && D2=$((-D2))
    { [ "$D1" -gt 2 ] || [ "$D2" -gt 2 ]; } && MISMATCH=true
  fi
fi

printf '{"ts":"%s","session":"%s","ticket":"%s","role":"%s","agent_type":"%s","agent_id":"%s","status":"%s","verdict":"%s","ac":%s,"conditions":%s,"blocked":%s,"crit":%s,"unmet":%s,"extra":%s,"edits":%s,"added":%s,"removed":%s,"diff_mismatch":%s,"evidence":"%s"}\n' \
  "$TS" "$SID" "$TICKET" "$ROLE" "$AGENT" "$AGENTID" "$STATUS" "$TOKEN" \
  "$AC" "$COND" "$BLOCKED" "$CRIT" "$UNMET" "$EXTRA" "$EDITS" "$ADDED" "$REMOVED" "$MISMATCH" "$EV" >> "$LED" 2>/dev/null || true

# --- the implementation entry, from what the engineer actually did ----------
# Written from the platform's own measurement rather than the engineer's
# summary of it. This is the entry the chair's reading has to postdate, and the
# one acts 5 and 7 quote their numbers from.
if [ "$ROLE" = engineer ]; then
  MOVED=no
  [ "$EDITS" -gt 0 ] && MOVED=yes
  if command -v git >/dev/null 2>&1 && git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    NOWTREE=$({ git -C "$CWD" status --porcelain 2>/dev/null; git -C "$CWD" diff --numstat HEAD 2>/dev/null; } | cksum 2>/dev/null | tr -d ' \t')
    PREVTREE=$(cat "$DATA/sessions/$SID.tree" 2>/dev/null) || PREVTREE=''
    [ -n "$NOWTREE" ] && [ -n "$PREVTREE" ] && [ "$NOWTREE" != "$PREVTREE" ] && MOVED=yes
    [ -n "$NOWTREE" ] && printf '%s\n' "$NOWTREE" > "$DATA/sessions/$SID.tree" 2>/dev/null || true
  fi

  if [ "$MOVED" = yes ]; then
    # editFileCount counts edit calls, not files: three edits to one file is
    # three. The file count comes from the paths the write recorder saw for
    # this agent, which is the same measurement at the right granularity.
    # "(working tree)" is the shell recorder's placeholder for a change it saw
    # without seeing a path. It is not a file and must not be counted as one.
    FILES=0
    if [ -n "$AGENTID" ] && [ -f "$LED" ]; then
      FILES=$(grep '"role":"implementation"' "$LED" 2>/dev/null | grep '"agent_id":"'"$AGENTID"'"' | sed -n 's/.*"file":"\([^"]*\)".*/\1/p' | grep -v '^(working tree)$' | sort -u | wc -l | tr -d ' ')
    fi
    FILES=$(int "$FILES")
    [ "$FILES" -eq 0 ] && FILES=$EDITS
    printf '{"ts":"%s","session":"%s","ticket":"%s","role":"implementation","by":"engineer","agent_id":"%s","via":"agent","files":%s,"added":%s,"removed":%s,"edits":%s}\n' \
      "$TS" "$SID" "$TICKET" "$AGENTID" "$FILES" "$ADDED" "$REMOVED" "$EDITS" >> "$LED" 2>/dev/null || true
  fi
fi

{
  printf '\n## '
  printf "$ACT"
  printf ' \342\200\224 %s \342\200\224 %s \342\200\224 %s\n\n' "$AGENT" "$TS" "$TOKEN"
  printf '%s\n' "$BODY"
} >> "$DIR/ticket.md" 2>/dev/null || true

exit 0
