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
  engineer)               SET='ENG-REPORTED'; ACT='1 \302\267 STANDUP' ;;
  product-owner)          SET='PO-ACCEPT PO-CLARIFY'; ACT='2 \302\267 GROOMING' ;;
  architect)              SET='ARCH-RECORDED'; ACT='3 \302\267 ADR' ;;
  change-advisory-board)  SET='CAB-APPROVED CAB-APPROVED-WITH-CONDITIONS CAB-NOTHING-TO-REVIEW'; ACT='4 \302\267 CHANGE ADVISORY BOARD' ;;
  qa)                     SET='QA-PASS QA-PARTIAL QA-FAIL QA-BLOCKED'; ACT='6 \302\267 DEFINITION OF DONE' ;;
  steering-committee)     SET='SC-ALIGNED-WITH-RESERVATIONS'; ACT='- \302\267 STEERING COMMITTEE' ;;
  *)                      SET=''; ACT='- \302\267 UNRECOGNISED ROLE' ;;
esac

OK=no
for t in $SET; do
  [ "$TOKEN" = "$t" ] && OK=yes && break
done
[ "$OK" = yes ] || TOKEN=MALFORMED

# --- the record ------------------------------------------------------------
ROOT="$CWD/.ceremony"
DIR="$ROOT/$TICKET"
mkdir -p "$DIR/evidence" 2>/dev/null || { rm -f "$TMPIN"; exit 0; }
[ -f "$ROOT/.gitignore" ] || printf '*\n' > "$ROOT/.gitignore" 2>/dev/null || true
[ -f "$ROOT/config.json" ] || printf '{"version":"2.0.1","enforce":"on"}\n' > "$ROOT/config.json" 2>/dev/null || true

N=$(ls "$DIR/evidence" 2>/dev/null | wc -l | tr -d ' ')
case "$N" in ''|*[!0-9]*) N=0 ;; esac
N=$((N + 1))
NNN=$(printf '%03d' "$N")
EV="evidence/$NNN-$ROLE.json"
cp "$TMPIN" "$DIR/$EV" 2>/dev/null || true
rm -f "$TMPIN"

TS=$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null) || TS=unknown

printf '{"ts":"%s","session":"%s","ticket":"%s","role":"%s","agent_type":"%s","verdict":"%s","evidence":"%s"}\n' \
  "$TS" "$SID" "$TICKET" "$ROLE" "$AGENT" "$TOKEN" "$EV" >> "$DIR/ledger.jsonl" 2>/dev/null || true

{
  printf '\n## '
  printf "$ACT"
  printf ' \342\200\224 %s \342\200\224 %s \342\200\224 %s\n\n' "$AGENT" "$TS" "$TOKEN"
  printf '%s\n' "$BODY"
} >> "$DIR/ticket.md" 2>/dev/null || true

exit 0
