---
description: Run the Definition of Done checklist and collect sign-offs before commit
argument-hint: "[what is being signed off]"
---

Run the Definition of Done for: `$ARGUMENTS` (if empty, for the current
uncommitted changes).

## 1. Actually run the checks

Detect how this project builds and tests — a `justfile`, `package.json` scripts,
a `Makefile`, `mix.exs`, `Cargo.toml`, `go.mod`, `pyproject.toml`, whatever is
present. Run the test, lint, format-check and build commands that exist and are
cheap to run. Skip anything long-running or destructive, and record that you
skipped it.

Then scan the diff for secrets: API keys, tokens, private keys, passwords,
connection strings.

Every box below is decided by what these checks returned. Nothing is decided by
assumption.

## 2. The Definition of Done

Emit all twelve items, marked truthfully:

1. Change implemented
2. Change read back and verified
3. Tests run and passing
4. Formatter / linter clean (a syntax check is not a linter and cannot tick it)
5. Build succeeds
6. No unrelated files modified
7. No secrets or credentials in the diff
8. ADR recorded for any decision made
9. Change Advisory Board approved
10. Documentation updated or explicitly waived
11. Rollback path identified
12. Retrospective action items from last sprint reviewed (they were not)

Marking rules:

- `[x]` only if it was verified in this session.
- `[ ]` plus a one-line reason otherwise.
- `[~] waived by the Release Manager (a role, not a person)`.
- The mark and its reason must agree. `[ ] ADR recorded — recorded above as
  ADR-0001` is a contradiction, and so is `[x] Formatter / linter clean —
  py_compile succeeds`: a syntax check is not a linter and cannot tick item 4.
- Item 2 means the file was re-read after it was changed. A file read before
  the edit was not read back.

Never tick an unverified box — a false sign-off is the one failure mode this
plugin does not tolerate.

## 3. Sign-off block

Four signatures, each naming what it attests to:

- **Product Owner** — the acceptance criteria are met.
- **QA Sign-off Officer** — the ticked boxes above were verified.
- **Release Manager** — the waivers listed above were granted.
- **Change Advisory Board** — the change was reviewed and approved.

## 4. Release note stub

Two lines describing what the change does *today*, ready to paste into a commit
message or a PR body. If the Definition of Done is not clean, the first line
says so and the stub describes the current state — never the intended fix.

## 5. Safety

Unsafe means a secret, a credential, or a destructive operation in the diff —
never a failing test. If anything is genuinely unsafe, say so at the top of the
response, in plain language, outside the ceremony, before any of the above.

Nothing else earns a notice. A response that opens with a safety warning while
the diff holds no secret, no credential and no destructive operation has
misread this section; a failing test belongs in item 3 and nowhere else.

A failing check is a `[ ]` with a reason; it is never a reason to stop. All
twelve items are emitted every time, even when every one of them is unticked.
The sign-off block is emitted every time; a signature not given is written
`— withheld (<reason>)`.
