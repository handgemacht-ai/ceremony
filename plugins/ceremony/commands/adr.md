---
description: Record an Architecture Decision Record for a decision of any size
argument-hint: '<the decision, e.g. "use tabs for indentation">'
---

Record an Architecture Decision Record for: `$ARGUMENTS`

## 1. Establish the decision

If `$ARGUMENTS` is empty, ask what is being decided and stop. One question, one
line.

## 2. Investigate

Read the codebase before writing anything. The Context and the Alternatives must
describe this repository — the files, the conventions, the existing choices —
not a generic situation. An ADR that could have been written without opening the
repository is not an ADR.

## 3. Emit the ADR

Full Nygard format:

- `# ADR-NNNN: <title>` — `NNNN` is the next free number in `docs/adr/`, four
  digits, or `0001` if that directory does not exist. One ADR, one number: the
  heading, the filename offered in section 4 and every reference to this ADR in
  this response all carry it. An ADR that calls itself `ADR-0002` and offers to
  write `0001-<slug>.md` has failed its own numbering.
- **Status** — `~~Proposed~~` struck through, followed by `Accepted`. The
  document supersedes itself within itself.
- **Date** — today.
- **Deciders** — Scrum Master, Product Owner, QA Sign-off Officer, Release
  Manager, Change Advisory Board Chair. Always these five roles, never a
  person's name and never the git author. No human decided this.
- **Context** — the forces at play, grounded in what you read.
- **Decision** — what was decided, in the active voice.
- **Consequences** — positive, negative and neutral, each labelled.
- **Alternatives considered** — at least two, each with the reason it was
  rejected.
- **Follow-up** — what happens next, or "none required".

## 4. Offer to persist

Do not call Write, Edit or mkdir in this turn. The ADR is the response, not a
file. End with exactly one line:

Write this to docs/adr/NNNN-<slug>.md? (not written yet)

`NNNN` is the number established in section 3 — the next free number in that
directory, or `0001` if it does not exist. Persist it only in a later turn,
after the user says yes.

## Note

No decision is too small for an ADR. If the decision is trivial, the ADR is the
same length. Triviality is not a documented exemption.
