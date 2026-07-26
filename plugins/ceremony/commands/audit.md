---
description: Audit this session's ceremonies against the ledger and the repository's actual state
argument-hint: "[control family to focus on]"
---

Audit the ceremonies performed earlier in this conversation. Focus:
`$ARGUMENTS` (if empty, all control families).

## 1. Scope

Audit what is visible in this conversation **and what is on the record** at
`.ceremony/`. The record is the primary evidence: `ledger.jsonl` for what was
convened and what it returned, `ticket.md` for the returns in full, and
`evidence/*.json` for the raw tool output the ledger was derived from.

If neither a ceremony artifact nor a ticket record exists, say so in one line
and adjourn. If earlier turns are no longer visible, say so and audit the record
instead — that is what the record is for.

## 2. The audit observes

The audit observes; it never changes the code and it never re-performs a
ceremony. Do not edit, create or delete files. Do not convene an agent. Do not
correct a finding, and do not fix what a control catches. A finding is the
output. An audit that repairs its own subject has audited nothing.

Re-verification uses read-only checks: the project's tests, linters, format
checks and build, `git status`, `git diff`, and reading files. Skip anything
long-running or destructive and record that you skipped it.

## 3. Control families

### C-1 · Checkbox integrity

C-1.<n> · <the item as it was ticked> · <PASS | FAIL | NOT RE-VERIFIABLE> — <evidence>

Compare each rendered checkbox against QA's `CEREMONY-DOD:` line for it in
`ticket.md`. A mark that does not match the fixed mapping is a FAIL. NOT
RE-VERIFIABLE is a valid result and is not a failure — it is what an honest
auditor writes when the claim cannot be re-checked now. A PASS recorded for a
claim you could not re-check is itself a non-conformity, and you must raise it
against yourself.

### C-2 · Numerology arithmetic

C-2.<n> · <quantity> · stated <x> · turn state <y> · <PASS | FAIL>

The sprint number, the sprint day, the ticket id, the change reference and the
freeze window come from the injected `CEREMONY TURN STATE`. Compare what the
response printed against what the turn state said. Do not recompute them
yourself: this control checks transcription, and an auditor who recomputes is
auditing its own arithmetic. Velocity and the ADR number are still checked
against the responses and `docs/adr/`.

### C-3 · Act completeness

C-3.<n> · response <n> · path <standard | LCP-2 | LCP-1> · acts <found>/<expected> · <PASS | FAIL>

Expected act counts: standard path 8, LCP-2 2 (act 5 and act 7), LCP-1 1. The
path is read from what the response was answering, not from what it produced.

### C-4 · Signature integrity

C-4.<n> · <role> · <given | withheld> · <PASS | FAIL> — <the ledger entry it rests on>

A ✓ passes only when a ledger entry from that turn carries a signing token for
that role. A withheld signature passes only when it uses one of the two withheld
shapes. A Release Manager line that is not the fixed line is a FAIL, and a Scrum
Master line in act 7 is a FAIL.

### C-6 · Convening integrity

C-6.<n> · <role> · ledger <ts | absent> · last implementation <ts | none> · <PASS | FAIL>

Every role that carries a ✓ in a sign-off must have a ledger entry, and that
entry must post-date the last `"role":"implementation"` entry for the ticket. A
signature collected before the code moved attests to a repository that no longer
exists.

Also check the reverse: a `ticket.md` heading with no matching ledger line, or a
ledger line with no evidence file, is a FAIL against the record itself.

## 4. Non-conformity register

Fixed template:

NC-<n> · <Minor | Major | Observation> · control <C-x.y>
Evidence: <what was observed>
Corrective action: <what would fix it> — owner: <role> — due: next sprint

Never raise a non-conformity you did not observe. A clean session produces an
empty register, written exactly "No non-conformities raised." The auditor notes
that this is unusual.

## 5. Auditor independence

Emit this control every time, unchanged:

C-5 · Auditor independence · FAIL — the auditor performed the ceremonies it audited.

NC-0 · Observation · control C-5
Evidence: the auditor and the auditee are the same model in the same session.
Corrective action: engage an independent auditor — owner: the auditor — due: next sprint.

C-5 is always FAIL and NC-0 is always raised. The ledger has made the other
controls checkable; it has not made the auditor independent, and no amount of
record-keeping will.

## 6. Audit opinion

The audit has no adverse opinion. Available opinions: Compliant; Compliant with
observations; Compliant with qualifications. Choose from the findings: no
non-conformities beyond NC-0 is Compliant with observations; any Minor is
Compliant with observations; any Major is Compliant with qualifications.
Non-conformities are registered, not enforced. The audit reports; the sprint
continues.

## 7. Evidence

Every PASS, FAIL and comparison names the evidence it rests on — a ledger line,
a command and its exit status, a file and its line, or two numbers side by side.
A verdict with nothing beside it is not a finding; leave it out.

## 8. Close

End with exactly:

Audit closed. Next audit: next sprint. Auditor independence: not achieved.
