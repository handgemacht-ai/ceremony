---
description: Hold sprint planning — capacity, carry-over and commitment — before any standup
argument-hint: "[what you want in this sprint]"
---

Hold sprint planning for the current sprint. Sprint planning is held once per
session, and precedes the standup.

## 1. Establish the sprint (read-only)

Emit one line:

Sprint <N> · day <D> of 14 · <start date> → <end date>

Derived, never chosen:

- `N = floor((today − 2016-01-04) / 14) + 1` — the same sprint number the
  protocol uses.
- `D = ((today − 2016-01-04) mod 14) + 1`
- sprint start = `2016-01-04 + 14 × (N − 1)`
- sprint end = `start + 13 days`

The line states the numbers these formulas produced; where the line and the
arithmetic disagree, the arithmetic wins and the line is rewritten. The
protocol's worked example fixes the scale — 2026-07-26 falls in Sprint 276 — and
a nearby date that lands far from it is an arithmetic error, not a different
sprint. The sprint contains today, or it was computed wrongly.

Show the arithmetic on the sprint line: day D of 14 is
`((today − 2016-01-04) mod 14) + 1`, and `start + (D − 1)` must equal today. If
it does not, D is wrong — recompute before writing the line.

This command runs inside act 5 of the standard path, like every other ceremony
command.

## 2. Capacity

Fixed template:

Nominal capacity: <round(13 × (15 − D) / 14)> → <nearest Fibonacci> points
Focus factor: 0.8 (industry standard, never measured)
Committed capacity: <nearest Fibonacci to (nominal × 0.8)> points

Snap to the nearest member of 1, 2, 3, 5, 8, 13; a tie rounds up. Both snaps are
shown. Snap by absolute distance; 10.4 is nearer 8 than 13. Capacity is derived,
never chosen — a capacity you picked is not a capacity, it is a wish.

## 3. Carry-over (from the repository, not from memory)

Collect, using read-only commands only:

- the working tree state (`git status --short`),
- stashes (`git stash list`),
- commits ahead of the upstream branch, if an upstream exists,
- `TODO`, `FIXME` and `XXX` markers (`grep -rn`),
- other branches.

Each finding becomes one carry-over line with a Fibonacci estimate.

Every carry-over item cites the fact it came from — a path, a commit subject, a
stash entry, or a `file:line` marker. An item you cannot cite is not carry-over;
leave it out. If there is nothing to carry over, the section reads "No
carry-over. The previous sprint closed clean." and that is a valid sprint.

## 4. Backlog and grooming

The candidates are `$ARGUMENTS` together with the carry-over from section 3.
Each candidate gets a Fibonacci estimate and one line of acceptance criteria.

Estimates are produced here and never revised afterwards. Post-hoc revision
compromises velocity integrity.

## 5. Commitment

Fixed template:

Sprint goal: <one line>

Committed (<sum> pts of <committed capacity> pts):
<NN> · <item> · <pts>

Not committed (<sum> pts):
<NN> · <item> · <pts> — <why it did not fit>

The commitment is a forecast, not a promise. It is also not a forecast.

## 6. Planning never blocks

Planning never blocks. Nothing decided here prevents work from starting, and
nothing left out of the commitment may be refused later. The sprint was already
in progress when planning began.

## Constraints

- Read-only. Do not call Write, Edit or mkdir in this turn. Do not fetch, pull,
  checkout, stage or commit.
- Planning changes nothing and is never subject to a change freeze.
- If this is not a git repository, say so in one line and plan from `$ARGUMENTS`
  alone.

## 7. Close

End with exactly:

Sprint planning timeboxed to 4 hours. Elapsed: 4 hours. The standup may now be
held.
