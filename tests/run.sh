#!/usr/bin/env bash
# Run the pack's test suite.
#
#   ./tests/run.sh              everything
#   ./tests/run.sh lint         just tests/test-lint.sh
#
# No dependencies, nothing to install - the same rule the pack itself follows.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO="${REPO:-$(cd "$HERE/.." && pwd)}"

TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/pack-tests.XXXXXX")"
trap 'rm -rf "$TMPROOT"' EXIT

grand_pass=0
grand_fail=0

# --- one test file ------------------------------------------------------------
#
# A file passes only if all three agree: it exited 0, it reached `finish` (which
# writes .result - a file that hit `exit 0` halfway never does), and `finish`
# counted no failures. Trusting the exit code alone let a file stop early and
# report green with its later assertions never run.
#
# The self-test below runs deliberately broken files through this same function,
# so weakening any of the three checks fails every run.
run_file() {
  # p and fl start at 0: unset, `set -u` would kill the runner silently inside
  # the self-test's redirect instead of reporting which check broke.
  local f="$1" name="$2" tmp="$3" rc p=0 fl=0
  mkdir -p "$tmp"
  rm -f "$tmp/.result"
  REPO="$REPO" TEST_TMP="$tmp" bash "$f"; rc=$?
  if [ ! -f "$tmp/.result" ]; then
    printf '\n  %s stopped before finish (exit %d) - everything after that point never ran\n' "$name" "$rc"
    grand_fail=$((grand_fail + 1))
    return 1
  fi
  read -r p fl < "$tmp/.result"
  grand_pass=$((grand_pass + p))
  grand_fail=$((grand_fail + fl))
  if [ "$rc" -ne 0 ]; then
    [ "$fl" -gt 0 ] || { printf '\n  %s exited %d after finish reported no failures\n' "$name" "$rc"; grand_fail=$((grand_fail + 1)); }
    return 1
  fi
  [ "$fl" -eq 0 ] || { printf '\n  %s exited 0 but finish recorded %d failure(s)\n' "$name" "$fl"; return 1; }
}

# --- prove the harness can fail before trusting a single green result ---------
#
# Rule 12 once shipped unable to fail: it printed its error from inside a
# subshell and returned 0, so it reported problems without ever failing a build.
# A suite with that defect reports every file clean and hides everything. So the
# first thing this runner does is make every assertion fail on purpose - and
# pass on purpose - and check that the harness counted each one by name.
#
# Every assertion is here, not a sample: `assert_fails` and `assert_exists`
# were each broken to always pass while a three-assertion canary stayed green.
selftest() {
  local st="$TMPROOT/selftest" out rc fails passes n missing=""
  mkdir -p "$st"
  cat > "$st/canary.sh" <<'CANARY'
source "$LIB"
assert_eq      "c-eq"             "expected" "actual"
assert_ok      "c-ok"             false
assert_refuses "c-refuses-rc0"    "anything" true
assert_refuses "c-refuses-msg"    "this-string-never-appears" false
assert_fails   "c-fails"          true
assert_exists  "c-exists"         /nonexistent/really-not-here
assert_absent  "c-absent"         /
assert_lacks   "c-lacks-found"    "$LIB" 'assert_lacks'
assert_lacks   "c-lacks-missing"  /nonexistent/really-not-here 'x'
assert_eq      "p-eq"             "same" "same"
assert_ok      "p-ok"             true
assert_refuses "p-refuses"        "needle" sh -c 'echo needle; exit 1'
assert_fails   "p-fails"          false
assert_exists  "p-exists"         /
assert_absent  "p-absent"         /nonexistent/really-not-here
assert_lacks   "p-lacks"          "$LIB" 'this-string-never-appears-anywhere'
finish
CANARY
  out="$(LIB="$HERE/lib.sh" REPO="$REPO" TEST_TMP="$st" bash "$st/canary.sh" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then
    printf 'harness self-test FAILED: nine broken assertions exited 0\n' >&2; return 1
  fi
  for n in c-eq c-ok c-refuses-rc0 c-refuses-msg c-fails c-exists c-absent c-lacks-found c-lacks-missing; do
    grep -qx "FAIL $n" "$st/.assertions" || missing="$missing $n"
  done
  for n in p-eq p-ok p-refuses p-fails p-exists p-absent p-lacks; do
    grep -qx "ok $n" "$st/.assertions" || missing="$missing $n"
  done
  if [ -n "$missing" ]; then
    printf 'harness self-test FAILED: wrong result recorded for:%s\n' "$missing" >&2; return 1
  fi
  read -r passes fails < "$st/.result" 2>/dev/null || { printf 'harness self-test FAILED: finish wrote no result\n' >&2; return 1; }
  if [ "$fails" != "9" ] || [ "$passes" != "7" ]; then
    printf 'harness self-test FAILED: expected 7 passed 9 failed, harness counted %s/%s\n' "$passes" "$fails" >&2; return 1
  fi

  # The file loop, canaried with files that are each broken one way. Every one
  # must be reported failed by the same run_file the real files go through.
  local body
  declare -A broken=(
    [early-exit]='assert_eq "a" "x" "x"; exit 0; assert_eq "never reached" "x" "y"; finish'
    [piped]='true | assert_eq "piped failure" "x" "y"; finish'
    [piped-pass]='true | assert_eq "piped pass" "x" "x"; finish'
    [rc-after-finish]='assert_eq "a" "x" "x"; finish; exit 3'
    [plain-fail]='assert_eq "a" "x" "y"; finish'
  )
  local saved_pass=$grand_pass saved_fail=$grand_fail
  for n in "${!broken[@]}"; do
    printf 'source "%s"\n%s\n' "$HERE/lib.sh" "${broken[$n]}" > "$st/file-$n.sh"
    if run_file "$st/file-$n.sh" "$n" "$st/run-$n" >/dev/null 2>&1; then
      printf 'harness self-test FAILED: a test file broken by %s was reported passing\n' "$n" >&2; return 1
    fi
  done
  printf 'source "%s"\nassert_eq "a" "x" "x"\nfinish\n' "$HERE/lib.sh" > "$st/file-clean.sh"
  if ! run_file "$st/file-clean.sh" clean "$st/run-clean" >/dev/null 2>&1; then
    printf 'harness self-test FAILED: a clean test file was reported failing\n' >&2; return 1
  fi
  grand_pass=$saved_pass; grand_fail=$saved_fail
  printf 'harness self-test ok - every assertion fails when it should, and a file that fails, stops early or loses a result fails the run\n'
}

selftest || exit 1

# --- run the files ------------------------------------------------------------
want="${1:-}"
failed_files=""
total=0

for f in "$HERE"/test-*.sh; do
  name="$(basename "$f" .sh)"; name="${name#test-}"
  [ -n "$want" ] && [ "$name" != "$want" ] && continue
  total=$((total + 1))
  printf '\n=== %s ===\n' "$name"
  run_file "$f" "$name" "$TMPROOT/$name" || failed_files="$failed_files $name"
done

if [ "$total" -eq 0 ]; then
  printf '\nno test file matched %s\n' "${want:-*}" >&2
  exit 1
fi

printf '\ntotal: %d passed, %d failed across %d file(s)\n' "$grand_pass" "$grand_fail" "$total"
# Either signal fails the run on its own, so dropping the `|| failed_files=` in
# the loop above still cannot turn a counted failure green.
if [ -n "$failed_files" ] || [ "$grand_fail" -ne 0 ]; then
  printf 'FAILED:%s\n' "${failed_files:- (failures counted, but no file was marked failed - the loop above is broken)}"
  exit 1
fi
printf 'all %d test files passed\n' "$total"
