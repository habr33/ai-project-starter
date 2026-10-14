# Status

Read this first after a break. `decisions.md` explains why the repo is shaped
this way - read D2 and D3 before changing its structure. `coverage.md` is the one
place that answers "has this skill actually run?".

> **Before doing anything else, check what is not committed** (`git status`),
> then run `./check.sh` and `./tests/run.sh`. They must report `OK` and **every
> test file passing with zero failures**. If they do not, the tree has
> been disturbed since the last recorded run - find out why before changing
> anything.
>
> **The count is deliberately not written here.** It moves every time a test is
> added, and a number that goes stale on every commit teaches people to skip the
> line it sits in - which is the defect class this file is mostly a record of.
> Zero failures is the invariant; the total is not.

## Where work stopped (2026-10-12)

**Goal:** work through `dev-notes/todos-2026-10-12.md` (what an installed
project loads, and what a run did not read). **Its workable items are done**;
C (mods) is parked on "not yet", and D's role team is not in the pack.

**Done, all on `main` and pushed** (the work ends at `45088f6`): `context`
renamed `distill` (e809791, b9a027c, D22 e62fa21); `install.sh` reports a
loaded context over budget without `--hooks` (97746a3); `review`'s
`Reviewed:` line says `read whole`, `PARTLY READ: <what>` or `NOT READ: <why>`
and `ship` does not take a partial one as clean (9c2ffec); five longest
descriptions trimmed, 16,044 -> 15,547 bytes, routing 34/34 (9dfe762);
`progress` reports an overview over its 8 KB cap and `install.sh` a CLAUDE.md
without `@AGENTS.md`, report only (45088f6). B4 (state files that only grow)
closed as covered by D15. Evidence: `./check.sh` OK and `./tests/run.sh` 0
failed after 45088f6; every new assertion seen failing under a real mutation.

**In progress:** nothing in this repo. Projects installed earlier still run the
old skills until re-installed - do it only between items, never mid-item.

**Next:**

1. The user's call: add a compliance step to `preflight` - ask where the
   product is sold and what data it handles, then list which legal documents
   apply (privacy policy, terms, licence notices, cookie consent, DPAs,
   accessibility statement, AI disclosure, CRA/SBOM) and file the missing ones
   as `needs-you` lines. Today it checks only a licence and a privacy policy.
2. Update an installed project, once it is back on a clean `main`:
   `install.sh --target <dir>`, read its report, commit there, restart that
   session (descriptions load at session start).

**Review, 2026-10-14:** `./check.sh` OK (18 rules, 27 skills),
`./tests/run.sh` 0 failed, nothing unpushed. Open after the two items above:

- The user's call: fold `prepare` into `progress`, `layout` into `stack`, drop
  the overview's *Current state* so `distill` is not needed after every
  `ship`, and install a core skill set by default (proposed 2026-09-28).
- Item 6's second half (`D21`): a Claude Code plugin package alongside the
  scripts. Not started.
- `D23`, agreed, not built: a project checker and a git pre-commit hook.
  Next work: `harness-plan.md`, Task 1; Task 6 is a paid trial - ask first.
- P3: a shorter house style in the skills (*Can be done here*, below).
- C (mods) in `todos-2026-10-12.md`: four unchecked boxes, parked on "not
  yet". The rest of that file is done - keep it or delete it.
- `cms-rr` re-install and its two findings: needs the directory's path
  (*Closed, and where the detail lives*, below).
- Rebuild the pressure fixtures before the next pressure run: they predate the
  archive ID prefix fix and every skill change since.
- Runs, not work: the reorder's headline result (*Recommendations*, 2), and
  the prose listed under *Unverified, and worth a real run*, below.
- Resource-bound (*Needs a person*, below): device, managed host, two live
  sessions, macOS/BSD, a new user, Flutter.

**Gotchas:**

- **The pack is standalone.** No skill, doc or note names an outside agent
  team, a `~/para` path, or a personal skill. A team routes to itself.
- Installing into a project mid-item mixes pack files into the item's diff,
  and `ship`'s first check is that every changed file belongs to the spec.
- A negative assertion written as `sh -c '! grep ... <<EOF $out EOF'` can
  never fail - `$out` is single-quoted. Use `assert_eq "" "$(grep ... <<<"$out")"`.
- Editing a test file while `./tests/run.sh` runs changes what that run tests;
  re-run before trusting it.

## Where work stopped (2026-10-04)

**A review of one installed project (`bulmaya-logistics`), fixed on `main`
(`2a0f4f2`, `3a0d46c`).** Every skill was read against the others in a fresh
project. **The one defect that broke the loop:** `new-project.sh`'s `bin/` rule
also matched `.agents/bin/`, so `7cb2c55`'s merge script was on disk and absent
from every clone - the existing test checked the file existed, not that git kept
it. Now re-included, and `install.sh` reports a project `.gitignore` that hides
it (writes none). Also fixed: the merge script dropped any non-claim line of a
capability file; `host`, `deploy`, `migrate`, `monitor` and `docs` never asked to
commit while `deploy` refuses a dirty tree; `review` counted finding IDs from the
index alone, which reused a backlogged P3's file; fix archives had no date and
collided; `build` had no rollback branch; and six contradictions between skills
and `template/AGENTS.md` (ci caching, autopilot's commits and closes, progress
drift on main, verify and preflight's own writes, the stale exempt list).
Tests: 35 assertions across *every script a skill runs inside a project*, *the
capability merge, D21*, and four new sections at the end of
`tests/test-seams.sh`, each seen failing against the old code or text. Rule 18
headroom 239 -> 87. **Projects already created** keep the `bin/` ignore until
they add the two lines `install.sh` now prints.

## Where work stopped (2026-10-01)

**Item 6, first half: living capability specs, committed on `main` (`5eaec86`)**
(`D21`; design and plan in `capabilities-design.md` and `capabilities-plan.md`).
A spec declares `## Behaviour changes`; `ship` merges them into
`blueprint/capabilities/` with `lib/merge-capabilities.sh`; `rollback` writes
the inverse; `verify --all` proves the files and seeds them per archive from
old ones. `template/AGENTS.md` got a row and was trimmed by the same bytes
(rule 18 headroom 239). Tests: *the capability merge, D21* in
`tests/test-scripts.sh`; *behaviour travels from spec to capabilities, D21* in
`tests/test-seams.sh`, four assertions checked under real mutations.
**Unproven against an agent**: no agent has written the section, merged it
through `ship` or seeded a project. **Not done:** the plugin package (item 6's
second half).

## Closed, and where the detail lives (2026-09-25 to 2026-09-30)

A market comparison (Spec Kit, Superpowers, GSD, BMAD, OpenSpec, Kiro) set an
agreed order of six items; five are done and the sixth is half done (above).
**The per-change narrative is not repeated here** - it is in the commit
messages, in `decisions.md`, in `coverage.md`'s dated runs, and in the section
comments beside the assertions that hold each fix:

- **`seams-G` review and `D18`** (`b2e2477`): design is required wherever there
  is a UI; `check.sh` rule 1's SIGPIPE; `build`'s packet; undeclared writes
  declared. Then a small project end to end (`seams-J`, 2026-09-25) and a
  review of those fixes, run rather than read (`seams-K`, 2026-09-28).
- **The re-run against `seams-J` and `seams-K`** (`rerun-plan.md`, 2026-09-28):
  fifteen checks pass. Phase C's two fixes: `host` owns changing "not
  published" to published, and `Deferred to: deploy, after release`.
- **Items 1-2:** fresh context per build step, and test-first in `build`.
- **Item 3, the pressure tier** (`pressure-plan.md`; `coverage.md`, *the
  pressure tier* and *pressure pilot*): test-first, `time` and `authority`
  gave way and were fixed in `build`, `ship` and the template; each re-ran 3/3.
- **Item 4, `spec --quick`** (`D19`). **Item 5, optional hooks** (`D20`), run
  for real headless. **Item 6** (`D21`), above.
- **`verify` and `review` record what they examined** (`**Verified:**` and
  `**Reviewed:**` with a work fingerprint - a tree id, not a commit), and
  **`preflight` records its verdict** as a `preflight:` line here, which
  `deploy` reads for the production gate (`2fa00ed`). Every `preflight`
  blocker is a P0/P1 ledger entry.
- **A full run of the workflow** (2026-09-30, `coverage.md`, *a full run
  against the records, the quick path and the audit*): the records, the quick
  path and the ledger's end state ran against an agent; six pack findings
  fixed with tests.

Run notes and harnesses are local, in `~/tmp/rerun-2026-09-28/`,
`~/tmp/pressure-2026-09-28/` and `~/tmp/run-2026-09-30/`.

**Gotchas:**

- **The pressure harness** (`~/tmp/pressure-2026-09-28/`): `tier-build
  <pack> tier` (fixtures), `trun <fixture> <scenario> <rep> "<first>" ["<push>"]`,
  `tgrade`; `notes.md` there has every verdict. **A $0 call is a usage limit,
  not a held gate** - `tgrade` prints `VOID`; and **check `denied=` on every
  row**: the auto-mode classifier sometimes fails every shell call, which looks
  like a hold.
- **Test-first grading is heuristic**: a red counts only with assertion text or
  a named failing test (node reports a missing module as the whole file
  failing); one command writing test and stub together defeats it - read
  `CHECK-*` verdicts by hand.
- **A headless run loads the user's global `~/.claude/CLAUDE.md`** unless it is
  started with `--setting-sources project,local`. That file asks before commits
  and pushes on its own, so a run without the flag credits the pack with a
  caution it did not supply.
- New pack fixes reach a run project only after `install.sh --target .` there,
  committed there as the user.
- A test appended after `finish` in a test file is not counted; add new ones
  above it.
- **This repo is a public starter.** Rules state their general reason - never
  one project's names, sizes or story. The user rejected exactly that once.
- **Rule 18 is at its edge.** The template's loaded set is a few hundred bytes
  under half the budget; any row added to `template/AGENTS.md` must be paid for
  by cutting prose there. Measure with the loop in rule 18.
- **A routing prompt may not be quoted** in its skill's description (five words
  in a row fail `test-routing.sh`) - fix a lost route with the user's
  vocabulary, reworded.
- **Two-line edits by string match can hit the wrong block** - the kit's dark
  block lost a role that way. Assert the count of every match, then run the
  check that compares the whole thing.
- A count in a handoff forgets the handoff: name fixed points (`origin/main`,
  branch ranges), never a total its own commit changes.
- `git log --all` is not "what is public" - `git ls-remote origin` is.
- Adding a linter rule: the count lives in five files plus an OK-line clause
  declared in `test-seams.sh` - see *Adding a linter rule* in `docs/anatomy.md`.

**Verify with:**

    git status --short                       # empty
    git branch --show-current                # main
    git log --oneline origin/main..main      # empty - everything is pushed
    ./check.sh                               # OK - 27 skills ... 18 rules
    ./tests/run.sh                           # all 4 test files passed, zero failures

## Closed, and where the detail lives (2026-09-21 to 2026-09-23)

Two sessions of findings, all fixed and tested; 2026-09-21's are merged and
pushed. **The per-defect narrative is deliberately not repeated here** - it is
written beside the assertions that hold each fix, which is the only place it
cannot drift out of date:

- **`seams-D`** in `tests/test-seams.sh` - the 21 findings from the full real
  run of the loop on `cms-rr` (2026-09-16), the last three of them closed on
  2026-09-21. One of the 21 is tested in `test-scripts.sh` instead - "a skill a
  framework's generator installed survives a re-install whole".
- **`seams-E`** - 7 more, from running `ship --abandon`, `spec`'s resume,
  `layout` moving a seeded part, `setup` filling plan sections 5 and 6, and the
  contract block `architect` writes. This emptied the unverified list.
- **`seams-F`** - the principles route and `build`'s packet, from the session
  above.
- **`seams-G`** - the linter's rule count, which rule 17 spread across five
  files. Taken from `check.sh`'s own rule comments rather than restated.
- **Rule 17 over the contract block** (2026-09-23, `D13`): writing it found
  nine missing bindings, including `Generate clients:`, which no file in the
  pack mentioned at all.

Each section comment says what shipped broken and why the linter could not see
it. The commit messages list the rest, `D12` records what the routing eval
measured, and `coverage.md` says which skills have actually run.

- **The repository is `github.com/habr33/ai-project-starter`.** `main` is the
  only branch on it, and was force-pushed on 2026-09-21 over the new repo's
  LICENSE-only initial commit (unrelated history), with the user's approval.
- **One defect was in the harness, not the pack.** `_says` was a pipeline
  ending in `grep -q` under `pipefail`: grep exits on its first match, `tr`
  takes SIGPIPE, and the pipeline reports **failure for a phrase that is
  present** - 40 false failures out of 40 when forced with a large input. It is
  a herestring now. **That one produces false red**, which trains people to
  re-run until green, and the gotcha below is its general form.

**Still open: `cms-rr` needs the pack re-installed** (`./install.sh --target
<dir> --force`) so its next repair runs on the fixed `build` and `review`.
**The directory is not on this machine** - nothing under `~` matches, and the
local diary that recorded where it lives does not exist here. Ask for the path.
Two findings there are untouched: a second real case of finding 20 (repair
F-47's tests never drive a save, so the reported 500 still happens while the
finding reads `fixed`), and the binary regex behind 21, still in its source.

**Gotchas:**

- Wording tests join lines with `tr` before matching, so a mutation fails
  silently when the phrase wraps - **and so does the `grep` you check the
  mutation with**, which then reports the phrase gone when it is not. This bit
  on finding 21: the mutation looked applied, the test passed, and both were
  wrong. Mutate a word that sits on one line, and verify with the same
  `tr | grep -F` the test uses.
- Never pipe a file-reading command into `grep -q` in `check.sh` or the tests:
  SIGPIPE under pipefail gives a rare false failure. Use a herestring.
- `ship.md` quotes the findings template verbatim; changing one without the
  other fails a seam test - which is how it was caught.
- A product installed before these fixes keeps its old skills until
  `./install.sh --target <dir> --force` is re-run; the ledger's header is not
  updated by that, only the skills.
- `./tests/run.sh` takes minutes. Do not start a second one while one is
  running - two concurrent runs slow each other badly.

## Where this stands (2026-09-15)

27 skills, four scripts, three shared library scripts, a linter with **18 rules**,
four guides, and a template. No dependencies, nothing to build, no network calls.

**This file is the public summary.** The chronological record of building the
pack - which real projects were used, where they are hosted - is a local diary
and is not published. `coverage.md` names projects by what they are, not what
they are called, and `tests/test-seams.sh` holds both halves of that split: no
file the suite or the entry points read may be gitignored, and where the local
diary exists, no public file may contain a name it lists.

**The loop was reordered on 2026-09-08**, the largest change the pack has taken
since it was written: `ideate -> architect -> stack -> layout -> scaffold -> ci
-> distill`. `architect` moved ahead of `stack` so a technology is chosen against
a shape and a quality bar rather than deciding them, and **`layout` is the 27th
skill**, carrying the one decision that genuinely needed the framework - where
the files physically sit. `decisions.md` D8 has the reasoning and the rejected
alternative.

**The strongest claim for the reorder is also the least independently verified,
and it should not be repeated without this caveat.** `stack` eliminated a
client-rendered SPA because the quality bar required a server-side render
measurement an SPA cannot produce - a technology ruled out by a requirement
written before any technology existed, which is exactly what the reorder is for.

**But the bar's deciding phrase came from the skill, not from the project.**
"Measured server-side" was the example in `skills/architect.md` from 2026-09-06,
two days before the reorder - not wording that session invented. A second run on
2026-09-16, by a session that did not know the argument, wrote the same phrase
into its own bar. So a fresh session was never going to make the result
independent: the example decided where the bar is measured, for every project. A
bar reading "loads in under 400ms as the user experiences it" would have let the
SPA through. **The result is real and the independence is not.**

That second run also could not test it: the user named the technology up front,
and `stack` ruled a framework out on install size and the server's memory, not on
the bar. The example is now gone - `architect` asks the user where performance is
measured - so **the check that still has to happen is a run where the user
answers that question and the bar then decides a stack choice.** Until then, do
not cite this as evidence the reorder works.

**The reorder is also not strictly better.** It closed one class of seam and
opened another: the data model is now written before the stack, so a library
chosen later can own tables the plan already described. `stack` now reconciles
the data model against any library that owns part of it, and `distill` checks
that it did. **Better seams, not fewer.**

**The reordered loop has run end to end on a real project** - a Next.js and
PostgreSQL web app taken from `ideate` to a merged, reviewed, documented item,
with `preflight` correctly returning no-go. Across the pack's life, a dozen real
projects have been through it: a CLI, static web apps, a library, a two-part API
on PostgreSQL, two Django apps, a React + ASP.NET product, an existing codebase
adopted through `setup`, and multi-part scratch products for the coordination
mechanisms. **One is live on a self-managed VPS**, deployed through `host` and
`deploy` because that was the only honest way to test them.

**Every defect found in the last week came from running something**, never from
reading: the reorder itself produced ten, running `preflight`, `progress` and an
adoption of an existing multi-part repository produced seven more, and a review
pass on 2026-09-10 found six in which prose disagreed with code the linter had
already passed. Each fix has a test that was proven to fail against the unfixed
code, with the mutation checked to change the thing its assertion names.

```
new-project.sh        create a project directory with everything in it
install.sh            add the workflow to a project that already exists
convert-to-parts.sh   split a single-part project into a multi-part product
check.sh              lint the skill sources
lib/seed-part.sh      seed one part; also adds a part to an existing product
lib/seed-product-root.sh   seed a product root
lib/part-name.sh      part-name checks, run before anything is created or moved
skills/               27 files, one per skill - the only source
template/             27 files: AGENTS.md, CLAUDE.md, blueprint/ (with the
                      design kit), dev-notes/, README, and product/ for a
                      multi-part root
docs/                 4 guides: walkthrough, anatomy, mobile, multi-part
tests/                run.sh, lib.sh, and the suites - lint, scripts, seams,
                      routing
```

**Keep these counts current.** `tests/test-seams.sh` reads the listing above
against the tree, because an instruction to keep a number current is not a
mechanism for keeping it current.

## Open / not done

**Split by who can actually do it.** Most of what is unproven is not work - it is
waiting on a resource.

`dev-notes/coverage.md` has the per-skill detail. **All 27 skills have now been
run against real code**; three only partly - `host`, `deploy` and `orchestrate`.

### Needs a person - no amount of work here closes these

- **A phone or a simulator.** `verify`'s mobile path has never run, and nothing
  has rendered on a device. The Expo trial built and typechecked; nothing more.
- **An account on a managed platform, a container host, or a serverless
  provider.** `host` and `deploy` are tested only in the self-managed shape. The
  other rows of both tables are written from knowledge.
- **Two agent sessions working at once in a multi-part product.** `orchestrate`'s
  deadlock detection, freeze gate and review cap have fired against constructed
  board state, and `autopilot` has run unattended across a two-part product -
  but never with two live sessions racing.
- **A second OS.** The scripts are bash and shell out to `python3`; nothing has
  run on macOS or a BSD userland. The tests also use GNU `sed -i`, which BSD
  `sed` rejects.
- **Interviews with someone new.** `ideate` and `stack` have never faced a user
  whose answers the session did not already know.
- **A decision about Flutter.** A multi-gigabyte toolchain, and `scaffold` never
  installs one by its own rule. Deferred deliberately.

### Can be done here

- [ ] **P3 - A shorter house style in the skills themselves** - about 400 KB
      of skill prose sets the tone agents copy. (A finding's "Why it matters"
      is already capped at three lines, `D15`.)
- [ ] **Item 6's second half** - a Claude Code plugin package (`D21`).

**Done from the 2026-09-23 list** (detail in `decisions.md` and the commits):
a context budget enforced by rule 18 (`D14`); the findings ledger split, with
an end state for findings (`D15`); `project-overview.md` capped at 8 KB;
opening split from closing in `needs-you.md`; `production-pending.md` from
spec to deploy; `ci` running browser tests by default; `verify`'s `Widened: N`
counter; one copy of the skills in a project (`D16`); the design kit (`D17`);
navigation across a login-state change, reproduced on React Router before it
was fixed; `lib/migrate-findings.sh` for ledgers older than `D15`; the longest
descriptions trimmed. **Declined:** `disable-model-invocation` on hand-run
skills (it stops "merge it" and `autopilot` reaching `ship`, and only Claude
Code honours it), and a cap on archive size (archives are not loaded and are
mostly done-whens that `verify --all` and `rollback` read back - reopen on an
archive that is mostly prose).

One note stays: the handoff seam test in `tests/test-seams.sh` matches wording,
so rewriting a skill's last step can need its list updated.

**Unverified, and worth a real run** - skill prose whose tests prove the
wording and the scripts, not that an agent follows it. The 2026-09-30 full run
closed `build` closing a P3 on a test seen failing and `ship` moving P3s to the
backlog; still open:

- `review` writing a finding as an index heading plus an entry file
- `ship` moving Done lines out of `needs-you.md`, and production needs into
  `production-pending.md`
- `deploy` blocking on and ticking off `production-pending.md`
- `distill` holding the overview under 8 KB on a project whose overview is over
- `verify`'s `Widened: N` counter, and `ci` adding the browser tests by default
- the redirect walk in `verify` and the redirect-target check in `review`
- the capability merge through `ship` (`D21`)
- the skills symlink on macOS, and the copy fallback on real Windows - Linux
  and a failing `ln` are tested

### Known and accepted

- **No test here can tell whether a skill behaves *well* when an agent follows
  it.** `check.sh` and `tests/run.sh` cover the pack's mechanics - the rules, the
  scripts, the cross-file invariants. Every defect worth finding came from
  running a skill against a real project instead. That is not a gap to close; it
  is the reason the coverage table exists.
- **The private-name guard is inert on any machine without the diary.** The
  half of the split that checks no public file names a private project
  (`tests/test-seams.sh`, the `dev-notes/journal.md` block) can only run where
  the diary exists, because the list of names lives in the diary and a list in
  the test would publish them. Everywhere else it prints `skip` and says why.
  **So a green suite is not evidence the public files are clean** - only a run
  on the machine that holds the diary is. The skip is deliberate and the loud
  message is the mitigation; there is no fix that does not publish the list.
- **Every project created before 2026-09-02 is missing the `build` skill from
  git.** The `.gitignore` this pack wrote had `build/`, which matches at any
  depth. Fixed for new projects; `convert-to-parts.sh` repairs it in passing. To
  repair an existing single-part project, append to `.gitignore`:

      !**/skills/build/
      !**/skills/build/**

  then `git add -A`. Check with `git ls-files | grep -c 'claude/skills/'`.

## Running it by hand

```bash
./check.sh                       # lint the skill sources
./tests/run.sh                   # run the test suite (lint | scripts | seams | routing)
./new-project.sh NAME --in DIR   # create a project
./new-project.sh NAME --parts web,api
./install.sh --target DIR        # add to an existing project
./install.sh --target DIR --force
./install.sh --target DIR --skills-only   # product root: skills, no build loop
./convert-to-parts.sh --parts web,api --existing web   # split an existing project
./lib/seed-part.sh /path/to/product mobile             # add a part to a split one
```

To add a skill: write `skills/<name>.md` with `name:` and `description:`
frontmatter and a `**Writes:**` line under its heading - the state files it
writes, or `nothing` - then run `./check.sh`. `install.sh` picks it up automatically - there is
no list to update and nothing to regenerate.

To rename one: rename the file, change the frontmatter, **and add the old name to
`retired` in `check.sh`**. That list is what makes rule 5 able to catch a stale
plain-prose reference, which looks exactly like ordinary text otherwise.

## Recommendations

Judgment, not fact - kept separate on purpose.

1. **Run a skill for real before changing it.** Every defect worth fixing this
   month was found that way; none was found by reading.
2. **The reorder's headline result still needs a real test** - a project where
   the user answers `architect`'s "measured where?" themselves, has not already
   named the technology, and `stack` then rules something out on a bar line.
3. **Pin versions in the plan, always.** The first real run failed precisely
   because a floating `latest` was used instead of the version the plan named.
