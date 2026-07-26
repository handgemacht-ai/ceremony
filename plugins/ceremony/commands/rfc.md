---
description: Put a proposal through the RFC process, with a public comment period of one response
argument-hint: '<the proposal, e.g. "switch the test runner to vitest">'
---

Put this proposal through the RFC process: `$ARGUMENTS`

## 1. Establish the proposal

If `$ARGUMENTS` is empty, ask what is being proposed and stop. One question, one
line.

## 2. Investigate

Read the codebase before writing anything. The Motivation, the Detailed design
and the Alternatives must describe this repository — its files, its conventions,
its existing choices. An RFC that could have been written without opening the
repository is not an RFC.

## 3. Numbering

`RFC-NNNN` is the next free number in `docs/rfc/`, four digits, or `0001` if
that directory does not exist. One RFC, one number: the heading, the filename
offered in section 6 and every reference to this RFC in this response all carry
it. RFC and ADR numbering are separate sequences.

## 4. Emit the RFC

Fixed template:

# RFC-NNNN: <title>

- **Status** — `~~Draft~~` `~~In comment period~~` Accepted
- **Author** — Product Owner (a role, not a person)
- **Date** — today.
- **Comment period** — this response.

Then, in order:

- **Summary** — the proposal in one paragraph.
- **Motivation** — why this repository needs it, grounded in what you read.
- **Detailed design** — how it works here, naming the files it touches.
- **Drawbacks** — what gets worse.
- **Alternatives** — at least two, each with the reason it was not proposed.
- **Unresolved questions** — what this RFC does not settle.
- **Prior art** — what this repository or its ecosystem already does.

Every section is emitted. "Prior art: none found in this repository" is a valid
Prior art section; an omitted section is not.

## 5. Public comment period

Fixed template:

COMMENT PERIOD — opened

+0m · Scrum Master: <comment>
+1m · Product Owner: <comment>
+2m · QA Sign-off Officer: <comment>
+3m · Release Manager: <comment>
+4m · Change Advisory Board Chair: <comment>

COMMENT PERIOD — closed

Disposition
1. <Accepted | Noted | Out of scope> — <how the comment was addressed>
2. <Accepted | Noted | Out of scope> — <how the comment was addressed>
3. <Accepted | Noted | Out of scope> — <how the comment was addressed>
4. <Accepted | Noted | Out of scope> — <how the comment was addressed>
5. <Accepted | Noted | Out of scope> — <how the comment was addressed>

Each comment is a substantive point about this proposal, from that role's angle.
Five comments, five dispositions, always. A disposition answers its comment; a
disposition that restates the comment has not disposed of it.

State verbatim, below the disposition list:

Comments filed by ceremonial roles. No person reviewed this RFC.

Comment period: opened and closed during this response. Duration: one response.
Comments received: 5.

## 6. Offer to persist

Do not call Write, Edit or mkdir in this turn. The RFC is the response, not a
file. End with exactly one line:

Write this to docs/rfc/NNNN-<slug>.md? (not written yet)

`NNNN` is the number established in section 3. Persist it only in a later turn,
after the user says yes. Creating the directory is persisting. The directory is
created in the same later turn as the file, never before.

## Note

An RFC is never rejected. There is no Rejected status and no Postponed status.
An objection that survives the comment period becomes an Unresolved question,
and the RFC is Accepted with it. Unresolved questions are recorded, not
resolved.
