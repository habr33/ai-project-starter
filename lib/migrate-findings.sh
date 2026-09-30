#!/usr/bin/env bash
# Split a findings ledger from before D15 into the index and one entry file per
# finding, for a project installed before the split. install.sh names this when
# it finds one.
#
#   lib/migrate-findings.sh [--target DIR]     # default: the current directory
#
# The old ledger held every finding whole in blueprint/context/findings.md,
# which every session loads. After: that file holds each heading, its File:
# line and a Deferred to: line where there is one - deploy and host read that
# there - and blueprint/findings/F-NN.md holds the rest. No status changes, and
# no P3 moves to the backlog: that is ship's call, not a migration's.
#
# Everything is checked before anything is written - every heading readable, no
# ID twice, none already in the backlog or on disk as an entry, every line of
# the old ledger present in the new files - so a refusal leaves the tree as it
# was.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="$PWD"
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:?--target needs a directory}"; shift 2 ;;
    --help|-h) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
[ -f "$TARGET/blueprint/context/findings.md" ] \
  || { echo "No blueprint/context/findings.md in $TARGET" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "migrate-findings.sh needs python3" >&2; exit 1; }

exec python3 - "$TARGET" "$HERE/template/blueprint/context/findings.md" <<'PY'
import os, re, sys
target, template = sys.argv[1], sys.argv[2]
index_path = os.path.join(target, "blueprint/context/findings.md")
entries_dir = os.path.join(target, "blueprint/findings")
backlog_path = os.path.join(entries_dir, "backlog.md")

def refuse(msg):
    print(f"{index_path}: {msg}. Nothing was written.", file=sys.stderr)
    sys.exit(1)

lines = open(index_path).read().split("\n")
HEAD = re.compile(r"^### (F-\d+) \[(P[0-3])\] ([a-z]+) - (\S.*)$")
FIELD = re.compile(r"^\*\*(File|Deferred to):\*\*\s*(.*)$|^(Deferred to):\s*(.*)$")

if not any(re.match(r"^\*\*(File|Found):\*\*", l) for l in lines):
    if any(l.startswith("### F-") for l in lines):
        refuse("already split - its headings carry no entry text")
    print(f"{index_path}: no findings to split")
    sys.exit(0)

# Blocks, by heading - never by a heading-like line inside a code fence.
preamble, blocks, fence = [], [], False
for n, l in enumerate(lines, 1):
    if l.lstrip().startswith("```"):
        fence = not fence
    if not fence and l.startswith("### F-"):
        m = HEAD.match(l)
        if not m:
            refuse(f"line {n} is a finding heading this cannot read: {l!r} - fix it by hand")
        blocks.append({"id": m[1], "heading": l, "title": m[4], "body": []})
    elif blocks:
        blocks[-1]["body"].append(l)
    else:
        preamble.append(l)

for l in preamble:
    if l.strip() and not (l.startswith("# Findings") or l.startswith(">") or l.strip() == "_No findings recorded._"):
        refuse(f"text before the first finding this would drop: {l!r}")

ids = [b["id"] for b in blocks]
dupes = sorted({i for i in ids if ids.count(i) > 1})
if dupes:
    refuse(f"{', '.join(dupes)} used more than once")
backlog = re.findall(r"^### (F-\d+) ", open(backlog_path).read(), re.M) if os.path.exists(backlog_path) else []
clash = [i for i in ids if i in backlog]
if clash:
    refuse(f"{', '.join(clash)} already in blueprint/findings/backlog.md")
exists = [i for i in ids if os.path.exists(os.path.join(entries_dir, i + ".md"))]
if exists:
    refuse(f"blueprint/findings/{', '.join(exists)}.md already exists")

header = open(template).read().split("_No findings recorded._")[0].rstrip("\n")
index, entries = [header, ""], {}
for b in blocks:
    loaded, body = [b["heading"]], []
    for l in b["body"]:
        m = FIELD.match(l)
        if m:
            key, val = (m[1], m[2]) if m[1] else (m[3], m[4])
            loaded.append(f"{key}: {val}")
        else:
            body.append(l)
    if not any(x.startswith("File: ") for x in loaded):
        loaded.insert(1, "File: (none recorded)")
    while body and not body[0].strip(): body.pop(0)
    while body and not body[-1].strip(): body.pop()
    index += loaded + [""]
    entries[b["id"]] = "\n".join([f"# {b['id']} - {b['title']}", ""] + body) + "\n"
new_index = "\n".join(index).rstrip("\n") + "\n"

# The hand check, before writing: each ID once across index and backlog, and
# every line of every old entry somewhere in the new files.
now = re.findall(r"^### (F-\d+) ", new_index, re.M) + backlog
assert sorted(now) == sorted(set(now)) and set(ids) <= set(now), "an ID is lost or doubled"
written = set(new_index.split("\n")) | {l for e in entries.values() for l in e.split("\n")}
for b in blocks:
    for l in b["body"]:
        m = FIELD.match(l)
        want = (f"{m[1]}: {m[2]}" if m[1] else f"{m[3]}: {m[4]}") if m else l
        if want not in written:
            refuse(f"{b['id']} would lose the line {l!r}")

os.makedirs(entries_dir, exist_ok=True)
for i, text in entries.items():
    with open(os.path.join(entries_dir, i + ".md"), "x") as f:
        f.write(text)
tmp = index_path + ".tmp"
with open(tmp, "w") as f:
    f.write(new_index)
os.replace(tmp, index_path)
print(f"Split {len(blocks)} finding(s): headings in blueprint/context/findings.md, "
      f"entries in blueprint/findings/. The old ledger is in git - git diff shows the move.")
PY
