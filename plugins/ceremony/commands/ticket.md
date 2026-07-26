---
description: Print the ticket record and the ledger for the current ticket
argument-hint: "[ticket id; defaults to the current one]"
---

Show the ticket record for `$ARGUMENTS`, or for the ticket in this turn's state
if no argument was given.

## 1. Find it

The record lives at `.ceremony/<ticket>/`. If `$ARGUMENTS` names a ticket, use
that. If the directory does not exist, say so in one line — no roles have been
convened for it — and stop.

If `.ceremony/` itself does not exist, say so in one line: this repository has
no ticket record, and enforcement is disarmed. `/ceremony:grooming` starts one.

## 2. Print it

Three parts, in this order:

**The ticket** — `.ceremony/<ticket>/ticket.md`, in full. It holds every
convened agent's entire return, under a heading naming the act, the agent type,
the timestamp and the verdict.

**The ledger** — `.ceremony/<ticket>/ledger.jsonl`, one line per entry, as
recorded. Agent entries and implementation entries in the order they happened.

**The evidence** — the file names in `.ceremony/<ticket>/evidence/`, with their
sizes. Do not print their contents; they are the raw hook payloads, and they are
long. Name them so they can be read on request.

## 3. Read the ordering out loud

One line after the three parts: whether the last verification entry (`qa` or
`change-advisory-board`) post-dates the last `implementation` entry, and say
which. Verification that precedes the change verified the previous state of the
repository.

## Constraints

- Read-only, and read-only in a stronger sense than the other ceremonies: this
  command reads the record, and the record is written by the plugin's hooks from
  real agent returns. Do not write to `.ceremony/`. An attempt is refused.
- Do not summarise, correct, reformat or re-word what is on the record. Print it.
