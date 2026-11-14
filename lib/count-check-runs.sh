#!/usr/bin/env bash
# Count how often a project's checks actually ran, from Claude Code's session
# logs. The skills say when a check runs; this is the only thing here that
# shows whether an agent did that. Reads, never writes.
#
#   lib/count-check-runs.sh [--project DIR] [--logs DIR] [--since DATE] [--until DATE]
#
# --project   where AGENTS.md is (default: the current directory)
# --logs      the session logs (default: Claude Code's directory for --project)
# --since, --until   ISO dates or times, to count one item's work
#
# The commands come from the Verify, Full verify and Test lines of AGENTS.md,
# each split at && and ; - so a full verify written as "verify, then the browser
# tests" is counted by its parts, and a part run alone is still seen.
#
# One row per part:
#   runs        Bash calls that ran it, each tool call counted once - a log
#               repeats records, and a count that does not de-duplicate reads high
#   main        of those, made by a main session
#   handed off  of those, made by a subagent
#   same tree   of those, made with no edit since the last run of the same
#               part, in any session - the same check on the same tree
#   named       of those, given a file or a test name, not the whole suite
#
# "same tree" is an estimate: an edit is an editing tool call, or a shell
# command that plainly writes (sed -i, a redirect, git switch) - before the
# check, or after it in the same command, where a redirect is the run's own log
# and is not one. A write it does not recognise makes a run look repeated, and
# two sessions at once blur it.
set -euo pipefail

PROJECT="$PWD"; LOGS=""; SINCE=""; UNTIL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --project) PROJECT="${2:?--project needs a directory}"; shift 2 ;;
    --logs) LOGS="${2:?--logs needs a directory}"; shift 2 ;;
    --since) SINCE="${2:?--since needs a date}"; shift 2 ;;
    --until) UNTIL="${2:?--until needs a date}"; shift 2 ;;
    --help|-h) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
command -v python3 >/dev/null 2>&1 || { echo "count-check-runs.sh needs python3" >&2; exit 1; }
[ -f "$PROJECT/AGENTS.md" ] || { echo "No AGENTS.md in $PROJECT" >&2; exit 1; }

exec python3 - "$PROJECT" "$LOGS" "$SINCE" "$UNTIL" <<'PY'
import json, os, re, sys
project, logs, since, until = os.path.abspath(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
if not logs:
    logs = os.path.join(os.path.expanduser("~/.claude/projects"), re.sub(r"[^A-Za-z0-9]", "-", project))
if not os.path.isdir(logs):
    sys.exit(f"No session logs at {logs} - name them with --logs")

# --- the declared commands, split into parts ---
declared = {}
for line in open(os.path.join(project, "AGENTS.md"), encoding="utf-8", errors="replace"):
    m = re.match(r"^- (Verify|Full verify|Test): *(.+)$", line.rstrip())
    if not m or m[1] in declared:
        continue
    value = m[2].strip()
    ticks = re.search(r"`([^`]+)`", value)
    value = ticks[1] if ticks else value
    if value.startswith("<") or re.match(r"(?i)(none|same as)\b", value):
        continue
    declared[m[1]] = [p.strip() for p in re.split(r"&&|;", value) if p.strip()]
if not declared:
    sys.exit(f"{project}/AGENTS.md records no Verify, Full verify or Test command")
parts = {}
for label in ("Verify", "Full verify", "Test"):
    for p in declared.get(label, []):
        parts.setdefault(p, []).append(label)

# A run, not a mention: the part stands where a command does - at the start, or
# after ; & | ( or a newline, behind at most timeout, time, nohup or VAR=value. So
# pgrep -f "make verify" and a note that names the command are not runs.
def pattern(p):
    return re.compile(r"(?:^|[;&|(\n])\s*(?:(?:timeout\s+\S+|time|nohup|\w+=\S*)\s+)*"
                      + re.escape(p) + r"(?![\w:-])(.*)", re.S)
HEREDOC = re.compile(r"<<-?\s*(['\"]?)(\w+)\1.*?\n\2[ \t]*(?=\n|$)", re.S)
PATTERNS = {p: pattern(p) for p in parts}
NAMED = re.compile(r"^\s*(?:--\s+)?(?:(?:-t|-k|-g|--grep|--filter)[ =]\S|[^\s&|;><-][^\s&|;><]*[/.])")
WRITES = re.compile(r"\bsed\s+-i|\bgit\s+(checkout|switch|merge|stash|reset|restore|apply|rebase|pull|revert)\b"
                    r"|(?<![0-9&>])>{1,2}(?!&|\s*/dev/null)|\b(mv|rm|cp|tee|patch|touch)\s|--fix\b|--write\b"
                    r"|\.write(_text)?\(")
# After the check, in the same command: only what plainly changes the tree. A
# redirect, tee or rm there is the run's own log, and counting it as an edit
# would hide the repeat that follows.
WRITES_AFTER = re.compile(r"\bsed\s+-i|\bgit\s+(checkout|switch|merge|stash|reset|restore|apply|rebase|pull|revert)\b"
                          r"|\bpatch\s|--fix\b|--write\b|\.write(_text)?\(")
EDITORS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}

# --- every tool call once, in time order across every log ---
calls, seen, files, handed_files = [], set(), 0, 0
for base, _, names in os.walk(logs):
    for name in sorted(names):
        if not name.endswith(".jsonl"):
            continue
        path = os.path.join(base, name)
        sub_file = "subagents" in os.path.relpath(path, logs).split(os.sep) or name.startswith("agent-")
        files += 1
        handed_files += sub_file
        for raw in open(path, encoding="utf-8", errors="replace"):
            try:
                rec = json.loads(raw)
            except ValueError:
                continue
            content = (rec.get("message") or {}).get("content")
            if rec.get("type") != "assistant" or not isinstance(content, list):
                continue
            when = rec.get("timestamp") or ""
            if (since and when < since) or (until and when > until):
                continue
            for block in content:
                if not isinstance(block, dict) or block.get("type") != "tool_use" or block.get("id") in seen:
                    continue
                seen.add(block.get("id"))
                calls.append((when, bool(rec.get("isSidechain")) or sub_file, block.get("name"),
                              (block.get("input") or {}).get("command") or ""))
calls.sort(key=lambda c: c[0])

rows = {p: {"runs": 0, "main": 0, "handed": 0, "same": 0, "named": 0} for p in parts}
clean = set()          # parts run since the last edit
for when, handed, tool, command in calls:
    if tool in EDITORS:
        clean.clear()
        continue
    if tool != "Bash":
        continue
    hit, last = False, None
    ran = HEREDOC.sub("", command)      # a heredoc's body is text, not commands
    for p, pat in PATTERNS.items():
        m = pat.search(ran)
        if not m:
            continue
        hit = True
        if WRITES.search(ran[:m.start()]):      # sed -i ... && the check: a new tree
            clean.clear()
        r = rows[p]
        r["runs"] += 1
        r["handed" if handed else "main"] += 1
        r["same"] += p in clean
        r["named"] += bool(NAMED.match(m[1]))
        clean.add(p)
        if last is None or m.start() > last.start():
            last = m
    if last is not None and WRITES_AFTER.search(last[1]):   # the check && sed -i ...: a new tree
        clean.clear()
    if not hit and WRITES.search(command):
        clean.clear()

span = "".join(f", {k} {v}" for k, v in (("since", since), ("until", until)) if v)
print(f"{project}: {files} session logs, {handed_files} of them a subagent's{span}")
width = max(len(p) for p in parts)
print(f"\n{'':<{width}}  {'in':<20} {'runs':>5} {'main':>5} {'handed off':>11} {'same tree':>10} {'named':>6}")
for p, r in rows.items():
    where = ", ".join(l.lower() for l in parts[p])
    print(f"{p:<{width}}  {where:<20} {r['runs']:>5} {r['main']:>5} {r['handed']:>11} {r['same']:>10} {r['named']:>6}")
PY
