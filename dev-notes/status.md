# Status

Read this first after a break. `decisions.md` explains why the repo is shaped
this way - read D2 and D3 before changing its structure. `coverage.md` is the one
place that answers "has this skill actually run?".

> **Before doing anything else, check what is not committed** (`git status`),
> then run `./check.sh` and `./tests/run.sh`. They must report `OK` and **all
> every test file passing with zero failures**. If they do not, the tree has
> been disturbed since the last recorded run - find out why before changing
> anything.
>
> **The count is deliberately not written here.** It moves every time a test is
> added, and a number that goes stale on every commit teaches people to skip the
> line it sits in - which is the defect class this file is mostly a record of.
> Zero failures is the invariant; the total is not.

## Handoff (2026-09-21)

**Goal:** close the defects a full real run of this workflow found (project
`cms-rr` in `coverage.md`), each with a test proven to fail against the unfixed
file. All 21 are now fixed and committed.

- **Branch:** `run-findings`, merged into `main` and pushed on 2026-09-21 with
  the user's approval. Both are on the new repository.
- **The repository moved** to `github.com/habr33/ai-project-starter`. Both
  branches are on it; `main` was force-pushed over the new repo's LICENSE-only
  initial commit (unrelated history), with the user's approval.
- **Verified 2026-09-21:** `./check.sh` OK (16 rules); `./tests/run.sh` 0 failed
  across all four files.

**Done - all 21 findings fixed**, tests under `seams-D` in `tests/test-seams.sh`
(one in `test-scripts.sh`); the commit messages list them. The last three:
**19** - `spec` makes a done-when needing a new kind of test name the command
that runs it and where, and check that place can run it; **20** - `build`'s
findings gate writes a repair's test from the finding's own reproduction and
proves it by reverting the repair; **21** - `review` Step 1 checks the changed
set for a file git calls binary, reads it whole, and records it, because the
diff is all a pull-request reviewer sees.

**The routing eval is built** - `tests/test-routing.sh`, the fourth suite. It is
the only thing here that reads the 27 `description:` lines as a set: the linter
checks one at a time, so a skill whose description omits the words people type
stays lintable and unreachable. It gates three things - every skill has a
declared prompt, no two descriptions collide, and every skill wins its own
prompt unless it is on `known_misses` with a reason.

- **The monitor finding reproduced and is fixed.** Written blind - the earlier
  prototype was gone and the prompts were rewritten from scratch - `monitor`
  still lost "the site is down and i need to know why" to `prepare`, by 0.0332.
  Its description now says *down, slow, alert, incident, errors*. Seen failing
  first; reverting the wording makes it fail again.
- **The rebuilt ranker is not the old one and its numbers do not carry over.**
  The worst pair here is `review` <-> `ship` at 0.28, not `integrate` <->
  `orchestrate` at 0.42. Any threshold has to be set against this ranker.
- **24 of 27 skills won their own prompt on the first run**, against 6 of 14
  before. That is mostly better prompts, not better descriptions: a prompt that
  paraphrases the description proves only that a sentence matches itself, so the
  file now rejects any prompt repeating five consecutive words of its own
  description. It caught `prototype`'s prompt immediately, and `verify`'s was a
  paraphrase too - rewritten, `verify` wins outright and its excuse was deleted.
  Only `stack` is excused now ("build this with" is lexically owned by `build`).
- **All 27 descriptions share one IDF table, so editing any one reweights every
  other skill.** Adding *down* to `monitor` diluted the only term separating
  `spec` from `progress`, and `spec` went from first to second on a margin of
  **0.0003**. Gating top-1 on that is gating on noise and would make every
  description edit break an unrelated skill, so a gap under `tie_margin` is a
  tie, not a miss.
- **The margin was measured, not picked**: 0.0003 for the `spec` noise, 0.0332
  for the real `monitor` miss, a factor of 100 apart, line drawn at 0.02. That
  claim was checked by raising it to 0.05 and watching the unfixed `monitor`
  pass as a tie - the defect class really does go invisible above ~0.03.
- Six mutations, each confirmed to land and to fail the assertion it names.
- **Rule 8 caught the new file on the day it was written** - nothing referenced
  it, because `run.sh` finds its files by glob. A seam test now requires every
  suite to be named in status.md's listing and in `AGENTS.md`.
- Still deferred: their Tier 3 (headless agent + graded trace) with **pressure
  cases** - time pressure, sunk cost, authority - the one test our gates have
  never had. It spends tokens per run.

**Still open in `cms-rr`, untouched** (item 2b built and uncommitted, Repair
F-47 awaiting the owner's approval): a second real case of 20 - F-47's tests
never drive a save, so the reported 500 still happens while the finding reads
`fixed` - and the binary regex behind 21 is still in its source.

**Next:**

1. Re-install the pack into `cms-rr` (`./install.sh --target <dir> --force`) so
   its next repair runs on the fixed `build` and `review`. **The directory is
   not on this machine** - nothing under `~` matches, and the local diary that
   recorded where it lives does not exist here. Ask for the path.
2. The routing eval is a regression guard, not a bug-finder, and it has found
   its one bug. The thing that would find more is the deferred pressure-case
   tier, which needs a token budget decided first.

**Gotchas:**

- Wording tests join lines with `tr` before matching, so a mutation fails
  silently when the phrase wraps - **and so does the `grep` you check the
  mutation with**, which then reports the phrase gone when it is not. This bit
  on 21: the mutation looked applied, the test passed, and both were wrong.
  Mutate a word that sits on one line, and verify with the same `tr | grep -F`
  the test uses.
- `ship.md` quotes the findings template verbatim; changing one without the
  other fails a seam test - which is how it was caught.
- Never pipe a file-reading command into `grep -q` in `check.sh` or the tests:
  SIGPIPE under pipefail gives a rare false failure. Use a herestring.
- A product installed before these fixes keeps its old skills until
  `./install.sh --target <dir> --force` is re-run; the ledger's header is not
  updated by that, only the skills.
- `./tests/run.sh` takes minutes. Do not start a second one while one is
  running - two concurrent runs slow each other badly.

**Verify with:**

    ./check.sh
    ./tests/run.sh


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
