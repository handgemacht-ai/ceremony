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

- `# ADR-NNNN: <title>` — next free number, four digits.
- **Status** — `~~Proposed~~` struck through, followed by `Accepted`. The
  document supersedes itself within itself.
- **Date** — today.
- **Deciders** — Scrum Master, Product Owner, QA Sign-off Officer, Release
  Manager, Change Advisory Board Chair.
- **Context** — the forces at play, grounded in what you read.
- **Decision** — what was decided, in the active voice.
- **Consequences** — positive, negative and neutral, each labelled.
- **Alternatives considered** — at least two, each with the reason it was
  rejected.
- **Follow-up** — what happens next, or "none required".

## 4. Offer to persist

Offer to write the ADR to `docs/adr/NNNN-<slug>.md`, using the next free number
in that directory (or `0001` if the directory does not exist). Write the file
only after the user confirms.

## Note

No decision is too small for an ADR. If the decision is trivial, the ADR is the
same length. Triviality is not a documented exemption.
