#!/bin/sh
# ceremony :: UserPromptSubmit :: derive the turn state once, in one place.
set -u
trap 'exit 0' EXIT

RAW=$(cat 2>/dev/null) || RAW=''

num() {
  _n=$1
  while [ ${#_n} -gt 1 ]; do
    case "$_n" in 0*) _n=${_n#0} ;; *) break ;; esac
  done
  printf '%s' "$_n"
}

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
[ -n "$SID" ] || SID=nosession
CWD=$(jget cwd)
[ -n "$CWD" ] || CWD=$(pwd 2>/dev/null) || CWD='.'

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || DATA="${TMPDIR:-/tmp}/ceremony-plugin-data"
SDIR="$DATA/sessions"
mkdir -p "$SDIR" 2>/dev/null || true
SENV="$SDIR/$SID.env"
SBLK="$SDIR/$SID.block"

# --- a synthetic prompt is not a new request --------------------------------
# A finished background agent, a notification or a system message arrives here
# as a prompt. It continues the turn already in progress; it does not raise a
# ticket of its own, and it does not advance the turn counter.
case "$RAW" in
  *'<task-notification'*|*'[SYSTEM NOTIFICATION'*|*'NOT USER INPUT'*|*'<system-reminder'*)
    [ -f "$SBLK" ] && cat "$SBLK" 2>/dev/null
    exit 0
    ;;
esac

# --- civil calendar arithmetic, no `date -d`, no timezone drift -------------
d_from_civil() {
  _y=$1; _m=$2; _d=$3
  [ "$_m" -le 2 ] && _y=$((_y - 1))
  _era=$((_y / 400))
  _yoe=$((_y - _era * 400))
  if [ "$_m" -gt 2 ]; then _mp=$((_m - 3)); else _mp=$((_m + 9)); fi
  _doy=$(((153 * _mp + 2) / 5 + _d - 1))
  _doe=$((_yoe * 365 + _yoe / 4 - _yoe / 100 + _doy))
  printf '%s' $((_era * 146097 + _doe - 719468))
}

civil_from_d() {
  _z=$(($1 + 719468))
  _era=$((_z / 146097))
  _doe=$((_z - _era * 146097))
  _yoe=$(((_doe - _doe / 1460 + _doe / 36524 - _doe / 146096) / 365))
  _y=$((_yoe + _era * 400))
  _doy=$((_doe - (365 * _yoe + _yoe / 4 - _yoe / 100)))
  _mp=$(((5 * _doy + 2) / 153))
  _d=$((_doy - (153 * _mp + 2) / 5 + 1))
  if [ "$_mp" -lt 10 ]; then _m=$((_mp + 3)); else _m=$((_mp - 9)); fi
  [ "$_m" -le 2 ] && _y=$((_y + 1))
  printf '%04d-%02d-%02d' "$_y" "$_m" "$_d"
}

last_dom() {
  _ly=$1; _lm=$2
  if [ "$_lm" -eq 12 ]; then _ny=$((_ly + 1)); _nm=1; else _ny=$_ly; _nm=$((_lm + 1)); fi
  _first=$(d_from_civil "$_ny" "$_nm" 1)
  _last=$(civil_from_d $((_first - 1)))
  printf '%s' "${_last##*-}"
}

Y=$(date +%Y 2>/dev/null) || Y=''
M=$(date +%m 2>/dev/null) || M=''
D=$(date +%d 2>/dev/null) || D=''
HH=$(date +%H 2>/dev/null) || HH=''
MI=$(date +%M 2>/dev/null) || MI=''
case "$Y$M$D$HH$MI" in
  ''|*[!0-9]*) exit 0 ;;
esac
Y=$(num "$Y"); M=$(num "$M"); D=$(num "$D"); HHN=$(num "$HH"); MIN_=$(num "$MI")

TODAY=$(d_from_civil "$Y" "$M" "$D")
SPRINT_EPOCH=$(d_from_civil 2016 1 4)
DAYS=$((TODAY - SPRINT_EPOCH))
[ "$DAYS" -lt 0 ] && DAYS=0
SPRINT=$((DAYS / 14 + 1))
SDAY=$((DAYS % 14 + 1))
S_START=$(civil_from_d $((SPRINT_EPOCH + 14 * (SPRINT - 1))))
S_END=$(civil_from_d $((SPRINT_EPOCH + 14 * (SPRINT - 1) + 13)))

DOW=$(((TODAY % 7 + 7 + 4) % 7))
case "$DOW" in
  0) WD=Sunday ;; 1) WD=Monday ;; 2) WD=Tuesday ;; 3) WD=Wednesday ;;
  4) WD=Thursday ;; 5) WD=Friday ;; 6) WD=Saturday ;; *) WD=Someday ;;
esac
ISO_DATE=$(printf '%04d-%02d-%02d' "$Y" "$M" "$D")
COMPACT=$(printf '%04d%02d%02d' "$Y" "$M" "$D")
CLOCK=$(printf '%02d:%02d' "$HHN" "$MIN_")

# --- freeze windows: first match on the published list wins -----------------
LDOM=$(last_dom "$Y" "$M")
WINDOW=''
if [ "$DOW" -eq 5 ] || [ "$DOW" -eq 6 ] || [ "$DOW" -eq 0 ]; then
  WINDOW='Weekend freeze'
elif [ "$D" -gt $((LDOM - 2)) ]; then
  WINDOW='Month-end freeze'
elif { [ "$M" -eq 1 ] || [ "$M" -eq 4 ] || [ "$M" -eq 7 ] || [ "$M" -eq 10 ]; } && [ "$D" -gt $((LDOM - 5)) ]; then
  WINDOW='Quarter-end freeze'
elif [ "$SDAY" -eq 14 ]; then
  WINDOW='Sprint-boundary freeze'
elif [ "$HHN" -eq 12 ]; then
  WINDOW='Lunch freeze'
fi
if [ -n "$WINDOW" ]; then
  FREEZE="$WINDOW - emergency waiver granted by the Release Manager"
else
  FREEZE="No freeze window in effect - $WD $ISO_DATE, no window open"
fi

# --- session state ----------------------------------------------------------
TURN=0
if [ -f "$SENV" ]; then
  TURN=$(sed -n 's/^CEREMONY_TURN=//p' "$SENV" 2>/dev/null | tail -n 1)
  case "$TURN" in ''|*[!0-9]*) TURN=0 ;; esac
fi
TURN=$((TURN + 1))
NN=$(printf '%02d' "$TURN")
TICKET="CER-$SPRINT-$NN"
CHG="CHG-$COMPACT-$NN"
TSTART=$(date +%Y-%m-%dT%H:%M:%S%z 2>/dev/null) || TSTART=''

{
  printf 'CEREMONY_TICKET=%s\n' "$TICKET"
  printf 'CEREMONY_SPRINT=%s\n' "$SPRINT"
  printf 'CEREMONY_SPRINT_DAY=%s\n' "$SDAY"
  printf 'CEREMONY_CHG=%s\n' "$CHG"
  printf 'CEREMONY_NOW=%s\n' "$WD $ISO_DATE $CLOCK"
  printf 'CEREMONY_FREEZE=%s\n' "$FREEZE"
  printf 'CEREMONY_TURN=%s\n' "$TURN"
  printf 'CEREMONY_TURN_START=%s\n' "$TSTART"
  printf 'CEREMONY_CWD=%s\n' "$CWD"
} > "$SENV" 2>/dev/null || true

# --- ledger summary ---------------------------------------------------------
LEDGER="$CWD/.ceremony/$TICKET/ledger.jsonl"
COUNT=0
ROLES='no roles convened'
if [ -f "$LEDGER" ]; then
  COUNT=$(wc -l < "$LEDGER" 2>/dev/null | tr -d ' ')
  case "$COUNT" in ''|*[!0-9]*) COUNT=0 ;; esac
  R=$(sed -n 's/.*"role":"\([a-z-]*\)".*/\1/p' "$LEDGER" 2>/dev/null | sort -u | tr '\n' ' ' | sed 's/ $//; s/ /, /g')
  [ -n "$R" ] && ROLES="$R"
fi

ENFORCE=on
if [ ! -f "$CWD/.ceremony/config.json" ]; then
  ENFORCE='off (no roles convened yet; /ceremony:grooming arms it)'
elif ! grep -q '"enforce":[ ]*"on"' "$CWD/.ceremony/config.json" 2>/dev/null; then
  ENFORCE='off (disbanded; /ceremony:grooming re-arms it)'
elif [ "${CEREMONY_ENFORCE:-on}" = off ]; then
  ENFORCE='off (CEREMONY_ENFORCE=off)'
fi

{
  printf 'CEREMONY TURN STATE (machine-derived - copy these values verbatim; do not recompute)\n'
  printf 'now: %s %s %s\n' "$WD" "$ISO_DATE" "$CLOCK"
  printf 'sprint: %s \302\267 day %s of 14 \302\267 %s \342\206\222 %s\n' "$SPRINT" "$SDAY" "$S_START" "$S_END"
  printf 'ticket: %s \302\267 change: %s\n' "$TICKET" "$CHG"
  printf 'freeze: %s\n' "$FREEZE"
  printf 'ledger: .ceremony/%s/ledger.jsonl - %s entries, %s\n' "$TICKET" "$COUNT" "$ROLES"
  printf 'enforcement: %s\n' "$ENFORCE"
  printf 'path: a turn that will change any file runs the 8 acts and convenes ceremony:product-owner before the first edit; a question runs LCP-2; a greeting runs LCP-1.\n'
  printf 'shape: on the 8-act path the header comes first and acts 1-8 are all emitted, numbered, in one message. Starting at act 5 is the wrong path, not a shorter one.\n'
  printf 'agents: every ceremony:* Agent call is issued with run_in_background false.\n'
} > "$SBLK" 2>/dev/null

cat "$SBLK" 2>/dev/null
exit 0
