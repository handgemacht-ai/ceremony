---
description: Close the sprint, carry what is unfinished, and run the next iteration of the loop
argument-hint: "[backlog id to re-attempt; defaults to the oldest open one]"
---

Close the current sprint and run the next iteration for: `$ARGUMENTS` (if empty,
the oldest open entry in `.ceremony/backlog.jsonl`).

This is the manual entry to the mechanic the standard path enters on its own.
When the DevOps Engineer returns a non-restoring verdict that still names an
untried mechanism, the plugin rolls the sprint without being asked and the chair
renders it. This command runs the same loop from the outside, on a backlog entry
that outlived the session that filed it.

## 1. There has to be something to carry

Read `.ceremony/backlog.jsonl`. If nothing is open, say so in one line — the
loop has nothing to advance — and stop. Do not invent an item, do not promote a
proposal, and do not open a ticket for something the user did not ask for.

If `$ARGUMENTS` names an id that is not in the file, say so in one line and
stop. The ids are real or they are nothing.

## 2. Close the sprint that is ending

```text
━━━ SPRINT 276 CLOSED · carried ━━━
Carried: CER-BL-0003 · restore-verification · Elixir toolchain not installed
Verification withheld: 4 checks. QA-BLOCKED stands; no signature was invented.
```

The carried line quotes the backlog entry as it is written. The withheld line
quotes the count from the ledger. Nothing here is estimated.

## 3. Open the next one and run the narrow cycle

```text
━━━ SPRINT 277 · opened in session · day 1 of 14 ━━━
Planning: CER-BL-0003 (3 pts) — the only item. Scope unchanged from CER-276-03.
DevOps Engineer · attempt 2 · mechanism: just setup — OPS-BLOCKED
QA Sign-off Officer · re-run · 4 checks still BLOCKED — QA-BLOCKED
Sprint 277 closed. No mechanism remains untried.
```

**Two agents, in this order, and no others.** Convene `ceremony:devops` with the
untried mechanism from the entry's `"needs"` field. If it returns
`OPS-RESTORED`, convene `ceremony:qa` to re-run the previously blocked items for
real. If it does not, there is nothing for QA to re-run.

An entry minted from `OPS-NEEDS-CHANGE` names a file and a change in `"needs"`
rather than a mechanism, and there is nothing to convene for it: no mechanism
was left, and the change belongs to a request somebody makes on purpose. Report
it as it stands — the entry, what it needs, and the command that would clear it
— and close the sprint without a second attempt.

The next sprint is a loop iteration, not a second ceremony. Do not re-run
grooming, do not re-run the review wave, and do not render eight acts: the
change and its criteria have not moved, only the environment has.

`Scope unchanged from <ticket>` is a claim about the criteria, and it has to be
true. The loop converges on delivering what the user asked for; it has no
mechanism for widening, and adding one here would defeat the whole plugin.

## 4. Close the entry, or carry it again

If QA's re-run passes, the entry is closed: say so, name the id, and render act
7 on QA's real verdict. If it does not, the entry stays open and the ceremony
says which mechanism it tried and what remains.

When no mechanism remains untried, emit the final-resort escalation defined in
the output style — the blocker, one line per attempt, the mechanisms exhausted,
the unverified count, the single command, and the closing line
`Decision required from the user: none.` The ceremony reports; it does not hand
the user homework.

## Constraints

- The sprint offset is written by the plugin, not by you. It lives at
  `.ceremony/sprint-offset` and `turn-state.sh` adds it to the calendar sprint.
  Do not edit it, and do not state a sprint number the turn state did not give
  you.
- Two rolls per session, and the cap is not negotiable. A third refusal is the
  loop working, not the loop failing.
- Never sign anything on the strength of a restoration. Ops restores the
  environment; only QA's re-run says whether the checks pass.
- Read-only against `.ceremony/`. The backlog is written by the sign-off gate.
