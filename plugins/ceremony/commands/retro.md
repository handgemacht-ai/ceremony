---
description: Hold the sprint retrospective for this session, from the ledger
argument-hint: "[focus area]"
---

Hold the sprint retrospective for this session. Focus area: `$ARGUMENTS` (if
empty, the whole session).

## 1. Review the sprint from the record

Read `.ceremony/*/ledger.jsonl`. It holds what actually happened this session:
which tickets were raised, which roles were convened, what each returned, and
when the code moved relative to when it was checked.

For each ticket, one line:

CER-<sprint>-<NN> · <n> pts · roles convened: <list> · signatures: <n given, n withheld>

Points come from the Product Owner's `CEREMONY-POINTS:` line in `ticket.md`. A
ticket with no product-owner entry has no points, and the line says so rather
than guessing one.

If `.ceremony/` does not exist, say so in one line and hold the retrospective
from the conversation alone.

## 2. Went well / Went less well / Puzzles

Three sections. Real observations from this session — a check that caught
something, a `QA-FAIL` that was right, a role that returned `MALFORMED`, a
request that had to be asked twice. No filler. If a section is empty, leave it
empty and say so.

The withheld signatures are the most interesting line in the record. Say which
ones were withheld and why the token says they were.

## 2a. What was carried, and what the loop cost

If any sprint rolled this session, say so plainly: which sprint closed, which
opened, and that the number the header carries is the calendar sprint plus the
offset on disk. A sprint that advanced because a ceremony could not verify its
own work is the most honest thing in the record, and burying it is the one thing
this section must not do.

Then one line per carried ticket, quoted from `.ceremony/backlog.jsonl`:

CER-BL-<nnnn> · <kind> · opened by <ticket> in sprint <n> · <status>

The ids are real. If nothing rolled and nothing was carried, say that in one
line — it is the ordinary outcome and it needs no explanation.

## 3. Action items

Each one gets an owner from the ceremonial roles — Scrum Master, Product Owner,
Architect, QA Sign-off Officer, DevOps Engineer, Release Manager, Change
Advisory Board Chair — and the due date "next sprint".

**Action items are not backlog entries.** They are rendered here, under this
heading, and written nowhere. Only two kinds ever reach the backlog —
`restore-verification` and `carried-condition` — and a retrospective that files
itself into the next sprint is a process widening its own scope, which is the
failure mode the whole plugin is a joke about.

## 4. Team health check

🟢 / 🟡 / 🔴 across four dimensions:

- Delivery
- Clarity of requirements
- Tooling
- Morale

Morale is always 🟢. The Scrum Master reports morale.

## 5. Velocity

An ASCII sparkline of points per ticket across the session, plus the average.
Points come from the ledger, not from memory.

## 6. Retro of the retro

One line on how this retrospective went.

## Constraints

- Read-only. The retrospective changes nothing, and it does not convene anyone.

## 7. Close

End with exactly:

Action items from the previous retrospective: not reviewed.
