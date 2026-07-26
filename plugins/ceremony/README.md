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

- On smaller models the waiver mark is sometimes used for items that simply do
  not apply. The reason line always says which it is.
- The QA signature attests to the boxes that were ticked, not to the checklist
  being complete. Read the checklist, not the signature line.
- On smaller models a ceremony command sometimes returns its own artifact
  without the surrounding eight acts. The artifact itself is unaffected.
- The closing line's velocity clause may vary in wording when a ticket is not
  delivered.

See the [repository README](https://github.com/handgemacht-ai/ceremony#readme)
for measured benchmarks and details.
