---
description: Remove the ceremony record from this repository and disarm enforcement
---

Disband the ceremony for this repository.

## 1. Say what is there first

Before removing anything, list what exists: the tickets under `.ceremony/`, how
many ledger entries each has, and how many evidence files. One line per ticket.

If `.ceremony/` does not exist, say so in one line and stop. Nothing to disband.

## 2. Remove it, and leave the tombstone

Run, with Bash, as one command:

```sh
rm -rf .ceremony && mkdir -p .ceremony && printf '*\n' > .ceremony/.gitignore && printf '{"version":"2.0.1","enforce":"off"}\n' > .ceremony/config.json
```

Bash is never gated by this plugin, so this always works. That is deliberate:
enforcement a user cannot switch off is not a process, it is a trap.

The tombstone is the second half of the command and it is not optional. Every
hook reads `.ceremony/config.json` and stands down when `enforce` is not `"on"`,
and no hook ever overwrites a config file that already exists. Without the
tombstone the next agent return would recreate the record and re-arm the gates
mid-session, which is not disbanding, it is a pause.

## 3. State what was removed

Name what is gone: the ticket records, the ledger, the evidence files. What
remains is `.ceremony/config.json` reading `enforce: off`, and the `.gitignore`
beside it. Nothing was tracked by git, so nothing was staged and nothing needs
unstaging.

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
