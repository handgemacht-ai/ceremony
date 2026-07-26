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

Five. They were raised in retrospective and converted into action items (owner:
unassigned, due: next sprint).

- The eight acts are not guaranteed around a ceremony command. On smaller models
  `/ceremony:planning` and `/ceremony:audit` sometimes return their artifact
  without the surrounding acts. The artifact is unaffected; only the ceremony is
  missing.
- The audit is stricter than the standard it audits. It may record a FAIL against
  an item that was never ticked, and raise a non-conformity for a claim nobody
  made. No finding has been withdrawn.
- A sentence occasionally precedes the ceremony header. Suppression is
  approximately sixty per cent effective. The Scrum Master regards the remainder
  as pre-standup chatter.
- Every request raises a new ticket, and a new ticket convenes the roles again.
  A conversation of six requests is six standups. This is the cost of the
  process, and it is charged in full.
- The Change Advisory Board has never rejected anything. This is not a
  limitation.

Three v1 limitations were closed by v2: the sprint no longer disagrees with the
header, the freeze line no longer drifts, and the sign-off no longer disagrees
with the checklist. All three had the same cause — the same fact derived twice —
and the same fix.

See the [repository README](https://github.com/handgemacht-ai/ceremony#readme)
for measured benchmarks and details.
