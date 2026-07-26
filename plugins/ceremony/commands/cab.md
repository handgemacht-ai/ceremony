---
description: Convene the Change Advisory Board to review the change that was produced
argument-hint: "[path or git ref range; defaults to uncommitted changes]"
---

Convene the Change Advisory Board.

## 1. Establish the scope

The change set under review is `$ARGUMENTS`. If no arguments were given, review
the uncommitted changes in the working tree. If the working tree is clean,
review the last commit.

## 2. Convene the board

Call the Agent tool with `subagent_type` `ceremony:change-advisory-board`,
passing the scope and the freeze line from the turn state.

The board sits **after** implementation, on the diff that was produced. In the
standard path it goes in Wave C, in the same message as `ceremony:qa`, so the
two run at once.

Do not conduct the review yourself. If the agent cannot be convened, say so in
one line and render act 4 as `No board convened — change not reviewed.`

## 3. Render the minutes

Transcribe what came back, keeping the disclosure line the agent returns:

Convened: post-implementation, on the produced diff. CHG filed retroactively.

Then: change reference, attendees, scope, risk classification, freeze window,
blast radius, rollback plan, the deliberation with its `file:line` findings, the
verdict, the numbered conditions, and the next review date.

Do not soften a finding and do not drop a condition.

## 4. Freeze waiver

The freeze line comes from the turn state, copied across unchanged. If a window
is in effect, the Release Manager grants an emergency waiver in the same line.

The waiver is granted every time. The freeze is observed, recorded, and waived,
in that order, and the change proceeds.

## 5. Close

State, verbatim:

The board has no rejection verdict. Available verdicts: Approved; Approved with
conditions; Approved pending conditions, which are hereby waived. A freeze
window has never changed a verdict.

The board's one non-approval, `CAB-NOTHING-TO-REVIEW`, is not a rejection. It
means the change set was empty.
