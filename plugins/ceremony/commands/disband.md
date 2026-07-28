---
description: Remove the ceremony record from this repository and disarm enforcement
---

Disband the ceremony for this repository.

## 0. This turn convenes nobody

**Agent budget for this turn: zero.** No standup, no grooming, no ADR, no
board, no QA. Not one `Agent` call, of any type, for any reason. The convening
gate refuses every one of them on a disband turn, and it is right to: an agent
return is what writes the record the user has just asked to have removed.

The work of this turn is three Bash commands at most — list, remove, read back
— and the sections below. Everything else is rendering.

The rendering is the eight acts, because this is a `/ceremony:*` command and
they all render that way. Acts 1, 2, 3, 4, 5a and 6 each say in one line that
the role was not convened. Act 5 holds the sections below in full. Act 7 is the
nine-line order with every convened role `withheld (role not convened)` — the
Engineer line reads `Engineer — not convened; makes no change and signs
nothing.` — plus the three fixed lines for the Team member, the Release Manager
and the Scrum Master. There is no chain line: no link of it ran. Act 8 is the
retrospective. The header is the one injected in the turn state, copied
verbatim, and the closing line is the standard one with `0 pts (not
estimated)`.

Reading an act's own line as an instruction to go and convene that role is the
one mistake this section exists to prevent. The acts are being reported, not
performed.

Every turn after this one keeps the eight-act shape too. Disbanding removes the
record and disarms the gates; it does not end the output style, so the acts
continue, unenforced, with every act 7 line withheld. `/output-style default`
is what ends the ceremony, and it is named in section 5.

## 1. Say what is there first

Before removing anything, list what exists: the tickets under `.ceremony/`, how
many ledger entries each has, and how many evidence files. One line per ticket.

If `.ceremony/` does not exist, say so in one line and stop. Nothing to disband.

## 2. Write the tombstone first, then remove the records

Run, with Bash, exactly this, as one command, copied verbatim:

```sh
mkdir -p .ceremony && printf '*\n' > .ceremony/.gitignore && printf '{"version":"2.3.2","enforce":"off"}\n' > .ceremony/config.json && find .ceremony -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} + && cat .ceremony/config.json
```

Bash is never gated by this plugin, so this always works. That is deliberate:
enforcement a user cannot switch off is not a process, it is a trap.

The order is the whole point and it is not to be rearranged. The tombstone is
written **before** anything is removed, so there is never an instant in which
`.ceremony/` exists without a config that reads `enforce: off`. Every hook
reads that file and stands down; no hook ever overwrites one that already
exists. `rm -rf .ceremony` on its own — the whole directory, tombstone and all
— is the failure this ordering prevents: it leaves a gap in which the next
agent return recreates the record with `enforce: "on"`, and the user who asked
to disband ends the turn more enforced than they started it.

`find … -type d` removes the ticket directories and leaves `config.json` and
`.gitignore` standing. The final `cat` is the verification read, and its output
goes in section 3. If it does not print `"enforce":"off"`, run the command
again before saying anything else; nothing has been disbanded until that line
has been read back.

## 3. State what was removed, and quote the read-back

Name what is gone: the ticket records, the ledger, the evidence files. What
remains is `.ceremony/config.json` and the `.gitignore` beside it. Quote the
line the final `cat` printed, so the claim and its evidence sit together.
Nothing was tracked by git, so nothing was staged and nothing needs unstaging.

## 4. State what changed

- The write gate is disarmed. Edits no longer require a Product Owner.
- The convening gate is disarmed. A role may be convened again.
- The sign-off gate is disarmed too, and nothing is recorded any more. With no
  ledger, every act 7 line is `withheld (role not convened)`. That is the honest
  outcome, and it is correct.
- The output style is unchanged. The eight acts continue, unenforced.

## 5. State how to come back

`/ceremony:grooming` is the only way back. It removes the tombstone before it
convenes the Product Owner, and the first agent return then recreates the
record. Nothing else re-arms enforcement: not an agent return, not an edit, not
a new ticket, not a new turn.

The other ways out, for the record: `CEREMONY_ENFORCE=off` in the environment
disarms the gates without removing the record; `/hooks` turns the hooks off for
the session; `/output-style default` ends the ceremony; `/plugin uninstall
ceremony@ceremony` removes the plugin.

## Constraints

- Touch `.ceremony/` and nothing else. Do not touch `.git`, the repository's own
  `.gitignore`, or any file the user wrote.
- Do not argue with the request and do not ask for confirmation. The user chose
  the ceremony; they may unchoose it.
- Zero `Agent` calls. Repeated here because it is the rule most easily lost
  between section 0 and the rendering of act 1.
