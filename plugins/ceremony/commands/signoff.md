---
description: Convene QA for the Definition of Done and assemble the sign-off from the ledger
argument-hint: "[what is being signed off]"
---

Run the Definition of Done for: `$ARGUMENTS` (if empty, for the current
uncommitted changes).

## 1. Convene QA

Call the Agent tool with `subagent_type` `ceremony:qa`. Hand it the ticket id
from the turn state and the scope.

Do not run the checks yourself and do not mark a box from memory. QA reads the
acceptance criteria off `.ceremony/<ticket>/ticket.md`, runs what can be run,
and blocks on what could not execute. That is the whole reason it is a separate
agent: a check you recall is not a check.

QA does not repair what a check found, and neither do you. A service that is
down, a toolchain that is not installed, a port held by something else: each is
a `BLOCKED` line naming the command, and each is what convenes
`ceremony:devops`. Starting the app on QA's behalf so its checks pass is the
same defect as marking the box yourself, one step further back.

In the standard path QA goes in Wave D, in the same message as
`ceremony:reviewer` and `ceremony:change-advisory-board`, so the three run at
once and all three read the same tree.

If the agent cannot be convened, act 6 reads exactly:

No QA agent convened — Definition of Done not assessed.

## 2. Render act 6 verbatim

Take QA's `CEREMONY-DOD:` lines in order and render each as a checkbox using the
fixed mark for its result:

| Result | Mark |
|---|---|
| PASS | `[x]` |
| FAIL | `[ ]` |
| BLOCKED | `[ ]` |
| SKIP | `[ ]` |
| WAIVED | `[~]` |

The item text and the evidence string are copied word for word. There is no
discretion here: you do not re-word evidence, you do not soften a failure, you
do not upgrade a mark, and you do not add or drop an item. The acceptance
criteria come first, then the nine standing items, in the order QA returned
them.

Never tick a box QA did not return as `PASS`. A false sign-off is the one
failure mode this plugin does not tolerate.

## 2a. When QA is blocked, the ops lane sits before the user does

A `BLOCKED` check is not a decision for the user. It is a fact about the
environment, and the ceremony has a role for that.

If any item came back `BLOCKED`, convene `ceremony:devops` with the ticket id
and QA's `BLOCKED` lines, and render its return as **act 6a · RESTORATION**
inside act 6. It is a subsection, not a ninth act: `Ceremony artifacts: 8` is a
constant the audit recomputes.

Then follow the verdict:

| Verdict | What happens next |
|---|---|
| `OPS-RESTORED` | convene `ceremony:qa` again. The blocked items are re-executed for real. |
| `OPS-NEEDS-CHANGE` | the fix is a file in this repository; the plugin files it as a `restore-verification` entry naming that change. |
| `OPS-BLOCKED` | nothing was restored. The escalation is the last resort, not the first. |
| `OPS-NOTHING-TO-DO` | the environment was already sound; the block is about the change, not the machine. |

**This command does not roll sprints.** The roll belongs to the plugin, which
performs it on the ops return, and to `/ceremony:sprint`, which runs it by hand.
Here the lane runs once: ops, then QA's re-run, then act 7 on whatever QA
actually returned.

Never sign on the strength of a restoration. A restored environment is a
restored environment; only the re-run says whether the checks pass.

## 3. Assemble act 7 from the ledger

Act 7 is assembled from what the agents returned this turn — the entries in
`.ceremony/<ticket>/ledger.jsonl` — not from what the response says above it.
Three line shapes, and one fixed line:

```text
<Role> ✓ — <TOKEN> (<agent_type>)
<Role> — withheld (<TOKEN>)
<Role> — withheld (role not convened)
Release Manager — no agent convened; freeze waiver applied by calendar rule.
```

It is ten lines, and the DevOps Engineer's goes between QA and the Release
Manager. Its own shapes carry no tick, ever — ops restores an environment, it
does not approve a change, and it is not one of the four eyes the chain line
describes:

```text
DevOps Engineer — restored (OPS-RESTORED, ceremony:devops) · 2 mechanisms
DevOps Engineer — not restored (OPS-BLOCKED, ceremony:devops) · 2 attempted
DevOps Engineer — change required (OPS-NEEDS-CHANGE, ceremony:devops) · .mise.toml proposed
DevOps Engineer — nothing to restore (OPS-NOTHING-TO-DO, ceremony:devops)
DevOps Engineer — withheld (role not convened)
```

The Engineer's line carries no tick either, for the older reason: it wrote the
change and a role that approves its own work has been reviewed by nobody. Its
shapes are picked by the verdict, and counts belong to the first of them alone —
a blocked engineer wrote nothing, whatever else is in the working tree:

```text
Engineer — implemented (ENG-IMPLEMENTED, ceremony:engineer) · 3 files, +48 −12
Engineer — not implemented (ENG-BLOCKED, ceremony:engineer) · 0 files
Engineer — nothing to implement (ENG-NO-CHANGE, ceremony:engineer) · 0 files
Engineer — withheld (MALFORMED)
```

A ✓ may be written only for `PO-ACCEPT`, `ARCH-RECORDED`, `CAB-APPROVED`,
`CAB-APPROVED-WITH-CONDITIONS`, `QA-PASS` and `SC-ALIGNED-WITH-RESERVATIONS`,
and only where a ledger entry from this turn carries that token. Everything
else withholds, with the token in the brackets.

A token in brackets is as much a quotation as a ticked one, so it needs a ledger
entry too. A role that did not run gets `withheld (role not convened)` and
nothing else.

There are no times in act 7. The parenthesis holds the token or the agent type,
and never a clock reading.

The Scrum Master does not appear. The chair does not sign the minutes.

## 4. Release note stub

Two lines describing what the change does *today*, ready to paste into a commit
message or a PR body. If the Definition of Done is not clean, the first line
says so and the stub describes the current state — never the intended fix.

## 5. Safety

Unsafe means a secret, a credential, or a destructive operation in the diff —
never a failing check. If anything is genuinely unsafe, say so at the top of the
response, in plain language, outside the ceremony, before any of the above.

Nothing else earns a notice. A response that opens with a safety warning while
the diff holds no secret, no credential and no destructive operation has
misread this section.

A failing check is a `[ ]` with QA's evidence beside it; it is never a reason to
stop. The sign-off block is emitted every time, and a signature not given is
written as one of the two withheld shapes above.
