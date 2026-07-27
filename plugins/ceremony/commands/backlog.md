---
description: List the carried backlog — what the ceremony filed and has not closed
argument-hint: "[open|all; defaults to open]"
---

Print the ceremony's backlog. Read-only.

## 1. Find it

The backlog lives at `.ceremony/backlog.jsonl`, one JSON object per line. It is
project-scoped and it outlives the session that wrote it.

If the file does not exist, say so in one line — nothing has been carried — and
stop. If `.ceremony/` itself does not exist, say so in one line: this repository
has no ticket record and enforcement is disarmed. `/ceremony:grooming` starts
one.

## 2. Print it

One line per entry, newest last, in the order the file holds them:

```text
CER-BL-0003 · restore-verification · open · opened by CER-276-03 in sprint 276
  Elixir toolchain not installed; mix unavailable
  Needs: mise install (pinned erlang + elixir) · Owner: DevOps Engineer
```

With `$ARGUMENTS` empty or `open`, print the entries whose `"status"` is
`"open"`. With `all`, print every entry and mark the closed ones. End with one
line: how many are open, and how many the file holds in total.

## 3. Say what each kind means

Only two kinds are ever filed, and the count of kinds is not a matter of
opinion:

- `restore-verification` — verification of the user's request was blocked, the
  DevOps Engineer could not restore it within the ceremony, and the ticket is
  carried until it can be verified.
- `carried-condition` — the Change Advisory Board attached a MUST condition that
  was not applied in the turn that raised it.

Everything else a ceremony proposes — SHOULD and NICE conditions, retro action
items, reviewer nice-to-haves — is rendered under *Proposed backlog (not filed)*
and written nowhere. If you see a third kind in this file, say so plainly: no
code path in the plugin writes one, so it was put there by hand.

## Constraints

- Read-only. Do not write to `.ceremony/`, do not close an entry, do not open
  one, and do not re-word what is on the record. Print it.
- Do not convene any agent. This command inspects the loop; it does not run it.
- The backlog is local. `.ceremony/.gitignore` is `*`, so a fresh clone of this
  repository has no backlog at all — which is the right default for a private
  record and the wrong one for a team that wants to share carry-over.
