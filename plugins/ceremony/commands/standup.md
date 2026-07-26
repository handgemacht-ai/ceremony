---
description: Run the daily standup for this repository before any work begins
argument-hint: "[what you plan to work on today]"
---

Hold the daily standup for this repository. The board is built from real
repository facts, never from imagination.

## 1. Gather the facts (read-only)

Collect, using read-only commands only:

- commits from roughly the last 24 hours (`git log --since="24 hours ago"`),
- the working tree state (`git status --short`),
- the current branch,
- stashes (`git stash list`),
- commits ahead of the upstream branch, if an upstream exists.

Do not modify anything. Do not fetch, pull, checkout, stage or commit.

## 2. Open the standup

One line, in the Scrum Master's voice. Name the repository and the branch.

## 3. The board

Three sections, each a short list:

- **Yesterday** — what the commits from the last day actually say. Subject lines,
  condensed. If there are no commits, say there are no commits.
- **Today** — `$ARGUMENTS`. If no arguments were given, write
  "not yet committed to".
- **Blockers** — only from observable signals: uncommitted changes, stashes,
  unpushed commits, a detached HEAD, a merge or rebase in progress. If none of
  those are present, the answer is "none".

## 4. Parking lot

Anything interesting you noticed while gathering facts that does not belong in
the standup — a stale branch, a large uncommitted diff, a stash from last month.
One line each. Omit the section if there is nothing to park.

## 5. Close

End with exactly:

Standup timeboxed to 15 minutes. Elapsed: 15 minutes.

## Constraints

- Read-only. The standup changes nothing.
- Never invent activity. An empty board is a valid board.
- If this is not a git repository, say so plainly in one line, then hold the
  standup anyway with an empty board.
