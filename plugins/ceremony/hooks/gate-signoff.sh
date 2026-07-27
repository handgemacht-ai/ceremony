#!/bin/sh
# ceremony :: Stop
# Four rules, checked in order. The first one tripped sends the turn back once.
set -u
trap 'exit 0' EXIT

RAW=$(cat 2>/dev/null) || RAW=''

case "$RAW" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

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

block() {
  printf '%s\n' "{\"decision\":\"block\",\"reason\":\"$1\"}"
  exit 0
}

MSG=$(jget last_assistant_message)
[ -n "$MSG" ] || exit 0

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
[ "${CEREMONY_ENFORCE:-on}" = off ] && exit 0
if [ -f "$CWD/.ceremony/config.json" ]; then
  grep -q '"enforce":[ ]*"on"' "$CWD/.ceremony/config.json" 2>/dev/null || exit 0
fi
TSTART=$(sed -n 's/^CEREMONY_TURN_START=//p' "$SENV" 2>/dev/null | tail -n 1)

LEDGER="$CWD/.ceremony/$TICKET/ledger.jsonl"
MINE=''
[ -f "$LEDGER" ] && MINE=$(grep '"session":"'"$SID"'"' "$LEDGER" 2>/dev/null)

HATCH='If you want none of this: /ceremony:disband removes the record, CEREMONY_ENFORCE=off disarms the gates, /hooks turns the hooks off, /output-style default ends the ceremony.'

# --- A: a signature nobody gave --------------------------------------------
SIGNING='PO-ACCEPT ARCH-RECORDED CAB-APPROVED CAB-APPROVED-WITH-CONDITIONS QA-PASS SC-ALIGNED-WITH-RESERVATIONS'
for tok in $(printf '%s' "$MSG" | grep -o '[A-Z][A-Z0-9-]*' 2>/dev/null | sort -u); do
  case " $SIGNING " in *" $tok "*) ;; *) continue ;; esac
  if ! printf '%s' "$MINE" | grep -q '"verdict":"'"$tok"'"' 2>/dev/null; then
    block "Act 7 carries the signing token $tok, and no agent returned $tok for $TICKET in this session. The ledger .ceremony/$TICKET/ledger.jsonl has no such entry, so that signature was written rather than collected.\\n\\nRewrite that line as: <Role> \\u2014 withheld (role not convened). A role that was never convened is withheld, and that is the ordinary outcome. Then finish the turn.\\n\\n$HATCH"
  fi
done

# --- B: a tick on a token that withholds ------------------------------------
CHECK=$(printf '\342\234\223')
for tok in $(printf '%s' "$MSG" | grep -F "$CHECK" 2>/dev/null | grep -o '[A-Z][A-Z0-9]*-[A-Z0-9-]*' 2>/dev/null | sort -u); do
  case "$tok" in CEREMONY-*|SIGN-OFF) continue ;; esac
  case " $SIGNING " in *" $tok "*) continue ;; esac
  block "Act 7 gives a tick to $tok. $tok is not a signing token: it withholds.\n\nOnly these six may carry a tick: PO-ACCEPT, ARCH-RECORDED, CAB-APPROVED, CAB-APPROVED-WITH-CONDITIONS, QA-PASS, SC-ALIGNED-WITH-RESERVATIONS. Every other token is written as: <Role> \u2014 withheld ($tok). The Engineer reports rather than approves and withholds every time.\n\nRewrite that line and finish the turn.\n\n$HATCH"
done

# --- C: a turn that changed files, rendered as though it had not -------------
IMPL_NOW=no
if [ -n "$TSTART" ]; then
  for t in $(printf '%s' "$MINE" | grep '"role":"implementation"' 2>/dev/null | sed -n 's/.*\"ts\":\"\([^\"]*\)\".*/\1/p'); do
    [ "$t" \< "$TSTART" ] || IMPL_NOW=yes
  done
fi
if [ "$IMPL_NOW" = yes ]; then
  if printf '%s' "$MSG" | grep -q 'No roles convened on this path' 2>/dev/null; then
    block "This turn changed files on $TICKET, and act 7 was rendered as the Lightweight Ceremony Path. LCP-2 is for a question that changes nothing. A turn that edits a file is never LCP-2, however small the edit.\n\nRe-render the whole response as the standard eight-act path, with act 7 assembled from the ledger: a role with an entry is quoted, a role without one is written as <Role> \u2014 withheld (role not convened).\n\n$HATCH"
  fi
  if ! printf '%s' "$MSG" | grep -q 'SIGN-OFF' 2>/dev/null; then
    block "This turn changed files on $TICKET and the response has no sign-off. The ceremony applies to every turn that changes a file, and the eight acts are how it applies.\n\nRe-render the response as the standard eight-act path, with act 7 assembled from the ledger: a role with an entry is quoted, a role without one is written as <Role> \u2014 withheld (role not convened).\n\n$HATCH"
  fi
fi

# --- D: an unsigned ceremony rendered as a signed one -----------------------
if printf '%s' "$MSG" | grep -q 'SIGN-OFF' 2>/dev/null; then
  if [ -z "$MINE" ]; then
    if ! printf '%s' "$MSG" | grep -q 'role not convened' 2>/dev/null; then
      if ! printf '%s' "$MSG" | grep -q 'No roles convened' 2>/dev/null; then
        block "Act 7 was rendered for $TICKET and the ledger for this ticket is empty: no agent was convened in this turn. A sign-off assembled from nothing has to say so.\\n\\nEither convene the roles through the Agent tool and render act 7 from what they return, or rewrite every line of act 7 as: <Role> \\u2014 withheld (role not convened). Then finish the turn.\\n\\n$HATCH"
      fi
    fi
  fi
fi

# --- E: a Definition of Done nobody assessed --------------------------------
if printf '%s' "$MSG" | grep -qF '[x]' 2>/dev/null; then
  if ! printf '%s' "$MINE" | grep -q '"role":"qa"' 2>/dev/null; then
    block "Act 6 has ticked boxes and no QA agent was convened for $TICKET in this session. Ticked boxes are claims about checks that ran; the ledger records none.\\n\\nEither convene ceremony:qa through the Agent tool and transcribe its CEREMONY-DOD lines verbatim, or replace act 6 with exactly: No QA agent convened - Definition of Done not assessed. Then finish the turn.\\n\\n$HATCH"
  fi
fi

# --- F: verification that happened before the change ------------------------
LASTIMPL=$(printf '%s' "$MINE" | grep '"role":"implementation"' 2>/dev/null | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
LASTVER=$(printf '%s' "$MINE" | grep -E '"role":"(qa|change-advisory-board)"' 2>/dev/null | sed -n 's/.*"ts":"\([^"]*\)".*/\1/p' | sort | tail -n 1)
if [ -n "$LASTIMPL" ] && [ -n "$LASTVER" ]; then
  if [ "$LASTVER" \< "$LASTIMPL" ]; then
    block "The last verification of $TICKET ran at $LASTVER and the last change to the code landed at $LASTIMPL. Verification that precedes the change verified the previous state of the repository.\\n\\nConvene ceremony:qa again through the Agent tool, on the code as it stands now, and render act 6 and act 7 from what it returns. The convening gate allows a re-convening once the code has moved.\\n\\n$HATCH"
  fi
fi

exit 0
