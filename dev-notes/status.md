# Status

Read this first after a break. `decisions.md` explains why the repo is shaped
this way - read D2 and D3 before changing its structure. `coverage.md` is the one
place that answers "has this skill actually run?".

> **Before doing anything else, check what is not committed** (`git status`),
> then run `./check.sh` and `./tests/run.sh`. They must report `OK` and **all
> three test files passing with zero failures**. If they do not, the tree has
> been disturbed since the last recorded run - find out why before changing
> anything.
>
> **The count is deliberately not written here.** It moves every time a test is
> added, and a number that goes stale on every commit teaches people to skip the
> line it sits in - which is the defect class this file is mostly a record of.
> Zero failures is the invariant; the total is not.

## Handoff (2026-09-16)

- **Branch:** `run-findings` off `main`, two commits (`b6e3c2c`, `8f9c619`);
  not pushed, no PR, not merged.
  `main` already holds the 2026-09-15 review fixes and this handoff's predecessor.
- **Last verified:** `./check.sh` OK (16 rules); `./tests/run.sh` 0 failed across
  all three files.
- **What this branch is:** fixes for the 18 defects a full run of the loop found
  on a new project - a React Router 8 + PostgreSQL CMS taken from `ideate` to a
  shipped login feature by a session that did not know the pack's arguments.
  `coverage.md` has the per-skill results (project `cms-rr`), and each fix has a
  test under `seams-D` in `tests/test-seams.sh` (one in `test-scripts.sh`),
  every one proven to fail against the unfixed file.
- **All of those tests check wording.** They prove the skills now say the right
  thing, not that an agent following them behaves differently. **Next:** re-install
  the pack into that project (`./install.sh --target <it> --force`) so item 2 runs
  on the fixed skills - it exercises the spec's Decisions section, the
  approval marker, `ship`'s PR route and the spent-mockup rule. Merging this
  branch to `main` is a separate ask.
- **The first section ran on the old skills and repeated two fixed defects**,
  confirming them: asked to remove old sites `host` went to delete before listing
  what would go (a permission classifier stopped it), and `context` wrote a
  seventh stale plan line into the overview while the plan still had it wrong.
- **The `host` -> `deploy` -> `monitor` section then ran on the same project,
  still on the old skills.** It repeated two of the defects above, confirming
  them, and found four more - all now fixed here, each with a test proven to
  fail:
  - a **`deferred`** status for a finding the user puts off rather than
    abandons. `accepted` meant "not fixing" and was doing both jobs: `ship`
    archived a deferred P1 an hour before `monitor` repaired it, so the repair
    had to be written into an archive nobody reads.
  - **`preflight` checks the proxy seam.** The first deploy served every page
    and rejected every form post - behind a TLS-terminating proxy the framework
    compared its own `http://` origin with the browser's `https://`. Nothing
    earlier can see it: tests, CI and `verify` all talk to the app directly.
  - **`ship` deletes only spent mockups**, not the directory, and says which
    items still hold the rest.
  - **`host` stops a process by the PID it started.** A restore drill's
    `pkill -f` matched the live server, and because SIGTERM reads as a clean
    exit, production stayed down for a minute with nothing watching.
- **The strongest result of the run** is not a fix: an independent `review` in a
  fresh session found a P1 - login rate limits bypassed by concurrent requests -
  that `autopilot`'s own review, verify and tests all passed. That is the
  self-review weakness `autopilot.md` describes, now seen on real code.
- **Gotchas from this session:**
  - Wording tests join lines with `tr` before matching, so a `sed` mutation
    fails silently when the phrase wraps. One did here; mutate the joined text.
  - Never pipe a file-reading command into `grep -q` in `check.sh` or the tests -
    SIGPIPE under pipefail gives a rare false failure. Use a herestring.
  - A mutation proves a test only if it changes what the assertion names; two
    first-draft tests here failed for fixture reasons, not the code.
  - A product created before `5306f41` ignores all of `blueprint/status/`; a
    fresh clone of it has no status directory. `install.sh` prints the fix.
  - Git's "already used by worktree at" path is wrong inside a submodule; the
    board command in `skills/orchestrate.md` is the reliable one.

## Where this stands (2026-09-15)

27 skills, four scripts, three shared library scripts, a linter with **16 rules**,
four guides, and a template. No dependencies, nothing to build, no network calls.

**This file is the public summary.** The chronological record of building the
pack - which real projects were used, where they are hosted - is a local diary
and is not published. `coverage.md` names projects by what they are, not what
they are called, and `tests/test-seams.sh` holds both halves of that split: no
file the suite or the entry points read may be gitignored, and where the local
diary exists, no public file may contain a name it lists.

**The loop was reordered on 2026-09-08**, the largest change the pack has taken
since it was written: `ideate -> architect -> stack -> layout -> scaffold -> ci
-> context`. `architect` moved ahead of `stack` so a technology is chosen against
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
the data model against any library that owns part of it, and `context` checks
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
template/             21 files: AGENTS.md, CLAUDE.md, blueprint/, dev-notes/,
                      README, and product/ for a multi-part root
docs/                 4 guides: walkthrough, anatomy, mobile, multi-part
tests/                run.sh, lib.sh, and three suites - lint, scripts, seams
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

**Nothing known is open.** The 2026-09-15 review and a run of the loop on a
two-part CMS were closed in commit `5306f41` - see D9 and D10 in `decisions.md`,
and the commit message for the full list. One note stays: the handoff seam test
in `tests/test-seams.sh` matches wording, so rewriting a skill's last step can
need its list updated.

**Unverified, and worth a real run** (all checked by wording tests only):
`ship --abandon` and `spec`'s resume, `layout` moving a seeded part, `architect`
writing the whole contract up front, and `setup` filling plan sections 5 and 6 on
an adoption.

### Known and accepted

- **No test here can tell whether a skill behaves *well* when an agent follows
  it.** `check.sh` and `tests/run.sh` cover the pack's mechanics - the rules, the
  scripts, the cross-file invariants. Every defect worth finding came from
  running a skill against a real project instead. That is not a gap to close; it
  is the reason the coverage table exists.
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
./tests/run.sh                   # run the test suite (lint | scripts | seams)
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
