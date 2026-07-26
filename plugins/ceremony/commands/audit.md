---
description: Audit this session's ceremonies for compliance against the repository's actual state
argument-hint: "[control family to focus on]"
---

Audit the ceremonies performed earlier in this conversation. Focus:
`$ARGUMENTS` (if empty, all control families).

## 1. Scope

Audit only what is visible in this conversation. If no ceremony artifact appears
earlier in this session, say so in one line and adjourn. If earlier turns are no
longer visible, say so in one line and audit what is. An audit that reports on
turns it cannot see is the violation it exists to find.

## 2. The audit observes

The audit observes; it never changes the code and it never re-performs a
ceremony. Do not edit, create or delete files. Do not re-run a ceremony, do not
correct a finding, and do not fix what a control catches. A finding is the
output — report it and let the user decide. An audit that repairs its own
subject has audited nothing.

Re-verification uses the same read-only checks `/ceremony:signoff` runs: the
project's tests, linters, format checks and build, `git status`, `git diff`, and
reading files. Skip anything long-running or destructive and record that you
skipped it.

## 3. Control families

Four families, each with a fixed result line.

### C-1 · Checkbox integrity

C-1.<n> · <the item as it was ticked> · <PASS | FAIL | NOT RE-VERIFIABLE> — <evidence>

Evidence is a command and its exit status, a `file:line`, or a git fact. NOT
RE-VERIFIABLE is a valid result and is not a failure — it is what an honest
auditor writes when the claim cannot be re-checked now. A PASS recorded for a
claim you could not re-check is itself a non-conformity, and you must raise it
against yourself.

### C-2 · Numerology arithmetic

C-2.<n> · <quantity> · stated <x> · recomputed <y> · <PASS | FAIL>

Recompute the sprint number, the sprint day, the ticket indices, the change
references, the ADR and RFC numbering, and the cumulative velocity. Show both
numbers on every line, including the ones that agree.

### C-3 · Act completeness

C-3.<n> · response <n> · path <standard | LCP-2 | LCP-1> · acts <found>/<expected> · <PASS | FAIL>

Expected act counts: standard path 8, LCP-2 3 (header, act 5, sign-off), LCP-1
1. The path is read from what the response was answering, not from what it
produced — a response that ran the wrong path fails this control rather than
redefining it.

### C-4 · Signature integrity

C-4.<n> · <role> · <given | withheld> · <PASS | FAIL> — <the checklist items it rests on>

A ✓ passes only when the Definition-of-Done items it attests to are ticked. A
withheld signature passes only when a reason is written beside it.

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

C-5 is always FAIL and NC-0 is always raised. It is the only finding in this
plugin that is known in advance, and it is true.

## 6. Audit opinion

The audit has no adverse opinion. Available opinions: Compliant; Compliant with
observations; Compliant with qualifications. Choose from the findings: no
non-conformities beyond NC-0 is Compliant with observations; any Minor is
Compliant with observations; any Major is Compliant with qualifications.
Non-conformities are registered, not enforced. The audit reports; the sprint
continues.

## 7. Evidence

Every PASS, FAIL and recomputation names the evidence it rests on — a command
and its exit status, a file and its line, or a formula and its two numbers. A
verdict with nothing beside it is not a finding; leave it out.

## 8. Close

End with exactly:

Audit closed. Next audit: next sprint. Auditor independence: not achieved.
