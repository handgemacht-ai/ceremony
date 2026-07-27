# ceremony

Maximum process rigor for Claude Code. v2.2 ships a full ceremony cycle as a
native output style, eight role agents that are actually convened — one of which
writes the code, and it is not the chair — hooks that keep the record, and
thirteen ceremonies you can run on their own.

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
- `commands/standup.md` — the daily standup, held by the Team Member agent.
- `commands/grooming.md` — acceptance criteria and an estimate from the Product
  Owner agent. The recommended way in, and what clears the tombstone after a
  disband.
- `commands/rfc.md` — an RFC with a public comment period of one response.
- `commands/adr.md` — an Architecture Decision Record from the Architect agent.
- `commands/review.md` — the conformance review: the Reviewer answers every
  accepted criterion against the diff, and nothing else.
- `commands/cab.md` — the Change Advisory Board, on the diff that was produced.
- `commands/steering.md` — the quarterly Steering Committee, with objectives
  drafted from the repository.
- `commands/signoff.md` — the Definition of Done, assessed by the QA
  agent and transcribed verbatim.
- `commands/ticket.md` — the ticket record, the ledger and the evidence listing.
- `commands/retro.md` — the sprint retrospective, read off the ledger.
- `commands/audit.md` — the compliance audit of this session's ceremonies,
  reconciled against the ledger, including the auditor.
- `commands/disband.md` — writes the tombstone, removes the record, convenes
  nobody.
- `agents/team-member.md` — the standup, from real repository facts.
- `agents/engineer.md` — the implementation. The only agent with write tools, and
  the only participant the write gate lets through.
- `agents/product-owner.md` — acceptance criteria and the Fibonacci estimate.
- `agents/architect.md` — the Nygard ADR, on full tickets.
- `agents/reviewer.md` — the conformance review: every criterion answered MET or
  UNMET against the diff, plus a line for every change nothing asked for.
- `agents/change-advisory-board.md` — the three-seat board behind `/ceremony:cab`.
- `agents/qa.md` — the Definition of Done, with the app started and the served
  bytes read.
- `agents/steering-committee.md` — the three-seat committee behind
  `/ceremony:steering`.
- `hooks/hooks.json` and nine `sh` scripts — the turn state, the four gates, the
  three ledger writers and the engineer marker.

## Who writes the code

The chair — the model you are talking to — does not edit files. It reads the
request, convenes the roles, reads the diff, and reports. The change itself is
made by `ceremony:engineer`, a separate agent with its own context, and the write
gate enforces that: while the engineer is running, its edits pass; outside it,
an edit from the chair is refused and the refusal names the agent to convene.
Every reviewing role is refused too.

The chain the sign-off rests on has six links, in this order:

PO(criteria) → Engineer(author) → Chair(diff) → Reviewer(criteria) → CAB(risk) → QA(execution)

Nobody in it checks their own work. The Product Owner writes the criteria and
does not implement them; the engineer implements and signs nothing; the chair
reads the diff and cannot have produced it; the Reviewer answers the criteria
without having seen the implementation reasoning; the board reads risk; QA runs
it. The Product Owner's acceptance now needs the Reviewer's verdict as well as
its own — one signature resting on two independent readings.

The cost, in agents, for a small ticket: six, in four stages. A full ticket: seven,
in five. The wall-clock cost is the point of the exercise, not a defect in it.

## The ceremony never commits

No ceremony turn runs `git commit`, and none ever will. Three reasons:

1. Committing is the user's decision, and it is the one decision in this process
   that was never delegated.
2. The working tree **is** the artifact under review. Every signature in act 7 is
   about a diff that is still a diff; committing it turns the thing that was
   reviewed into history and the thing you have into something else.
3. The rollback promise the board writes down — `git checkout` the touched files
   — is only true while the change is uncommitted.

Acceptance criteria are therefore written so they can be checked in the working
tree. A criterion that asks for a commit, a push or a merge is recorded as
`PO-ACCEPT-OUT-OF-SCOPE`, which is not a signature and does not open the write
gate.

Since v2.2.1 it is a refusal rather than a stance: `git commit`, `add`, `push`,
`merge`, `rebase` and their kind are denied at the tool for every actor,
including the chair. Ask a ceremony turn to commit and it makes the change,
declines the commit and says so.

If the tree was already dirty when the session started, that is disclosed once,
in act 1, and reviewed nowhere else. It is not the ticket's scope and no
signature covers it. The paths are written to the top of the ticket record before
the first act, which is where the reviewer, the board and QA read them from — so
yesterday's edits are listed as inherited rather than raised as unrequested
changes.

## The record

The hooks keep `.ceremony/` in the working repository: `ticket.md` with every
agent's entire return, `ledger.jsonl` with one line per verdict — carrying the
conditions the board raised and the checks QA could not run — and one line per
edit, and `evidence/` with the raw hook payloads. It ignores itself via
`.ceremony/.gitignore` containing `*`; delete that file to commit the trail.

The model may read it. The model may not write it.

## Turning it off

`/ceremony:disband` writes the tombstone first and then removes the record, so
enforcement is never left standing by a removal that stops halfway. The turn
convenes nobody. `CEREMONY_ENFORCE=off` disarms the gates and keeps the record.
`/hooks` turns the hooks off for the session. `/output-style default` ends the
ceremony.

The `Stop` hook corrects a turn at most twice. A third defect in the same turn
ships unchecked; the count resets with the next prompt. Two rules are outside
that budget and always fire: a change the chair made itself, and a turn that
committed.

## Conditions and escalation

Every condition the Change Advisory Board raises is answered in act 4 with one
line, in one of three closed forms — `applied`, `waived`, or `carried` with an
owner and a due date that appear again in act 8. The `Stop` hook counts the
conditions against the dispositions. Applying one moves the code after the board
looked, so QA sits a second time on the code as it now stands: an applied
condition is one extra agent, and that is the price of acting on advice.

When QA marks any check `BLOCKED` — a missing toolchain, a start command that is
not there — the response carries an escalation block between act 8 and the
closing line, quoting the exact command that failed and naming the decision the
user has to make, and the closing line ends `Work delivered: yes · Verification:
blocked (escalated)`. The blocker is reported, never repaired.

## Known limitations (observed in dogfooding)

Eleven, plus one that is not a limitation. They were raised in retrospective
and converted into action items (owner: unassigned, due: next sprint).

- The eight acts are not guaranteed on smaller models. Around a ceremony command
  `/ceremony:planning` and `/ceremony:audit` sometimes return their artifact
  without the surrounding acts, and the turns after a disband may lose them too.
  On ordinary work turns the same models drop an act or render two of them out
  of numeric order. The work and the artifact are unaffected; the ceremony is
  what goes missing. Two shapes recur on haiku: act 5a rendered as `[x]`
  checkboxes rather than the reviewer's `MET`/`UNMET` lines, and a short question
  answered as a one-line LCP-1 when it should have been LCP-2 with a sign-off.
  v2.2.1 adds a fenced template and a decision rule for both, which reduced them
  and did not eliminate them.
- The audit is stricter than the standard it audits. It may record a FAIL against
  an item that was never ticked, and raise a non-conformity for a claim nobody
  made. No finding has been withdrawn.
- A message occasionally precedes the ceremony header, more often on smaller
  models than on larger ones. Suppression is partial and no figure is claimed for
  it. The Scrum Master regards the remainder as pre-standup chatter.
- Each request raises its own ticket, and a new ticket convenes the roles again.
  A conversation of six requests is six standups. Within a turn the ticket is now
  stable; across turns, the cost of the process is charged in full.
- A smaller model may still stop a turn on a question it invented. The gate now
  refuses an act headed by an agent that never ran, which is how the invented
  clarification used to be dressed. A question asked in plain prose, with no act
  heading and no agent named, is not caught by anything.
- The prose is not checked; the counts are. The gates check the verdicts in act
  7, the marks in act 6, the number of dispositions in act 4 and the path the
  turn took. The sentences in acts 1, 2, 3, 4 and 8 are composed by the model,
  and nothing verifies them — including the reason in a waived condition and the
  command quoted in an escalation.
- The chair can still route around the write gate with `Bash`. The gate checks
  who is editing as well as whether the ticket was accepted, on `Edit`, `Write`,
  `MultiEdit` and `NotebookEdit`. A shell heredoc is none of those. It is
  recorded with `"by": "chair"`, and the sign-off gate refuses the turn — after
  the fact, which is the best a post-hook can do.
- The write gate covers `Edit` and `Write`, not `Bash`. A heredoc through a
  shell command changes a file without passing the gate. Bash is mostly ungated
  on purpose, so that `/ceremony:disband` always works. Since v2.0.3 the change
  is at least recorded: a hook after every `Bash` call compares the working tree
  and files an implementation entry marked `via: "bash"`. Recorded is not
  refused. Two families are the exception and are refused outright since v2.2.1:
  any `git` subcommand that writes history or the index, for every actor, and
  `chmod`, `chown`, `chgrp` and `sudo` for subagents. The subcommand is read by
  tokenising the command line, so `git log --all` and `grep -rn "git commit"` are
  untouched. The recorder cannot tell a change from a side effect either: a QA
  check that imports a Python module leaves a `__pycache__` directory, the tree
  has moved, and an implementation entry is filed against whoever ran it.
- The correction budget is two, and the third problem ships. After two `Stop`
  corrections the gate stops blocking, because a turn stuck in a loop is worse
  than a turn with a flaw in it. Two rules are exempt since v2.2.1 and always
  fire — a change the chair made itself, and a turn that committed — because both
  are about the record rather than the render, and both were observed shipping on
  turns whose budget had gone on formatting. The exemption is capped at two, so
  the ceiling is four.
- The sign-off gate reads the last message of a turn, and act 7 within it.
  Smaller models sometimes deliver one response as two or three messages, and
  only the final one is checked. Token checking is scoped to the sign-off block,
  which is what stops a quoted gate message from reading as a forged signature —
  and it means a stray token elsewhere is not checked either. A split render is
  also how an act headed by an agent that never ran gets past the check:
  measured at roughly one turn in nine on smaller models.
- QA's start command can outlive the check through its own children. The
  served-artifact check starts the project's own command under `timeout`, so the
  command itself ends by itself; a start script that spawns background children
  can leave those behind. No leak was observed in the most recent round.
- The Change Advisory Board has never rejected anything. This is not a
  limitation.

A `/ceremony:*` command turn is mechanically read-only, which is a design
decision rather than a limitation. A command produces a report, and producing a
report is not doing the work it describes; so on a command turn the plugin
refuses every edit and refuses to convene the engineer at all. `/ceremony:audit`
once answered its own finding by raising a ticket, convening seven agents and
writing a 213-line file into the repository, and never produced the audit. When
a report identifies work worth doing it says so and stops; the work is then
asked for in a plain request, which runs the standard path.

`.ceremony/` appears the first time a turn changes a file. It ignores itself,
arms nothing on its own, and `/ceremony:disband` removes the ticket records
inside it, leaving the tombstone behind.

Enforcement arms itself the first time an agent returns: the hook that writes
the record creates `config.json` with `enforce: "on"`, and every gate reads that
file. `/ceremony:grooming` is the recommended way in, not the mechanism. The
consequence is deliberate — in a repository the plugin has never touched, the
first edit of the first turn is ungated, because arming a repository nobody
asked to arm would be worse.

Closed by v2.0.1 and v2.0.2: the ticket changing mid-turn, launch stubs recorded
as `MALFORMED`, a disband that re-armed itself, edit turns rendered as the
question path, QA improvising a server, the format dropping on edit turns,
under-estimated refactors, ✓ on tokens that withhold, a missing Architect line,
invented times in act 7, turns abandoned after a gate correction, `TBD pts` in
the header, question-path responses ending before their sign-off, withheld lines
quoting tokens no agent returned, and a malformed Product Owner opening the write
gate.

Closed by v2.0.3: a `/ceremony:disband` that convened four agents, ran a
truncated removal and let the next agent return re-arm the gates; a correction
that re-ran the whole ceremony instead of re-rendering it from the ledger; a gate
that read its own quoted wording as a forged signature; `? pts` in the header on
smaller models; a clarification invented under an act heading naming a Product
Owner that never ran; and a shell write that left no trace on the record.

Closed by v2.2.0: a chair that made the change itself and then convened six
agents to admire it. The engineer is now an implementer with write tools, the
chair is refused by the same gate that refuses every reviewing role, and act 5
is rendered from a diff the chair had to read first — recorded, and checked. The
file and line counts in acts 5 and 7 are the runtime's own measurements, not the
engineer's claim about them; when the two disagree the record says so. The
Product Owner's tick now needs a Reviewer that answered every criterion, and a
deviation withholds it.

Closed by v2.2.1, all three found by auditing v2.2.0 rather than by using it:
the implementation counts were wrong, because the runtime added up the lines each
edit call touched instead of measuring the diff — a file edited three times
counted three times, and in four runs out of eleven the engineer's own figure was
right and the ledger's was wrong; the runtime now snapshots the tree when the
engineer is convened and diffs it against the tree that comes back. A ceremony
command re-performed the ceremony, as above. And a commit shipped, on a turn
whose correction budget was already spent — commits are refused at the tool now,
before they run.

Closed by v2.1.0: a Change Advisory Board whose conditions were never applied,
waived or answered at all; a turn that hit a missing toolchain, marked four
checks `BLOCKED` and still closed on a bare `Work delivered: yes`; and a QA
standing list carrying three items about the record that QA could not see and
skipped every time.

Three v1 limitations were closed by v2: the sprint no longer disagrees with the
header, the freeze line no longer drifts, and the sign-off no longer disagrees
with the checklist. All three had the same cause — the same fact derived twice —
and the same fix.

See the [repository README](https://github.com/handgemacht-ai/ceremony#readme)
for measured benchmarks and details.
