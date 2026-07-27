#!/bin/sh
# ceremony :: PreToolUse Bash
# Three refusals, all narrow. Bash is otherwise ungated on purpose: enforcement
# a user cannot switch off is a trap, and /ceremony:disband has to work.
#
# 1. The ceremony never commits. The working tree is the artifact every
#    signature in act 7 is about, and a commit turns the reviewed thing into
#    history while leaving the user holding something else. Until v2.2.1 that
#    stance was documented and checked after the fact; a turn that had already
#    spent its correction budget shipped a commit anyway. It is a refusal now.
# 2. An obstacle is a finding, not a task. An engineer that chmods a read-only
#    file and edits it anyway has removed the one signal the ticket had.
# 3. The ops lane restores through the project's own mechanisms or not at all.
#    An agent told to make verification work has standing motive to kill the
#    thing in the way and to install its way around it, and both of those
#    produce an environment the project does not describe. Killing is refused
#    to every agent, because the process manager owns those processes; the
#    system package managers are refused to the role that would reach for them.
set -u
trap 'exit 0' EXIT

RAW=$(cat 2>/dev/null) || RAW=''

jget() {
  printf '%s' "$RAW" | awk -v k="$1" '
    BEGIN { RS = "\1" }
    {
      key = "\"" k "\":\""
      i = index($0, key)
      if (i == 0) exit
      off = i + length(key); n = length($0); out = ""
      for (j = off; j <= n; j++) {
        c = substr($0, j, 1)
        if (c == "\\") {
          d = substr($0, j + 1, 1)
          if (d == "n") out = out "\n"
          else if (d == "t") out = out "\t"
          else if (d == "r") out = out ""
          else if (d == "u") { out = out "?"; j = j + 4 }
          else out = out d
          j++
        } else if (c == "\"") break
        else out = out c
      }
      printf "%s", out
    }' 2>/dev/null
}

deny() {
  printf '%s\n' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$1\"}}"
  exit 0
}

CMD=$(jget command)
[ -n "$CMD" ] || exit 0

SID=$(jget session_id)
[ -n "$SID" ] || exit 0
CWD=$(jget cwd)
[ -n "$CWD" ] || CWD=$(pwd 2>/dev/null) || exit 0

# --- is enforcement armed? --------------------------------------------------
# Unarmed, disbanded, or switched off in the environment: this hook has nothing
# to say. The tombstone command in /ceremony:disband runs after config.json
# already reads "off", and it names no git verb in any case.
[ -f "$CWD/.ceremony/config.json" ] || exit 0
grep -q '"enforce":[ ]*"on"' "$CWD/.ceremony/config.json" 2>/dev/null || exit 0
[ "${CEREMONY_ENFORCE:-on}" = off ] && exit 0

DATA="${CLAUDE_PLUGIN_DATA:-}"
[ -n "$DATA" ] || DATA="${TMPDIR:-/tmp}/ceremony-plugin-data"
[ -f "$DATA/sessions/$SID.env" ] || exit 0
[ -f "$DATA/sessions/$SID.disbanding" ] && exit 0

AID=$(jget agent_id)
[ -n "$AID" ] || AID=$(jget agentId)
case "$AID" in *[!A-Za-z0-9._-]*) AID='' ;; esac

ATYPE=$(jget agent_type)
[ -n "$ATYPE" ] || ATYPE=$(jget agentType)
[ -n "$ATYPE" ] || ATYPE=$(jget subagent_type)
case "$ATYPE" in *[!A-Za-z0-9:._-]*) ATYPE='' ;; esac

# --- what is this command about to run? -------------------------------------
# Tokenised rather than matched as a substring, because the two are not the
# same question. `git log --all | grep add` names no subcommand; `git -C x
# commit -m "add"` names one. The scan walks each bare `git` token forward past
# its global flags and reads the first word that is not one - which is the
# subcommand, and the only thing this gate judges.
VERB=$(printf '%s' "$CMD" | tr '\n' ' ' | awk '
  {
    n = split($0, t, /[ \t]+/)
    for (i = 1; i <= n; i++) {
      w = t[i]
      sub(/^[;&|()`$]+/, "", w)
      if (w == "git") {
        j = i + 1
        while (j <= n) {
          v = t[j]
          if (v == "-C" || v == "-c" || v == "--git-dir" || v == "--work-tree" ||
              v == "--exec-path" || v == "--namespace" || v == "--super-prefix") { j += 2; continue }
          if (substr(v, 1, 1) == "-") { j++; continue }
          break
        }
        if (j <= n) {
          v = t[j]
          if (v == "commit" || v == "push" || v == "merge" || v == "rebase" ||
              v == "add" || v == "am" || v == "cherry-pick" || v == "revert" ||
              v == "stage") { print v; exit }
        }
        i = j
      }
    }
  }' 2>/dev/null)

if [ -n "$VERB" ]; then
  deny "git $VERB is not available in a ceremony turn. This ceremony never commits, stages, pushes, merges or rebases, and the refusal is the same for you as for every agent in it.\\n\\nThree reasons, in order of how much they matter. Committing is the user's decision, and it is the one decision in this process that was never delegated. The working tree is the artifact under review - every signature in act 7 is about a diff that is still a diff, and a commit turns the reviewed thing into history. And the rollback the board writes down is only true while the change is uncommitted.\\n\\nThis refuses the commit and nothing else. **The work itself is not blocked and the ticket is not blocked.** Carry on exactly as you would have: the change stays in the working tree, the reviewing roles read it there, the engineer's verdict is ENG-IMPLEMENTED if it implemented something, act 5 quotes the files and lines it actually changed, and the closing line ends \\\"Work delivered: yes \\\\u00b7 Committed: no (the tree is yours)\\\". A turn that reports 0 files and \\\"Work delivered: no\\\" because of this message has mistaken a refused commit for a failed ticket. Add one sentence at the end of act 5 saying the commit was not made and why, and finish the ceremony.\\n\\nIf an acceptance criterion asked for a commit, it was out of scope and the record already says so.\\n\\nIf the user wants this committed, they will commit it, or ask for it outside the ceremony: /ceremony:disband removes the record, CEREMONY_ENFORCE=off disarms the gates, /hooks turns the hooks off."
fi

# --- an obstacle is a finding ------------------------------------------------
# Scoped to agents, and to these two commands. The chair may still need them for
# ordinary work outside the change, and the chair is not the one whose account
# of the change everybody else is relying on.
if [ -n "$AID" ]; then
  PERM=$(printf '%s' "$CMD" | tr '\n' ' ' | awk '
    {
      n = split($0, t, /[ \t]+/)
      for (i = 1; i <= n; i++) {
        w = t[i]
        sub(/^[;&|()`$]+/, "", w)
        if (w == "chmod" || w == "chown" || w == "chgrp") { print w; exit }
        if (w == "sudo") { print "sudo"; exit }
      }
    }' 2>/dev/null)
  if [ -n "$PERM" ]; then
    deny "$PERM is not available to an agent in this ceremony. A file you cannot write, a directory you cannot enter, a permission that is not yours - each of those is a finding about the ticket, and removing it removes the finding.\\n\\nReturn CEREMONY-VERDICT: ENG-BLOCKED with a CEREMONY-BLOCKED line naming the criterion, what you attempted and what stopped you. A blocked implementation is an ordinary outcome and it is reported without apology; work that only completed because the obstacle was taken away is not reported at all, and that is the difference."
  fi
fi

# --- the ops lane works through the project, or not at all -------------------
# Only a word in command position is judged. A substring scan would refuse
# `echo "don't kill the server"`, which names no verb at all - the same reason
# the git scan above walks tokens rather than matching text. A command position
# is the start of the command line or the word after a shell separator, past
# any environment assignments, wrappers and their flags.
if [ -n "$AID" ]; then
  HIT=$(printf '%s' "$CMD" | tr '\n' ';' | awk '
    {
      s = $0
      gsub(/\$\(/, " @ ", s)
      gsub(/[;|&()<>{}`]/, " @ ", s)
      n = split(s, t, /[ \t]+/)
      cmd = 1
      for (i = 1; i <= n; i++) {
        w = t[i]
        if (w == "") continue
        if (w == "@") { cmd = 1; continue }
        if (!cmd) continue
        if (w ~ /^[A-Za-z_][A-Za-z0-9_]*=/) continue
        if (substr(w, 1, 1) == "-") continue
        if (w ~ /^[0-9]/) continue
        if (w == "sudo" || w == "doas" || w == "command" || w == "nohup" ||
            w == "exec" || w == "env" || w == "time" || w == "timeout" ||
            w == "nice" || w == "ionice" || w == "xargs" || w == "stdbuf" ||
            w == "setsid") continue
        if (w == "kill" || w == "pkill" || w == "killall" || w == "killall5" ||
            w == "systemctl" || w == "service" || w == "launchctl") {
          print "KILL " w; exit
        }
        if (w == "fuser") {
          for (j = i + 1; j <= n && t[j] != "@"; j++)
            if (t[j] ~ /^-[A-Za-z]*k/) { print "KILL fuser -k"; exit }
          cmd = 0; continue
        }
        if (w == "docker" || w == "podman") {
          v = ""
          for (j = i + 1; j <= n && t[j] != "@"; j++) {
            if (t[j] == "" || substr(t[j], 1, 1) == "-") continue
            if (t[j] == "compose" || t[j] == "container" || t[j] == "stack") { v = ""; continue }
            v = t[j]; break
          }
          if (v == "kill" || v == "rm" || v == "stop" || v == "down") {
            print "KILL docker " v; exit
          }
          cmd = 0; continue
        }
        if (w == "apt" || w == "apt-get" || w == "aptitude" || w == "brew" ||
            w == "yum" || w == "dnf" || w == "pacman" || w == "apk" ||
            w == "zypper" || w == "snap" || w == "emerge" || w == "port") {
          print "PKG " w; exit
        }
        cmd = 0
      }
    }' 2>/dev/null)

  case "$HIT" in
    KILL\ *)
      V=${HIT#KILL }
      deny "$V is not available to an agent in this ceremony. The process manager owns those processes: this ceremony does not stop what it did not start, and killing a service to free a port removes the finding rather than the fault.\\n\\nBring it back through the project's own command instead - the justfile recipe, the Procfile entry, the compose file, the package script. If none of them brings it back, that is the answer: CEREMONY-OPS-NEXT: none and CEREMONY-VERDICT: OPS-BLOCKED, with one CEREMONY-OPS-TRIED line per command you actually ran. A blocked restoration is an ordinary outcome and it is reported without apology.\\n\\nThis refuses the command and nothing else. The ticket is not blocked by this message, and the ceremony continues from the verdict you return."
      ;;
    PKG\ *)
      V=${HIT#PKG }
      case "$ATYPE" in
        ceremony:devops)
          deny "$V is not a project mechanism, and this role works only through what the repository itself defines: the justfile, the Procfile, .mise.toml or .tool-versions, the package.json scripts, the Makefile, the compose file, the language manifest. Those are the seven, in that order, and there is no eighth.\\n\\nA dependency the project cannot install by its own instructions is a finding about the project, not a gap for you to fill by hand. Installing it from outside produces an environment the project does not describe, and a check that passes in that environment says nothing about this repository.\\n\\nIf the fix is a file - a version pin, a missing recipe, an engines field - that is CEREMONY-VERDICT: OPS-NEEDS-CHANGE with a CEREMONY-OPS-CHANGE line naming the file and the change. It becomes a ticket for ceremony:engineer, groomed and reviewed like any other. If there is no mechanism left, that is CEREMONY-OPS-NEXT: none and OPS-BLOCKED."
          ;;
      esac
      ;;
  esac
fi

exit 0
