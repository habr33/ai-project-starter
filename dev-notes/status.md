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

## Handoff (2026-09-23) - principles file, idea gate, build's verify handoff

**Goal:** close two gaps a comparison against public prior art (spec-kit,
BMAD-METHOD, ai-blueprint) surfaced - no project-level "non-negotiable
commitments" file, no explicit go/kill verdict in `ideate` - plus a `build`
handoff fix. Then a review of that work against what the commands print.

**Branch:** `add-principles-file`, **nothing committed**. 12 files modified -
that count includes `tests/test-seams.sh` **and this file**, which is the one a
count like this always forgets. Nothing is half-built.

**Done, with evidence:**

- **`blueprint/context/principles.md`** - what the project will never trade
  away, distinct from `quality-bar.md` (numbers). Written once by `ideate`,
  product-root in multi-part products, read by `architect`/`review`/
  `preflight`. `setup` never infers one - a commitment cannot be read off code.
  `D11`. Files: `template/AGENTS.md`, five skills, `docs/anatomy.md`, `README`.
- **`ideate` Step 2** - advisory Go / Not yet / Doesn't clear the bar, before
  scope-cutting. Old Steps 2-4 renumbered 3-5.
- **`build`'s review packet** names `verify` first when any behavioral
  done-when was proven only by a green check, and `review` directly only when
  every one was run live in Step 3.
- **Fixed: the rescope path stranded `setup`'s pointer.** `setup` sends an
  adopted project to `ideate --rescope` as the only writer of `principles.md`;
  that path said "leave it alone unless the user raises it", so every adopted
  project was routed to a skill told not to do the thing. Rule 8 cannot see it -
  the writer row exists and the declining sentence is *inside* the writer.
- **Fixed: the `grep -q` SIGPIPE hazard was still live in `test-seams.sh`.**
  One full run failed; seven were clean. Two parent-shell pipelines gated a
  counter on `&& n=$((n+1))`, so a SIGPIPE **undercounts silently** and reads
  as an off-by-one. Forced with a 60k-line file: 40 false failures out of 40,
  0 as a herestring. The rule against this read only `check.sh`; now covers the
  suites, `bash -c` exempt (pipefail is not inherited - checked, not assumed).
- **Ten new checks under `seams-F`**, each seen failing against a mutated file,
  each mutation confirmed to land through the same `tr | grep -F` they use.
- **`./check.sh` -> OK** (16 rules, 27 skills); **`./tests/run.sh` -> 806
  passed, 0 failed**, five consecutive clean runs.

**Next:**

1. **Ask whether to commit the 12 files**, then whether to merge to `main` or
   open a PR. Nothing else is pending on this branch.
2. `ideate`'s Step 2 has **no test and cannot usefully have one here** -
   advisory prose gates nothing, so no command can disagree with it. Do not
   cite it as proven. Also unacted from the same comparison: no single binding
   "constitution" (rejected - `D11`), no planning surface for a non-technical
   stakeholder, no partial install of the 27 skills.

**Gotchas:**

- A product-root file needs **two** declarations in `template/AGENTS.md`: the
  writer row *and* a line in the MULTI-PART MARKER block. Only the second makes
  rule 13 require the "Product root:" mention.
- Renumbering an `ideate` step touches prose cross-references, not just
  headings - grep the old heading text repo-wide after any renumber.
- **A file count in a handoff forgets the handoff**, and the opening
  instruction treats a mismatch as a disturbed tree. It was wrong twice here.
- `check.sh` still has small `printf ... | grep -q` pipelines. Same shape, but
  single table rows fit the pipe buffer, so they were left alone.

**Verify with:**

    git status --short   # 12 modified files, nothing else
    ./check.sh           # OK - 27 skills ... 16 rules
    ./tests/run.sh       # total: 806 passed, 0 failed across 4 file(s)

## Closed, and where the detail lives (2026-09-21 to 2026-09-22)

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

Each section comment says what shipped broken and why the linter could not see
it. The commit messages list the rest, `D12` records what the routing eval
measured, and `coverage.md` says which skills have actually run.

- **The repository is `github.com/habr33/ai-project-starter`.** Both branches
  are on it; `main` was force-pushed on 2026-09-21 over the new repo's
  LICENSE-only initial commit (unrelated history), with the user's approval.
- **One defect was in the harness, not the pack.** `_says` was a pipeline
  ending in `grep -q` under `pipefail`: grep exits on its first match, `tr`
  takes SIGPIPE, and the pipeline reports **failure for a phrase that is
  present** - 40 false failures out of 40 when forced with a large input. It is
  a herestring now. **That one produces false red**, which trains people to
  re-run until green, and the gotcha below is its general form.

**Still open:**

1. **`cms-rr` needs the pack re-installed** (`./install.sh --target <dir>
   --force`) so its next repair runs on the fixed `build` and `review`. **The
   directory is not on this machine** - nothing under `~` matches, and the local
   diary that recorded where it lives does not exist here. Ask for the path.
   Two findings there are untouched: a second real case of finding 20 (repair
   F-47's tests never drive a save, so the reported 500 still happens while the
   finding reads `fixed`), and the binary regex behind 21, still in its source.
2. **A 17th rule, over `template/product/AGENTS.md`'s contract block.** The
   `Kind:` defect in `seams-E` is rule 9's class in a file rule 9 does not read,
   and the move this repo keeps making is to declare the fields and let the rule
   follow. It touches the rule counts in `AGENTS.md`, `docs/anatomy.md` and this
   file, so it was left as a decision rather than taken unilaterally.
3. **The pressure-case tier** - a headless agent and a graded trace under time
   pressure, sunk cost and authority - is the one test these gates have never
   had, and the only thing likely to find more than the routing eval can. It
   spends tokens per run, so it needs a budget decided first.

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

**One thing is: the 17th rule** over `template/product/AGENTS.md`'s contract
block - item 2 under *Still open* above. It needs a decision about the rule
counts, not a resource. Everything else known is closed: the 2026-09-15 review
and a run of the loop on a two-part CMS went in commit `5306f41` - see D9 and
D10 in `decisions.md`, and the commit message for the full list. One note
stays: the handoff seam test in `tests/test-seams.sh` matches wording, so
rewriting a skill's last step can need its list updated.

**Unverified, and worth a real run:** none. **The list was emptied on
2026-09-22** - `ship --abandon`, `spec`'s resume, `layout` moving a seeded part,
`setup` filling plan sections 5 and 6, and the contract block `architect` writes
were all run, between them finding seven defects in the skills and one in the
test harness. What is left unproven needs a person or a resource, not work here.

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
