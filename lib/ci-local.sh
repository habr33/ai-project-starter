#!/usr/bin/env bash
# ci-local.sh - run the project's pipeline on this machine, the way a runner would.
#
# Usage (from the project, or from a part's directory):
#   .agents/bin/ci-local.sh                     # HEAD, scoped against main
#   .agents/bin/ci-local.sh --base origin/main  # what a pull request runs
#   .agents/bin/ci-local.sh --push              # everything, as main does
#   .agents/bin/ci-local.sh --commit SHA --push --keep   # deploy builds there
#
# It is the CI for `- CI tool: local`, and the fallback for any other tool
# when that one cannot run - no minutes left, a runner offline. It checks out
# the commit into a fresh worktree, so only what is committed is tested: no
# uncommitted file, no build directory, no node_modules and no .env. The
# commands run with a clean environment (PATH, HOME, USER, LANG, TERM,
# TMPDIR, and CI=true), so a variable from this shell cannot make it pass.
#
# Jobs, as ci lays out a pipeline: scope (.agents/bin/test-scope.sh), verify
# (`- Install:`, then `- Verify:`, then .agents/bin/check-project.sh), then
# `- Affected:` when the scope is affected, or `- Full verify:` when it is
# full - which then runs in verify's place, since it begins with Verify -
# and a gate that passes only when every job the scope chose passed. The
# commands are read from AGENTS.md as committed in that commit.
#
# It writes the result to .git/ci-local/<sha>.json, which ci-checks.sh reads
# for `- CI tool: local`, and each job's log beside it in .git/ci-local/<sha>/.
# Nothing it writes is in the working tree or committed.
#
# --keep leaves the worktree in place and prints its path: deploy builds the
# release there when CI could not, so what ships is what was just tested.
#
# Exit: 0 the gate passed; 1 it did not, naming the job and its log; 2 bad
# usage, or nothing to run (no Verify recorded at that commit).
set -uo pipefail

base="" push=0 commit=HEAD keep=0
die() { echo "ci-local: $1" >&2; exit 2; }
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="${2:-}"; shift 2 || die "--base needs a ref" ;;
    --push) push=1; shift ;;
    --commit) commit="${2:-}"; shift 2 || die "--commit needs a ref" ;;
    --keep) keep=1; shift ;;
    -h|--help) sed -n '2,33p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "usage: [--base REF | --push] [--commit REF] [--keep] (got $1)" ;;
  esac
done
[ "$push" = 1 ] && [ -n "$base" ] && die "--base and --push are two different runs - give one"
[ "$push" = 1 ] || [ -n "$base" ] || base=main

top="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repository"
prefix="$(git rev-parse --show-prefix)"
sha="$(git rev-parse --verify -q "$commit^{commit}")" || die "no commit $commit"
[ -n "$base" ] && { git rev-parse --verify -q "$base^{commit}" >/dev/null || die "no ref $base to scope against"; }

agents="$(git show "$sha:${prefix}AGENTS.md" 2>/dev/null)" || die "no AGENTS.md at ${prefix:-the root} in ${sha:0:7}"
field() { # NAME: its value at that commit, or nothing for a placeholder
  printf '%s\n' "$agents" | sed -n "s/^[[:space:]]*- $1:[[:space:]]*//p" | head -1 \
    | grep -v '^<' | sed 's/[[:space:]]*$//; s/^`\(.*\)`$/\1/'
}
install="$(field Install)"; verify="$(field Verify)"; full="$(field 'Full verify')"; affected="$(field Affected)"
[ -n "$verify" ] || die "no Verify command recorded at ${sha:0:7} - CI that runs nothing is worse than none"
case "$full" in ""|"same as Verify"|\"same\ as\ Verify\") full="$verify" ;; esac

if [ -n "$(git status --porcelain --untracked-files=no)" ] && [ "$commit" = HEAD ]; then
  echo "ci-local: uncommitted changes are not tested - a runner sees only ${sha:0:7}" >&2
fi

# Everything checked above; from here on it writes, and every outcome is a verdict.
out="$(git rev-parse --git-common-dir)"; out="$(cd "$out" && pwd)/ci-local"
logs="$out/$sha"; mkdir -p "$logs"
wt="$(mktemp -d "${TMPDIR:-/tmp}/ci-local.XXXXXX")"
# after-write: only the log directory exists yet, and it holds the reason
git worktree add -q --detach "$wt" "$sha" 2>"$logs/worktree.log" \
  || { rmdir "$wt" 2>/dev/null; echo "ci-local: could not check out ${sha:0:7} - see $logs/worktree.log" >&2; exit 1; }
cleanup() { [ "$keep" = 1 ] || git worktree remove --force "$wt" >/dev/null 2>&1; }
trap cleanup EXIT
here="$wt/$prefix"

run() { # JOB COMMAND: in the clean worktree, with a clean environment
  echo "ci-local: $1 - $2" >&2
  (cd "$here" && env -i PATH="$PATH" HOME="$HOME" USER="${USER:-}" LANG="${LANG:-C.UTF-8}" \
     TERM="${TERM:-dumb}" TMPDIR="${TMPDIR:-/tmp}" CI=true BASE="${base:-}" \
     bash -c "$2") >>"$logs/$1.log" 2>&1
}
: >"$logs/scope.log"; : >"$logs/verify.log"
started=$(date +%s)
b_scope=skipping b_verify=skipping b_affected=skipping b_full=skipping   # bash 3.2: no arrays of names

scope_sh="$wt/.agents/bin/test-scope.sh"; [ -x "$scope_sh" ] || scope_sh="$(dirname "$0")/test-scope.sh"
if [ "$push" = 1 ]; then level="$(cd "$here" && "$scope_sh" --push 2>>"$logs/scope.log")"
else level="$(cd "$here" && "$scope_sh" --base "$base" 2>>"$logs/scope.log")"; fi
case "$level" in none|affected|full) b_scope=pass ;; *) level="" ; b_scope=fail ;; esac

if [ -n "$level" ]; then
  ok=1
  [ -n "$install" ] && { run verify "$install" || ok=0; }
  if [ "$ok" = 1 ] && [ "$level" = full ]; then
    run full "$full" && b_full=pass || b_full=fail
    b_verify=$b_full                    # full verify begins with Verify
  elif [ "$ok" = 1 ]; then
    run verify "$verify" && b_verify=pass || b_verify=fail
    if [ "$b_verify" = pass ] && [ "$level" = affected ]; then
      run affected "$affected" && b_affected=pass || b_affected=fail
    fi
  else
    b_verify=fail
  fi
  if [ "$b_verify" = pass ] && [ -x "$wt/.agents/bin/check-project.sh" ]; then
    (cd "$wt" && .agents/bin/check-project.sh) >>"$logs/verify.log" 2>&1 || b_verify=fail
  fi
fi

gate=pass
[ "$b_scope" = pass ] && [ "$b_verify" = pass ] || gate=fail
case "$level" in
  affected) [ "$b_affected" = pass ] || gate=fail ;;
  full) [ "$b_full" = pass ] || gate=fail ;;
esac
took=$(( $(date +%s) - started ))

python3 -c '
import json, sys
sha, level, gate, took = sys.argv[1:5]
jobs = [{"name": n, "bucket": b} for n, b in zip(("scope", "verify", "affected", "full"), sys.argv[5:9])]
jobs.append({"name": "gate", "bucket": gate})
json.dump({"sha": sha, "level": level, "seconds": int(took),
           "conclusion": "success" if gate == "pass" else "failure", "jobs": jobs},
          open(sys.argv[9], "w"))
' "$sha" "${level:-unknown}" "$gate" "$took" \
  "$b_scope" "$b_verify" "$b_affected" "$b_full" "$out/$sha.json"

for j in scope verify affected full; do
  [ "$j" = verify ] && [ "$level" = full ] && [ "$b_full" != skipping ] && continue   # it is full's result
  eval "b=\$b_$j"
  [ "$b" = fail ] && { echo "ci-local: $j failed - $logs/$j.log:" >&2; tail -15 "$logs/$j.log" >&2; }
done
echo "ci-local: ${sha:0:7} scope ${level:-unknown} - gate $gate in ${took}s, result in $out/$sha.json"
[ "$keep" = 1 ] && echo "ci-local: kept the tested worktree at $here"
[ "$gate" = pass ]
