#!/usr/bin/env bash
# Claude Code PreToolUse hook on Bash, installed by `install.sh --hooks` as
# .claude/hooks/hook-main-commit.sh. See D20.
#
# A `git commit` on `main` or `master` makes Claude Code ask the person, rather
# than trusting the model to remember "Never build on `main`". It asks instead of
# refusing because some commits on `main` are the workflow's own: the setup
# commits `scaffold`, `ci`, `context` and `prototype` make, and `ship`'s squash.
#
# It fails open: input it cannot read, no python3, or no repository, and it
# prints nothing - a guard that breaks every shell call is worse than none.
command -v python3 >/dev/null 2>&1 || exit 0
exec python3 -c '
import json, re, subprocess, sys
try:
    call = json.load(sys.stdin)
    cmd = call["tool_input"]["command"]
except Exception:
    sys.exit(0)
# git, then only its own options, then the commit subcommand - so
# `git log --grep commit` is not a commit, and `git -c k=v commit` is.
m = re.search(r"(?:^|[\s;&|(])git((?:\s+(?:-[Cc]\s+\S+|--?[\w-]+(?:=\S+)?))*)\s+commit(?=\s|$)", cmd)
if not m:
    sys.exit(0)
where = call.get("cwd") or "."
c = re.search(r"-C\s+(\S+)", m.group(1))
if c:
    where = c.group(1) if c.group(1).startswith("/") else where + "/" + c.group(1)
try:
    branch = subprocess.run(["git", "-C", where, "branch", "--show-current"],
                            capture_output=True, text=True).stdout.strip()
except Exception:
    sys.exit(0)
if branch not in ("main", "master"):
    sys.exit(0)
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason":
        "A commit on " + branch + ". AGENTS.md: Never build on `main`. Setup "
        "commits and ship'"'"'s merge belong here; anything else belongs on a branch."}}))
'
