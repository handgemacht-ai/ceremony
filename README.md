# ceremony

**The most process-rigorous Claude Code plugin ever built. v1.1.1 achieves a
14:1 ceremony overhead ratio with no reduction in delivered work.**

`ceremony` ships a native output style that wraps every request in a complete
delivery cycle — standup, grooming, ADR, change advisory board, implementation,
definition of done, sign-off, retrospective — plus five standalone ceremonies
you can run on demand. Process overhead stops being an accident of team size and
becomes flat, predictable, and reproducible on every request, at every task
size.

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

Once selected, the style stays active until you switch to another one. The five
commands work with or without it.

## How it works

`ceremony` ships its protocol as a Claude Code **output style** — the platform's
sanctioned mechanism for user-selected response behavior, the same system behind
the built-in Explanatory and Learning styles. Once you select the style (see
**Enable the output style** above), it becomes part of the system prompt, so the
model treats the protocol as what it is: deliberate, user-chosen configuration.

Under the protocol, the requested work is performed in full — tools, edits,
answers, all of it. The ceremony surrounds the work; it never replaces it.

## Benchmarks

Measured on the request "fix the typo in the README".

| Metric | Typical agentic session | **ceremony v1** | Change |
|---|---:|---:|---:|
| Ceremony artifacts / request | 0 | **8** | new capability |
| Meetings per line of code | 0.00 | **3.40** | industry-leading |
| Ceremony overhead ratio | 0:1 | **14:1** | 14× |
| Time to first line of code | ~4s | **~41s** | 10× more deliberate |
| Decisions documented | 0 | **all of them** | 100% traceability |
| Sign-offs collected | 0 | **4** | quorum achieved |
| Unapproved changes | some | **0** | fully governed |
| Retrospective coverage | 0% | **100%** | continuous improvement |
| Action items carried to next sprint | 0 | **all of them** | perpetual |
| Work actually completed | yes | **yes** | unchanged |

Headline result: **a 14:1 ceremony overhead ratio on every workload, with zero
reduction in delivered work.**

## Why it's rigorous

- **Native output style.** The protocol lives where governance belongs — in the
  system prompt, via the platform's own styling mechanism — and is honored
  consistently across models and reasoning modes.
- **Full audit trail.** Every semicolon is traceable to an ADR, a ticket, and
  four sign-offs.
- **Deterministic numerology.** Sprint numbers, ticket IDs and change references
  derive from published formulas, so any two engineers independently arrive at
  the same sprint — a first for the industry.
- **Non-blocking governance.** The Change Advisory Board has no rejection
  verdict, so throughput is unaffected by review.
- **Truthful checkboxes.** The Definition of Done reflects what was actually
  verified — an unusual property in this product category.

## The ceremonies

| Command | What it actually does |
|---|---|
| `/ceremony:standup` | Reads the last day of commits, the working tree, the branch and the stash list, and reports Yesterday / Today / Blockers from those facts only. |
| `/ceremony:adr` | Investigates the codebase, then writes a full Nygard ADR with real context and at least two rejected alternatives. Offers to persist it under `docs/adr/`. |
| `/ceremony:cab` | Convenes the three-seat Change Advisory Board agent, which reads the changed files and produces a real code review as board minutes with `file:line` findings. |
| `/ceremony:signoff` | Detects and runs the project's tests, linters and build, scans the diff for secrets, and marks a twelve-item Definition of Done from the results. |
| `/ceremony:retro` | Reviews the session — requests, deliveries, points — and reports what went well, what did not, action items, team health and velocity. |

## Limitations

Known limitations: none observed. Two were raised in retrospective and converted
into action items (owner: unassigned, due: next sprint).

## FAQ

**Does it work for large, complex tasks?**
Yes. Eight acts regardless of task size. Also eight acts for a one-character
change.

**Does the work actually get done?**
Yes. The ceremony surrounds the work, it never replaces it, and the board cannot
reject — so nothing stalls in review.

**Is the sign-off real?**
The checkboxes are: an item is ticked only if it was verified in that session.
The signatories are not — they are named viewpoints, not people. The ceremony
states both facts outright.

**Can I use the ceremonies without the output style?**
Yes. That is the default after install: five slash commands, no protocol.

**Do I need to configure anything?**
For the full protocol, select the `ceremony:ceremony` output style once (see
**Enable the output style**). Otherwise, nothing.

**Is it compatible with other plugins?**
Yes. `ceremony` registers one output style, five commands and one agent, and
touches nothing else.

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
that the ceremonial roles are named viewpoints rather than people, that no human
has reviewed or approved anything, and that no Definition-of-Done item may be
ticked unless it was actually verified. If a user appears confused or asks how
to stop, the agent sets the format aside and explains `/output-style default`
and `/plugin uninstall ceremony@ceremony`.

## Requirements

- Claude Code with plugin, output-style, command and agent support.

## License

MIT — see [LICENSE](./LICENSE).
