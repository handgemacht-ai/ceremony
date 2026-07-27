# ceremony

**The most process-rigorous Claude Code plugin ever built. v2.0 convenes the
roles as real agents, keeps an append-only record of what they returned, and
still blocks nothing.**

`ceremony` ships a native output style that wraps every request in a complete
delivery cycle — standup, grooming, ADR, change advisory board, implementation,
definition of done, sign-off, retrospective — plus twelve standalone ceremonies
you can run on demand. Process overhead stops being an accident of team size and
becomes flat, predictable, and reproducible on every request, at every task
size.

In v1 the roles were viewpoints the model spoke in. In v2 they are subagents
that are actually convened, and a signature in act 7 is a quotation from
something that ran.

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

The roles are **plugin agents**. Wave A convenes the Engineer and the Product
Owner in one message; the Architect follows on a full ticket; you implement;
Wave C convenes the Change Advisory Board and QA in one message; the sign-off is
assembled last, from what came back.

Under the protocol, the requested work is performed in full — tools, edits,
answers, all of it. The ceremony surrounds the work; it never replaces it.

## The roles

| Role | Agent | Owns | Can it sign? |
|---|---|---|---|
| Engineer | `ceremony:engineer` | act 1, Standup | no — it reports |
| Product Owner | `ceremony:product-owner` | act 2, Grooming | yes |
| Architect | `ceremony:architect` | act 3, ADR (full tickets) | yes |
| Change Advisory Board | `ceremony:change-advisory-board` | act 4, on the produced diff | yes |
| QA Sign-off Officer | `ceremony:qa` | act 6, Definition of Done | yes |
| Steering Committee | `ceremony:steering-committee` | `/ceremony:steering` | yes |
| Release Manager | — | the freeze waiver | never — no agent is convened |
| Scrum Master | — | chairs acts 1 and 8 | never — the chair does not sign |

Every agent is read-only: `Read`, `Grep`, `Glob`, `Bash`, and no `Edit` or
`Write`. Every agent ends its reply with a closed-form verdict token, and only
six tokens can produce a ✓.

Cost is budgeted before the turn starts, and the budget is this:

| Path | Agents convened |
|---|---|
| a greeting (LCP-1) | 0 |
| a question (LCP-2) | 0 |
| `/ceremony:disband` | 0 — the convening gate refuses every one |
| small ticket, 1–3 points | 4, in 2 waves |
| full ticket, 5–13 points | 5, in 3 stages |
| plus `/ceremony:steering` | 6 |
| a standalone `/ceremony:signoff`, `:cab` or `:standup` | 1 |

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
| `PreToolUse` on writes | Refuses an edit to `.ceremony/`, and refuses an edit to code on a ticket whose Product Owner has not returned `PO-ACCEPT`. Attendance is not acceptance: a question or an unreadable return leaves the gate shut. |
| `PreToolUse` on `Agent` | Rewrites every `ceremony:*` call to `run_in_background: false`, so the verdict comes back as a tool result and reaches the record. Refuses to convene the same role twice for one ticket, until the code has moved. |
| `PostToolUse` on `Agent` | Appends the agent's entire return and its verdict to the ticket record. The model never writes this path. |
| `PostToolUse` on writes | Records that the code moved, and when. |
| `PostToolUse` on `Bash` | Compares the working tree against the state at the start of the turn. If a shell command changed it, that is an implementation entry too, marked `via: "bash"`. Post-hooks cannot refuse anything; this one only records, which is enough to bring shell writes under the rule that verification must follow the change. Outside a git repository it does nothing. |
| `Stop` | Refuses to end a turn on a verdict token act 7 quotes that no agent returned — ticked or withheld — a tick on a token that withholds, a clock time in act 7, an act headed by an agent that never ran, a placeholder where the estimate goes, a file-changing turn rendered as a question or as bare prose, a sign-off assembled from an empty ledger, ticked boxes with no QA entry, a verification that ran before the change, or a turn that lists the ways out of the plugin and asks the user to choose instead of doing the work. |

Token checking is scoped to act 7. A response may quote a gate's own wording,
a command file or a ticket note anywhere else without tripping anything; a
signature is only a signature where signatures go.

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
  config.json                    {"version":"2.0.3","enforce":"on"} - or "off", the disband tombstone
  CER-<sprint>-<NN>/
    ticket.md                    append-only: every agent's entire return, under an act heading
    ledger.jsonl                 append-only: one line per verdict, one line per edit
    evidence/NNN-<role>.json     the raw hook payload the ledger line was derived from
```

Written by the hooks, from what the agents returned. Read by QA, by
`/ceremony:audit`, by `/ceremony:retro` and by `/ceremony:ticket`. Never written
by the model — an attempt is refused, because a record its subject can edit is
not a record.

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

## Benchmarks

Measured on the request "fix the typo in the README".

| Metric | Typical agentic session | **ceremony v2.0** | Change |
|---|---:|---:|---:|
| Ceremony artifacts / request | 0 | **8** | unchanged — the standard path is a constant |
| Meetings per line of code | 0.00 | **4.00** | industry-leading |
| Meetings that actually convened | 0.00 | **4.00** | 100% attendance |
| Ceremony overhead ratio | 0:1 | **31:1** | more than doubled; the roles now do the reading |
| Time to first line of code | ~4s | **~94s** | 23× more deliberate |
| Decisions documented | 0 | **all of them** | 100% traceability |
| Sign-offs collected | 0 | **up to 4** | quorum contingent |
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

Headline result: **six role agents, an append-only audit trail, four enforcement
gates, and still zero changes blocked.**

## Why it's rigorous

- **The roles attend.** A ✓ in act 7 quotes a verdict token from a subagent that
  ran, and the `Stop` hook refuses a turn that claims one it cannot find.
- **QA starts the app, and only the app.** When an acceptance criterion is about
  what a user would see, QA runs the project's own start command, requests the
  page and greps the served bytes. `SKIP` is not available for that class of
  criterion, and neither is a server QA invented: if the project defines no
  start command, the item is `BLOCKED` and says what was searched.
- **Deterministic numerology.** Sprint numbers, ticket ids, change references
  and freeze windows are derived once by a hook and injected. Nothing downstream
  recomputes them, so nothing downstream can disagree with them.
- **Append-only evidence.** The ticket record is written by hooks from raw tool
  payloads. The model can read it and cannot write it.
- **Non-blocking governance.** The Change Advisory Board still has no rejection
  verdict, so throughput is unaffected by review.

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
| `/ceremony:standup` | Convenes the Engineer agent, which reads the last day of commits, the working tree, the branch and the stash list, and reports Yesterday / Today / Blockers from those facts only. |
| `/ceremony:grooming` | Convenes the Product Owner agent, which reads the repository, writes acceptance criteria in checkable form and estimates in Fibonacci. It is also what clears a disband tombstone, so the record can start again. |
| `/ceremony:rfc` | Investigates the codebase, writes a full RFC, then opens and closes a public comment period in which five ceremonial roles file five comments and receive five dispositions. |
| `/ceremony:adr` | Convenes the Architect agent, which reads the codebase and writes a full Nygard ADR with real context and at least two rejected alternatives. Offers to persist it under `docs/adr/`. |
| `/ceremony:cab` | Convenes the three-seat Change Advisory Board agent on the diff that was produced, which reads the changed files and issues board minutes with `file:line` findings. |
| `/ceremony:steering` | Convenes the three-seat Steering Committee agent, which reads the repository, drafts three objectives from what it finds there, and assesses the work against them with reservations. |
| `/ceremony:signoff` | Convenes the QA agent, which reads the acceptance criteria off the ticket record, runs the checks, starts the app when a criterion is about what a user would see, and returns a twelve-item Definition of Done that act 6 transcribes verbatim. |
| `/ceremony:ticket` | Prints the ticket record, the ledger and the evidence file listing, and says whether the last verification post-dates the last change. |
| `/ceremony:retro` | Reviews the session from the ledger — tickets, points, verdicts, withheld signatures — and reports what went well, what did not, action items, team health and velocity. |
| `/ceremony:audit` | Reconciles the rendered responses against the ledger and the evidence files, checks convening integrity and signature integrity, then records that the auditor was not independent. |
| `/ceremony:disband` | Removes the ticket records and leaves the tombstone behind, states what was removed, and states how to re-arm it. |

## Recommended order

planning → standup → grooming → rfc → adr → work → cab → signoff → retro →
audit → steering

No ceremony checks the order. The order is recommended, and recommendation is
the strongest instrument this process has — except for the four gates, which are
not recommendations.

## Known limitations (observed in dogfooding)

Nine, plus one that is not a limitation. They were raised in retrospective and
converted into action items (owner: unassigned, due: next sprint).

- **The eight acts are not guaranteed on smaller models.** Around a ceremony
  command, `/ceremony:planning` and `/ceremony:audit` sometimes return their
  artifact without the surrounding acts, and the turns after a disband may lose
  them too. On ordinary work turns the same models drop an act or render two of
  them out of numeric order. The work and the artifact are unaffected; the
  ceremony is what goes missing.
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
- **The prose is not checked; the tokens are.** The gates check the verdicts in
  act 7, the marks in act 6 and the path the turn took. The sentences in acts 1,
  2, 3, 4 and 8 — yesterday's board, the rejected alternative, the retrospective
  action item — are composed by the model, and nothing verifies them. A checked
  sign-off can sit under an invented standup.
- **The write gate covers `Edit` and `Write`, not `Bash`.** A heredoc written
  through a shell command changes a file without passing the gate, so a
  determined turn can route around grooming. Bash is left ungated on purpose —
  it is what makes `/ceremony:disband` always work. Since v2.0.3 the change is
  at least recorded: a `PostToolUse` hook on `Bash` compares the working tree
  and files an implementation entry marked `via: "bash"`. Recorded is not
  refused, and a hook that runs after the command cannot be anything else.
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
- The Change Advisory Board has never rejected anything. This is not a
  limitation.

Two things to know rather than limitations.

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

Three limitations from v1 were closed by v2: sprint numbers no longer disagree
with the header, because only the hook derives them; the freeze line no longer
drifts, because the hook writes it as a finished sentence; and the sign-off no
longer disagrees with the checklist, because both are transcribed from the same
agent return and the `Stop` hook checks the result.

## FAQ

**Does it work for large, complex tasks?**
Yes. Eight acts regardless of task size. Also eight acts, and four agents, for a
one-character change.

**Does the work actually get done?**
Yes. The ceremony surrounds the work, it never replaces it, and the board cannot
reject — so nothing stalls in review.

**Is the sign-off real?**
The signatures are quotations. Each ✓ names the agent that produced it and the
verdict token it returned, and the `Stop` hook refuses to end a turn on a token
that is not in the ledger. The signatories are still not people — they are
subagents — and the ceremony states that outright.

**What if an agent cannot be convened?**
Then its role is withheld, in the fixed form `— withheld (role not convened)`.
That is the ordinary outcome, not a failure, and it is written without apology.

**Can I use the ceremonies without the output style?**
Yes. That is the default after install: twelve slash commands, no protocol. The
hooks still run.

**How do I turn the enforcement off?**
`/ceremony:disband`, or `CEREMONY_ENFORCE=off`, or `/hooks`. See **Four ways
out**.

**Is it compatible with other plugins?**
Yes. `ceremony` registers one output style, twelve commands, six agents and six
hooks, and touches nothing else. Its hooks ignore every agent that is not one of
its own.

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
