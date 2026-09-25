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

## Where work stopped (2026-09-25)

**Goal:** close the gaps a market comparison found (Spec Kit, Superpowers, GSD,
BMAD, OpenSpec, Kiro), after a round on context cost and a design kit.

**Branches: none open.** `retro-improvements` (context budget and rule 18,
findings index and end state, overview cap, production-pending, needs-you
closing, CI browser tests, one skills copy linked for Claude Code; `D14`-`D16`)
and `design-kit` (`blueprint/design-kit/` and the rewritten `prototype`; `D17`)
were fast-forwarded into `main` on 2026-09-25 at the user's request, and `main`
pushed. Both branches are deleted.

**Open branch: `claude/admiring-meitner-w9m4vx`**, off `main` at `81da70f`, not
merged. A read of all 27 skills end to end (`seams-G`) and `D18`:

- **Design is required wherever there is a UI** (`D18`). `spec` stops on a UI
  with no `design.md`; a CLI, library or API, a fix and `--preview` pass.
  `prototype` gained *Recording a look that already exists*, without which an
  adopted app could never reach `spec`.
- **`check.sh` rule 1 took SIGPIPE** - `sed '/^---$/q'` in an assignment under
  `set -e`, exit 141 with no output in roughly one lint fixture in fifteen. Now
  a range; a seam check forbids an early-quitting reader in any check.sh
  assignment.
- **`build`'s packet** names all four standards by path, and test-first means
  the test is written and seen red *before* the code, with the running app as
  the evidence where no test can see the claim.
- **Self-contradictions fixed**: `stack`'s empty-directory claim, `architect`
  asking its six questions twice, steps that did not exist (`build` "Step 6",
  `autopilot` "Step 1b" - now a check across every skill), `verify`'s needs-you
  rule reachable only under `--manual`, and six miscounts.
- **Undeclared writes declared**: `scaffold`, `context` and `spec` write the
  plans, `spec` writes `design.md`. Paid for under rule 18 by cutting a
  duplicated paragraph from the template's `coding-standards.md`.
- **Then three follow-ups:** `autopilot` stops at `prototype` when there is no
  `design.md` (a look is the user's choice, and required design made every UI
  range reach it), and checks for the record when its range starts past
  `prototype`; a seam heuristic for a skill that tells the agent to write a
  state file its `Writes:` line leaves out - it finds two of the four
  undeclared writes above, and the other two name their file only as "it";
  and `install.sh` names a hand edit found only in `.claude/skills` before
  converting or overwriting it.
- **Proposed, not done - the user's call:** fold `prepare` into `progress`,
  `layout` into `stack`, drop the overview's *Current state* so `context` is not
  needed after every `ship`, and install a core set of skills by default.

**Done, with evidence:** `./check.sh` OK and `./tests/run.sh` all four files
passing, zero failures, on `main`. Each new check was seen failing under a
mutation first; the kit's four checks were run against four broken copies. The
kit sheet was rendered headless at 1280 and 390 px, light and dark.

**Two of the agreed next six, now on `main`:**

1. **Fresh context per build step.** `build` Step 3 prepares a packet (spec
   step text, done-when, claimed files, standards, no-commit rule) and hands it
   to a subagent where the host supports one, falling back to inline where it does
   not; the main session keeps the comprehension gate - reading the diff,
   explaining it, and proving the done-when.
2. **Test-first in `build`.** Step 3's "Prove the done-when" states "Every
   step with a behavioural done-when is proven test-first" - the test must be
   seen failing before the step is claimed. `test-seams.sh` asserts this
   generalization separately from the repair-specific rule.

**Next - the agreed order, one commit each on a new branch off `main`:**

3. **The pressure-test tier** (open item 3 under *Still open*) - needs a token
   budget agreed with the user before any run. **Blocked on the user: what token
   budget?**
4. **A quick-fix path** - a lighter spec/build/ship for small fixes.
5. **Optional hooks** (`.claude/settings.json`) for rules that must not depend
   on the model remembering them - e.g. no commit on `main`, the budget check.
6. **Living capability specs** that `ship` updates (OpenSpec-style); a Claude
   Code plugin package alongside the scripts.

Also open: the `verify` redirect sweep and `review` redirect-target check
(see *Can be done here*), and a ledger migration script.

**Gotchas:**

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
- `./tests/run.sh` takes minutes; never run two at once.

**Verify with:**

    git status --short                       # nothing modified
    git branch --show-current                # main
    git log --oneline origin/main..main      # empty - main is pushed
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

**Still open:**

1. **`cms-rr` needs the pack re-installed** (`./install.sh --target <dir>
   --force`) so its next repair runs on the fixed `build` and `review`. **The
   directory is not on this machine** - nothing under `~` matches, and the local
   diary that recorded where it lives does not exist here. Ask for the path.
   Two findings there are untouched: a second real case of finding 20 (repair
   F-47's tests never drive a save, so the reported 500 still happens while the
   finding reads `fixed`), and the binary regex behind 21, still in its source.
2. **Done on 2026-09-23 - rule 17 over the contract block.** `D13`. The fields
   are declared in a table beside the block and bound to the skills that write
   and read them; writing the rule found **nine missing bindings**, including
   `Generate clients:`, which no file in the pack mentioned at all. The count
   was in five files, not three - `check.sh`'s OK line and `README.md` as well -
   and a seam test now takes it from `check.sh` and holds the rest to it.
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

**Todos, 2026-09-23** - context cost and state files that only grow. Ordered by
payoff:

- [x] **P1 - Context budget, enforced by `check.sh`.** Rule 18, `D14`:
      the loaded files have a declared budget; `fundamentals.md` is read on
      demand; closed needs-you lines leave the loaded file.
- [x] **P1 - Split the findings ledger.** `D15`: a loaded index, one heading
      per live finding, and full entries under `blueprint/findings/`.
- [x] **P1 - Give findings an end state.** `D15`: `build` closes a P2 or P3 on
      a test seen failing; `ship` moves unresolved P3s to a backlog that is
      not loaded; `spec` offers a tidy item.
- [x] **P1 - Cap `project-overview.md`** at 8 KB - `context` links, never
      restates.
- [x] **P2 - Split opening from closing.** Any `needs-you.md` writer may close
      a line with evidence, recording which; findings close by severity.
- [x] **P2 - Track what production will need, from spec to deploy.**
      `blueprint/production-pending.md`, written by `ship`, met by `deploy`,
      reported by `progress`.
- [x] **P2 - `ci` runs the browser tests by default**, with a database
      service container; leaving them out is the user's explicit call.
- [x] **P2 - Time-limit manual checks.** `verify` counts `Widened: N` and
      asks at 3.
- [x] **P3 - One copy of the skills in a project.** `D16`: `.claude/skills`
      links to `.agents/skills`, copying where a symlink will not work.
- [x] **Design kit** - `D17`: tokens, every core component in every state,
      a UX checklist, and a `prototype` that recommends and maps navigation.
- [ ] **P2 - Navigation across a login-state change.** *Partly addressed by
      `D17`: the checklist names the journeys and `spec` makes each a
      done-when; the `verify` sweep and the `review` check are still open.* No skill asks for a
      done-when that follows the whole redirect chain when an action changes
      the session - a password change, a role change, logging in to return to
      a page - for the user affected *and* for yourself, through a full-page
      load and a client-side submit. `spec`, `verify` and `review` never mention
      redirects. Proposed: that done-when in `spec`; a logged-out-then-login
      sweep over protected routes in `verify`; and a `review` check that a
      redirect target built from the request URL cannot carry the framework's
      internal URL forms. **Not started - reproduce a real case with `debug`
      first.**
- [ ] **P3 - A ledger migration for projects installed before `D15`.** Done
      by hand once; a script would need the same checks - every entry intact,
      every ID exactly once across index and backlog.
- [ ] **P3 - Trim the longest descriptions** (`verify`, `stack`, `spec`,
      `architect`). `disable-model-invocation` on hand-run skills was
      **declined**: a small saving, the approval gates already exist, it stops
      "merge it" and `autopilot` reaching `ship`, and only Claude Code honours
      it.
- [ ] **P3 - Cap archive size.** `ship` archives the spec, the outcome and
      links to evidence, not every narrative.
- [ ] **P3 - A shorter house style in the skills themselves** - about 400 KB
      of skill prose sets the tone agents copy. (A finding's "Why it matters"
      is already capped at three lines, `D15`.)

**Before this list, nothing known was open here.** The 17th rule, the last item that needed a
decision rather than a resource, went in on 2026-09-23 - see `D13` and item 2
above. Everything else known is closed: the 2026-09-15 review
and a run of the loop on a two-part CMS went in commit `5306f41` - see D9 and
D10 in `decisions.md`, and the commit message for the full list. One note
stays: the handoff seam test in `tests/test-seams.sh` matches wording, so
rewriting a skill's last step can need its list updated.

**Unverified, and worth a real run** - everything the `retro-improvements`
branch changed in skill prose. Its tests prove the wording and the scripts, not
that an agent follows it:

- `review` writing a finding as an index heading plus an entry file, and
  `build` closing a P2 or P3 on a test it saw fail
- `ship` moving P3s to the backlog, Done lines out of `needs-you.md`, and
  production needs into `production-pending.md`
- `deploy` blocking on and ticking off `production-pending.md`
- `context` holding the overview under 8 KB on a project whose overview is over
- `verify`'s `Widened: N` counter, and `ci` adding the browser tests by default
- the skills symlink on macOS, and the copy fallback on real Windows - Linux
  and a failing `ln` are tested

**It was emptied once before, on
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
