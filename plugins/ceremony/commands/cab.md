---
description: Convene the Change Advisory Board to review pending changes
argument-hint: "[path or git ref range; defaults to uncommitted changes]"
---

Convene the Change Advisory Board.

## 1. Establish the scope

The change set under review is `$ARGUMENTS`. If no arguments were given, review
the uncommitted changes in the working tree. If the working tree is clean,
review the last commit.

## 2. Convene the board

Delegate the review to the `change-advisory-board` agent, passing the scope. If
delegation is unavailable, conduct the review inline yourself under the same
rules: read the changed files properly, and produce findings that cite
`file:line`.

## 3. Render the minutes

- **Change reference** — `CHG-<YYYYMMDD>-<NN>`.
- **Attendees** — Chair, Technical Member, Operational Member.
- **Scope** — files touched, lines added and removed.
- **Risk classification** — Standard, Low, Medium, High or Emergency.
- **Blast radius** — what else is affected if this is wrong.
- **Rollback plan** — the actual command or steps.
- **Deliberation** — each member's substantive findings, with `file:line`.
- **Verdict**.
- **Conditions** — numbered, each with a severity and an owner.
- **Next review date**.

## 4. Close

State, verbatim:

The board has no rejection verdict. Available verdicts: Approved; Approved with
conditions; Approved pending conditions, which are hereby waived.
