---
description: Convene the Reviewer to check the change against the accepted criteria
argument-hint: "[ticket id; defaults to the ticket in the turn state]"
---

Convene the Reviewer.

## 1. Establish what is being reviewed

The ticket is `$ARGUMENTS`. If no argument was given, use the ticket id from the
injected turn state.

Run `git diff` and `git status --porcelain` yourself before convening anything.
You are the second pair of eyes in the chain and your reading is recorded; a
review turn where the chair never opened the diff is a review of a description.

If the working tree is clean and nothing was implemented this session, say so in
one line and render act 5a as `Nothing to review — the tree is clean.` Do not
convene the agent to tell you that.

## 2. Convene the Reviewer

Call the Agent tool with `subagent_type` `ceremony:reviewer`. Hand it the ticket
path and nothing else. The criteria live in `.ceremony/<TICKET>/ticket.md` and
the Reviewer reads them there — restating them in the brief is how a review
comes back agreeing with the caller instead of with the record.

Do not conduct the review yourself, and do not tell the Reviewer what you
expect it to find.

## 3. Render act 5a

One `CEREMONY-CRIT:` line per criterion, in the Reviewer's numbering, transcribed
as it came back — `MET`, `UNMET`, or `EXTRA` for a change nothing asked for.

The count matters and is checked: the number of criterion lines equals the number
of `CEREMONY-AC:` lines the Product Owner accepted. A reviewer that answered
fewer has not finished, and the turn says so rather than rounding up.

## 4. Deviations

If the verdict is `REV-DEVIATES`, or any line reads `UNMET` or `EXTRA`, act 5a
carries a **Deviations** subsection with one line per deviation, and the Product
Owner's sign-off line is withheld on that turn. Acceptance is a statement that
the change matches what was asked for; while a deviation stands, that statement
is not available.

## 5. What the Reviewer does not do

It does not run the tests, the build or the linter — that is QA's, in act 6, and
a reviewer that runs them is doing someone else's job with none of their tools.
It does not edit anything. It does not approve the change; `REV-MATCHES-CRITERIA`
signs for conformance to the criteria and for nothing else.

## 6. Close

The Reviewer's four verdicts: `REV-MATCHES-CRITERIA`, `REV-DEVIATES`,
`REV-INCOMPLETE`, `REV-NOTHING-TO-REVIEW`. Only the first signs.

`REV-INCOMPLETE` wins over `REV-DEVIATES` when both apply: a review that could
not see everything cannot report what deviated.
