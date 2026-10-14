#!/usr/bin/env bash
# Claude Code PreToolUse hook on Bash, installed by `install.sh --hooks` as
# .claude/hooks/hook-main-commit.sh. See D20.
#
# A `git commit` on `main` or `master` makes Claude Code ask the person, rather
# than trusting the model to remember "Never build on `main`". It asks instead of
# refusing because some commits on `main` are the workflow's own: the setup
# commits `scaffold`, `ci`, `distill` and `prototype` make, and `ship`'s squash.
#
# Where `install.sh --git-hooks` made .agents/git-hooks the active hooksPath
# (D23), it also denies the two ways past that hook: a commit with --no-verify
# or -n, and a change to core.hooksPath. Deny, not ask - no skill needs either.
#
# It fails open: input it cannot read, no python3, or no repository, and it
# prints nothing - a guard that breaks every shell call is worse than none.
command -v python3 >/dev/null 2>&1 || exit 0
exec python3 -c '
import json, re, shlex, subprocess, sys
try:
    call = json.load(sys.stdin)
    cmd = call["tool_input"]["command"]
except Exception:
    sys.exit(0)
def git_in(where, *args):
    try:
        return subprocess.run(["git", "-C", where, *args], capture_output=True, text=True).stdout.strip()
    except Exception:
        return ""
def repo(opts):
    where = call.get("cwd") or "."
    c = re.search(r"-C\s+(\S+)", opts)
    if c:
        where = c.group(1) if c.group(1).startswith("/") else where + "/" + c.group(1)
    return where
def words(text):
    try:
        return shlex.split(text)
    except ValueError:
        return text.split()
# Options of commit that take a value, so `-m -n` is a message, not -n.
VALUED = {"-m", "-F", "-C", "-c", "-t", "--message", "--file", "--author", "--date",
          "--template", "--reuse-message", "--reedit-message", "--fixup", "--squash",
          "--cleanup", "--trailer"}
def skips_hook(args):
    it = iter(args)
    for t in it:
        if t == "--":
            return False
        if t in VALUED:
            next(it, None)
        elif t.startswith("--"):
            # git takes any unambiguous prefix; --no-ve is ambiguous with --no-verbose
            if len(t) >= 8 and "--no-verify".startswith(t):
                return True
        elif t.startswith("-"):
            for ch in t[1:]:
                if ch == "n":
                    return True
                if ch in "mFcCtS":     # takes the rest of the word as its value
                    break
    return False
def moves_hooks(args):
    if not any(t.lower() == "core.hookspath" for t in args):
        return False
    writes = {"--unset", "--unset-all", "--replace-all", "--add", "set", "unset"}
    values = [t for t in args if not t.startswith("-") and t.lower() != "core.hookspath"
              and t not in ("get",)]
    return bool(writes & set(args)) or bool(values)
SEG = re.compile(r"(?:^|[\s;&|(])git((?:\s+(?:-[Cc]\s+\S+|--?[\w-]+(?:=\S+)?))*)\s+(commit|config)(?=\s|$)([^;&|\n]*)")
for g in SEG.finditer(cmd):
    opts, sub, rest = g.groups()
    args = words(rest)
    bad = None
    if re.search(r"-c\s+core\.hookspath=", opts, re.I):
        bad = "sets core.hooksPath for one command"
    elif sub == "commit" and skips_hook(args):
        bad = "skips the pre-commit hook (--no-verify or -n)"
    elif sub == "config" and moves_hooks(args):
        bad = "changes core.hooksPath"
    if bad and git_in(repo(opts), "config", "core.hooksPath") == ".agents/git-hooks":
        print(json.dumps({"hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason":
                "This command " + bad + ". The project'"'"'s git pre-commit hook "
                "(.agents/git-hooks/pre-commit) checks the state files; fix what it "
                "names with the skill it names instead of going around it."}}))
        sys.exit(0)
# git, then only its own options, then the commit subcommand - so
# `git log --grep commit` is not a commit, and `git -c k=v commit` is.
m = re.search(r"(?:^|[\s;&|(])git((?:\s+(?:-[Cc]\s+\S+|--?[\w-]+(?:=\S+)?))*)\s+commit(?=\s|$)", cmd)
if not m:
    sys.exit(0)
branch = git_in(repo(m.group(1)), "branch", "--show-current")
# A branch created earlier in the same command is where the commit lands, though
# HEAD is still on main while this runs.
moves = re.findall(r"git\s+(?:switch|checkout)\s+(?:-q\s+)?(-c|-C|--create|-b|-B)?\s*([^\s;&|]+)", cmd[:m.start()])
if moves and moves[-1][0] and moves[-1][1] not in ("main", "master"):
    sys.exit(0)
# ...and a switch to main is, though HEAD is still on the branch.
if moves and moves[-1][1] in ("main", "master"):
    branch = moves[-1][1]
if branch not in ("main", "master"):
    sys.exit(0)
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason":
        "A commit on " + branch + ". AGENTS.md: Never build on `main`. Setup "
        "commits and ship'"'"'s merge belong here - if this is one and the person "
        "declines, leave it uncommitted and say so; never move it to a branch. "
        "Anything else belongs on a branch."}}))
'
