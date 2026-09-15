#!/usr/bin/env bash
# Assertions for the pack's test suite.
#
# Deliberately not `set -e`: a failing assertion has to be recorded and the file
# has to keep going. The counts are the result, not the exit status of the last
# command.
#
# **The harness proves it can fail before anything trusts it** - `run.sh`
# self-tests it on every run. Rule 12 once shipped unable to fail, because both
# its loops piped into `while read` and so `fail` ran in a subshell where the
# exit code was thrown away: it printed the error and returned 0. It was caught
# only because that one negative test checked `$?` instead of the message. A
# test suite that cannot report a failure is that same defect one level up, and
# it would hide every other defect underneath it.

set -uo pipefail

: "${REPO:?lib.sh needs REPO - the pack under test}"
: "${TEST_TMP:?lib.sh needs TEST_TMP - a scratch directory}"

_pass=0
_fail=0
_name=""

# Every result is also appended to a log file, because a counter cannot survive
# a subshell and a file can. `true | assert_eq ...` runs the assertion in a pipe:
# it printed FAIL and the summary still said 0 failed. `finish` counts the log,
# and treats any disagreement with the in-process counters as a failure of its
# own - an assertion that ran where its result could be lost is a broken test
# even when it happened to pass.
_log="$TEST_TMP/.assertions"
: > "$_log"
rm -f "$TEST_TMP/.result"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  _R=$'\033[31m'; _G=$'\033[32m'; _D=$'\033[2m'; _0=$'\033[0m'
else
  _R=""; _G=""; _D=""; _0=""
fi

_ok()  { _pass=$((_pass + 1)); printf 'ok %s\n' "$_name" >> "$_log"; printf '  %sok%s   %s\n' "$_G" "$_0" "$_name"; }
_no()  { _fail=$((_fail + 1)); printf 'FAIL %s\n' "$_name" >> "$_log"; printf '  %sFAIL%s %s\n       %s%s%s\n' "$_R" "$_0" "$_name" "$_D" "$1" "$_0"; }

section() { printf '\n%s\n' "$1"; }

# --- assertions -------------------------------------------------------------

# A command that must exit non-zero AND say something specific. Both halves
# matter: "it failed" is satisfied by a typo in the command, which is how a
# negative test comes to pass for the wrong reason.
assert_refuses() {
  _name="$1"; local needle="$2"; shift 2
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then
    _no "expected a non-zero exit, got 0"
  # Herestring, not a pipe. `grep -q` exits on its first match and closes the
  # pipe; the writer takes SIGPIPE; `set -o pipefail` above then reports the
  # pipeline as failed even though the match succeeded. It is a race on whether
  # the writer finished first, so it fires intermittently - it cost three
  # spurious failures in ten runs of the seam suite before being found. Every
  # assertion in this harness must be immune to it, because a harness that
  # fails at random is worse than one that fails always.
  elif grep -qF -- "$needle" <<< "$out"; then
    _ok
  else
    _no "exited $rc as expected, but no '$needle' in: $(printf '%s' "$out" | head -2 | tr '\n' ' ')"
  fi
}

assert_ok() {
  _name="$1"; shift
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  if [ "$rc" -eq 0 ]; then _ok; else
    _no "expected exit 0, got $rc: $(printf '%s' "$out" | tail -2 | tr '\n' ' ')"
  fi
}

assert_fails() {
  _name="$1"; shift
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  if [ "$rc" -ne 0 ]; then _ok; else _no "expected a non-zero exit, got 0"; fi
}

assert_eq() {
  _name="$1"
  if [ "$2" = "$3" ]; then _ok; else _no "expected '$2', got '$3'"; fi
}

assert_exists()  { _name="$1"; if [ -e "$2" ]; then _ok; else _no "missing: $2"; fi; }
assert_absent()  { _name="$1"; if [ ! -e "$2" ]; then _ok; else _no "should not exist: $2"; fi; }

# A pattern that must NOT be in a file that MUST exist. `assert_fails grep -q X
# file` passes on grep's exit 2 when the file is missing, so a step that deleted
# the file instead of rewriting it read as "the stale content is gone".
assert_lacks() {
  _name="$1"; local file="$2" pattern="$3"
  if [ ! -f "$file" ]; then _no "missing: $file - cannot show it lacks '$pattern'"
  elif grep -qE -- "$pattern" "$file"; then _no "'$pattern' found in $file"
  else _ok; fi
}

# --- fixtures ---------------------------------------------------------------

# A throwaway copy of the pack, so a rule can be broken and the real tree is
# never touched. `.git` is dropped: some tests run `git init` inside it.
#
# The directory name comes from mktemp, not from a counter. These are always
# called as `r=$(fresh_repo)`, which is a subshell - a counter incremented in
# here never survives, so every call handed back the *same* directory and each
# test inherited every previous test's damage. The suite caught that on its
# first run, because the rule 9 assertion checked the message and got rule 7's.
fresh_repo() {
  local d; d="$(mktemp -d "$TEST_TMP/repo.XXXXXX")"
  # Only what check.sh reads. Copying the whole tree pulled in .git (slow) and
  # tests/ - and tests/ mattered: rule 8 scans it, so a fixture script named in
  # this suite's own source counted as "referenced" and the negative test for an
  # unrouted script passed for the wrong reason.
  local item
  for item in skills template docs dev-notes lib check.sh install.sh \
              new-project.sh convert-to-parts.sh README.md CLAUDE.md AGENTS.md; do
    [ -e "$REPO/$item" ] && cp -R "$REPO/$item" "$d/"
  done
  # ...but leaving tests/ out entirely made the fixture red before any test broke
  # it: the prose names tests/lib.sh, run.sh and test-*.sh, so rule 8 reported
  # five "not a script" errors on the untouched copy, and every negative test got
  # its non-zero exit from rule 8 instead of the rule it was breaking. Empty stubs
  # resolve the names without adding any content for rule 8 to count as a
  # reference. test-lint.sh asserts the unbroken fixture lints green first.
  mkdir -p "$d/tests"
  local t
  for t in "$REPO"/tests/*.sh; do
    [ -e "$t" ] && : > "$d/tests/$(basename "$t")"
  done
  printf '%s' "$d"
}

workdir() {
  mktemp -d "$TEST_TMP/work.XXXXXX"
}

# Writes $TEST_TMP/.result, which run.sh requires: a file that stopped early -
# an `exit 0` halfway down - never gets here, and without the marker run.sh
# reports it failed instead of trusting an exit code that says nothing ran.
finish() {
  local p f
  p=$(grep -c '^ok ' "$_log" || true)
  f=$(grep -c '^FAIL ' "$_log" || true)
  if [ "$p" -ne "$_pass" ] || [ "$f" -ne "$_fail" ]; then
    f=$((f + 1))
    printf '  %sFAIL%s harness: %d assertion(s) ran in a subshell (a pipe or $(...)) - their result would have been lost\n' \
      "$_R" "$_0" "$(( (p + f - 1) - (_pass + _fail) ))"
  fi
  printf '\n  %d passed, %d failed\n' "$p" "$f"
  printf '%d %d\n' "$p" "$f" > "$TEST_TMP/.result"
  [ "$f" -eq 0 ]
}
