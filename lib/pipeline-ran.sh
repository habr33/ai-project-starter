#!/usr/bin/env bash
# pipeline-ran.sh - did a pull request's pipeline run every check, and pass?
#
# Usage:
#   gh pr checks <number> --json name,bucket | .agents/bin/pipeline-ran.sh
#   .agents/bin/pipeline-ran.sh checks.json
#
# ship reads it before treating a pipeline as the full verify gate. A skipped
# job reports success, to a required check too, so a list that looks green can
# have run none of the browser tests. Only `pass` counts: `skipping`, `cancel`
# and `fail` are each a check that did not pass, and `pending` is one still
# running. No checks at all is not a pass either - nothing ran.
#
# Exit: 0 every check ran and passed; 1 one did not; 3 one is still running
# (wait and ask again); 2 the input could not be read. Reads only.
set -uo pipefail

case "${1:-}" in
  -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac

if [ $# -gt 0 ]; then
  [ -r "$1" ] || { echo "pipeline-ran: cannot read $1" >&2; exit 2; }
  input="$(cat "$1")"
else
  input="$(cat)"
fi

python3 -c '
import json, sys
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
for n, b in rows:
    print(f"{said.get(b, b)}: {n}")
bad = [b for _, b in rows if b != "pass"]
if bad and all(b == "pending" for b in bad):
    sys.exit(3)
sys.exit(1 if bad else 0)
' "$input"
rc=$?
# A crash in the reader is not a verdict on the pipeline.
case $rc in 0|1|3) exit $rc ;; *) exit 2 ;; esac
