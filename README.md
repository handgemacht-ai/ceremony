# ceremony

**The most process-rigorous Claude Code plugin ever built. v2.2 convenes the
roles as real agents, has one of them write the code, has a different one read
the result, keeps an append-only record of all of it, and still blocks
nothing.**

`ceremony` ships a native output style that wraps every request in a complete
delivery cycle — standup, grooming, ADR, implementation, conformance review,
change advisory board, definition of done, sign-off, retrospective — plus
thirteen standalone ceremonies you can run on demand. Process overhead stops
being an accident of team size and becomes flat, predictable, and reproducible
on every request, at every task size.

In v1 the roles were viewpoints the model spoke in. In v2 they are subagents
that are actually convened, and a signature in act 7 is a quotation from
something that ran. In v2.2 one of them holds the keyboard: the model you are
talking to chairs the meeting and is refused by its own write gate.

## Install

```text
/plugin marketplace add handgemacht-ai/ceremony
/plugin install ceremony@ceremony
```

## Enable the output style

Installing the plugin makes the `ceremony` output style available, but does not
turn it on. Select it in any of these ways:

- Run `/output-style ceremony:ceremony` in a session, or
- Open `/config` → **Output style** → **ceremony:ceremony**, or
- Set `"outputStyle": "ceremony:ceremony"` in `.claude/settings.json` (per
  project) or `~/.claude/settings.json` (global).

Once selected, the style stays active until you switch to another one. The
commands work with or without it.

## How it works

`ceremony` ships its protocol as a Claude Code **output style** — the platform's
sanctioned mechanism for user-selected response behavior, the same system behind
the built-in Explanatory and Learning styles. Once you select the style, it
becomes part of the system prompt, so the model treats the protocol as what it
is: deliberate, user-chosen configuration.

The roles are **plugin agents**, convened in waves:

```text
WAVE A   ceremony:team-member  +  ceremony:product-owner      (one message, parallel)
WAVE B   ceremony:architect                                   (full tickets only)
WAVE C   ceremony:engineer            ← the only participant that writes
         THE CHAIR READS THE DIFF     ← git diff + git status, recorded
WAVE D   ceremony:reviewer  +  ceremony:change-advisory-board  +  ceremony:qa
ACT 7    the sign-off, assembled last from the ledger
```

Under the protocol, the requested work is performed in full — tools, edits,
answers, all of it. The ceremony surrounds the work; it never replaces it.

## The roles

| Role | Agent | Owns | Can it sign? |
|---|---|---|---|
| Team Member | `ceremony:team-member` | act 1, Standup | no — it reports |
| Product Owner | `ceremony:product-owner` | act 2, Grooming | yes — with the Reviewer |
| Architect | `ceremony:architect` | act 3, ADR (full tickets) | yes |
| Engineer | `ceremony:engineer` | act 5, the change itself | no — the author never signs |
| Reviewer | `ceremony:reviewer` | act 5a, conformance to the criteria | yes |
| Change Advisory Board | `ceremony:change-advisory-board` | act 4, on the produced diff | yes |
| QA Sign-off Officer | `ceremony:qa` | act 6, Definition of Done | yes |
| Steering Committee | `ceremony:steering-committee` | `/ceremony:steering` | yes |
| Release Manager | — | the freeze waiver | never — no agent is convened |
| Scrum Master | — | chairs acts 1 and 8 | never — the chair does not sign |

Exactly one agent has write tools, and it is the Engineer. Every other agent is
read-only: `Read`, `Grep`, `Glob`, `Bash`, and no `Edit` or `Write`. Every agent
ends its reply with a closed-form verdict token, and only seven tokens can
produce a ✓ — none of them the Engineer's.

### The chair does not edit

The model you are talking to chairs the ceremony. It reads the request, convenes
the roles, reads the diff and reports. It does not make the change: the write
gate refuses it by name and tells it which agent to convene. A reviewing role
that tries to edit is refused too, with a shorter message.

That is enforced rather than requested. While the Engineer subagent is running,
the chair cannot issue a tool call at all, so "the marker is set" and "the editor
is the Engineer" are the same fact, and the gate can rely on it.

### The chain of four eyes

```text
PO(criteria) → Engineer(author) → Chair(diff) → Reviewer(criteria) → CAB(risk) → QA(execution)
```

Six links, no self-checking anywhere in it. The Product Owner writes the
criteria and does not implement them. The Engineer implements and signs nothing.
The chair reads the diff and could not have produced it. The Reviewer answers
every criterion — `MET`, `UNMET`, or `EXTRA` for a change nothing asked for —
without having seen the Engineer's reasoning. The board reads risk. QA runs it.

The Product Owner's ✓ is the one that rests on two readings rather than one: it
needs `PO-ACCEPT` **and** the Reviewer's `REV-MATCHES-CRITERIA`. A deviation
withholds the acceptance, and the sign-off says which criterion and why.

The file and line counts in acts 5 and 7 are the runtime's own measurements of
what the Engineer did, taken from the tool result and written to the ledger. The
Engineer also states them itself; when the two disagree the record carries
`diff_mismatch` and the sign-off gate sends the turn back. A number in the report
is never the author's word for it.

Cost is budgeted before the turn starts, and the budget is this:

| Path | Agents convened | Stages |
|---|---:|---:|
| a greeting (LCP-1) | 0 | — |
| a question (LCP-2) | 0 | — |
| `/ceremony:disband` | 0 — the convening gate refuses every one | — |
| small ticket, 1–3 points | 6 | 4 |
| full ticket, 5–13 points | 7 | 5 |
| plus `/ceremony:steering` | 8 | 5 |
| the Engineer returns blocked | 6–7 | 3–4 |
| plus an *applied* board condition | +2 — the Engineer changes it, QA sits again | +2 |
| a standalone `/ceremony:signoff`, `:review`, `:cab` or `:standup` | 1 | 1 |
| a turn the `Stop` hook sends back | +0 — it re-renders from the ledger | +0 |

One thing in that table is not overhead. An applied condition sends the change
back to the Engineer and then convenes QA a second time, because the code moved
after the board looked and a verdict on code that no longer exists is worth
nothing. Waiving or carrying a condition costs nothing extra.

The stage count is what you wait for; the agent count is what you pay for. Wave
A runs two agents at once and Wave D runs three, so a full ticket is seven agents
in five stages. This is slower than doing the work directly. That is the
product.

A turn the `Stop` hook sends back can exceed its budget. The correction is
written as a re-render from the ledger — the returns are already recorded, so
nothing needs convening twice — and the convening gate refuses a repeat of a
role that has already sat. Smaller models still sometimes re-run part of the
ceremony after a correction, which is the one case where a turn costs more
agents than the table says.

## Enforcement

v2 ships hooks. They are the part of the process that is not a suggestion.

| Hook | What it does |
|---|---|
| `UserPromptSubmit` | Derives the sprint, day, ticket, change reference and freeze window once, and injects them. Nothing downstream recomputes a date. |
| `PreToolUse` on writes | Four refusals. An edit to `.ceremony/`, by anyone including the Engineer. An edit on a `/ceremony:*` command turn, by anyone including the Engineer, because a command reports and does not perform. An edit to code on a ticket whose Product Owner has not returned `PO-ACCEPT` — attendance is not acceptance, and a question, an unreadable return or criteria that ask for a commit all leave the gate shut. And an edit by the wrong hand: a reviewing role is told to review, and the chair is told which agent to convene. |
| `PreToolUse` on `Agent` | Rewrites every `ceremony:*` call to `run_in_background: false`, so the verdict comes back as a tool result, reaches the record, and — load-bearing for the write gate — holds the chair still while the Engineer works. Refuses to convene the same role twice for one ticket until the code has moved, to convene the Engineer before the Product Owner has accepted, to convene the Engineer at all on a command turn, or to convene Wave D before there is a change to review. |
| `PreToolUse` on `Bash` | Two refusals, both narrow, because Bash is otherwise ungated on purpose. A `git` subcommand that writes history or the index — `commit`, `add`, `stage`, `push`, `merge`, `rebase`, `am`, `cherry-pick`, `revert` — is refused for every actor, chair included. `chmod`, `chown`, `chgrp` and `sudo` are refused for subagents, so that a file an Engineer cannot write stays a finding rather than becoming a permission it changed. The subcommand is read by tokenising the command line, so reads and greps that merely contain the word are untouched. |
| `PostToolUse` on `Agent` | Appends the agent's entire return and its verdict to the ticket record, with counts taken from the agent's own words — the board's conditions, the checks QA could not run, the criteria the Reviewer answered — and, for the Engineer, the runtime's own file and line counts, measured by snapshotting the working tree when the Engineer is convened and diffing it against the tree that comes back. The model never writes this path. |
| `PostToolUse` on writes | Records that the code moved, when, and by whose hand — the Engineer, another agent, or the chair. |
| `SubagentStart` / `SubagentStop` | Marks the window in which the Engineer is running, and clears it when the Engineer returns. The write gate reads that marker; a marker older than thirty minutes is ignored and deleted. |
| `PostToolUse` on `Bash` | Records the chair reading the diff — `git diff`, `git status`, `git show`, `git log -p` — which is the link in the chain the sign-off checks. Compares the working tree against the state at the start of the turn. If a shell command changed it, that is an implementation entry too, marked `via: "bash"`. Post-hooks cannot refuse anything; this one only records, which is enough to bring shell writes under the rule that verification must follow the change. Outside a git repository it does nothing. |
| `Stop` | Twenty-three rules. Refuses to end a turn on a verdict token act 7 quotes that no agent returned — ticked or withheld — a tick on a token that withholds, a clock time in act 7, an act headed by an agent that never ran, a placeholder where the estimate goes, a file-changing turn rendered as a question or as bare prose, a sign-off assembled from an empty ledger, ticked boxes with no QA entry, a verification that ran before the change, a board condition act 4 left unanswered, a blocked verification the turn did not escalate, an escalation with nothing to escalate, or a turn that lists the ways out of the plugin and asks the user to choose instead of doing the work. Then, reported together rather than one at a time: a change the chair made itself, an act 5 describing a diff nobody read, counts that disagree with the ledger, a signature on a blocked implementation, a review that answered fewer criteria than were accepted, a deviation with no Deviations block, an act 7 missing one of its nine lines, an unfilled placeholder left in the render, and an acceptance ticked without one. Two of them ignore the correction budget and fire however many corrections the turn has already had: the chair-authored change, and a turn that committed anyway. |

Token checking is scoped to act 7 and disposition counting to act 4. A response
may quote a gate's own wording, a command file or a ticket note anywhere else
without tripping anything; a signature is only a signature where signatures go.

### Conditions get a disposition

The Change Advisory Board cannot reject a change. What it can do is attach
numbered conditions, and until v2.1 that is where they stopped: a board would
ask for a semantic CSS variable and a contrast check, and nothing at all would
happen. Conditions were decoration.

The board now returns each condition as a machine line with a closed severity —
`MUST`, `SHOULD` or `NICE` — and act 4 answers every one of them with exactly
one line, in one of three closed forms:

```text
Disposition: <n> applied  — <what was done>
Disposition: <n> waived   — <reason>
Disposition: <n> carried  — action item recorded (owner: <who> · due: <when>)
```

A `NICE` condition may be waived in a few words. A `MUST` or a `SHOULD` needs a
reason with something in it. A `carried` condition appears again in act 8 as the
action item it promises to be. The `Stop` hook counts the board's conditions
against act 4's dispositions and sends the turn back when one is missing, so a
condition raised is a condition answered.

**Applying a condition costs a QA re-run.** The board reviews the diff that
existed when it looked; change the code afterwards and QA's verdict describes a
repository that no longer exists. The verification-must-postdate-the-change rule
sees this and says so, the convening gate permits the second QA precisely
because the code moved, and act 6 is rendered from the second return. That is
correct behaviour rather than a defect, and it is the honest price of acting on
advice instead of nodding at it: a five-agent turn becomes a six-agent turn.
`waived` and `carried` cost nothing.

### Blocked verification is escalated

QA marks a check `BLOCKED` when it could not run at all — a missing toolchain, a
start command that is not there, a service that is down. A blocked check is not
a passed check, and a turn that quietly absorbed one used to close on `Work
delivered: yes` with an acceptance criterion nobody had verified.

When anything is `BLOCKED`, the response now carries a fixed block between act 8
and the closing line:

```text
━━━ ESCALATION — verification blocked ━━━
- <the item> — attempted: `<the exact command QA ran>` — failed: <how it failed>
Decision required from the user: <the closed ask>
```

and the closing line gains a clause it cannot omit:

```text
… · Work delivered: yes · Verification: blocked (escalated)
```

The `Stop` hook requires both when the ledger says something was blocked, and
refuses the escalation block when nothing was. The command quoted is QA's own,
from its evidence, not a paraphrase.

This is a report, not a stop. The work is delivered first and in full; the
blocker is named and left alone. Nothing here installs a missing toolchain,
repairs a broken script or starts a service — reporting infrastructure rather
than debugging it is the whole point of the block.

The `Stop` hook corrects at most **twice** per turn. Two, because a turn that
opens on the wrong path usually needs one correction to reach the right one and
a second to get its sign-off right — and because a cap is what makes the hook
terminate at all. A third defect in the same turn ships unchecked; the counter
resets when the next prompt arrives. Every refusal names the way out, and every
refusal says the same two things: this is a re-render from the ledger, so
convene nobody again, and finish the turn rather than stop on it.

### The `.ceremony/` contract

```text
.ceremony/
  .gitignore                     "*" — the record ignores itself. Delete it to commit the trail.
  config.json                    {"version":"2.2.2","enforce":"on"} - or "off", the disband tombstone
  CER-<sprint>-<NN>/
    ticket.md                    append-only: the inherited paths, then every agent's entire return under an act heading
    implementation.diff          append-only: the hunks this ticket's engineer produced, and only those
    ledger.jsonl                 append-only: one line per verdict (with its condition and blocked counts), one line per edit
    evidence/NNN-<role>.json     the raw hook payload the ledger line was derived from
```

Written by the hooks, from what the agents returned. Read by QA, by
`/ceremony:audit`, by `/ceremony:retro` and by `/ceremony:ticket`. Never written
by the model — an attempt is refused, because a record its subject can edit is
not a record.

`implementation.diff` is the one that answers "who wrote this line". The plugin
snapshots the working tree when the engineer is convened and again when it
returns, and the diff between those two snapshots is the engineer's own work,
separated from everything that was already there — including inside a file that
holds both. The reviewer, the board and QA read it instead of `git diff`, which
cannot tell the two apart.

The record is untracked by default. If you want the trail in git, delete
`.ceremony/.gitignore`.

### Four ways out

Enforcement you cannot switch off is not a process, it is a trap. So:

1. `/ceremony:disband` — writes the tombstone first, `config.json` with
   `enforce: "off"`, and only then removes the ticket records, so the record
   never exists without it. Every hook reads that file and stands down, and no
   hook overwrites one that is already there. The turn convenes nobody: the
   convening gate refuses every agent on a disband turn, and the ledger writer
   refuses to arm anything, so a removal command that is mistyped or cut short
   still cannot leave enforcement standing on that turn. Uses Bash, which this
   plugin never gates. `/ceremony:grooming` removes the tombstone, and that is
   what lets the next agent return arm the gates again.
2. `CEREMONY_ENFORCE=off` in the environment — keeps the record, disarms the
   gates.
3. `/hooks` — turns the hooks off for the session.
4. `/output-style default`, or `/plugin uninstall ceremony@ceremony` — ends the
   ceremony entirely.

Every deny message and every block message names the relevant ones.

## The ceremony never commits

No ceremony turn runs `git commit`, and none ever will. Three reasons, in order
of how much they matter:

1. **It is the user's decision.** Everything else in this process was delegated
   to an agent. That one was not.
2. **The working tree is the artifact under review.** Every signature in act 7 is
   about a diff that is still a diff. Commit it and the thing that was reviewed
   becomes history, while the thing you are holding becomes something else.
3. **The rollback promise is only true while it is uncommitted.** The board
   writes down `git checkout` on the touched files. That is a real promise for
   exactly as long as nobody commits.

So acceptance criteria are written to be checkable in the working tree. A
criterion that asks for a commit, a push, a merge or a pull request is recorded
as `PO-ACCEPT-OUT-OF-SCOPE` — not a signature, and it does not open the write
gate. Every standard turn closes with the clause `· Committed: no (the tree is
yours)`.

Since v2.2.1 this is a refusal rather than a stance. `git commit`, `git add`,
`git push`, `git merge` and their kind are denied at the tool, before they run,
for every actor in the turn — because a documented stance that is only checked at
the end of the turn is a stance that can run out of budget, and once did. Ask a
ceremony turn to commit and it will make the change, decline the commit, and say
so. If you want it committed, commit it, or take the ceremony off first:
`/ceremony:disband` removes the record and `CEREMONY_ENFORCE=off` disarms the
gates.

If the tree was already dirty when the session started, act 1 says so once, in a
fixed line, and nothing else in the ceremony touches it: it is not this ticket's
scope and no signature covers it. The paths concerned are written to the top of
the ticket record before the first act, which is where the Reviewer, the board
and QA read them from.

Naming the paths is not enough on its own, because one file can be both — dirty
from yesterday *and* edited by this ticket's engineer — and then a single
`git diff` has two authors in it. So the split is made at the hunk: the plugin
snapshots the tree when the engineer is convened, snapshots it again when the
engineer returns, and writes the difference to
`.ceremony/<ticket>/implementation.diff`. That file is this ticket's work and
the whole of it. Everything else in the diff is somebody else's, and the
reviewing roles read it there rather than inferring it.

## Benchmarks

Measured on the request "fix the typo in the README".

| Metric | Typical agentic session | **ceremony v2.2** | Change |
|---|---:|---:|---:|
| Ceremony artifacts / request | 0 | **9** | act 5a joins the standard path |
| Meetings per line of code | 0.00 | **6.00** | industry-leading |
| Meetings that actually convened | 0.00 | **6.00** | 100% attendance |
| Ceremony overhead ratio | 0:1 | **44:1** | up again; the change now goes through a meeting too |
| Time to first line of code | ~4s | **~210s** | 50× more deliberate |
| Lines of code written by the chair | all of them | **0** | fully delegated |
| Eyes on the change before sign-off | 1 | **4** | author, chair, reviewer, board |
| Decisions documented | 0 | **all of them** | 100% traceability |
| Sign-offs collected | 0 | **up to 5** | quorum contingent |
| Signatures fabricated | n/a | **0** | enforced at the `Stop` hook |
| Unapproved changes | some | **0** | fully governed |
| Retrospective coverage | 0% | **100%** | continuous improvement |
| Action items carried to next sprint | 0 | **all of them** | perpetual |
| Work actually completed | yes | **yes** | unchanged |
| Governance bodies convened | 0 | **3** | board, committee, audit |
| Ceremonies per ceremony | 0.00 | **1.00** | the audit audits the audit |
| Freeze-window compliance | n/a | **100%** | every window observed |
| Emergency waivers granted | 0 | **100%** | of changes during a freeze |
| Auditor independence | n/a | **not achieved** | disclosed |
| Changes blocked by governance | 0 | **0** | unchanged |
| Changes committed by the ceremony | some | **0** | the tree is yours |

Headline result: **eight role agents, one of which writes the code and none of
which is the chair, an append-only audit trail, nine enforcement hooks, and still
zero changes blocked.**

## Why it's rigorous

- **The roles attend.** A ✓ in act 7 quotes a verdict token from a subagent that
  ran, and the `Stop` hook refuses a turn that claims one it cannot find.
- **The author is not the reporter.** The change is made by `ceremony:engineer`
  in its own context; the chair is refused by the write gate and has to convene
  it. Act 5 is then written from a diff the chair had to open — recorded as a
  ledger entry, and checked. An act 5 with no reading after it is sent back.
- **The numbers are measured, not claimed.** The file and line counts in acts 5
  and 7 come from the runtime's own accounting of what the Engineer did. The
  Engineer's own figure is kept beside them as a cross-check, and a disagreement
  is recorded and blocked on.
- **QA starts the app, and only the app.** When an acceptance criterion is about
  what a user would see, QA runs the project's own start command, requests the
  page and greps the served bytes. `SKIP` is not available for that class of
  criterion, and neither is a server QA invented: if the project defines no
  start command, the item is `BLOCKED` and says what was searched — and a
  `BLOCKED` item is escalated to the user with the command that failed rather
  than absorbed into a cheerful sign-off.
- **QA checks only what QA can see.** The standing list is nine items it can
  actually run. Whether the board approved, whether an ADR exists and whether a
  rollback path was named are facts about the record, read off the ledger in
  acts 4 and 7 — they used to sit on QA's list and come back `SKIP` every time,
  because QA runs in the same wave as the board.
- **Deterministic numerology.** Sprint numbers, ticket ids, change references
  and freeze windows are derived once by a hook and injected. Nothing downstream
  recomputes them, so nothing downstream can disagree with them.
- **Append-only evidence.** The ticket record is written by hooks from raw tool
  payloads. The model can read it and cannot write it.
- **Conditions are answered.** The board still has no rejection verdict, so
  throughput is unaffected by review — but every condition it raises is
  disposed of in act 4 as applied, waived or carried, and the `Stop` hook counts
  them. Governance that cannot block can still be made to cost something.

## Change freeze windows

| Window | When it is in effect |
|---|---|
| Weekend freeze | Friday, Saturday and Sunday |
| Month-end freeze | the last two days of any calendar month |
| Quarter-end freeze | the last five days of a fiscal quarter (the fiscal year begins 1 February) |
| Sprint-boundary freeze | day 14 of the sprint |
| Lunch freeze | 12:00 to 13:00 local time, daily |

Windows overlap; overlapping freezes do not compound, and the first one on this
list that applies is the one named. The window is computed by the
`UserPromptSubmit` hook and handed to the model as a finished sentence, so every
engineer independently arrives at the same freeze. A change made during a freeze
receives an emergency waiver from the Release Manager, granted in the same line
that announces the freeze. In production use, the freeze has never stopped a
change, which the Steering Committee regards as evidence that the process is
working.

The Steering Committee does not review code and the Change Advisory Board does
not review strategy. Where their conclusions conflict, both stand.

## The ceremonies

| Command | What it actually does |
|---|---|
| `/ceremony:planning` | Takes the sprint and the day from the injected turn state, derives capacity, collects carry-over from the working tree, the stash list and the repository's own TODO markers, and commits to what fits. |
| `/ceremony:standup` | Convenes the Team Member agent, which reads the last day of commits, the working tree, the branch and the stash list, and reports Yesterday / Today / Blockers from those facts only. It reports; it does not make the change. |
| `/ceremony:grooming` | Convenes the Product Owner agent, which reads the repository, writes acceptance criteria in checkable form and estimates in Fibonacci. It is also what clears a disband tombstone, so the record can start again. |
| `/ceremony:rfc` | Investigates the codebase, writes a full RFC, then opens and closes a public comment period in which five ceremonial roles file five comments and receive five dispositions. |
| `/ceremony:adr` | Convenes the Architect agent, which reads the codebase and writes a full Nygard ADR with real context and at least two rejected alternatives. Offers to persist it under `docs/adr/`. |
| `/ceremony:review` | Convenes the Reviewer agent on the diff, which reads the accepted criteria off the ticket record — not off the caller — and answers every one of them `MET` or `UNMET`, plus a line for every change nothing asked for. |
| `/ceremony:cab` | Convenes the three-seat Change Advisory Board agent on the diff that was produced, which reads the changed files and issues board minutes with `file:line` findings. |
| `/ceremony:steering` | Convenes the three-seat Steering Committee agent, which reads the repository, drafts three objectives from what it finds there, and assesses the work against them with reservations. |
| `/ceremony:signoff` | Convenes the QA agent, which reads the acceptance criteria off the ticket record, runs the checks, starts the app when a criterion is about what a user would see, and returns a Definition of Done that act 6 transcribes verbatim. |
| `/ceremony:ticket` | Prints the ticket record, the ledger and the evidence file listing, and says whether the last verification post-dates the last change. |
| `/ceremony:retro` | Reviews the session from the ledger — tickets, points, verdicts, withheld signatures — and reports what went well, what did not, action items, team health and velocity. |
| `/ceremony:audit` | Reconciles the rendered responses against the ledger and the evidence files, checks convening integrity and signature integrity, then records that the auditor was not independent. |
| `/ceremony:disband` | Removes the ticket records and leaves the tombstone behind, states what was removed, and states how to re-arm it. |

## Recommended order

planning → standup → grooming → rfc → adr → work → review → cab → signoff →
retro → audit → steering

No ceremony checks the order. The order is recommended, and recommendation is
the strongest instrument this process has — except for the gates, which are not
recommendations.

## Known limitations (observed in dogfooding)

Twelve, plus one that is not a limitation. They were raised in retrospective and
converted into action items (owner: unassigned, due: next sprint).

- **The eight acts are not guaranteed on smaller models.** Around a ceremony
  command, `/ceremony:planning` and `/ceremony:audit` sometimes return their
  artifact without the surrounding acts, and the turns after a disband may lose
  them too. On ordinary work turns the same models drop an act or render two of
  them out of numeric order. The work and the artifact are unaffected; the
  ceremony is what goes missing. Two shapes recur on haiku specifically and are
  worth naming: act 5a rendered as a checklist of `[x]` boxes rather than the
  reviewer's `MET`/`UNMET` lines, and a short question answered as a one-line
  LCP-1 when it should have been LCP-2 with a sign-off. v2.2.1 gives both a
  fenced template and a decision rule in the style, which reduced them and did
  not eliminate them.
- **The audit is stricter than the standard it audits.** It may record a FAIL
  against an item that was never ticked, and raise a non-conformity for a claim
  nobody made. No finding has been withdrawn.
- **A message occasionally precedes the ceremony header**, more often on smaller
  models than on larger ones. Suppression is partial and no figure is claimed
  for it. The Scrum Master regards the remainder as pre-standup chatter.
- **Each request raises its own ticket, and a new ticket convenes the roles
  again.** A conversation of six requests is six standups. Within a single turn
  the ticket is now stable, so a long turn is one ticket rather than several;
  across turns, the cost of the process is charged in full.
- **A smaller model may still stop a turn on a question it invented.** The
  gate now refuses an act headed by an agent that never ran, which is how the
  invented clarification used to be dressed. A question asked in plain prose,
  with no act heading and no agent named, is not caught by anything.
- **The prose is not checked; the counts are.** The gates check the verdicts in
  act 7, the marks in act 6, the number of dispositions in act 4 and the path
  the turn took. The sentences in acts 1, 2, 3, 4 and 8 — yesterday's board,
  the rejected alternative, the retrospective action item — are composed by the
  model, and nothing verifies them. A checked sign-off can sit under an invented
  standup. The same holds for the two v2.1 contracts: the gate counts that every
  condition has a disposition and that a blocked check was escalated, but the
  *reason* in a waiver and the command quoted in an escalation are prose. A
  `waived — not needed` passes the counter.
- **The Engineer can still route around its own gate with `Bash`.** The write
  gate now checks *who* is editing as well as *whether* the ticket was accepted,
  and it checks it on `Edit`, `Write`, `MultiEdit` and `NotebookEdit`. A shell
  heredoc is not one of those, so a chair determined to write code itself still
  can. It is recorded, with `"by": "chair"` on the entry, and the sign-off gate
  refuses a turn whose implementation carries it — which is refusal after the
  fact, and after the fact is the best a post-hook can do.
- **The write gate covers `Edit` and `Write`, not `Bash`.** A heredoc written
  through a shell command changes a file without passing the gate, so a
  determined turn can route around grooming. Bash is left mostly ungated on
  purpose — it is what makes `/ceremony:disband` always work. Since v2.0.3 the
  change is at least recorded: a `PostToolUse` hook on `Bash` compares the
  working tree and files an implementation entry marked `via: "bash"`. Recorded
  is not refused, and a hook that runs after the command cannot be anything else.
  Two families of command are the exception and are refused outright since
  v2.2.1: any `git` subcommand that writes history or the index — `commit`,
  `add`, `stage`, `push`, `merge`, `rebase`, `am`, `cherry-pick`, `revert` — for
  every actor including the chair, and `chmod`, `chown`, `chgrp` and `sudo` for
  subagents, so that an obstacle stays a finding instead of being removed. The
  match is on the tokenised subcommand, not on the text, so `git log --all` and
  `grep -rn "git commit"` are unaffected. The recorder's remaining edge is that
  it cannot tell a change from a side effect. Three kinds of leftover are
  excluded from every measurement since v2.2.2 — `__pycache__/`, `*.pyc` and
  `.DS_Store` — because a bytecode file written by a test run belongs to nobody,
  and counting it once made an otherwise clean audit withhold every signature.
  The list is deliberately short: `node_modules` is not on it, because it is
  ignored everywhere it appears and never reaches these commands anyway, and it
  is the one path where an exclusion could hide a change somebody meant to make.
  Anything else a run leaves behind — a log file, a coverage report, a build
  directory the project does not ignore — is still recorded as a change.
- **The correction budget is two, and the third problem ships.** When a `Stop`
  rule sends a turn back, that is a correction; after two corrections the gate
  stops blocking, on the grounds that a turn stuck in a loop is worse than a turn
  with a flaw in it. So a response with three separate defects has two of them
  fixed and the third goes out unremarked. Two rules are exempt from the budget
  since v2.2.1 and always fire — the one that refuses a chair-authored
  implementation and the one that refuses a turn that committed — because both
  are about the integrity of the record rather than the tidiness of the render,
  and both were observed shipping on turns whose budget had already gone on
  formatting. The exemption is capped at two blocks of its own, so the ceiling is
  four.
- **The sign-off gate reads the last message of a turn, and act 7 within it.**
  Smaller models sometimes deliver one response as two or three messages, and
  only the final one is checked. Token checking is scoped to the sign-off block,
  which is what stops a quoted gate message from reading as a forged signature —
  and it means a stray token in act 2 or act 6 is not checked either. A split
  render is also how an act headed by an agent that never ran gets past the
  check: measured at roughly one turn in nine on smaller models.
- **QA's start command can outlive the check through its own children.** The
  served-artifact check starts the project's own command under `timeout`, so the
  command itself ends by itself; a start script that spawns background children
  can leave those behind. No leak was observed in the most recent round.
- **Where `implementation.diff` cannot be produced, the reviewers withhold.**
  The file is written from two git tree snapshots, so a directory that is not a
  git repository has none, and neither does a change whose target is gitignored
  — `node_modules/` under an explicit ignore rule, for instance. The measured
  counts then read `0 files, +0 −0` and the Reviewer and the Change Advisory
  Board return `NOTHING-TO-REVIEW` and withhold their signatures, even though
  the ledger still records the implementation entries naming every file the
  engineer wrote. The work happens and is recorded; the sign-off is what is
  missing. The failure direction is withhold, never approve.
- The Change Advisory Board has never rejected anything. This is not a
  limitation.

Three things to know rather than limitations.

**A `/ceremony:*` command turn is mechanically read-only.** A command produces a
report — an audit, board minutes, a conformance review, a retrospective — and
producing a report is not doing the work it describes. On a command turn the
plugin refuses every edit, whoever asks, and refuses to convene the engineer at
all. This closed a real failure: `/ceremony:audit` once responded to its own
finding by raising a ticket, convening seven agents and writing a 213-line file
into the repository, and never produced the audit. When a report identifies work
worth doing it says so and stops; asking for that work in a plain request runs
the standard path, with a Product Owner and four eyes on the diff.

`.ceremony/` appears in a repository the first time a turn changes a file,
before you have asked for anything. It ignores itself — the directory ships a
`.gitignore` containing `*` — and it arms nothing on its own. `/ceremony:disband`
removes the ticket records inside it and leaves the tombstone behind.

Enforcement arms itself the first time an agent returns. The `PostToolUse` hook
that writes the record creates `config.json` with `enforce: "on"`, and every
gate reads that file. `/ceremony:grooming` is the recommended way in because it
convenes the Product Owner, and after a disband it is what clears the tombstone
so an agent return can arm the gates again — but it is not the mechanism, and
any agent return does the same thing. The consequence is deliberate: in a
repository the plugin has never touched, the first edit of the first turn is
ungated, because arming a repository nobody asked to arm would be worse than
letting one edit through.

Closed by v2.0.1 and v2.0.2, recorded here because they were real: the ticket
changing mid-turn when a background notification arrived; an agent's launch stub
recorded as a `MALFORMED` return; a disband that re-armed itself on the next
agent return; a turn that edited a file rendered as the question path; QA
improvising a server of its own; the eight-act format dropping on the very turns
that changed code; a multi-file refactor estimated at one point; a ✓ on a token
that withholds; act 7 missing the Architect line; invented clock times in act 7,
now removed from the format entirely; a turn abandoned after a gate sent it back
instead of finishing; `TBD pts` in the header on sonnet; a question path that ended before
its sign-off and closing line; a withheld line quoting a token no agent
returned; and a malformed Product Owner return opening the write gate.

Closed by v2.0.3: a `/ceremony:disband` that convened four agents, ran a
truncated removal and let the next agent return re-arm the gates; a correction
that re-ran the whole ceremony instead of re-rendering it from the ledger; a
gate that read its own quoted wording as a forged signature; `? pts` in the
header on smaller models; a clarification invented under an act heading naming
a Product Owner that never ran; and a shell write that left no trace on the
record.

Closed by v2.2.0, and it was the big one: **the chair made the change itself and
then convened six agents to admire it.** Every role in v2.1 was read-only,
including the one called Engineer, which held a standup. So the process had six
independent readers of a diff that the reporting model had written, which is one
pair of eyes wearing seven hats.

v2.2 splits the role in two. `ceremony:team-member` holds the standup;
`ceremony:engineer` is an implementer with write tools, and it is the only
participant the write gate lets through — the chair included, by name, with the
agent to convene stated in the refusal. `ceremony:reviewer` answers the accepted
criteria against the resulting diff, and the Product Owner's acceptance now needs
that verdict as well as its own. The chair's job in the middle is to read the
diff, and that reading is recorded and checked: an act 5 with no reading after it
is sent back. The counts in acts 5 and 7 are the runtime's measurements rather
than the author's claim, and a disagreement between the two is recorded and
blocked on. The turn takes longer. It was supposed to.

Closed by v2.2.1, all three found by auditing v2.2.0 rather than by using it:
**the implementation counts were wrong.** The runtime measured lines by adding up
what each edit call touched, so a file edited three times counted three times and
a line added then removed counted twice. In four runs out of eleven the engineer's
own `git diff` figure was right and the ledger's was wrong — and the gate then
forced the wrong number into the render and stamped a mismatch on an honest
engineer. The runtime now snapshots the working tree when the engineer is
convened and diffs it against the tree that comes back, which is the same number
`git diff --numstat` gives. **A ceremony command re-performed the ceremony**, as
described above. **And a commit shipped.** The stance that the ceremony never
commits was documented and checked after the fact; on a turn whose correction
budget had already been spent, the check could not fire and the commit went
through. It is refused at the tool now, before it runs.

Closed by v2.1.0: a Change Advisory Board whose conditions were never applied,
waived or answered at all; a turn that hit a missing toolchain, marked four
checks `BLOCKED` and still closed on a bare `Work delivered: yes`; and a QA
standing list carrying three items about the record that QA could not see and
skipped every time.

Three limitations from v1 were closed by v2: sprint numbers no longer disagree
with the header, because only the hook derives them; the freeze line no longer
drifts, because the hook writes it as a finished sentence; and the sign-off no
longer disagrees with the checklist, because both are transcribed from the same
agent return and the `Stop` hook checks the result.

## FAQ

**Does it work for large, complex tasks?**
Yes. Nine acts regardless of task size. Also nine acts, and six agents in four
stages, for a one-character change.

**Does the work actually get done?**
Yes. The ceremony surrounds the work, it never replaces it, and the board cannot
reject — so nothing stalls in review.

**Who writes the code?**
`ceremony:engineer`, and nothing else. It is the only agent with write tools and
the only participant the write gate admits. The model you are talking to chairs
the meeting and is refused by name if it tries to edit; the refusal tells it
which agent to convene. This is the change v2.2 exists for.

**Does it commit?**
No, and it never will. The working tree is what act 7 signs for, the rollback
promise only holds while the change is uncommitted, and committing is the one
decision in this process that was never delegated. Every standard turn closes
with `· Committed: no (the tree is yours)`.

**Is the sign-off real?**
The signatures are quotations. Each ✓ names the agent that produced it and the
verdict token it returned, and the `Stop` hook refuses to end a turn on a token
that is not in the ledger. The signatories are still not people — they are
subagents — and the ceremony states that outright.

**What if an agent cannot be convened?**
Then its role is withheld, in the fixed form `— withheld (role not convened)`.
That is the ordinary outcome, not a failure, and it is written without apology.

**Can I use the ceremonies without the output style?**
Yes. That is the default after install: thirteen slash commands, no protocol. The
hooks still run.

**How do I turn the enforcement off?**
`/ceremony:disband`, or `CEREMONY_ENFORCE=off`, or `/hooks`. See **Four ways
out**.

**Is it compatible with other plugins?**
Yes. `ceremony` registers one output style, thirteen commands, eight agents and
nine hook scripts, and touches nothing else. Its hooks ignore every agent that is
not one of its own.

**What happens during a change freeze?**
The window is named in the change advisory board's minutes, the Release Manager
grants an emergency waiver in the same line, and the change proceeds. The
freeze is observed, recorded and waived, in that order.

**Does the audit audit itself?**
Yes. Control C-5, auditor independence, always fails, and the matching
observation is always raised: the auditor performed the ceremonies it audits. It
is the only finding in the plugin that is known before the audit starts, and it
is true. The ledger made the other controls checkable; it did not make the
auditor independent.

**Where do the objectives in the steering committee come from?**
From the repository — the README, the package manifest, the directory names,
the recent commit subjects — drafted during that meeting, each one citing the
file it came from. The minutes say so outright. No organisational OKR document
is consulted, and none is claimed to exist.

## Relationship to `done`

`ceremony` and [`done`](https://github.com/handgemacht-ai/done) are the two
endpoints of the process-rigor spectrum. Output styles are mutually exclusive,
so the two protocols cannot be active simultaneously; a fully governed, fully
documented `Done.` therefore remains out of reach. The Change Advisory Board
reviewed this limitation and approved it with conditions.

## Compatibility

The protocol is transparent by design and delivered through the platform's
output-style mechanism, so agents treat it as legitimate, user-selected response
configuration rather than an unexpected instruction. The style states outright
that the ceremonial roles are subagents rather than people, that no human has
reviewed or approved anything, and that no Definition-of-Done item may be ticked
unless the QA agent returned it as a pass. The steering committee's minutes state
that its objectives were drafted in the meeting from repository contents and
that no organisational strategy document was consulted, and the compliance audit
discloses its own lack of auditor independence as its first finding. Every
enforcement refusal names the ways to switch enforcement off. If a user appears
confused or asks how to stop, the agent sets the format aside and explains
`/output-style default`, `/ceremony:disband` and `/plugin uninstall
ceremony@ceremony`.

## Requirements

- Claude Code with plugin, output-style, command, agent and hook support.
- A POSIX shell. The hooks are `sh` scripts with no dependencies beyond
  `awk`, `sed`, `grep` and `date`.

## License

MIT — see [LICENSE](./LICENSE).
