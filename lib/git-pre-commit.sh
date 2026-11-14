#!/usr/bin/env bash
# git pre-commit hook, installed by `install.sh --git-hooks` as
# .agents/git-hooks/pre-commit and made active with core.hooksPath. See D23.
#
# Runs the project checker over what the commit will hold (--staged), from the
# repository's top level - at a multi-part product's root that covers every
# part. Exit 1 from the checker refuses the commit and prints its lines.
#
# It fails open: no checker, or one that could not run (exit 2), and the commit
# goes through with one line saying so. It is a tripwire for honest mistakes,
# not a wall - `--no-verify` skips it, and CI runs the same check on the push.
top=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
ck="$top/.agents/bin/check-project.sh"
if [ ! -x "$ck" ]; then
  echo "pre-commit: no .agents/bin/check-project.sh here - nothing was checked (install.sh puts it there)" >&2
  exit 0
fi
out=$("$ck" --staged "$top" 2>&1); rc=$?
case "$rc" in
  0) exit 0 ;;
  1) printf '%s\n' "$out" >&2
     echo "pre-commit: commit refused - run the skill each line names, then stage again" >&2
     exit 1 ;;
  *) echo "pre-commit: the project checker could not run - nothing was checked: $(printf '%s' "$out" | head -1)" >&2
     exit 0 ;;
esac
