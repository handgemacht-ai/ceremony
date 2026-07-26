---
description: Remove the ceremony record from this repository and disarm enforcement
---

Disband the ceremony for this repository.

## 1. Say what is there first

Before removing anything, list what exists: the tickets under `.ceremony/`, how
many ledger entries each has, and how many evidence files. One line per ticket.

If `.ceremony/` does not exist, say so in one line and stop. Nothing to disband.

## 2. Remove it

Run, with Bash:

```sh
rm -rf .ceremony
```

Bash is never gated by this plugin, so this always works. That is deliberate:
enforcement a user cannot switch off is not a process, it is a trap.

## 3. State what was removed

Name what is gone: the ticket records, the ledger, the evidence files. They were
not tracked by git — `.ceremony/.gitignore` contained `*` — so nothing was
staged, and nothing needs unstaging.

## 4. State what changed

- The write gate is disarmed. Edits no longer require a Product Owner.
- The convening gate is disarmed. A role may be convened again.
- The sign-off gate still runs, and with an empty ledger every act 7 line is
  `withheld (role not convened)`. That is the honest outcome, and it is correct.
- The output style is unchanged. The eight acts continue.

## 5. State how to come back

`/ceremony:grooming` convenes the Product Owner, the first agent return recreates
`.ceremony/`, and enforcement arms itself again.

The other ways out, for the record: `CEREMONY_ENFORCE=off` in the environment
disarms the gates without removing the record; `/hooks` turns the hooks off for
the session; `/output-style default` ends the ceremony; `/plugin uninstall
ceremony@ceremony` removes the plugin.

## Constraints

- Remove `.ceremony/` and nothing else. Do not touch `.git`, `.gitignore`, or
  any file the user wrote.
- Do not argue with the request and do not ask for confirmation. The user chose
  the ceremony; they may unchoose it.
