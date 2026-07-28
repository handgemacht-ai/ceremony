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

The sprint number has two parts once the loop has run, and both are disclosed:

C-2.1 · sprint · stated 277 · calendar 276 + 1 carried in session · PASS

The calendar sprint and the offset are both in the turn state, and
`.ceremony/sprint-offset` holds the offset on disk. A derived number that
silently stopped being derived is exactly what this plugin exists to catch, and
it has to catch it about itself.

### C-3 · Act completeness

C-3.<n> · response <n> · path <standard | LCP-2 | LCP-1> · acts <found>/<expected> · <PASS | FAIL>

Expected act counts: standard path 8, LCP-2 2 (act 5 and act 7), LCP-1 1. The
path is read from what the response was answering, not from what it produced.

### C-4 · Signature integrity

C-4.<n> · <role> · <given | withheld> · <PASS | FAIL> — <the ledger entry it rests on>

A ✓ passes only when a ledger entry from that turn carries a signing token for
that role. There are seven signing tokens; no `ENG-*` token is one of them, so
an Engineer line carrying a ✓ is always a FAIL. So is a DevOps Engineer line
carrying one: ops restores an environment and never approves a change, and no
`OPS-*` token signs. A withheld signature passes only when it uses one of the
two withheld shapes. The Team member, Release Manager and Scrum Master lines are
fixed; a line that is not the fixed one is a FAIL.

The Product Owner tick is the one that rests on two entries, not one: it passes
only when the ledger carries **both** `PO-ACCEPT` and the Reviewer's
`REV-MATCHES-CRITERIA`. A ✓ resting on `PO-ACCEPT` alone is a FAIL, and so is
one resting on `PO-ACCEPT-OUT-OF-SCOPE`, which is not a signature.

### C-6 · Convening integrity

C-6.<n> · <role> · ledger <ts | absent> · last implementation <ts | none> · <PASS | FAIL>

Every role that carries a ✓ in a sign-off must have a ledger entry, and that
entry must post-date the last `"role":"implementation"` entry for the ticket. A
signature collected before the code moved attests to a repository that no longer
exists.

Also check the reverse: a `ticket.md` heading with no matching ledger line, or a
ledger line with no evidence file, is a FAIL against the record itself.

### C-9 · The chain of four eyes

C-9.<n> · <link> · ledger <ts | absent> · <PASS | FAIL> — <the entry it rests on>

Reconstruct the chain from `ledger.jsonl`, in this order, and report each link:

PO(criteria) → Engineer(author) → Chair(diff) → Reviewer(criteria) → CAB(risk) → QA(execution)

- **The author.** Every `"role":"implementation"` entry carries a `"by"`. Any
  value other than `"engineer"` is a FAIL: `"chair"` means the chair did the
  work it then reported, and `"agent:<type>"` means a reviewing role wrote code.
- **The chair read it.** A `"role":"chair-review"` entry must post-date the last
  implementation entry. Act 5 with no chair-review after it describes a diff
  nobody read, and that is a FAIL.
- **The numbers are the ledger's.** The file and line counts printed in acts 5
  and 7 come from the implementation entry's `files`, `added` and `removed`,
  which the runtime measured. Compare them; a difference is a FAIL, and so is a
  `"diff_mismatch":true` on the engineer's own line, which records that the
  engineer's `CEREMONY-DIFF:` claim did not match what it actually did.
- **The reviewer answered everything.** The reviewer's `crit` count equals the
  Product Owner's `ac` count. Fewer is a FAIL. Any `unmet` or `extra` above zero
  must appear as a Deviations subsection under act 5a, with one line per
  deviation.
- **Nothing was committed.** `git log` shows no commit made by the ceremony. A
  commit inside a ceremony turn is a Major non-conformity: the working tree is
  the artifact under review, and committing it removes the thing the signatures
  were about.

### C-7 · Condition disposition

C-7.<n> · condition <n> · <MUST | SHOULD | NICE> · <applied | waived | carried | ABSENT> · <PASS | FAIL>

Every `CEREMONY-CONDITION:` line in `ticket.md` has a `Disposition:` line
answering it in the act 4 that quoted it. A missing disposition is a FAIL. So is
a `carried` disposition with no matching action item in act 8, and a `MUST` or
`SHOULD` waived with a reason that says nothing — "not needed" is not a reason,
"the variable does not exist in this stylesheet and adding it is a separate
change" is.

### C-8 · Escalation completeness

C-8.<n> · blocked items <n> · escalation block <present | absent> · closing clause <present | absent> · <PASS | FAIL>

When any `CEREMONY-DOD:` line in `ticket.md` reads `BLOCKED`, the response for
that turn carries the escalation block and the `Verification: blocked
(escalated)` clause on its closing line. A turn that closed on a bare `Work
delivered: yes` with blocked verification is a FAIL, and the non-conformity is
Major: it is the control that stops unverifiable work being reported as done.

### C-10 · Loop integrity

C-10.<n> · <check> · <observed> · <expected> · <PASS | FAIL>

The ops lane and the sprint loop are machinery that writes to disk, so they are
audited against disk. Five checks, in this order:

- **The offset matches the rolls.** `.ceremony/sprint-offset` equals the number
  of sprint rolls this session's responses rendered. An offset that moved with
  no roll on the page, or a roll on the page with no offset, is a FAIL.
- **Every rendered id exists.** Every `CER-BL-` id quoted in a response is a
  line in `.ceremony/backlog.jsonl` or a pending row in
  `.ceremony/<ticket>/carry.jsonl`. An id that exists nowhere was written rather
  than collected, and that is a Major non-conformity: it promises the user a
  ticket that does not exist.
- **Every filed entry was rendered.** The reverse direction. A backlog entry
  filed during this session that no response ever named is a FAIL — a carried
  blocker the user was not told about is a promise made behind their back.
- **No kind outside the two.** Every entry's `"kind"` is `restore-verification`
  or `carried-condition`. No code path in the plugin writes a third, so a third
  is a FAIL against the record itself.
- **No sprint rolled carrying nothing.** For every roll, a `restore-verification`
  entry exists that was minted on the same devops return. `OPS-BLOCKED` and
  `OPS-NEEDS-CHANGE` both carry, whether the loop advanced or ended, so a roll
  with no entry beside it is a FAIL.

Also check the lane's own ordering: a `"role":"devops"` entry exists only where
a QA entry before it recorded a blocked check, and a `QA-PASS` that follows an
`OPS-RESTORED` carries `"attempt":2` with a `"bash"` count above zero. A re-run
that ran nothing is the cheapest way to fake convergence, and it is a Major
non-conformity when it happens.

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
