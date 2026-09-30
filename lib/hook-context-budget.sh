#!/usr/bin/env bash
# Claude Code SessionStart hook, installed by `install.sh --hooks` as
# .claude/hooks/hook-context-budget.sh. See D20.
#
# Adds up what CLAUDE.md loads - itself and every `@` import, as check.sh rule
# 18 counts it - against the `**Context budget: N KB.**` line in AGENTS.md. Over
# it, one line goes into the session; under it, nothing. `progress` reports the
# same, but only when someone runs it, and loaded files grow by accretion.
#
# It fails open: no CLAUDE.md, no stated budget, and it prints nothing.
dir="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -f "$dir/CLAUDE.md" ] || exit 0
budget_kb=$(grep -oE '^\*\*Context budget: [0-9]+ KB\.\*\*' "$dir/AGENTS.md" 2>/dev/null | grep -oE '[0-9]+' || true)
[ -n "$budget_kb" ] || exit 0

total=$(wc -c < "$dir/CLAUDE.md")
sizes=""
while IFS= read -r imp; do
  [ -f "$dir/$imp" ] || continue
  n=$(wc -c < "$dir/$imp")
  total=$((total + n))
  sizes="$sizes$n $imp"$'\n'
done <<< "$(sed -n 's/^@//p' "$dir/CLAUDE.md")"

max=$((budget_kb * 1024))
[ "$total" -gt "$max" ] || exit 0
largest=$(printf '%s' "$sizes" | sort -rn | head -3 | awk '{print $2 " (" $1 ")"}' | paste -sd, - | sed 's/,/, /g')
echo "Always-loaded context is $total bytes, over the $budget_kb KB budget in AGENTS.md ($max) - largest: $largest. Run progress to see what can move out."
