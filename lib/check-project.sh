#!/usr/bin/env bash
# Check that a project's state files are in the form the skills write them, so
# a malformed one is named at commit time rather than misread by a later skill.
# install.sh puts this at .agents/bin/check-project.sh. See D23.
#
#   check-project.sh [--staged] [DIR]    # DIR defaults to the current directory
#   check-project.sh --sources           # the declared format sources, for tests
#
# DIR is a part (it holds blueprint/context/) or a product root (it holds
# blueprint/orchestration.md); at a root every part one level down is checked
# too. --staged reads each file from git's index - what the commit will hold.
# One line per problem, naming the file and the skill that repairs it.
#
# Exit 0 clean, 1 with problems, 2 when it could not run. It checks only forms a
# skill or template already states, each declared below with the text it rests
# on, and a seam test holds every declaration to its source. Writes nothing.
set -uo pipefail

STAGED=0; DIR=""; SOURCES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --staged)  STAGED=1; shift ;;
    --sources) SOURCES=1; shift ;;
    --help|-h) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "Unknown option: $1" >&2; exit 2 ;;
    *)  DIR="$1"; shift ;;
  esac
done
command -v python3 >/dev/null 2>&1 || { echo "check-project.sh needs python3 - nothing was checked" >&2; exit 2; }

exec python3 - "${DIR:-$PWD}" "$STAGED" "$SOURCES" <<'PY'
import os, re, subprocess, sys
root, staged, sources_only = os.path.abspath(sys.argv[1]), sys.argv[2] == "1", sys.argv[3] == "1"

# check | skill that repairs it ("" when the fix is a move, not a skill's run)
#       | the state file whose writers must include that skill | source | text
SOURCES = [
    ("findings-heading", "review", "blueprint/context/findings.md", "skills/review.md",
     "### F-03 [P0] open - Session cookie is readable from JavaScript"),
    ("findings-status", "review", "blueprint/context/findings.md", "skills/review.md", "Move `fixed` to `closed`"),
    ("findings-status", "review", "blueprint/context/findings.md", "skills/review.md", "Set `accepted` only"),
    ("findings-status", "review", "blueprint/context/findings.md", "skills/review.md", "Set `deferred` the same way"),
    ("findings-status", "review", "blueprint/context/findings.md", "skills/review.md", "Set `invalid` only"),
    ("findings-status", "review", "blueprint/context/findings.md", "skills/review.md",
     "Record a risk worth tracking but unproven as `unverified`"),
    ("findings-file-line", "review", "blueprint/context/findings.md", "skills/review.md", "heading and one `File:` line"),
    ("findings-entry", "review", "blueprint/context/findings.md", "skills/review.md",
     "**The entry** goes in `blueprint/findings/F-03.md`"),
    ("findings-deferred", "review", "blueprint/context/findings.md", "skills/review.md",
     "its `Deferred to:` line goes under the heading too"),
    ("findings-unique", "review", "blueprint/context/findings.md", "skills/review.md",
     "IDs are sequential within the ledger, never reused"),
    ("needs-you-open", "", "", "template/blueprint/context/needs-you.md", "**Closed lines move to Done"),
    ("needs-you-line", "", "", "template/blueprint/context/needs-you.md", "**A line is at most 400 bytes.**"),
    ("spec-header", "spec", "blueprint/context/current-work.md", "skills/spec.md", "**Type:** Feature | Fix"),
    ("spec-header", "spec", "blueprint/context/current-work.md", "skills/spec.md", "**Verified:** not yet"),
    ("spec-header", "spec", "blueprint/context/current-work.md", "skills/spec.md", "**Reviewed:** not yet"),
    ("spec-header", "spec", "blueprint/context/current-work.md", "skills/spec.md", "**Full verify:** not yet"),
    ("spec-full-verify", "build", "blueprint/context/current-work.md", "skills/build.md",
     "`**Full verify:** 2026-03-02, 6f06b62b2f2c, "),
    ("spec-verified", "verify", "blueprint/context/current-work.md", "skills/verify.md",
     "`**Verified:** 2026-03-02, 6f06b62b2f2c, "),
    ("spec-reviewed", "review", "blueprint/context/current-work.md", "skills/review.md",
     "`**Reviewed:** 2026-03-02, 6f06b62b2f2c, "),
    ("context-budget", "", "", "lib/hook-context-budget.sh", "Context budget: [0-9]+ KB"),
    ("overview-cap", "distill", "blueprint/context/project-overview.md", "template/AGENTS.md",
     "at most 8 KB; it links, never restates"),
    ("full-verify", "", "", "template/AGENTS.md", "- Full verify: "),
    ("standards-verify", "setup", "blueprint/context/coding-standards.md",
     "template/blueprint/context/coding-standards.md", "Do not write either command in this file"),
    ("capability-claims", "ship", "blueprint/capabilities/", "lib/merge-capabilities.sh",
     'CLAIM = re.compile(rf"^- \\*\\*({NAME})\\.(\\d+)\\*\\* - (.*?) \\*Since:\\* (\\S+)(?: · \\*Changed:\\* (\\S+))?$")'),
    ("capability-claims", "ship", "blueprint/capabilities/", "lib/merge-capabilities.sh",
     'TOMB = re.compile(rf"^- ({NAME})\\.(\\d+) - removed by (\\S+)$")'),
    ("preflight-line", "preflight", "dev-notes/status.md", "skills/preflight.md",
     "`preflight: no-go, 2026-03-02, a1b2c3d - blockers F-12, F-14`"),
    ("status-uncommitted", "", "", "lib/seed-product-root.sh", "/blueprint/status/*.md"),
]
if sources_only:
    for s in SOURCES:
        print("|".join(s))
    sys.exit(0)

NAME = r"[a-z0-9][a-z0-9-]*"
CLAIM = re.compile(rf"^- \*\*({NAME})\.(\d+)\*\* - (.*?) \*Since:\* (\S+)(?: · \*Changed:\* (\S+))?$")
TOMB = re.compile(rf"^- ({NAME})\.(\d+) - removed by (\S+)$")
HEAD = re.compile(r"^### (F-\d+) \[(P[0-3])\] ([a-z]+) - \S")
STATUSES = {"unverified", "open", "fixed", "closed", "accepted", "deferred", "invalid"}
DATED = re.compile(r"^\d{4}-\d{2}-\d{2}, [0-9a-f]{7,40}, \S")
PREFLIGHT = re.compile(r"^preflight: (go|no-go), \d{4}-\d{2}-\d{2}, [0-9a-f]{7,40}( - \S.*)?$")
FIX = {s[0]: s[1] for s in SOURCES}
# The number in the needs-you-line declaration above, so the two cannot differ.
OVERVIEW_CAP = int(re.search(r"at most (\d+) KB", next(s[4] for s in SOURCES if s[0] == "overview-cap"))[1])
NEEDS_YOU_LINE = int(re.search(r"at most (\d+) bytes", next(s[4] for s in SOURCES if s[0] == "needs-you-line"))[1])

def git(*args, cwd=root):
    r = subprocess.run(["git", "-C", cwd, *args], capture_output=True, text=True)
    return r.stdout if r.returncode == 0 else None

top = (git("rev-parse", "--show-toplevel") or "").strip() or None
if staged and not top:
    print(f"{root}: --staged needs a git repository - nothing was checked", file=sys.stderr)
    sys.exit(2)
indexed = set((git("ls-files", "--cached", "-z", cwd=top) or "").split("\0")) if top else set()

def read(path):
    """A file's text as the commit would hold it, or None if it is not there."""
    if staged:
        rel = os.path.relpath(path, top)
        if rel not in indexed:
            return None
        r = subprocess.run(["git", "-C", top, "show", f":{rel}"], capture_output=True, text=True)
        return r.stdout if r.returncode == 0 else None
    return open(path, encoding="utf-8", errors="replace").read() if os.path.isfile(path) else None

def listdir(path):
    if staged:
        rel = os.path.relpath(path, top) + "/"
        return sorted({f[len(rel):].split("/")[0] for f in indexed if f.startswith(rel)})
    return sorted(os.listdir(path)) if os.path.isdir(path) else []

problems = []
def say(path, check, msg):
    fixer = FIX[check]
    problems.append(f"{os.path.relpath(path, root)}: {msg}" + (f" - fix with {fixer}" if fixer else ""))

def section(text, title):
    out, on = [], False
    for l in text.split("\n"):
        if l.startswith("## "):
            on = l.strip() == f"## {title}"
            continue
        if on:
            out.append(l)
    return out

def check_findings(part):
    idx = os.path.join(part, "blueprint/context/findings.md")
    text = read(idx)
    if text is None:
        return
    entries = set(listdir(os.path.join(part, "blueprint/findings")))
    backlog = read(os.path.join(part, "blueprint/findings/backlog.md")) or ""
    seen, lines = {}, text.split("\n")
    for n, l in enumerate(lines):
        if not l.startswith("### "):
            continue
        m = HEAD.match(l)
        if not m:
            say(idx, "findings-heading", f"line {n+1} is not '### F-NN [Px] <status> - <title>': '{l}'")
            continue
        fid, status = m[1], m[3]
        if status not in STATUSES:
            say(idx, "findings-status", f"{fid} has status '{status}', not one of {', '.join(sorted(STATUSES))}")
        if fid in seen:
            say(idx, "findings-unique", f"{fid} is listed twice")
        seen[fid] = True
        under = []
        for nxt in lines[n+1:]:
            if nxt.startswith("#"):
                break
            if nxt.strip():
                under.append(nxt.strip())
        if not under or not under[0].startswith("File:"):
            say(idx, "findings-file-line", f"{fid} has no File: line under its heading")
        if status == "deferred" and not any(u.startswith("Deferred to:") for u in under):
            say(idx, "findings-deferred", f"{fid} is deferred with no Deferred to: line under its heading")
        if f"{fid}.md" not in entries:
            say(idx, "findings-entry", f"{fid} has no entry at blueprint/findings/{fid}.md")
    for fid in re.findall(r"^### (F-\d+) ", backlog, re.M):
        if fid in seen:
            say(idx, "findings-unique", f"{fid} is in the index and in blueprint/findings/backlog.md")

def check_needs_you(part):
    p = os.path.join(part, "blueprint/context/needs-you.md")
    text = read(p)
    if text is None:
        return
    for l in section(text, "Open"):
        if re.match(r"^\s*- \[[xX]\]", l) or re.search(r"Status: (done|dropped)\b", l):
            say(p, "needs-you-open", f"a closed line is still under Open - move it to Done: '{l.strip()[:70]}'")
    # One entry is a bullet and the lines indented under it. Measured with its
    # whitespace collapsed, so wrapping and indentation cost nothing.
    entries = []
    for l in section(text, "Open"):
        if l.startswith("- "):
            entries.append(l)
        elif entries and l.startswith((" ", "\t")) and l.strip():
            entries[-1] += " " + l
        elif l.strip():
            entries.append("")  # prose or a comment: not part of the entry above
    for e in entries:
        size = len(" ".join(e.split()).encode())
        if size > NEEDS_YOU_LINE:
            say(p, "needs-you-line",
                f"an open line is {size} bytes, over {NEEDS_YOU_LINE} - every session loads it: keep what, whose,"
                f" what it blocks and status, and name the file that holds the steps: '{e.strip()[:60]}'")

def check_spec(part):
    p = os.path.join(part, "blueprint/context/current-work.md")
    text = read(p)
    if text is None:
        return
    first = next((l for l in text.split("\n") if l.startswith("# ")), "")
    if first.strip() == "# Current work":
        return
    if not re.match(r"^# (Feature|Fix): \S", first):
        say(p, "spec-header", f"neither the reset stub nor a spec: its title is '{first.strip()}'")
        return
    for field in ("Type", "Verified", "Reviewed"):
        m = re.search(rf"^\*\*{field}:\*\* *(.*)$", text, re.M)
        if not m:
            say(p, "spec-header", f"the spec has no **{field}:** line")
        elif field != "Type" and m[1].strip() != "not yet" and not DATED.match(m[1].strip()):
            say(p, "spec-verified" if field == "Verified" else "spec-reviewed",
                f"**{field}:** is neither 'not yet' nor '<date>, <fingerprint>, <result>': '{m[1].strip()}'")
    # A spec written before this line existed has none, and that is not a
    # problem: ship then has no recorded run to reuse and runs full verify.
    m = re.search(r"^\*\*Full verify:\*\* *(.*)$", text, re.M)
    if m and m[1].strip() != "not yet" and not DATED.match(m[1].strip()):
        say(p, "spec-full-verify",
            f"**Full verify:** is neither 'not yet' nor '<date>, <fingerprint>, <result>': '{m[1].strip()}'")

def check_budget(d, required=False):
    claude, agents = read(os.path.join(d, "CLAUDE.md")), read(os.path.join(d, "AGENTS.md"))
    if claude is None or agents is None:
        return
    m = re.search(r"^\*\*Context budget: ([0-9]+) KB\.\*\*", agents, re.M)
    total = len(claude.encode())
    for imp in re.findall(r"^@(.+)$", claude, re.M):
        t = read(os.path.join(d, imp))
        total += len(t.encode()) if t is not None else 0
    if not m and required:
        # A part's AGENTS.md from before the line existed: with nothing to hold
        # the total to, saying nothing would read as within budget.
        say(os.path.join(d, "AGENTS.md"), "context-budget",
            f"states no context budget, so the {total} bytes CLAUDE.md loads are held to nothing"
            " - add a '**Context budget: N KB.**' line (install.sh names the pack's)")
    if m:
        if total > int(m[1]) * 1024:
            say(os.path.join(d, "CLAUDE.md"), "context-budget",
                f"what it loads is {total} bytes, over the {m[1]} KB budget in AGENTS.md - run progress")
    cap = re.search(r"project-overview\.md` \|[^|\n]*at most ([0-9]+) KB", agents)
    ov = read(os.path.join(d, "blueprint/context/project-overview.md"))
    # An AGENTS.md from before the cap was written states none. Passing it then
    # let one several times the cap through; hold it to the pack's.
    limit = int(cap[1]) if cap else (OVERVIEW_CAP if required else None)
    if limit and ov is not None and len(ov.encode()) > limit * 1024:
        say(os.path.join(d, "blueprint/context/project-overview.md"), "overview-cap",
            f"{len(ov.encode())} bytes, over its {limit} KB cap"
            + ("" if cap else " - AGENTS.md states none, so this is the pack's"))
    # Verify runs after every build step. With no second line the browser and
    # database suites have nowhere to go but into it.
    if required and re.search(r"^- Verify:", agents, re.M) and not re.search(r"^- Full verify:", agents, re.M):
        say(os.path.join(d, "AGENTS.md"), "full-verify",
            "records a Verify command and no '- Full verify:' line - add one under Commands"
            " (setup settles it): Verify, then every test that needs a browser, a database or a service")

def check_standards(part):
    """The verify commands live in AGENTS.md. A copy in the standards file that
    no longer matches is a second definition, and that file says it wins."""
    p = os.path.join(part, "blueprint/context/coding-standards.md")
    text, agents = read(p), read(os.path.join(part, "AGENTS.md"))
    if text is None or agents is None:
        return
    declared = set()
    for m in re.finditer(r"^- (?:Verify|Full verify): *(.+)$", agents, re.M):
        ticks = re.search(r"`([^`]+)`", m[1])
        whole = (ticks[1] if ticks else m[1]).strip()
        declared.add(whole)
        # A part of a recorded command is recorded: "pnpm e2e" beside a full
        # verify of "pnpm verify && pnpm e2e" is a matching copy, not a second one.
        declared.update(x.strip() for x in re.split(r"&&|;", whole) if x.strip())
    if not declared:
        return
    body = re.sub(r"<!--.*?-->", "", "\n".join(section(text, "Verify command")), flags=re.S)
    for cmd in re.findall(r"`([^`]+)`", body):
        if " " in cmd.strip() and cmd.strip() not in declared:
            say(p, "standards-verify",
                f"its Verify command section says '{cmd.strip()}', which is neither command AGENTS.md"
                " records nor a part of one - the commands live in AGENTS.md only; remove the copy")
            return

def check_capabilities(part):
    cdir = os.path.join(part, "blueprint/capabilities")
    for f in listdir(cdir):
        if not f.endswith(".md"):
            continue
        cap, p = f[:-3], os.path.join(cdir, f)
        text = read(p) or ""
        ids = {}
        looks = re.compile(rf"^- (\*\*)?{re.escape(cap)}\.\d+\b")
        for l in text.split("\n"):
            m = CLAIM.match(l) or TOMB.match(l)
            if m and m[1] == cap:
                if m[2] in ids:
                    say(p, "capability-claims", f"{cap}.{m[2]} appears twice")
                ids[m[2]] = True
            elif looks.match(l):
                say(p, "capability-claims", f"a claim line the merge script cannot read: '{l[:70]}'")

def check_preflight(d):
    p = os.path.join(d, "dev-notes/status.md")
    text = read(p)
    if text is None:
        return
    lines = [l for l in text.split("\n") if l.startswith("preflight:")]
    for l in lines:
        if not PREFLIGHT.match(l):
            say(p, "preflight-line", f"not in the form deploy reads: '{l[:70]}'")
    if len(lines) > 1:
        say(p, "preflight-line", f"{len(lines)} preflight: lines - each verdict replaces the last")

def check_part(part):
    check_findings(part); check_needs_you(part); check_spec(part)
    check_budget(part, required=True); check_standards(part); check_capabilities(part); check_preflight(part)

is_root = os.path.isfile(os.path.join(root, "blueprint/orchestration.md"))
if is_root:
    check_budget(root); check_preflight(root)
    if top:
        rel = os.path.relpath(root, top)
        pre = "" if rel == "." else rel + "/"
        for f in sorted(indexed):
            if f.startswith(pre + "blueprint/status/") and not f.endswith("/.gitkeep"):
                problems.append(f"{f[len(pre):]}: live part state is never committed (blueprint/orchestration.md) - git rm --cached it")
    for d in sorted(os.listdir(root)):
        if os.path.isdir(os.path.join(root, d, "blueprint/context")) and not d.startswith("."):
            check_part(os.path.join(root, d))
elif os.path.isdir(os.path.join(root, "blueprint/context")):
    check_part(root)
else:
    print(f"{root}: not a project part or a product root - nothing was checked", file=sys.stderr)
    sys.exit(2)

for p in problems:
    print(p)
sys.exit(1 if problems else 0)
PY
