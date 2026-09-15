#!/usr/bin/env bash
# Lint the skill sources before committing.
#
# Small on purpose, but it catches the class of bug that actually shipped in the
# pack this replaces: a skill referring to another by a tool-specific name
# (/status) that had been renamed, wrong for every tool but one, and caught by
# nobody.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
errors=0
skills=0

fail() { echo "error  $1"; errors=$((errors + 1)); }

# The set of names that may be cross-referenced, taken from the files present.
known=""
for f in "$HERE"/skills/*.md; do
  known="$known $(basename "$f" .md)"
done

# Names this workflow used to have. A leftover reference to one of these is a
# stale cross-reference that nothing else would catch.
#
# The list lives in lib/retired-names because install.sh needs the same one, to
# remove a project's old skills on upgrade. Two copies of it is how the two
# stop agreeing - the same reason the seed scripts are shared.
retired_file="$HERE/lib/retired-names"
[ -f "$retired_file" ] || { echo "error  lib/retired-names is missing - rule 5 cannot run"; exit 1; }
retired="$(grep -v '^#' "$retired_file" | grep -v '^[[:space:]]*$' | tr '\n' ' ')"
[ -n "${retired// /}" ] || { echo "error  lib/retired-names is empty - rule 5 is not checking anything"; exit 1; }

# Names are [a-z0-9-] (rule 11), so neither alternation needs escaping.
alt_known=$(printf '%s' "$known" | sed 's/^ *//; s/ *$//; s/  */|/g')
alt_retired=$(printf '%s' "$retired" | sed 's/^ *//; s/ *$//; s/  */|/g')

for f in "$HERE"/skills/*.md; do
  name="$(basename "$f" .md)"
  skills=$((skills + 1))
  rel="skills/$name.md"

  # 1. frontmatter present and terminated
  if [ "$(head -1 "$f")" != "---" ]; then
    fail "$rel: missing frontmatter"
    continue
  fi
  if [ "$(tail -n +2 "$f" | grep -n '^---$' | head -1 | cut -d: -f1)" = "" ]; then
    fail "$rel: unterminated frontmatter"
    continue
  fi
  # The first `---` closes it, so everything before that must look like
  # frontmatter. Without this a file missing its terminator passed on any later
  # `---` - a horizontal rule - with the whole body parsed as YAML.
  fm=$(tail -n +2 "$f" | sed '/^---$/q' | sed '$d')
  if grep -qvE '^([A-Za-z_-]+:.*|[[:space:]].*|)$' <<< "$fm"; then
    fail "$rel: unterminated frontmatter - a body line comes before the closing ---"
    continue
  fi

  # 2. name matches the filename
  declared="$(grep -m1 '^name:' <<< "$fm" | sed 's/^name:[[:space:]]*//' | tr -d '"'"'" || true)"
  [ "$declared" = "$name" ] || fail "$rel: frontmatter name '$declared' != filename '$name'"

  # 3. description present - it drives skill auto-invocation
  grep -q '^description:' <<< "$fm" || fail "$rel: missing description"

  # 4. no tool-specific invocation syntax. Cross-references are plain names, so
  #    the same file reads correctly in every tool and on paper.
  #    One grep per file over an alternation of every name, not one per name:
  #    27 x 27 greps were most of this script's runtime. Each name is still
  #    reported once, at its first line.
  # A backtick does not excuse it - `/ship` is the same tool-specific call - and a
  # retired name written /idea is a stale call rule 5 cannot see either.
  hits=$(grep -noE "(^|[^[:alnum:]/_-])[/\$]($alt_known|$alt_retired)\b" "$f" || true)
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    fail "$rel:${h%%:*}: tool-specific reference to '${h##*[/\$]}' - use a plain name instead"
  done <<< "$(printf '%s\n' "$hits" | awk '{ k = $0; sub(/.*[\/$]/, "", k) } k != "" && !seen[k]++')"

  # 5. no reference to a skill that used to exist but does not any more. The
  #    tool-specific check above cannot see these, because a retired name written
  #    as a plain `name` looks exactly like ordinary prose.
  hits=$(grep -noE -- "\`($alt_retired)\`" "$f" || true)
  while IFS= read -r h; do
    [ -n "$h" ] || continue
    r=${h#*:}; r=${r//\`/}
    fail "$rel:${h%%:*}: refers to '$r', which is not a skill in this pack"
  done <<< "$(printf '%s\n' "$hits" | awk -F: '$2 != "" && !seen[$2]++')"

  # 6. numbered steps run in order, so the file works as a manual worksheet.
  #    A skill with no numbered steps is fine - but `|| true` is load-bearing:
  #    grep exits 1 on no match, pipefail propagates it, and `set -e` would kill
  #    the whole run here with no output at all. That silently skipped every
  #    later rule, including the reachability check below, which runs last.
  nums=$(grep -oE '^## Step [0-9]+' "$f" | grep -oE '[0-9]+' | tr '\n' ' ' || true)
  if [ -n "$nums" ]; then
    i=1
    for n in $nums; do
      [ "$n" = "$i" ] || { fail "$rel: step headings run [$nums] - expected $i in position $i"; break; }
      i=$((i + 1))
    done
  fi
done

# 7. Every skill must be reachable: something has to hand off to it, or nobody
#    will ever find it. `prototype` sat unreachable for the pack's whole life
#    because it declared its place in the flow and nothing routed to it. Entry
#    points are exempt - they are reached from the CLI or invoked by name.
entry_points="ideate setup autopilot"
#    Reachable means reachable from an entry point, followed hop by hop - not
#    "something names it". Two skills naming only each other passed the old count
#    while no path from anywhere a person starts ever led to either.
reached=" $entry_points "
frontier="$entry_points"
while [ -n "$frontier" ]; do
  next=""
  for src in $frontier; do
    [ -f "$HERE/skills/$src.md" ] || continue
    for dst in $(grep -oE "\`($alt_known)\`" "$HERE/skills/$src.md" | tr -d '\`' | sort -u || true); do
      case "$reached" in *" $dst "*) continue ;; esac
      reached="$reached$dst "; next="$next $dst"
    done
  done
  frontier="$next"
done
for f in "$HERE"/skills/*.md; do
  name="$(basename "$f" .md)"
  case "$reached" in *" $name "*) continue ;; esac
  routes=$(grep -l -- "\`$name\`" "$HERE"/skills/*.md 2>/dev/null | grep -vc "/$name.md" || true)
  if [ "${routes:-0}" -gt 0 ]; then
    fail "skills/$name.md: no route from an entry point ($entry_points) reaches it - only skills that are themselves unreachable name it"
  else
    fail "skills/$name.md: no other skill routes to it - it is unreachable"
  fi
done

# 8. Every script must be referenced somewhere a person will actually look, for
#    the same reason rule 7 exists for skills - and rule 7 does not cover them.
#    `convert-to-parts.sh` was written, tested against seven refusal cases, and
#    routed to by nothing at all: the pack's own "a skill nothing routes to is a
#    skill that does not exist", reproduced on a script within an hour of that
#    rule being re-read. Nothing here would have caught it.
prose="$HERE/README.md $HERE/CLAUDE.md $HERE/AGENTS.md"
for extra in "$HERE"/docs/*.md "$HERE"/skills/*.md "$HERE"/dev-notes/*.md \
             "$HERE"/*.sh "$HERE"/lib/*.sh "$HERE"/tests/*.sh; do
  [ -e "$extra" ] && prose="$prose $extra"
done

# tests/ is included on both sides. Leaving it out would have made every test
# script invisible to the one rule written because a script nothing routed to
# shipped anyway - the same defect, in the rule built to prevent it.
scripts=""
for s in "$HERE"/*.sh "$HERE"/lib/*.sh "$HERE"/tests/*.sh; do
  [ -e "$s" ] || continue
  scripts="$scripts ${s#"$HERE"/}"
done

for rel in $scripts; do
  # Search for the path as written. A lib/ script is referred to with its
  # directory, a root one by bare name, and both forms appear inside the other
  # scripts that call them.
  # A whole name, not a substring: a longer script name ending in this one is
  # not a reference to it.
  rel_re=$(printf '%s' "$rel" | sed 's/[.]/\\./g')
  refs=$(grep -l -E -- "(^|[^A-Za-z0-9_.-])$rel_re" $prose 2>/dev/null | grep -vc "/$rel\$" || true)
  [ "${refs:-0}" -gt 0 ] || fail "$rel: nothing references it - no docs, no skill, no other script"
done

# ...and the reverse: a script named in the prose that does not exist. A command
# in a guide that cannot be run is worse than an undocumented one, because
# somebody will type it.
#
# tests/ is excluded from *this* direction only. A test file names scripts that
# deliberately do not exist - fabricating a broken tree is what it is for - and
# reading those as claims turns every negative test into a lint error. It stays
# in the forward direction above, so a test script still has to be referenced.
prose_named=""
for pf in $prose; do
  case "$pf" in "$HERE"/tests/*) continue ;; esac
  prose_named="$prose_named $pf"
done
named=$(grep -ohE '(\./|lib/|tests/)?[a-z][a-z0-9-]*\.sh' $prose_named 2>/dev/null | sed 's|^\./||; s|^tests/||' | sort -u || true)
for n in $named; do
  [ -e "$HERE/$n" ] && continue
  # A bare name that exists under lib/ or tests/ is fine - the prose may not
  # qualify it with its directory.
  [ -e "$HERE/lib/$n" ] && continue
  [ -e "$HERE/tests/$n" ] && continue
  # tests/ is in the prefix set: without it a name qualified with that directory
  # never matched here, and the error printed with an empty location.
  where=$(grep -lE "(^|[^a-z0-9./-])(\./|lib/|tests/)?$n" $prose_named 2>/dev/null | head -1 || true)
  fail "${where#"$HERE"/}: refers to '$n', which is not a script in this repo"
done

# 9. Every field in the board's status-file example must have a writer, and a row
#    in that file's writer table. `Blocked on:` shipped with four readers -
#    orchestrate's deadlock detection, its stale-block hunt, and stop conditions
#    in spec and autopilot - and nothing that ever set it. Every reader reported
#    a confident `-` forever. `Item:` and `Updated:` were the same.
#
#    A mention is not a write. The first version of this rule counted any skill
#    naming `Blocked on:` as its writer, so deleting every status-block line that
#    set it still passed - `autopilot` also says it finds stale blocks "by
#    reading `Blocked on:`", and reading counted. So the writers come from the
#    declaration, the board's own "Who writes what" table, and each one must set
#    the field the way the board example does: an indented `**Field:**` line.
#
#    A backticked name in the writer columns must be a skill or a declared state
#    (`building`, `idle`...); anything else is a stale name after a rename.
#    "every write above" in a row means every skill the table names.
board="$HERE/template/blueprint/orchestration.md"
if [ ! -f "$board" ]; then
  fail "template/blueprint/orchestration.md is missing - rule 9 is not checking anything"
else
  # Field names contain spaces ("Blocked on", "Review packet"), so iterate over
  # lines rather than letting word-splitting take them apart.
  fields=$(sed -n '/^Each status file:/,/^\*\*States:\*\*/p' "$board" \
           | grep -oE '^[[:space:]]+\*\*[^*]+:\*\*' \
           | sed 's/^[[:space:]]*//; s/\*\*//g; s/:$//' || true)
  [ -n "$fields" ] || fail "template/blueprint/orchestration.md: cannot find the status-file example - rule 9 is not checking anything"
  states=" $(sed -n '/^\*\*States:\*\*/,/^$/p' "$board" | grep -oE '`[^`]+`' | tr -d '`' | tr '\n' ' ') "
  all_writers=""
  while IFS= read -r row; do
    for w in $(printf '%s' "$row" | awk -F'|' '{print $3 "|" $4}' | grep -oE '`[^`]+`' | tr -d '`' || true); do
      if [ -f "$HERE/skills/$w.md" ]; then
        case " $all_writers " in *" $w "*) ;; *) all_writers="$all_writers $w" ;; esac
      else
        case "$states" in *" $w "*) ;; *) fail "template/blueprint/orchestration.md: writer table names \`$w\`, which is neither a skill nor a declared state" ;; esac
      fi
    done
  done <<< "$(grep -E '^\| `[^`]+` \|' "$board" || true)"
  while IFS= read -r field; do
    [ -n "$field" ] || continue
    row=$(grep -F -- "| \`$field\` |" "$board" | head -1 || true)
    if [ -z "$row" ]; then
      fail "template/blueprint/orchestration.md: field '$field' has no row in the writer table"
      continue
    fi
    if printf '%s' "$row" | grep -qF 'every write above'; then
      declared="$all_writers"
    else
      declared=""
      for w in $(printf '%s' "$row" | awk -F'|' '{print $3 "|" $4}' | grep -oE '`[^`]+`' | tr -d '`' || true); do
        [ -f "$HERE/skills/$w.md" ] && declared="$declared $w"
      done
    fi
    written=0
    for w in $declared; do
      if grep -qE "^[[:space:]]+\*\*$field:\*\*" "$HERE/skills/$w.md"; then
        written=$((written + 1))
      else
        fail "template/blueprint/orchestration.md: table says \`$w\` writes '$field', but skills/$w.md never sets it in a status block"
      fi
    done
    [ "$written" -gt 0 ] \
      || fail "template/blueprint/orchestration.md: field '$field' has no writer - no declared writer sets it, and a reader is not a writer"
  done <<< "$fields"
fi

# 10 - every skill states its preconditions, and the entry points are declared.
#
#    A skill that reads state written by an earlier step must say what happens
#    when that step has not run. Without it the skill proceeds confidently on a
#    placeholder file - which is how `coding-standards.md` went four readers deep
#    with nothing written to it, and how `spec` could overwrite an in-flight item.
#
#    The exempt list is the entry points and the read-only reporters: they work
#    in any project state by design. Anything else must carry the heading.
# `ideate` came off this list when it gained a --rescope mode. It was exempt as a
# greenfield entry point - "works in any project state by design" - and that
# stopped being true the moment it could run against a plan with built work
# behind it. An exemption is a claim about the skill, not a permanent property.
exempt_preconditions="setup progress preflight debug docs prepare"

# An exemption naming a skill that does not exist is dead config, and it hides
# the thing it was meant to exempt: this list still said `idea` after the rename
# to `ideate`, so the entry point was being checked by a rule it is exempt from
# and only passed because other skills happen to route to it. Both lists are
# checked against the files present.
for n in $entry_points $exempt_preconditions; do
  [ -f "$HERE/skills/$n.md" ] \
    || fail "check.sh: exempt list names \`$n\`, which is not a skill - a stale entry after a rename"
done

for f in "$HERE"/skills/*.md; do
  name=$(basename "$f" .md)
  case " $exempt_preconditions " in
    *" $name "*) 
      grep -q '^## Before you start' "$f" \
        && fail "skills/$name.md: has '## Before you start' but is on the exempt list - remove it from exempt_preconditions in check.sh"
      continue ;;
  esac
  grep -q '^## Before you start' "$f" \
    || fail "skills/$name.md: no '## Before you start' - say what this skill needs and what to run when it is missing, or add it to exempt_preconditions in check.sh"
done

# 11 - frontmatter stays within what every host tool accepts.
#
#    Claude Code, opencode and anything else reading `SKILL.md` cap the
#    description and constrain the name. A skill that breaks either is not
#    reported as broken - it silently does not load, which looks exactly like the
#    agent choosing not to use it.
for f in "$HERE"/skills/*.md; do
  name=$(basename "$f" .md)
  desc=$(sed -n '/^---$/,/^---$/p' "$f" | sed -n 's/^description:[[:space:]]*//p' | sed 's/^"//; s/"$//')
  # A YAML block scalar (`>-`, `|`) puts the text on the lines below, where this
  # length check and install.sh's wrapper generation both read nothing.
  case "$desc" in
    ">"*|"|"*) fail "skills/$name.md: description must be on one line - a block scalar hides it from the length check and the wrappers"; continue ;;
  esac
  len=${#desc}
  [ "$len" -le 1024 ] \
    || fail "skills/$name.md: description is $len characters, over the 1024 limit - it will silently fail to load"
  [ "$len" -ge 1 ] \
    || fail "skills/$name.md: description is empty"
  printf '%s' "$name" | grep -qE '^[a-z0-9]+(-[a-z0-9]+)*$' \
    || fail "skills/$name.md: name must be lowercase alphanumeric with single hyphens"
done

# 12 - every state file the skills read has a declared writer, and that writer
#      declares that it writes it.
#
#    This is rule 9 applied to project state rather than board fields, and it
#    exists because the same defect keeps recurring in a new place: a file with
#    several readers and nothing that ever writes it. `coding-standards.md` had
#    four readers and a writer reachable only from the brownfield path; the plan's
#    UI/UX section had a reader and no writer at all; `Blocked on:` had four
#    readers and none.
#
#    Two declarations, which must agree: the table in template/AGENTS.md, and a
#    `**Writes:**` line in every skill. A file the skills reference must have a
#    row; the skills a row names as writers must be exactly the skills whose
#    Writes: line names that file; and a declared file must also be named
#    somewhere else in the skill, so a declaration has an instruction behind it.
#
#    The Writes: line replaced "the writer mentions the file", which any reader
#    passes - a reader declared as a writer read as green, and a real writer the
#    table omitted was never looked for. Written down, the first audit found seven:
#    `rollback` writes current-work.md, `build` and `architect` write
#    needs-you.md, and `ideate`, `host`, `migrate` and `ci` write dev-notes files,
#    none of them in the table. `nothing` is a declaration too, so every skill
#    has answered the question once.
agents="$HERE/template/AGENTS.md"
if [ ! -f "$agents" ]; then
  # Checked before anything reads it. Missing, this file used to skip rule 12
  # and then kill the script under pipefail at rule 13 - exit 2, no output.
  fail "template/AGENTS.md is missing - rules 12 and 13 are not checking anything"
else
  rows=$(grep -oE '^\| `[^`]+` \| [^|]+ \| [^|]+ \|$' "$agents" || true)
  [ -n "$rows" ] \
    || fail "template/AGENTS.md: cannot find the state/writer table - rule 12 is not checking anything"

  # NOTE: both loops read from a herestring, never a pipe. `fail` increments a
  # counter, and a pipe would run it in a subshell - the error would print and
  # the exit code would stay 0. That is exactly the "rule that reports but cannot
  # fail" this file already got wrong once, so it is negative-tested on the exit
  # code, not on the message.

  # Every state file a skill names must have a row - one reader is enough. This
  # once required two, and the plan's UI/UX section, the bug the rule cites, had
  # exactly one reader. It also only looked in blueprint/context/ for lowercase
  # hyphenated names, while the table has rows elsewhere; a file under a
  # directory row (blueprint/history/) is covered by that row.
  dir_rows=$(printf '%s\n' "$rows" | sed -n 's/^| `\([^`]*\/\)`.*/\1/p')
  counts=$(for f in "$HERE"/skills/*.md; do
    grep -ohE '(blueprint|dev-notes)/[A-Za-z0-9_./-]*[A-Za-z0-9_-]\.md' "$f" | sort -u || true
  done | sort | uniq -c)
  while read -r n path; do
    [ -n "$path" ] || continue
    printf '%s' "$rows" | grep -qF -- "| \`$path\` |" && continue
    covered=""
    for d in $dir_rows; do
      case "$path" in "$d"*) covered=1 ;; esac
    done
    [ -n "$covered" ] \
      || fail "template/AGENTS.md: $path is read by $n skill(s) but has no row in the state/writer table"
  done <<< "$counts"

  # Every skill's Writes: line - one, naming files in backticks, or `nothing`.
  declared=""
  for f in "$HERE"/skills/*.md; do
    n=$(basename "$f" .md)
    wl=$(grep '^\*\*Writes:\*\*' "$f" || true)
    if [ -z "$wl" ]; then
      fail "skills/$n.md: no '**Writes:**' line - declare the state files it writes, or 'nothing'"; continue
    fi
    [ "$(printf '%s\n' "$wl" | wc -l | tr -d ' ')" = 1 ] \
      || { fail "skills/$n.md: more than one '**Writes:**' line"; continue; }
    paths=$(printf '%s' "$wl" | grep -oE '`[^`]+`' | tr -d '`' || true)
    if [ -z "$paths" ]; then
      [ "$wl" = "**Writes:** nothing" ] \
        || fail "skills/$n.md: '**Writes:**' names no file in backticks and is not 'nothing'"
      continue
    fi
    for p in $paths; do
      printf '%s' "$rows" | grep -qF -- "| \`$p\` |" \
        || fail "skills/$n.md: declares it writes $p, which has no row in template/AGENTS.md's state/writer table"
      # Herestring, not a pipe: see tests/lib.sh on grep -q and SIGPIPE.
      grep -qF -- "${p%/}" <<< "$(grep -v '^\*\*Writes:\*\*' "$f")" \
        || fail "skills/$n.md: declares it writes $p, but nothing else in the skill names it - a declaration with no instruction behind it"
      declared="$declared$n $p"$'\n'
    done
  done

  # The table's writers must be exactly the skills that declare the file.
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    path=$(printf '%s' "$row" | sed 's/^| `\([^`]*\)`.*/\1/')
    writers=$(printf '%s' "$row" | awk -F'|' '{print $4}' | grep -oE '`[a-z-]+`' | tr -d '`' || true)
    for w in $writers; do
      if [ ! -f "$HERE/skills/$w.md" ]; then
        fail "template/AGENTS.md: $path names \`$w\` as its writer, which is not a skill"; continue
      fi
      grep -qxF -- "$w $path" <<< "$declared" \
        || fail "template/AGENTS.md: table says \`$w\` writes $path, but skills/$w.md's **Writes:** line does not name it"
    done
  done <<< "$rows"
  while read -r n p; do
    [ -n "$p" ] || continue
    row=$(grep -F -- "| \`$p\` |" <<< "$rows" | head -1 || true)
    [ -n "$row" ] || continue
    grep -qF -- "\`$n\`" <<< "$(printf '%s' "$row" | awk -F'|' '{print $4}')" \
      || fail "skills/$n.md: declares it writes $p, but template/AGENTS.md does not name \`$n\` as its writer"
  done <<< "$declared"
fi

# 13 - a file that lives at the product root is named as such by every skill
#      that reads it.
#
#    The path class, finally made checkable for the shape that keeps recurring:
#    a skill running inside a part reads `blueprint/x.md`, which there means that
#    part's own directory, while the file actually lives at the product root. Six
#    times now - `spec`, `build`, `ship` and `autopilot` once, `orchestrate`
#    again, then `quality-bar.md`, and then five more skills (`host`, `deploy`,
#    `migrate`, `prepare`, `docs`) reading a product plan that does not exist in
#    a part at all. `host` reads it to decide whether to spend money.
#
#    Every file is valid and every string is right; only the runtime directory is
#    wrong, which is why this class was long recorded as unlintable. It is lintable
#    once the product-level files are *declared* - the same move that made rules
#    9 and 12 possible. template/AGENTS.md's multi-part marker is the list.
#
#    Carrying the note is what satisfies this. A skill that only mentions a file
#    inside the note passes, correctly.
product_files=""
[ -f "$agents" ] && product_files=$(sed -n 's|^ *<product root>/\([A-Za-z0-9_./-]*\).*|\1|p' "$agents" \
                | sed 's/\.$//' | sort -u)
if [ -z "$product_files" ]; then
  fail "template/AGENTS.md: no <product root>/ files declared - rule 13 is not checking anything"
else
  while IFS= read -r pf; do
    [ -n "$pf" ] || continue
    # A file is also named by its bare filename in backticks - `orchestration.md`
    # read from inside a part resolves exactly as wrongly as the full path does.
    bare=""; case "$pf" in *.md) bare="\`${pf##*/}\`" ;; esac
    for sk in "$HERE"/skills/*.md; do
      grep -qF -- "$pf" "$sk" || { [ -n "$bare" ] && grep -qF -- "$bare" "$sk"; } || continue
      grep -qF -- 'Product root:' "$sk" \
        || fail "skills/$(basename "$sk"): names $pf, which lives at the product root, without saying where it resolves"
    done
  done <<< "$product_files"
fi

# 14 - a skill that writes a foundational decision says what happens when that
#    decision already exists.
#
#    `ideate` assumed a fresh project: run against a plan with shipped items it
#    would propose a whole new build plan, and approving one erases the `- [x]`
#    marks that are the entire resume mechanism. It then handed off to `stack`,
#    which refuses a project that has code. A dead end that destroyed state on
#    the way in, and every file involved was individually valid.
#
#    The same shape was in three more: `architect` never said that re-deciding a
#    layout after `scaffold` moves every file - the pack knew, and said it in
#    `autopilot` instead. `prototype` never said a second `design.md` can end up
#    describing a look the code does not have, which makes `review` measure
#    against a bar nobody built to. `stack` sent two different situations to the
#    same wrong answer.
#
#    `host` joined them: it provisions paid infrastructure, and nothing in its
#    preconditions said what a second run does when hosting is already there.
#
#    These are the skills whose output a project commits to and may later
#    need to change. Read-only reporters and per-item skills are not on the list:
#    re-running `review` or `progress` costs nothing. **The list is the rule** -
#    a fifth decision-writing skill has to be added here deliberately, which is
#    the point at which someone asks the question this rule exists to force.
decision_skills="ideate stack architect layout prototype host"

for n in $decision_skills; do
  [ -f "$HERE/skills/$n.md" ] \
    || fail "check.sh: decision_skills names \`$n\`, which is not a skill - a stale entry after a rename"
done

for n in $decision_skills; do
  f="$HERE/skills/$n.md"
  [ -f "$f" ] || continue
  # The claim must live in the preconditions, where a skill states what it needs
  # before acting - not buried in a later step that only runs once it has begun.
  pre=$(sed -n '/^## Before you start/,/^## [^B]/p' "$f")
  [ -n "$pre" ] || { fail "skills/$n.md: on decision_skills but has no '## Before you start'"; continue; }
  # The claim is a declared shape, not a phrase: a bold lead - a paragraph or a
  # bullet opening with `**` - whose bold text says the decision is already
  # there. Matching "already has" anywhere let "If the user already has an
  # opinion, ask" satisfy the rule, and `scaffold` passed by accident on "a shape
  # that has already been chosen", a sentence about somebody else's decision.
  printf '%s' "$pre" | grep -qE '^(- )?\*\*[^*]*already (exists|filled|recorded|decided|has|have|been)' \
    || fail "skills/$n.md: writes a foundational decision but its preconditions never say what happens when that decision already exists - see rule 14 in check.sh"
done

# 15 - a mode a skill declares in its `## Input` table is named in its
#    description.
#
#    The description is what an agent matches a request against, so a mode
#    missing from it is a capability only someone who already knows about it can
#    reach. `docs --check` was that: its own Input row, its own section, and a
#    question the skill itself says nothing else in this workflow asks - audit
#    what is written against what is true - invisible to every agent choosing a
#    skill. `review full` was the same, one step milder: the prose said "the
#    whole project" without ever naming the argument.
#
#    No declared list here - the Input tables ARE the declaration, which is why
#    this rule can be strict. A mode worth a table row is worth six words in the
#    description.
for f in "$HERE"/skills/*.md; do
  name=$(basename "$f" .md)
  grep -q '^## Input' "$f" || continue
  desc=$(sed -n '/^description:/,/^---$/p' "$f")
  # `|| true`: set -euo pipefail is on, and five skills have an Input table with
  # no backticked argument rows (they describe inputs in prose). Without it grep's
  # empty result aborts the whole script - silently, exit 1 and not one message,
  # which looks exactly like a linter that found nothing to say.
  args=$(sed -n '/^## Input/,/^## [^I]/p' "$f" | grep -oE '^\| `[^`]+`' | sed 's/^| //; s/`//g' | sort -u || true)
  for a in $args; do
    # A --flag is distinctive; a word-like mode (`current`, `full`) must appear
    # in backticks, or ordinary prose like "the current work" satisfies it.
    needle="$a"; case "$a" in --*) ;; *) needle="\`$a\`" ;; esac
    grep -qF -- "$needle" <<< "$desc" \
      || fail "skills/$name.md: declares mode '$a' in its Input table but never names it in the description - an agent matching on the description cannot reach it"
  done
done

# 16 - no script refuses after its first write, unless the refusal says why that
#    leaves nothing half-made.
#
#    Three times a script wrote first and validated second: lib/seed-part.sh
#    (2026-09-09), new-project.sh (2026-09-10), and convert-to-parts.sh
#    (2026-09-15), which moved every file in the project into the first part and
#    only then refused `-api`. A refused run leaves a half-made tree, and the
#    retry with the typo corrected is then blocked by the half-made tree.
#
#    Two of the three refusals were not in the script that wrote - they were in
#    lib/seed-part.sh, called after the caller's writes. So a call to a pack
#    script that can refuse counts as a refusal too, and "can refuse" is
#    transitive: seed-product-root.sh has no exit of its own but calls install.sh.
#
#    The declaration is a comment that opens with `after-write:` and gives a
#    reason, on the refusing line or in the comment block directly above its
#    statement. Not a
#    line number: those go stale on the next edit. The marker is a claim, and the
#    rule cannot check the claim - it can only make somebody write it. A marker
#    that covers nothing is an error, for the same reason a stale name in any
#    declared list is: dead config hides the thing it was meant to check.
#
#    tests/ is excluded: a test writes a fixture and then fails on purpose.
r16_refusal='(^|[^a-z_])exit[[:space:]]+([1-9]|\$)|sys\.exit\([1-9]|\$\{[A-Za-z0-9_]+:\?'
r16_scripts=""
for s in "$HERE"/*.sh "$HERE"/lib/*.sh; do [ -e "$s" ] && r16_scripts="$r16_scripts ${s#"$HERE"/}"; done
r16_refusers=" "
for s in $r16_scripts; do
  grep -qE "$r16_refusal" <<< "$(grep -vE '^[[:space:]]*#' "$HERE/$s")" && r16_refusers="$r16_refusers$s "
done
r16_grew=1
while [ "$r16_grew" -eq 1 ]; do
  r16_grew=0
  for s in $r16_scripts; do
    case "$r16_refusers" in *" $s "*) continue ;; esac
    for c in $(grep -vE '^[[:space:]]*#' "$HERE/$s" | grep -oE '\$HERE/(lib/)?[a-z0-9-]+\.sh' | sed 's|^\$HERE/||' || true); do
      case "$r16_refusers" in *" $c "*) r16_refusers="$r16_refusers$s "; r16_grew=1; break ;; esac
    done
  done
done
r16_awk=$(cat <<'AWK'
function stripq(s) { gsub(/"[^"]*"/, "\"\"", s); gsub(/'[^']*'/, "''", s); return s }
# The marker line covering line n, or 0: on n itself, or in the comment block
# directly above the start of n's statement (walking up through `\` lines).
function marker(n,   i) {
  if (line[n] ~ M) return n
  i = n
  while (i > 1 && line[i-1] ~ /\\[[:space:]]*$/) i--
  for (i = i - 1; i >= 1 && line[i] ~ /^[[:space:]]*#/; i--) if (line[i] ~ M) return i
  return 0
}
{ line[NR] = $0 }
END {
  # `after-write:` must open the comment, so prose mentioning it is not one.
  M = "(^|[[:space:]])#[[:space:]]*after-write:[[:space:]]*[^[:space:]]"
  first = 0; term = ""
  for (n = 1; n <= NR; n++) {
    l = line[n]; body = 0
    if (term != "") {
      if (l ~ "^[[:space:]]*" term "[[:space:]]*$") { term = ""; continue }
      body = 1
    }
    if (!body && l ~ /^[[:space:]]*#/) continue
    code = body ? l : stripq(l)
    # Found on the quote-stripped line, so a `<<` inside a string is not one; the
    # terminator is read from the raw line, because stripping empties <<'USAGE'.
    if (!body && code ~ /<</ && match(l, /<<-?[[:space:]]*['"]?[A-Za-z_]+/)) {
      term = substr(l, RSTART, RLENGTH); sub(/^<<-?[[:space:]]*['"]?/, "", term)
    }
    if (!first) {
      if (body) w = (code ~ /\.write_text\(|\.write\(/)
      else w = (code ~ /(^|[;&|{([:space:]])(mkdir|cp|mv|rm|ln|touch|tee)[[:space:]]/ \
             || code ~ /git[[:space:]]+(-C[[:space:]]+[^[:space:]]+[[:space:]]+)?(init|add|commit|mv|rm)([[:space:]]|$)/ \
             || code ~ /sed[[:space:]]+-i/ \
             || code ~ /[^0-9&<]>>?[[:space:]]*[^&[:space:]\/]/)
      if (w) first = n
      continue
    }
    why = ""
    if (body) { if (code ~ /sys\.exit\([1-9]/) why = "exits non-zero" }
    else if (code ~ /(^|[^a-z_])exit[[:space:]]+([1-9]|\$)/) why = "exits non-zero"
    else if (code !~ /^[[:space:]]*(source|\.)[[:space:]]/ && match(l, /\$HERE\/(lib\/)?[a-z0-9-]+\.sh/)) {
      callee = substr(l, RSTART + 6, RLENGTH - 6)
      if (index(refusers, " " callee " ")) why = "calls " callee ", which can refuse,"
    }
    if (why == "") continue
    m = marker(n)
    if (m) used[m] = 1
    else printf "%s:%d: %s after its first write (line %d) - a refusal there leaves a half-made tree. Move the check above that write, or mark it with a comment '# after-write: <why nothing is left half-made>'\n", rel, n, why, first
  }
  for (n = 1; n <= NR; n++)
    if (line[n] ~ M && !used[n])
      printf "%s:%d: an after-write marker that covers no refusal after a write - remove it, or it hides the next one\n", rel, n
}
AWK
)
for s in $r16_scripts; do
  while IFS= read -r msg; do
    [ -n "$msg" ] && fail "$msg"
  done <<< "$(awk -v refusers="$r16_refusers" -v rel="$s" "$r16_awk" "$HERE/$s")"
done

if [ "$errors" -gt 0 ]; then
  echo
  echo "$errors error(s) across $skills skill(s)."
  exit 1
fi

echo "OK - $skills skills, frontmatter valid, no tool-specific references, steps in order,"
echo "     every script referenced, every board field written, every skill states"
echo "     its preconditions, frontmatter within host limits, every state file a writer,"
echo "     every product-root file named as one, every decision skill says what"
echo "     happens when its decision already exists, every declared mode named"
echo "     in its description, no script refusing after it has written"
