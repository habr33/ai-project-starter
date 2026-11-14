#!/usr/bin/env bash
# Claude Code PreToolUse hook on Bash, installed by `install.sh --hooks` as
# .claude/hooks/hook-main-commit.sh. See D20.
#
# A `git commit` on `main` or `master` makes Claude Code ask the person, rather
# than trusting the model to remember "Never build on `main`". It asks instead of
# refusing because some commits on `main` are the workflow's own: the setup
# commits `scaffold`, `ci`, `distill` and `prototype` make, and `ship`'s squash.
#
# A commit on `main` holding only workflow state - blueprint/, dev-notes/,
# CHANGELOG.md, the files AGENTS.md's tables declare - says nothing: it is a
# skill's record of its own run, and asking for it twice is what people stopped
# reading (D24). A plain push of `main` is allowed outright where the committed
# AGENTS.md says `**Push main without asking:** yes`; any other push is left to
# Claude Code's own permission rules.
#
# Where `install.sh --git-hooks` made .agents/git-hooks the active hooksPath
# (D23), it also denies the two ways past that hook: a commit with --no-verify
# or -n, and a change to core.hooksPath. Deny, not ask - no skill needs either.
#
# It fails open: input it cannot read, no python3, or no repository, and it
# prints nothing - a guard that breaks every shell call is worse than none.
command -v python3 >/dev/null 2>&1 || exit 0
exec python3 -c '
import json, os, re, shlex, subprocess, sys
from shlex import shlex as Lexer
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
def segments(text):
    # The commands of a line, quoting respected: a message holding `; ` or `&&`,
    # or a heredoc inside "$(...)", stays one word.
    try:
        lex = Lexer(text, posix=True, punctuation_chars="();<>|&\n")
        lex.whitespace = " \t\r"
        lex.whitespace_split = True
        toks = list(lex)
    except ValueError:
        return None
    segs, cur = [], []
    for t in toks:
        if t and all(c in "();<>|&\n" for c in t):
            segs.append(cur)
            cur = []
        else:
            cur.append(t)
    segs.append(cur)
    return [g for g in segs if g]
def git_call(seg):
    if not seg or seg[0] != "git":
        return None
    where, i = call.get("cwd") or ".", 1
    while i < len(seg) and seg[i].startswith("-"):
        if seg[i] in ("-C", "-c") and i + 1 < len(seg):
            if seg[i] == "-C":
                where = os.path.join(where, seg[i + 1])
            i += 2
        else:
            i += 1
    return (where, seg[i], seg[i + 1:]) if i < len(seg) else None
def raw(where, *args):
    try:
        return subprocess.run(["git", "-C", where, *args], capture_output=True, text=True).stdout
    except Exception:
        return ""
def changed(where, specs):
    out = raw(where, "-c", "status.relativePaths=false", "status", "--porcelain", "-z", "-uall", "--", *specs)
    names, it = set(), iter(out.split("\0"))
    for e in it:
        if len(e) > 3:
            names.add(e[3:])
            if e[0] in "RC":
                names.add(next(it, ""))
    return names
# Workflow state, as the tables in AGENTS.md declare it: every file there lives
# under blueprint/ or dev-notes/, or is CHANGELOG.md - at the top, or in a part.
STATE = re.compile(r"(?:blueprint|dev-notes)/.+|CHANGELOG\.md")
def is_state(path, top):
    if STATE.fullmatch(path):
        return True
    part, _, rest = path.partition("/")
    return bool(STATE.fullmatch(rest)) and os.path.isdir(os.path.join(top, part, "blueprint", "context"))
ADD_FLAGS = {"-A", "--all", "-u", "--update", "-f", "--force", "-v", "--verbose", "-N", "--intent-to-add"}
def commit_files(segs, where):
    # What the commit would hold, or None when the line does anything else -
    # a cd, a merge, an rm - that could change it out of sight.
    top = git_in(where, "rev-parse", "--show-toplevel")
    if not top or segs is None:
        return None
    files = {f for f in raw(where, "diff", "--cached", "--name-only", "-z").split("\0") if f}
    for seg in segs:
        g = git_call(seg)
        if not g or os.path.realpath(g[0]) != os.path.realpath(where):
            return None
        _, sub, args = g
        if sub == "add":
            if any(a.startswith("-") and a != "--" and a not in ADD_FLAGS for a in args):
                return None
            files |= changed(where, [a for a in args if not a.startswith("-")] or [":/"])
        elif sub == "commit":
            specs, it = [], iter(args)
            for t in it:
                if t in ("--amend", "-p", "--patch", "--interactive") or t.startswith("--pathspec"):
                    return None
                if t in VALUED:
                    next(it, None)
                elif t == "--all" or (t.startswith("-") and not t.startswith("--")
                                      and "a" in re.split(r"[mFcCtS]", t[1:])[0]):
                    files |= {f for f in raw(where, "diff", "--name-only", "-z").split("\0") if f}
                elif not t.startswith("-"):
                    specs.append(t)
            if specs:
                files |= changed(where, specs)
        else:
            return None
    return files, top
# A plain push of main is let through when the project has said so in the
# committed AGENTS.md - a working-tree edit cannot grant it. One command and
# nothing else on the line: anything more, and Claude Code asks as it would.
def push_allowed(segs):
    if segs is None or len(segs) != 1:
        return False
    g = git_call(segs[0])
    if not g or g[1] != "push":
        return False
    where, _, args = g
    branch = git_in(where, "branch", "--show-current")
    # Any other flag lands in pos, where it is neither a remote nor main.
    pos = [a for a in args if a not in ("-q", "--quiet")]
    if branch not in ("main", "master") or len(pos) > 2:
        return False
    if pos and pos[0] not in git_in(where, "remote").split():
        return False
    if len(pos) == 2 and pos[1] not in (branch, "HEAD", branch + ":" + branch):
        return False
    if len(pos) < 2 and git_in(where, "config", "push.default") not in ("", "simple", "current", "upstream"):
        return False
    top = git_in(where, "rev-parse", "--show-toplevel")
    agents = os.path.join(os.environ.get("CLAUDE_PROJECT_DIR") or where, "AGENTS.md")
    rel = os.path.relpath(os.path.realpath(agents), os.path.realpath(top or "/"))
    if not top or rel.startswith(".."):
        return False
    return bool(re.search(r"^ *\*\*Push main without asking:\*\* *yes\b",
                          git_in(top, "show", "HEAD:" + rel), re.M | re.I))
segs = segments(cmd)
if push_allowed(segs):
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "permissionDecisionReason":
            "A plain push of main, which AGENTS.md says needs no asking."}}))
    sys.exit(0)
# git, then only its own options, then the commit subcommand - so
# `git log --grep commit` is not a commit, and `git -c k=v commit` is.
m = re.search(r"(?:^|[\s;&|(])git((?:\s+(?:-[Cc]\s+\S+|--?[\w-]+(?:=\S+)?))*)\s+commit(?=\s|$)", cmd)
if not m:
    sys.exit(0)
where = repo(m.group(1))
branch = git_in(where, "branch", "--show-current")
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
# Workflow state alone is the record a skill keeps of its own run, committed without
# asking (AGENTS.md); a commit holding anything else still asks.
held = commit_files(segs, where)
if held and held[0] and all(is_state(f, held[1]) for f in held[0]):
    sys.exit(0)
other = sorted(f for f in held[0] if not is_state(f, held[1]))[:3] if held else []
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason":
        "A commit on " + branch
        + (" holding more than workflow state: " + ", ".join(other) if other else "")
        + ". AGENTS.md: Never build on `main`. Setup "
        "commits and ship'"'"'s merge belong here - if this is one and the person "
        "declines, leave it uncommitted and say so; never move it to a branch. "
        "Anything else belongs on a branch."}}))
'
