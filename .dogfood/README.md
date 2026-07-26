# Dogfood Claude Code config

This directory (`config/`) is a dedicated `CLAUDE_CONFIG_DIR` for "dogfooding"
Claude Code sessions. It is separate from a developer's normal `~/.claude` (or
`$CLAUDE_CONFIG_DIR`) so that every dogfood run gets its own, complete,
persistent transcript trail instead of mixing into personal session history.

## Usage

Prefix any dogfood run with:

```
CLAUDE_CONFIG_DIR=/srv/handgemacht/handgemacht/ceremony/.dogfood/config claude ...
```

For example:

```
CLAUDE_CONFIG_DIR=/srv/handgemacht/handgemacht/ceremony/.dogfood/config claude -p "your prompt" --model claude-haiku-4-5
```

## What's in `config/`

- `.credentials.json` — OAuth credentials copied from the operator's live
  config, used for headless auth. Local-only, never committed.
- `.claude.json` — minimal state (incl. a `hasTrustDialogAccepted` entry for
  the repo root) so headless runs don't hit onboarding/trust-dialog prompts.
  The CLI also writes its own runtime state (feature-flag cache, etc.) into
  this file as it runs — that's expected.
- `projects/`, `sessions/` — written automatically by the CLI on each run.
  This is the whole point of this directory: every dogfood session's full
  transcript (prompts, responses, tool calls) lands here, isolated and kept.

## Credentials are local-only

`.credentials.json` (and anything else under `config/` that looks like
secrets or tokens) must never be committed. The ceremony repo gitignores
this directory's sensitive contents — verify a `.gitignore` entry exists
before adding anything here to version control.
