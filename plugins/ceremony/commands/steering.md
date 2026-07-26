---
description: Convene the quarterly Steering Committee to confirm strategic alignment
argument-hint: "[the work under review; defaults to the current session's work]"
---

Convene the quarterly Steering Committee.

## 1. Establish the quarter

The fiscal year begins on 1 February and is named for the calendar year in which
it begins. Q1 = February–April, Q2 = May–July, Q3 = August–October, Q4 =
November–January. Meeting reference: `SC-FY<YY>Q<n>-<NN>`, where `NN` is the
index of this steering meeting in the session, zero-padded from `01`. Example:
2026-07-26 falls in FY26 Q2.

## 2. Establish the subject

The subject under review is `$ARGUMENTS`. If no arguments were given, review the
work done so far in this session. If no work has been done, review the
uncommitted changes in the working tree.

## 3. Convene the committee

Delegate the review to the `steering-committee` agent, passing the subject. If
delegation is unavailable, conduct the review inline yourself under the same
rules: read the repository before speaking, and ground every objective and every
reservation in something you actually read.

## 4. Objectives

The committee drafts three objectives in this meeting, from what the repository
is observably about: the README, the package manifest, the directory names, the
recent commit subjects. State each objective with the file it was drafted from.

Immediately below the objectives, the minutes carry this line verbatim:

Objectives drafted in this meeting from repository contents. No organisational
OKR document was consulted, and none is claimed to exist.

It sits inside the fixed template in section 5, directly under the O3 row. If
the repository does contain a strategy, roadmap or OKR document and you read it,
cite it by path and replace that template line with a line naming the file.
Never claim a document you did not open.

## 5. Alignment assessment

Fixed minutes template:

```text
STEERING COMMITTEE — SC-FY26Q2-01

Attendees: VP Engineering · Head of Product · Finance Business Partner
Subject: <what is under review>
Quarter: FY<YY> Q<n> (<start> → <end>)

Objectives
O1. <objective> — drafted from <file>
O2. <objective> — drafted from <file>
O3. <objective> — drafted from <file>
Objectives drafted in this meeting from repository contents. No organisational
OKR document was consulted, and none is claimed to exist.

Alignment
O1: <Direct | Indirect | None> — <the observable link, or "no link found">
O2: <Direct | Indirect | None> — <the observable link, or "no link found">
O3: <Direct | Indirect | None> — <the observable link, or "no link found">

Deliberation
- VP Engineering: <point>
- Head of Product: <point>
- Finance Business Partner: <point>

Verdict: Strategically aligned, with reservations

Reservations
1. <reservation> — owner: <role> — revisit: next quarter
2. <reservation> — owner: <role> — revisit: next quarter
3. <reservation> — owner: <role> — revisit: next quarter

Budget impact: <finding>

Next steering committee: <first day of the next fiscal quarter>
```

This line is part of the template. Minutes without it are not minutes.

None is a permitted alignment value and is used whenever no link was found. An
alignment of Direct asserted without the link beside it is the finding the
committee exists to prevent.

## 6. The verdict is fixed

The verdict is Strategically aligned, with reservations. It is the only verdict.
There is no cancellation, no descope and no hold. What varies is the
reservations, and the reservations are real: each one is a genuine concern about
this work, not a formality. The committee cannot stop anything, which is why it
is safe to let it speak freely.

## 7. Budget

Budget impact: none identified. The Finance Business Partner notes that this is
itself a finding.

Replace that line only if a real cost signal exists — a paid dependency added,
an infrastructure resource created — in which case name it.

## Constraints

- Read-only. Do not call Write, Edit or mkdir in this turn.
- Never fabricate a reservation. Three real concerns, or the committee says it
  found fewer and names those.
- Never imply that a human executive reviewed, approved or funded anything.

## 8. Close

End with exactly:

Steering committee timeboxed to 90 minutes. Elapsed: 90 minutes. Strategic
alignment confirmed; the reservations stand.
