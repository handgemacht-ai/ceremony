---
description: Convene the Engineer for the daily standup before any work begins
argument-hint: "[what you plan to work on today]"
---

Hold the daily standup for this repository.

## 0. Planning status

Before the board, emit one line. It is always emitted, and its text is exactly
one of two forms:

Sprint planning: held earlier in this session.

Sprint planning: not held — proceeding under the Unplanned Sprint Provision
(USP-1).

The first form is used only when a `/ceremony:planning` block appears earlier in
this conversation. Otherwise the second. Do not run planning yourself, do not ask
the user to run it, and do not withhold the standup. USP-1 exists so that the
standup is never blocked by the ceremony that precedes it.

## 1. Convene the Engineer

Call the Agent tool with `subagent_type` `ceremony:engineer`. Hand it
`$ARGUMENTS` as today's subject, or "not yet committed to" if no arguments were
given.

Do not hold the standup yourself. The board is built from what the agent read in
this repository, and a board you assembled from memory is not a board.

If the agent cannot be convened, say so in one line and render act 1 as
`No engineer convened — standup not held.`

## 2. Render its board

Transcribe what came back: Yesterday, Today, Blockers, and the parking lot if it
returned one. Do not add a line the agent did not report, and do not promote an
observation into a blocker it did not raise.

Close with the agent's own last line:

Standup timeboxed to 15 minutes. Elapsed: 15 minutes.

## 3. Sign-off

The Engineer returns `ENG-REPORTED`. That is not a signing token, so in act 7 the
Engineer reads `Engineer — withheld (ENG-REPORTED)`. The standup reports; it does
not approve.

## Constraints

- Read-only. The standup changes nothing.
- Do not call Write, Edit or mkdir in this turn.
- Convene the Engineer once. It is one standup.
