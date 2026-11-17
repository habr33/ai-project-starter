#!/usr/bin/env bash
# pipeline-ran.sh - did a pull request's pipeline run every check, and pass?
#
# Usage:
#   gh pr checks <number> --json name,bucket | .agents/bin/pipeline-ran.sh
#   .agents/bin/pipeline-ran.sh checks.json
#   gh run list --branch main --event push --json status,conclusion,headSha \
#     | .agents/bin/pipeline-ran.sh --main
#
# ship reads it before treating a pipeline as the full verify gate. A skipped
# job reports success, to a required check too, so a list that looks green can
# have run none of the browser tests. Only `pass` counts: `skipping`, `cancel`
# and `fail` are each a check that did not pass, and `pending` is one still
# running. No checks at all is not a pass either - nothing ran.
#
# With a job named `gate` (or --gate NAME) - the one ci ends the pipeline on,
# which fails unless every job the diff's scope needed succeeded (D40) - a
# skip elsewhere is the gate's call: the gate passing is the verdict, and a
# failed job anywhere still fails.
#
# --main reads the default branch's push runs, newest first: its last
# completed run must have succeeded. A red main is fixed before anything else
# merges or deploys. No completed run yet blocks nothing.
#
# Exit: 0 every check ran and passed; 1 one did not; 3 one is still running
# (wait and ask again); 2 the input could not be read. Reads only.
set -uo pipefail

mode=checks gate=gate
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --main) mode=main; shift ;;
    --gate) gate="${2:-}"; shift 2 || { echo "pipeline-ran: --gate needs a job name" >&2; exit 2; } ;;
    *) break ;;
  esac
done

if [ $# -gt 0 ]; then
  [ -r "$1" ] || { echo "pipeline-ran: cannot read $1" >&2; exit 2; }
  input="$(cat "$1")"
else
  input="$(cat)"
fi

python3 -c '
import json, sys
mode, gate = sys.argv[2], sys.argv[3]
if mode == "main":
    try:
        runs = [(r["status"], r.get("conclusion") or "", r.get("headSha") or "") for r in json.loads(sys.argv[1])]
    except Exception as e:
        print(f"pipeline-ran: not the JSON of gh run list --json status,conclusion,headSha: {e}", file=sys.stderr)
        sys.exit(2)
    done = [r for r in runs if r[0] == "completed"]
    if not done:
        print("main: no completed run yet - nothing to hold a merge on")
        sys.exit(0)
    _, c, sha = done[0]
    if c == "success":
        print(f"main is green at {sha[:7]}")
        sys.exit(0)
    print(f"main is red at {sha[:7]} ({c}) - fix it before anything else merges or deploys")
    sys.exit(1)
try:
    checks = json.loads(sys.argv[1])
    rows = [(c["name"], c["bucket"]) for c in checks]
except Exception as e:
    print(f"pipeline-ran: not the JSON of gh pr checks --json name,bucket: {e}", file=sys.stderr)
    sys.exit(2)
if not rows:
    print("not run: the pipeline reported no checks for this commit")
    sys.exit(1)
said = {"pass": "ran and passed", "pending": "still running", "fail": "failed",
        "cancel": "not run (cancelled)",
        "skipping": "not run (skipped - a skip reports success, it ran nothing)"}
gated = any(n == gate for n, _ in rows)
if gated:
    said["skipping"] = f"skipped by scope - the {gate} job decides whether it was needed"
for n, b in rows:
    print(f"{said.get(b, b)}: {n}")
bad = [b for n, b in rows if b != "pass" and not (gated and b == "skipping" and n != gate)]
if bad and all(b == "pending" for b in bad):
    sys.exit(3)
sys.exit(1 if bad else 0)
' "$input" "$mode" "$gate"
rc=$?
# A crash in the reader is not a verdict on the pipeline.
case $rc in 0|1|3) exit $rc ;; *) exit 2 ;; esac
