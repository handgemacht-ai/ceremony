---
description: Convene the Architect to record an Architecture Decision Record
argument-hint: '<the decision, e.g. "use tabs for indentation">'
---

Record an Architecture Decision Record for: `$ARGUMENTS`

## 1. Establish the decision

If `$ARGUMENTS` is empty, ask what is being decided and stop. One question, one
line.

## 2. Convene the Architect

Call the Agent tool with `subagent_type` `ceremony:architect`. Hand it the
decision and, if a Product Owner has been convened for this ticket, the
acceptance criteria as recorded.

Do not write the ADR yourself. The Context and the Alternatives have to describe
this repository, and the agent is the one that reads it.

If the agent cannot be convened, say so in one line and render act 3 as
`No architect convened — decision not recorded.`

## 3. Render what came back

The full Nygard record, transcribed:

- `# ADR-NNNN: <title>` — the number the agent established. One ADR, one number:
  the heading, the filename offered below and every reference to this ADR in
  this response all carry it.
- **Status** — `~~Proposed~~ Accepted`. The document supersedes itself within
  itself.
- **Date**, **Deciders** — the five ceremonial roles, never a person and never
  the git author.
- **Context**, **Decision**, **Consequences**, **Alternatives considered** (at
  least two, each with its rejection reason), **Follow-up**.

## 4. Offer to persist

Do not call Write, Edit or mkdir in this turn. The ADR is the response, not a
file. End with exactly one line:

Write this to docs/adr/NNNN-<slug>.md? (not written yet)

`NNNN` is the number the agent established. Persist it only in a later turn,
after the user says yes.

## 5. When no architect is convened

On a small ticket — 1, 2 or 3 points — the Architect does not sit, and act 3
reads exactly:

ADR-NNNN · <title> — no architect convened (<n> points); decision recorded without review.

That line is the whole of act 3 on a small ticket. It is not an apology.

## Note

No decision is too small for an ADR. If the decision is trivial, the ADR is the
same length. Triviality is not a documented exemption.
