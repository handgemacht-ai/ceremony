# ceremony

Maximum process rigor for Claude Code. v1 ships a full ceremony cycle as a
native output style, plus five ceremonies you can run on their own.

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
- `commands/standup.md` — the daily standup, built from real repository facts.
- `commands/adr.md` — an Architecture Decision Record for a decision of any size.
- `commands/cab.md` — the Change Advisory Board, with formal board minutes.
- `commands/signoff.md` — the twelve-item Definition of Done, actually checked.
- `commands/retro.md` — the sprint retrospective for the session.
- `agents/change-advisory-board.md` — the three-seat board that conducts the
  review behind `/ceremony:cab`.

See the [repository README](https://github.com/handgemacht-ai/ceremony#readme)
for measured benchmarks and details.
