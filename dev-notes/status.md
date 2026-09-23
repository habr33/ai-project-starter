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

## Where work stopped (2026-09-23)

**Goal of the last session:** land the principles-file branch, audit what this
public repo actually publishes, then close the 17th rule - the last open item
that needed a decision rather than a resource.

**The tree is clean and everything passes. `main` is ahead of `origin/main`, on
purpose.** `origin/main` is at `c7cd606` - it is the only sha worth writing
down here, because it is the only one that does not move. **How far ahead
`main` is, is deliberately not written**, for the reason under *Gotchas*: the
commit that writes such a count is the one it forgets. The user is deleting the
GitHub repository and re-creating it from this local clone, so **do not push,
and do not offer to** until they say the new remote exists.

**Done, with evidence:**

- **`dac5d79`** - the principles-file work, merged to `main` and pushed. `D11`.
- **`083b124`** - three corrections to this file, listed in its message.
- **`4cb6514`** - **rule 17**, over `template/product/AGENTS.md`'s contract
  block. `D13`. The fields are declared in a table beside the block; the binding
  must be the literal `` `Field:` ``, because the paraphrase is what hid
  `Kind:`. It found **nine missing bindings** on its first run, two of them
  orphan fields: `Regenerate:`, read only as "the regeneration command", and
  **`Generate clients:`, which no file in the pack mentioned at all**. `ci` now
  regenerates the clients too. Nine negative tests in `test-lint.sh`, each
  **seen failing with the rule body removed**; `seams-G` holds the rule count,
  which turned out to live in five files, not three.
- **`check.sh`'s OK line is held clause by clause.** `test-seams.sh` declares
  one clause per rule (2, 3, 5 and 7 declared silent) and fails by rule number.
  The old grep for rule 17's phrase alone stayed green with rule 12's clause
  cut out; **seen failing** with that same cut, reporting `got '12'`. `D13`.
- **The public surface was audited and is clean.** All 74 tracked files are pack
  content; no secrets, keys, IPs or personal paths in any commit's content.
- **`./check.sh` -> OK** (18 rules, 27 skills); **`./tests/run.sh` -> every file
  passing, zero failures** - the total is not recorded here, for the reason the
  opening gives.

**Branch `retro-improvements`** (2026-09-23) holds the retrospective's P1 and
P2 todos, one commit each - `git log --oneline main..retro-improvements`. The
user will **squash-merge it later**; do not merge it without them. `D14`, `D15`.

**Next:**

1. **Wait for the user to re-create the remote**, then push `main` to it. They
   said they would do this part themselves.
2. **The retrospective's P3s under *Can be done here*.** One needed the user
   first: `disable-model-invocation` would stop `autopilot` invoking `ship`,
   and was judged not worth it (small saving, gates already exist). Everything under *Still open* needs a person or a resource.

**Do not cite `ideate`'s Step 2 as proven.** It has no test and cannot usefully
have one here: advisory prose gates nothing, so no command can disagree with it.
Also unacted from the same prior-art comparison: no single binding
"constitution" (rejected - `D11`), no planning surface for a non-technical
stakeholder, no partial install of the 27 skills.

**Gotchas from those sessions:**

- **`git log --all` is not "what is public".** An audit here reported a personal
  address in 17 of 36 commits and was **wrong on both numbers**: `--all` sweeps
  `refs/original/*`, the local backup refs a previous `filter-branch` leaves
  behind, so pre-scrub history was counted as live. `main` had 19 commits, all
  already clean. **`git ls-remote origin` is the only answer to what is
  published.** The unnecessary rewrite that followed was reverted and nothing
  was force-pushed, but it overwrote the earlier session's backup refs.
- **A mutation aimed at the wrong form changes nothing and still reads green.**
  The contract block writes its fields plain (`- Kind: <...>`) and the table
  backticks them; one rule-17 test mutated the backticked form and passed for
  the wrong reason. It now asserts the mutation landed first.
- Adding a rule means editing the count in **five** places, `check.sh`'s OK line
  among them. `seams-G` checks this now - see *Adding a linter rule* in
  `docs/anatomy.md`.
- A product-root file needs **two** declarations in `template/AGENTS.md`: the
  writer row *and* a line in the MULTI-PART MARKER block. Only the second makes
  rule 13 require the "Product root:" mention.
- **A count in a handoff forgets the handoff**, and the opening instruction
  treats a mismatch as a disturbed tree. It has been wrong three times here -
  twice on a file count, and once on `[ahead 2]` and a HEAD sha that named the
  commit *before* the one that wrote them. **A handoff cannot state a number
  its own commit changes**: name a fixed point instead - `origin/main`, or a
  range against it - which is why this section now counts nothing.
- `check.sh` still has small `printf ... | grep -q` pipelines. Same shape as the
  SIGPIPE defect, but single table rows fit the pipe buffer, so they were left
  alone.

**Verify with:**

    git status --short             # nothing modified
    git log --oneline c7cd606..    # the commits under "Done", plus this file's own
    git status -sb | head -1       # main...origin/main [ahead N] - N is not fixed
    ./check.sh                     # OK - 27 skills ... 18 rules
    ./tests/run.sh                 # all 4 test files passed, zero failures

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

**Todos from a full-loop retrospective, 2026-09-23.** A single-part web CMS
ran the whole loop (8 items, 15 sub-items, production live) over 31 sessions.
It shipped, but it cost 3.29 B cache-read tokens for ~13K lines of code; the
median context before the user's first message was 107K tokens. The findings
ledger only grew (100 raised, 26 P3 still open), and the planning and archive
files came to ~680 KB. Ordered by payoff:

- [x] **P1 - Context budget, enforced by `check.sh`.** Done - rule 18, `D14`. Add a rule that fails
      when the files `template/CLAUDE.md` imports exceed a byte budget. Stop
      importing `fundamentals.md` every session (`review`/`build` read it).
      Load only the Open section of `needs-you.md`; Done moves to history.
- [x] **P1 - Split the findings ledger.** Done - `D15`. Always-loaded index, one line per
      open finding (ID, severity, title, file); full entries under
      `findings/`, read on demand. Keeps `AGENTS.md`'s "never miss an open
      blocker" guarantee at a fraction of the size. Decide before starting -
      it changes a documented invariant.
- [x] **P1 - Give findings an end state.** Done - `D15`. The repairing skill may close a
      P2/P3 on evidence it has seen fail; only P0/P1 wait for `review`.
      `ship` archives resolved entries. P3s get a policy: a batched "tidy"
      item every N items, or expiry to a backlog file that is not loaded.
      Observed: an entry stayed `fixed` for a week, still loaded every session.
- [x] **P1 - Cap `project-overview.md`** Done - `context` Step 3. (e.g. <=8 KB). It restated the
      findings ledger and `needs-you.md` in prose, so every regeneration was
      another docs commit (12 of 33 commits were docs). Link, don't restate.
- [x] **P2 - Split opening from closing.** Done for `needs-you.md`; findings close by severity - `D15`. Keep one named writer for
      *opening* a `needs-you.md` or findings line; let any skill *close* one
      with evidence, recording which. Observed: a satisfied `.env` line
      survived three overview regenerations because `context` saw it but did
      not own the file; a done monitoring line stayed open too.
- [x] **P2 - Track what production will need, from spec to deploy.** Done - `blueprint/production-pending.md`. `spec`
      records new env vars, migrations and external accounts; `ship` appends
      them to a pending-for-production list; `progress` reports "production
      is N items behind, needs X". Observed: 4 items merged before anyone
      noticed production lacked their env vars and 2 migrations.
- [x] **P2 - `ci` runs the browser tests by default when they need a
      database** (service container). Observed: the tests covering the worst
      defects gated nothing for the project's whole life.
- [x] **P2 - Time-limit manual checks.** Done - `verify`, `Widened: N`. A `needs-you.md` manual-check line
      widened N times forces a decision: do it, or accept the risk. Observed:
      the screen-reader line was widened by every item, then accepted as a
      risk all at once.
- [x] **P3 - One copy of the skills in a project.** Done - `D16`, a link, copy fallback. `.claude/`, `.agents/`
      and `.opencode/` each committed ~7.9K lines of identical text; generate
      or symlink at install.
- [ ] **P3 - `disable-model-invocation: true`** on hand-run skills (`deploy`,
      `ship`, `migrate`, `setup`, `autopilot`); trim the longest
      descriptions (`verify`, `stack`, `spec`, `architect`).
- [ ] **P3 - Cap archive size.** `ship` archives the spec, outcome and links
      to evidence, not every narrative; item 1's archive was 60 KB.
- [ ] **P3 - Length limits for written entries.** At most 3 lines for a
      finding's "Why it matters", and a shorter house style in the skills
      themselves (~400 KB of skill prose sets the tone agents copy).

**Before this list, nothing known was open here.** The 17th rule, the last item that needed a
decision rather than a resource, went in on 2026-09-23 - see `D13` and item 2
above. Everything else known is closed: the 2026-09-15 review
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
