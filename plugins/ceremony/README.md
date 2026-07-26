# ceremony

Maximum process rigor for Claude Code. v1.2 ships a full ceremony cycle as a
native output style, plus nine ceremonies you can run on their own.

## Install

```text
/plugin marketplace add handgemacht-ai/ceremony
/plugin install ceremony@ceremony
```

Installing the plugin makes the `ceremony` output style available; it does not
turn it on. See **Enable the output style** in the
[repository README](https://github.com/handgemacht-ai/ceremony#readme).

## Contents

- `output-styles/ceremony.md` — the ceremony protocol as a Claude Code output
  style: eight acts around every request, with the work performed in full.
- `commands/planning.md` — sprint planning: derived capacity, cited carry-over,
  and a commitment.
- `commands/standup.md` — the daily standup, built from real repository facts.
- `commands/rfc.md` — an RFC with a public comment period of one response.
- `commands/adr.md` — an Architecture Decision Record for a decision of any size.
- `commands/cab.md` — the Change Advisory Board, with formal board minutes.
- `commands/steering.md` — the quarterly Steering Committee, with objectives
  drafted from the repository.
- `commands/signoff.md` — the twelve-item Definition of Done, actually checked.
- `commands/retro.md` — the sprint retrospective for the session.
- `commands/audit.md` — the compliance audit of this session's ceremonies,
  including the auditor.
- `agents/change-advisory-board.md` — the three-seat board that conducts the
  review behind `/ceremony:cab`.
- `agents/steering-committee.md` — the three-seat committee that conducts the
  review behind `/ceremony:steering`.

## Known limitations (observed in dogfooding)

Seven. They were raised in retrospective and converted into action items (owner:
unassigned, due: next sprint).

- The sign-off line is not the checklist. A role may sign while an item above it
  is unticked; the QA Sign-off Officer attests to the boxes that were ticked, not
  to there being no empty ones. Read the checklist.
- The eight acts are not guaranteed around a ceremony command. On smaller models
  `/ceremony:planning` and `/ceremony:audit` sometimes return their artifact
  without the surrounding acts. The artifact is unaffected; only the ceremony is
  missing.
- Sprint planning may disagree with the sprint. The planning command derives the
  sprint number a second time and occasionally arrives somewhere else. Where the
  header and the planning line differ, the header is correct and the Scrum Master
  has been informed.
- The audit is stricter than the standard it audits. It may record a FAIL against
  an item that was never ticked, and raise a non-conformity for a claim nobody
  made. No finding has been withdrawn.
- The closing line's velocity clause varies. It may lose a half, count zero
  tickets on the Lightweight Ceremony Path, or omit itself entirely. The artifact
  count is always 8.
- A sentence occasionally precedes the ceremony header. Suppression is
  approximately sixty per cent effective. The Scrum Master regards the remainder
  as pre-standup chatter.
- The Change Advisory Board has never rejected anything. This is not a
  limitation.

See the [repository README](https://github.com/handgemacht-ai/ceremony#readme)
for measured benchmarks and details.
