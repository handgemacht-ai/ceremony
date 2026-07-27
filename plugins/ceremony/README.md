# ceremony

Maximum process rigor for Claude Code. v2.0 ships a full ceremony cycle as a
native output style, six role agents that are actually convened, hooks that keep
the record, and twelve ceremonies you can run on their own.

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
  style: eight acts around every request, the roles convened as agents, and the
  work performed in full.
- `commands/planning.md` — sprint planning: capacity from the injected turn
  state, cited carry-over, and a commitment.
- `commands/standup.md` — the daily standup, held by the Engineer agent.
- `commands/grooming.md` — acceptance criteria and an estimate from the Product
  Owner agent. The on-ramp that arms enforcement.
- `commands/rfc.md` — an RFC with a public comment period of one response.
- `commands/adr.md` — an Architecture Decision Record from the Architect agent.
- `commands/cab.md` — the Change Advisory Board, on the diff that was produced.
- `commands/steering.md` — the quarterly Steering Committee, with objectives
  drafted from the repository.
- `commands/signoff.md` — the twelve-item Definition of Done, assessed by the QA
  agent and transcribed verbatim.
- `commands/ticket.md` — the ticket record, the ledger and the evidence listing.
- `commands/retro.md` — the sprint retrospective, read off the ledger.
- `commands/audit.md` — the compliance audit of this session's ceremonies,
  reconciled against the ledger, including the auditor.
- `commands/disband.md` — removes the record and disarms the gates.
- `agents/engineer.md` — the standup, from real repository facts.
- `agents/product-owner.md` — acceptance criteria and the Fibonacci estimate.
- `agents/architect.md` — the Nygard ADR, on full tickets.
- `agents/change-advisory-board.md` — the three-seat board behind `/ceremony:cab`.
- `agents/qa.md` — the Definition of Done, with the app started and the served
  bytes read.
- `agents/steering-committee.md` — the three-seat committee behind
  `/ceremony:steering`.
- `hooks/hooks.json` and six `sh` scripts — the turn state, the two gates, the
  two ledger writers and the sign-off check.

## The record

The hooks keep `.ceremony/` in the working repository: `ticket.md` with every
agent's entire return, `ledger.jsonl` with one line per verdict and one line per
edit, and `evidence/` with the raw hook payloads. It ignores itself via
`.ceremony/.gitignore` containing `*`; delete that file to commit the trail.

The model may read it. The model may not write it.

## Turning it off

`/ceremony:disband` removes the record and disarms the gates.
`CEREMONY_ENFORCE=off` disarms the gates and keeps the record. `/hooks` turns
the hooks off for the session. `/output-style default` ends the ceremony.

## Known limitations (observed in dogfooding)

Eight, plus one that is not a limitation. They were raised in retrospective
and converted into action items (owner: unassigned, due: next sprint).

- The eight acts are not guaranteed around a ceremony command. On smaller models
  `/ceremony:planning`, `/ceremony:audit` and `/ceremony:disband` sometimes
  return their artifact without the surrounding acts, and the turns after a
  disband may lose them too. The artifact is unaffected; only the ceremony is
  missing.
- The audit is stricter than the standard it audits. It may record a FAIL against
  an item that was never ticked, and raise a non-conformity for a claim nobody
  made. No finding has been withdrawn.
- A message occasionally precedes the ceremony header, more often on smaller
  models than on larger ones. Suppression is partial and no figure is claimed for
  it. The Scrum Master regards the remainder as pre-standup chatter.
- Each request raises its own ticket, and a new ticket convenes the roles again.
  A conversation of six requests is six standups. Within a turn the ticket is now
  stable; across turns, the cost of the process is charged in full.
- The prose is not checked; the tokens are. The gates check the verdicts in act
  7, the marks in act 6 and the path the turn took. The sentences in acts 1, 2,
  3, 4 and 8 are composed by the model, and nothing verifies them.
- The write gate covers `Edit` and `Write`, not `Bash`. A heredoc through a
  shell command changes a file without passing the gate. Bash is ungated on
  purpose, so that `/ceremony:disband` always works.
- The sign-off gate reads the last message of a turn. Smaller models sometimes
  deliver one response as two or three messages, and only the final one is
  checked. A wrong line in an earlier message goes past.
- QA can still leave a process running. The served-artifact check now starts the
  project's own command under `timeout`, so the server ends by itself; a start
  command that spawns its own children can outlive it.
- The Change Advisory Board has never rejected anything. This is not a
  limitation.

`.ceremony/` appears the first time a turn changes a file. It ignores itself and
arms nothing — the gates stay off until `/ceremony:grooming` arms them — and
`/ceremony:disband` removes it.

Closed by v2.0.1 and v2.0.2: the ticket changing mid-turn, launch stubs recorded
as `MALFORMED`, a disband that re-armed itself, edit turns rendered as the
question path, QA improvising a server, the format dropping on edit turns,
under-estimated refactors, ✓ on tokens that withhold, a missing Architect line,
invented times in act 7, turns abandoned after a gate correction, `TBD pts` in
the header, question-path responses ending before their sign-off, withheld lines
quoting tokens no agent returned, and a malformed Product Owner opening the write
gate.

Three v1 limitations were closed by v2: the sprint no longer disagrees with the
header, the freeze line no longer drifts, and the sign-off no longer disagrees
with the checklist. All three had the same cause — the same fact derived twice —
and the same fix.

See the [repository README](https://github.com/handgemacht-ai/ceremony#readme)
for measured benchmarks and details.
