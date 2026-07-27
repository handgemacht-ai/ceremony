---
description: Convene the Product Owner to groom a request into acceptance criteria and an estimate
argument-hint: "[the request to groom; defaults to the request under discussion]"
---

Groom: `$ARGUMENTS` (if empty, the request currently under discussion).

## 0. Re-arm if the ceremony was disbanded

Read `.ceremony/config.json` if it exists. If it says `"enforce":"off"`, this
repository was disbanded and every hook is standing down. Remove the tombstone
with Bash before convening anything:

```sh
rm -rf .ceremony
```

Say in one line that enforcement is being re-armed. If the file says
`"enforce":"on"`, or `.ceremony/` does not exist, do nothing here.

This is the only place the tombstone is removed. Re-arming is explicit, and it
is a thing the user asked for by running this command.

## 1. Convene the Product Owner

Call the Agent tool with `subagent_type` `ceremony:product-owner`. Hand it the
request **in the user's own words**. Your paraphrase is not the subject; the
criteria it writes become the standard the work is measured against later, and a
standard derived from a summary measures the summary.

Do not groom it yourself. A Product Owner you performed did not attend.

## 2. Render act 2

Transcribe what came back:

- Context and assumptions, as returned.
- The acceptance criteria, numbered, in the agent's words.
- `Estimate: <n> points` with the agent's reason.
- The path: small ticket (1, 2 or 3 points — no architect) or full ticket (5, 8
  or 13 points — the Architect is convened).

Do not adjust an estimate. Do not add, merge, reword or drop a criterion.

## 3. If it returns PO-CLARIFY

Put its open question in act 2 and stop there. Do not implement anything, do not
convene anything else, and do not answer the question on the user's behalf.
Resume once it is answered.

## 4. What this arms

The first agent return of a ticket creates `.ceremony/` in this repository, and
from that point the plugin's hooks refuse an edit on a ticket that has no
Product Owner entry. That is the intended effect: grooming is the on-ramp, and
the only on-ramp.

To remove the record and the enforcement: `/ceremony:disband`.

## Constraints

- Read-only in this turn. Grooming decides what will be built; it does not build
  it.
- Convene the Product Owner once per ticket. Its return is on the record at
  `.ceremony/<ticket>/ticket.md`.
