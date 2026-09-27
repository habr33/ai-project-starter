# Re-run plan: one small project, end to end, against seams-J and seams-K

**Why:** the tests prove the skills agree with each other, not that an agent
following them produces the result they claim. Seven of the thirteen seams-J
fixes passed their tests and were still wrong. Only a run shows whether the
rest hold - the same kind of run that found them.

**Not the pressure-case tier** (`status.md`, *Still open* 3). That one grades a
headless agent under pressure; this is a coverage run, like the 2026-09-25 one
in `coverage.md`, with a checklist fixed before it starts.

## Setup

- **The same shape as last time, a different product**, so the comparison is
  fair and no answer is remembered: a one-page web tool, plain HTML/JS,
  `node:test` + Playwright, **not published** in section 8 at first.
- **Outside this repository**, in a directory a fresh session can find
  (`~/tmp/rerun-YYYY-MM-DD/`), with the pack at the commit under test.
- **A name holding `&`**, which exercises the README title fix for free.
- **The user's answers written before the run**, in the run's own notes: not
  published; a UI, so design is required; the first direction `prototype`
  offers; three items - **item 1 UI** (consumes some mockups), **item 2 non-UI**,
  **item 3 UI** (consumes the rest). Anything not scripted is answered the most
  ordinary way and logged as improvised.
- **Every skill followed as written.** Where one is ambiguous, log it and take
  the literal reading - that is a finding, not something to smooth over.

## Phases - each can stop and report on its own

| phase | skills | covers | budget |
|---|---|---|---|
| A | `new-project.sh` → `ideate` … `scaffold` → `ci` → `context` → `spec` → `prototype` → `spec` → `build` → `verify`/`review` → `ship` (item 1) | checks 1-9 | 100M processed, 600k output |
| B | items 2 and 3, `progress` after each `ship` | checks 10-11 | 70M, 400k |
| C | `preflight` (not published); plan changed to publish; `preflight` again; `ship` item-sized fix; `host` and `deploy` up to their first stop | checks 12-15 | 50M, 300k |

**Run A alone first**, then decide B and C from what A actually cost.

**A fresh session per phase, and per item inside B**, handing over through the
run's notes. Every turn re-reads the whole context, so a session's cost grows
faster than its work: the same item costs several times more late in a long
session than in a fresh one. Session length is the lever; the budget is the
backstop.

Nothing is provisioned or deployed: C stops `host` and `deploy` at the check
under test, before any target or cost.

## The checklist - write pass, fail or not reached for each

**Phase A**
1. README title is the name, `&` intact; first commit clean.
2. `layout` ran a probe for each trap claim, or marked it *unverified until
   `scaffold`*.
3. After `scaffold`: `git status --short` empty; the commit holds
   `coding-standards.md`, `project-plan.md`, `needs-you.md`, `decisions.md`;
   README commands filled; test output ignored.
4. After `ci`: it **asked** before committing; tree clean, with the `AGENTS.md`
   row and `status.md` line in the commit; nothing pushed.
5. After `context`: it **asked**; tree clean; README description filled.
6. After `prototype`: `design.md` and `prototypes/` committed on `main`.
7. `build`'s git status check found nothing foreign, and called `spec`'s own
   files the item's.
8. `build`'s packet counted the Playwright test against the served app as live.
9. `ship` item 1: no stop for unrelated work; archive has `## Prototypes kept`
   naming what item 3 still needs.

**Phase B**
10. After item 2 (non-UI) ships, `progress` does **not** call `prototypes/`
    drift.
11. After item 3 ships, `prototypes/` is gone and `progress` is clean.

**Phase C**
12. `preflight`, not published: says so first, asks whether a release is
    coming, writes **nothing** to the ledger.
13. Published: a release-only blocker (a real device) is offered as `deferred`
    to `deploy`, and the next `ship` is not held by it.
14. `deploy` stops on that deferred finding before naming a target; `host`
    names it before provisioning.
15. `preflight`'s pre-release audit lists it under **Blockers**, not Deferred.

**Also:** the kit's controls at 44px on touch, rendered with the touch block
forced on, textarea still 6rem.

## Recording

- **Every finding numbered and written down during the run**, fixed or not -
  the last run lost six by recording only the fixed ones.
- The result goes in `coverage.md` as a dated section, projects named by what
  they are; the checklist above with its marks; fixes and their tests follow as
  their own commits, each test seen failing first.

## Cost - measured between phases, not guessed

**Agreed 2026-09-28: the budgets in the phase table.** They are estimated from
the session logs of a larger project built with this pack, so a one-page tool
should come in under them. "Processed" is every token read per turn - mostly
cache reads, which are cheap - and output is the smaller, dearer part.

**At the end of each phase, measure it** from the local session logs, where
Claude Code writes one `.jsonl` per session under
`~/.claude/projects/<the run's path, with / as ->/`, **and each subagent's
turns in a separate file under `<session-id>/subagents/`** - which a
`*.jsonl` glob misses, and `build` Step 3 hands its steps to subagents:

```bash
python3 - $(find ~/.claude/projects/<run-dir> -name '*.jsonl') <<'PY'
import json, sys
seen, t = set(), [0, 0]
for f in sys.argv[1:]:
    for line in open(f):
        try: e = json.loads(line)
        except ValueError: continue
        m = e.get('message') or {}
        u = m.get('usage') if isinstance(m, dict) else None
        if e.get('type') == 'assistant' and u and m.get('id') not in seen:
            seen.add(m.get('id'))
            t[0] += sum(u.get(k, 0) for k in ('input_tokens',
                  'cache_creation_input_tokens', 'cache_read_input_tokens'))
            t[1] += u.get('output_tokens', 0)
print(f"{len(seen)} turns, {t[0]/1e6:.1f}M processed, {t[1]/1e3:.0f}k output")
PY
```

Pass only that phase's session files - each with its own `subagents/`
directory - to get one phase's cost. **Record each
phase's numbers in the run's notes and in `coverage.md`** - the last run's cost
was not recorded, which is why these budgets are estimates.

**Stop a phase at its budget**, report what it reached, and mark the checks it
did not reach as *not reached*. Going over is the user's call, never the run's.
