#!/usr/bin/env bash
# Shared part-name validation for new-project.sh and convert-to-parts.sh.
#
# Both scripts create only TOP-LEVEL part directories - a nested layout is
# lib/seed-part.sh's job, and each caller already prints its own pointer to it
# for a name containing '/'. What must not drift between them is everything
# else that makes a name usable at all, because it drifted once already:
# convert-to-parts.sh checked only '*/*', '.' and '..' while lib/seed-part.sh
# also refused a leading '-', a backslash, a space and an empty segment - so
# `convert-to-parts.sh --parts 'web,-api' --existing web` moved every file in
# the project into web/, THEN failed inside lib/seed-part.sh on '-api', after
# the destructive step had already run. Re-running reported "already a
# multi-part project" because the move itself had already happened.
#
# Usage: check_part_name "$name" || exit 1
# Prints its own error, naming the bad part, and returns 1 on a bad name.
# Callers still check for '/' themselves, before calling this, so each can
# point its own message at the route that does take a nested path.
check_part_name() {
  local name="$1"
  case "$name" in
    "")
      echo "Not a usable part name: '' (empty)." >&2
      return 1 ;;
    .|..)
      echo "Not a usable part name: '$name'." >&2
      return 1 ;;
    -*)
      echo "Not a usable part name: '$name' - a part name may not start with '-'." >&2
      return 1 ;;
    *\\*)
      echo "Not a usable part name: '$name' - a part name may not contain a backslash." >&2
      return 1 ;;
    *[[:space:]]*)
      echo "Not a usable part name: '$name' - a part name may not contain a space." >&2
      return 1 ;;
  esac
  return 0
}

# Usage: check_part_name_unique "$name" "${clean_parts[@]}"
# clean_parts is the list of names ALREADY accepted; $name is the one about to
# be added. Duplicates matter for two reasons at once: `new-project.sh dup
# --parts web,web` exited 0 with AGENTS.md listing web/ twice, and in
# convert-to-parts.sh a duplicate also defeated the "at least two parts" guard
# - `--parts web,web` has two entries and only one real part.
check_part_name_unique() {
  local name="$1"; shift
  local existing
  for existing in "$@"; do
    if [ "$existing" = "$name" ]; then
      echo "Not a usable part list: '$name' is listed more than once." >&2
      return 1
    fi
  done
  return 0
}
