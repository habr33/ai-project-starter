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

| phase | skills | covers |
|---|---|---|
| A | `new-project.sh` → `ideate` … `scaffold` → `ci` → `context` → `spec` → `prototype` → `spec` → `build` → `verify`/`review` → `ship` (item 1) | checks 1-9 |
| B | items 2 and 3, `progress` after each `ship` | checks 10-11 |
| C | `preflight` (not published); plan changed to publish; `preflight` again; `ship` item-sized fix; `host` and `deploy` up to their first stop | checks 12-15 |

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

## Cost - needs the user's number before starting

The last run's token count was not recorded; **record this one's**. Phase A is
most of the work. **Set a cap, and the run stops at the end of the phase that
reaches it**, reporting what it has.
