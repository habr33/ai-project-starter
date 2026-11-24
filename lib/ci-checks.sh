#!/usr/bin/env bash
# ci-checks.sh - what did the project's CI say about a commit, whichever tool runs it?
#
# Usage (from the project, or from a part's directory):
#   .agents/bin/ci-checks.sh --commit SHA | .agents/bin/pipeline-ran.sh
#   .agents/bin/ci-checks.sh --main [BRANCH] | .agents/bin/pipeline-ran.sh --main
#   .agents/bin/ci-checks.sh --map TOOL [--main] < raw.json   # the mapping alone
#
# The tool is `- CI tool:` in AGENTS.md (here, else the repository root), or
# --tool TOOL: github-actions | forgejo-actions | gitlab-ci | woodpecker |
# local | other. ci writes that field; ship and deploy read every pipeline
# through this script, so neither names a tool's CLI.
#
# --commit prints each job of that commit's newest pipeline as
# {"name","bucket"}: pass, fail, skipping, cancel, pending, and two that
# matter when CI itself is short - `blocked`, a job that never started (no
# minutes left, no runner matched, a quota), and `queued`, a job still
# waiting for a runner. --main prints the branch's push pipelines, newest
# first, as {"status","conclusion","headSha"}; a run that failed only because
# its jobs never started has conclusion `blocked`.
#
# Where each comes from:
#   github-actions   gh (logged in); a failed job with no steps never started
#   forgejo-actions  the commit status API; FORGEJO_URL (default: the
#                    remote's host) and FORGEJO_TOKEN or GITEA_TOKEN
#   gitlab-ci        glab (logged in); failure_reason says quota or runner
#   woodpecker       the API; WOODPECKER_SERVER and WOODPECKER_TOKEN
#   local            the results .agents/bin/ci-local.sh writes in .git/ci-local
#   other            `- Read checks:` in AGENTS.md, run with CI_MODE (commit or
#                    main), CI_SHA and CI_BRANCH set; it prints these forms itself
#
# Exit: 0 printed; 2 bad usage, no CI tool recorded, or the tool could not be
# asked (not logged in, no token, no network) - which is not a verdict on the
# code. Reads only: it never starts, cancels or re-runs a pipeline.
set -uo pipefail

mode="" sha="" branch="main" tool="" maptool=""
die() { echo "ci-checks: $1" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --commit) mode=commit; sha="${2:-}"; shift 2 || die "--commit needs a SHA" ;;
    --main) [ -n "$maptool" ] && { mode=mapmain; shift; continue; }
            mode=main; shift
            case "${1:-}" in ""|-*) ;; *) branch="$1"; shift ;; esac ;;
    --map) maptool="${2:-}"; case "$mode" in main|mapmain) mode=mapmain ;; *) mode=map ;; esac
           shift 2 || die "--map needs a tool" ;;
    --tool) tool="${2:-}"; shift 2 || die "--tool needs a name" ;;
    -h|--help) sed -n '2,34p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "usage: --commit SHA | --main [BRANCH] | --map TOOL [--main] (got $1)" ;;
  esac
done
[ -n "$mode" ] || die "usage: --commit SHA | --main [BRANCH] | --map TOOL [--main]"

agents_field() { # NAME: the field's value, or nothing for a placeholder
  local f top; f=AGENTS.md
  if ! grep -qE "^\s*- $1:" "$f" 2>/dev/null; then
    top="$(git rev-parse --show-toplevel 2>/dev/null)" && f="$top/AGENTS.md"
  fi
  sed -n "s/^[[:space:]]*- $1:[[:space:]]*//p" "$f" 2>/dev/null | head -1 \
    | grep -v '^<' | sed 's/[[:space:]]*$//'
}

# --- the mapping: a tool's own JSON in, the shared forms out ---------------
map() { # TOOL MODE (commit or main), raw JSON on stdin
  python3 -c '
import json, sys
tool, mode = sys.argv[1], sys.argv[2]
try:
    raw = json.load(sys.stdin)
except Exception as e:
    print(f"ci-checks: the {tool} answer is not JSON: {e}", file=sys.stderr); sys.exit(2)

def gh_job(j):
    s, c = j.get("status", ""), j.get("conclusion") or ""
    if s in ("queued", "waiting", "requested"): return "queued"
    if s != "completed": return "pending"
    if c == "success": return "pass"
    if c in ("skipped", "neutral"): return "skipping"
    if c == "cancelled": return "cancel"
    if c == "startup_failure": return "blocked"
    return "fail" if j.get("steps") else "blocked"     # failed before its first step

GL_BLOCKED = {"ci_quota_exceeded", "no_matching_runner", "runner_system_failure",
              "stuck_or_timeout_failure", "scheduler_failure", "runner_unsupported"}
def gl_job(j):
    s = j.get("status", "")
    if s in ("created", "waiting_for_resource", "preparing", "pending"): return "queued"
    if s in ("running", "scheduled", "waiting_for_callback"): return "pending"
    if s == "success": return "pass"
    if s in ("skipped", "manual"): return "skipping"   # manual: left for someone to start
    if s == "canceled": return "cancel"
    return "blocked" if j.get("failure_reason") in GL_BLOCKED else "fail"

FJ = {"success": "pass", "pending": "pending", "failure": "fail", "warning": "fail",
      "error": "blocked", "skipped": "skipping"}
WP = {"pending": "queued", "running": "pending", "success": "pass", "failure": "fail",
      "killed": "cancel", "declined": "cancel", "error": "blocked",
      "blocked": "skipping", "skipped": "skipping"}   # woodpecker blocked: awaiting approval

def jobs_of(r):
    if tool == "github-actions": return [{"name": j["name"], "bucket": gh_job(j)} for j in r]
    if tool == "gitlab-ci":      return [{"name": j["name"], "bucket": gl_job(j)} for j in r]
    if tool == "forgejo-actions":
        return [{"name": s["context"], "bucket": FJ.get(s.get("status") or s.get("state"), "fail")}
                for s in r.get("statuses") or []]
    if tool == "woodpecker":
        return [{"name": w["name"], "bucket": WP.get(w.get("state"), "fail")}
                for w in r.get("workflows") or []]
    if tool in ("local", "other"): return r.get("jobs", r) if isinstance(r, dict) else r
    print(f"ci-checks: unknown CI tool {tool}", file=sys.stderr); sys.exit(2)

def run_of(r):
    """one pipeline of the branch, as status, conclusion and headSha"""
    if tool == "github-actions":
        s, c = r.get("status", ""), r.get("conclusion") or ""
        if s == "completed" and c != "success" and r.get("jobs") is not None:
            bad = [gh_job(j) for j in r["jobs"] if gh_job(j) not in ("pass", "skipping")]
            if bad and all(b == "blocked" for b in bad): c = "blocked"
        return s, c, r.get("headSha", "")
    if tool == "gitlab-ci":
        s = r.get("status", "")
        if s in ("success", "failed", "canceled", "skipped"):
            c = {"success": "success", "failed": "failure", "canceled": "cancelled"}.get(s, s)
            if s == "failed" and r.get("jobs") is not None:
                bad = [gl_job(j) for j in r["jobs"] if gl_job(j) in ("fail", "blocked")]
                if bad and all(b == "blocked" for b in bad): c = "blocked"
            return "completed", c, r.get("sha", "")
        return "in_progress", "", r.get("sha", "")
    if tool in ("forgejo-actions", "woodpecker"):
        st = r.get("state") or r.get("status", "")
        if st in ("pending", "running"): return "in_progress", "", r.get("sha") or r.get("commit", "")
        c = {"success": "success", "failure": "failure", "error": "blocked",
             "killed": "cancelled", "declined": "cancelled"}.get(st, st)
        return "completed", c, r.get("sha") or r.get("commit", "")
    if tool in ("local", "other"):
        return r["status"], r.get("conclusion", ""), r["headSha"]
    print(f"ci-checks: unknown CI tool {tool}", file=sys.stderr); sys.exit(2)

try:
    if mode == "main":
        out = [dict(zip(("status", "conclusion", "headSha"), run_of(r))) for r in raw]
    else:
        out = jobs_of(raw)
        for j in out: j["name"], j["bucket"]          # the form pipeline-ran reads
except (KeyError, TypeError, AttributeError) as e:
    print(f"ci-checks: the {tool} answer is not in the shape expected: {e}", file=sys.stderr); sys.exit(2)
print(json.dumps(out))
' "$1" "$2"
}

case "$mode" in
  map)     map "$maptool" commit; exit $? ;;
  mapmain) map "$maptool" main; exit $? ;;
esac

[ -n "$tool" ] || tool="$(agents_field 'CI tool')"
tool="${tool%%[ :]*}"
[ -n "$tool" ] || die "no CI tool recorded - \`- CI tool:\` in AGENTS.md is written by ci"
[ "$mode" = commit ] && [ -z "$sha" ] && die "--commit needs a SHA"
[ "$mode" = commit ] && sha="$(git rev-parse --verify -q "$sha^{commit}" 2>/dev/null || echo "$sha")"

need() { command -v "$1" >/dev/null 2>&1 || die "$tool needs $1, which is not installed"; }
remote_slug() { # owner and repo, from origin
  git remote get-url origin 2>/dev/null | sed -E 's#^[a-z]+://([^@/]+@)?[^/]+/##; s#^[^@]+@[^:]+:##; s#\.git$##'
}
remote_host() {
  git remote get-url origin 2>/dev/null | sed -E 's#^[a-z]+://([^@/]+@)?([^/:]+).*#\2#; s#^[^@]+@([^:]+):.*#\1#'
}
api() { # URL TOKEN: JSON, or exit 2 naming what failed (never the token)
  curl -fsS --max-time 30 -H "Authorization: token $2" -H 'Accept: application/json' "$1" \
    || die "$tool could not be asked: $1"
}

case "$tool" in
github-actions)
  need gh
  if [ "$mode" = commit ]; then
    ids="$(gh run list --commit "$sha" --json databaseId --jq '.[].databaseId' -L 20)" \
      || die "gh could not list runs - is it logged in?"
    rows=""
    for id in $ids; do
      js="$(gh run view "$id" --json jobs --jq '[.jobs[]|tojson]|join(",")')" || die "gh could not read run $id"
      [ -n "$js" ] && rows="$rows${rows:+,}$js"
    done
    printf '[%s]' "$rows" | map github-actions commit
  else
    runs="$(gh run list --branch "$branch" --event push -L 20 \
      --json databaseId,status,conclusion,headSha)" || die "gh could not list runs - is it logged in?"
    # the newest completed run that did not pass: did its jobs ever start?
    id="$(python3 -c 'import json,sys
r=[x for x in json.loads(sys.argv[1]) if x["status"]=="completed"]
print(r[0]["databaseId"] if r and r[0]["conclusion"]!="success" else "")' "$runs")"
    if [ -n "$id" ]; then
      jobs="$(gh run view "$id" --json jobs --jq .jobs)" || die "gh could not read run $id"
      runs="$(python3 -c 'import json,sys
r=json.loads(sys.argv[1]); i=int(sys.argv[2]); j=json.loads(sys.argv[3])
for x in r:
    if x["databaseId"]==i: x["jobs"]=j
print(json.dumps(r))' "$runs" "$id" "$jobs")"
    fi
    printf '%s' "$runs" | map github-actions main
  fi ;;
gitlab-ci)
  need glab
  if [ "$mode" = commit ]; then
    raw="$(glab api "projects/:id/pipelines?sha=$sha&per_page=1")" || die "glab could not list pipelines - is it logged in?"
    pid="$(printf '%s' "$raw" | python3 -c 'import json,sys
p=json.load(sys.stdin); print(p[0]["id"] if p else "")')" || die "glab gave an unreadable pipeline list"
    [ -n "$pid" ] || { echo '[]'; exit 0; }
    raw="$(glab api "projects/:id/pipelines/$pid/jobs?per_page=100")" || die "glab could not read pipeline $pid"
    printf '%s' "$raw" | map gitlab-ci commit
  else
    ps="$(glab api "projects/:id/pipelines?ref=$branch&source=push&per_page=20")" \
      || die "glab could not list pipelines - is it logged in?"
    pid="$(python3 -c 'import json,sys
p=[x for x in json.loads(sys.argv[1]) if x["status"] in ("success","failed","canceled","skipped")]
print(p[0]["id"] if p and p[0]["status"]=="failed" else "")' "$ps")"
    if [ -n "$pid" ]; then
      jobs="$(glab api "projects/:id/pipelines/$pid/jobs?per_page=100")" || die "glab could not read pipeline $pid"
      ps="$(python3 -c 'import json,sys
p=json.loads(sys.argv[1]); i=int(sys.argv[2])
for x in p:
    if x["id"]==i: x["jobs"]=json.loads(sys.argv[3])
print(json.dumps(p))' "$ps" "$pid" "$jobs")"
    fi
    printf '%s' "$ps" | map gitlab-ci main
  fi ;;
forgejo-actions)
  need curl
  base="${FORGEJO_URL:-https://$(remote_host)}"; token="${FORGEJO_TOKEN:-${GITEA_TOKEN:-}}"
  [ -n "$token" ] || die "forgejo-actions needs FORGEJO_TOKEN (or GITEA_TOKEN) in the environment"
  repo="$base/api/v1/repos/$(remote_slug)"
  if [ "$mode" = commit ]; then
    raw="$(api "$repo/commits/$sha/status" "$token")" || exit 2
    printf '%s' "$raw" | map forgejo-actions commit
  else
    raw="$(api "$repo/commits?sha=$branch&limit=20" "$token")" || exit 2
    shas="$(printf '%s' "$raw" | python3 -c 'import json,sys
print(" ".join(c["sha"] for c in json.load(sys.stdin)))')" || die "could not read $branch's commits"
    rows=""
    for s in $shas; do
      raw="$(api "$repo/commits/$s/status" "$token")" || exit 2
      st="$(printf '%s' "$raw" | python3 -c 'import json,sys
d=json.load(sys.stdin); print(d.get("state","") if d.get("statuses") else "")')" || die "unreadable status for $s"
      [ -n "$st" ] || continue                         # no pipeline ran on this commit
      rows="$rows${rows:+,}{\"sha\":\"$s\",\"state\":\"$st\"}"
    done
    printf '[%s]' "$rows" | map forgejo-actions main
  fi ;;
woodpecker)
  need curl
  base="${WOODPECKER_SERVER:-}"; token="${WOODPECKER_TOKEN:-}"
  [ -n "$base" ] && [ -n "$token" ] || die "woodpecker needs WOODPECKER_SERVER and WOODPECKER_TOKEN in the environment"
  wp() { curl -fsS --max-time 30 -H "Authorization: Bearer $token" "$base/api/$1" || die "woodpecker could not be asked: $1"; }
  raw="$(wp "repos/lookup/$(remote_slug)")" || exit 2
  rid="$(printf '%s' "$raw" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')" \
    || die "woodpecker has no repository $(remote_slug)"
  pls="$(wp "repos/$rid/pipelines?per_page=50")" || exit 2
  if [ "$mode" = commit ]; then
    n="$(python3 -c 'import json,sys
p=[x for x in json.loads(sys.argv[1]) if x.get("commit")==sys.argv[2]]
print(p[0]["number"] if p else "")' "$pls" "$sha")"
    [ -n "$n" ] || { echo '[]'; exit 0; }
    raw="$(wp "repos/$rid/pipelines/$n")" || exit 2
    printf '%s' "$raw" | map woodpecker commit
  else
    python3 -c 'import json,sys
print(json.dumps([x for x in json.loads(sys.argv[1]) if x.get("branch")==sys.argv[2] and x.get("event")=="push"]))' \
      "$pls" "$branch" | map woodpecker main
  fi ;;
local)
  dir="$(git rev-parse --git-common-dir 2>/dev/null)/ci-local"
  if [ "$mode" = commit ]; then
    [ -f "$dir/$sha.json" ] || { echo '[]'; exit 0; }   # never run here: no checks
    map local commit < "$dir/$sha.json"
  else
    { echo '['; first=1
      for s in $(git rev-list -n 20 "$branch" 2>/dev/null); do
        [ -f "$dir/$s.json" ] || continue
        [ $first = 1 ] || echo ','; first=0
        python3 -c 'import json,sys
r=json.load(open(sys.argv[1]))
print(json.dumps({"status":"completed","conclusion":r.get("conclusion","failure"),"headSha":r["sha"]}))' "$dir/$s.json"
      done; echo ']'; } | map local main
  fi ;;
other)
  cmd="$(agents_field 'Read checks')"
  [ -n "$cmd" ] || die "CI tool is other, and no \`- Read checks:\` command is recorded in AGENTS.md"
  raw="$(CI_MODE="$mode" CI_SHA="$sha" CI_BRANCH="$branch" bash -c "$cmd")" \
    || die "the Read checks command failed"
  printf '%s' "$raw" | map other "$mode" ;;
*) die "unknown CI tool '$tool' - one of github-actions forgejo-actions gitlab-ci woodpecker local other" ;;
esac
