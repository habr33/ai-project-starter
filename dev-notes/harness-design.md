# Rules that execute in every tool - design (2026-10-14)

**Agreed 2026-10-14**, with the answers below; `harness-plan.md` implements
it. Layers 1 and 2 of four; 3 and 4 are named at the end so
the first two do not close them off. `D23` records the direction.

## The problem

Every rule in an installed project is prose an agent has to remember. The
pressure tier (`coverage.md`, 2026-09-28) showed prose giving way under "just
do it", and D20's two hooks held where the prose did not - but D20 runs only in
Claude Code, and nothing may depend on a hook having run.

What an installed project can check without a model, and does not:

- **State files drift from their format.** The findings index must hold only
  `### F-NN [Px] <status> - <title>` headings with a `File:` line; `needs-you.md`
  keeps open lines only; `current-work.md`'s header fields are read by `ship`,
  `deploy` and `progress`. Today a malformed one is found when a later skill
  misreads it - the class every seam test in this repo was written for.
- **Budgets are reported, not held.** The loaded context (D14) and the 8 KB
  overview cap are measured by `install.sh`, `progress` and an optional hook -
  nothing stops a commit that breaks them.
- **The checks that exist live in skill prose**, so they run only when an agent
  runs that skill and reads it all.

**Success:** a project has one command that says whether its state files are
well-formed, every tool's commits run it, CI runs it, and its formats cannot
drift from what the skills write, because a test here holds the two together.

## Layer 2 first: the project checker

Layer 1 only calls it, so it is designed first.

**`lib/check-project`** (a bash script; the name is a proposal), installed to `.agents/bin/check-project` beside
`merge-capabilities.sh` - the path `install.sh` already writes and already
reports when `.gitignore` hides it. Run from a project or a part root:

    .agents/bin/check-project            # every check; one line per problem
    .agents/bin/check-project --staged   # the index's copies, for pre-commit

Exit 0 clean, 1 with problems, 2 when it could not run (no python3, not a
project). Every line names the file, the problem and **the skill that owns the
file**, from the writer column of `template/AGENTS.md` - the fix is a skill, not
a hand edit.

**Checks, v1** - only what a format already states, nothing new invented:

| Check | Format stated in |
| :- | :- |
| Findings index: headings in the stated form, statuses from the set, every `File:` exists, nothing else | `template/blueprint/context/findings.md` |
| A `deferred` finding has a `Deferred to:` line | the same, and `review` |
| `needs-you.md`: no closed line under *Open* | `template/blueprint/context/needs-you.md` |
| `current-work.md`: reset, or `Type:`, `Verified:` and `Reviewed:` present; `Verified:`/`Reviewed:` either `not yet` or the form the skills write | `skills/spec.md` Step 3, `verify`, `review` |
| Loaded context within the stated budget | rule 18; reuses `hook-context-budget.sh`'s count |
| Overview within 8 KB | `distill`, `progress` |
| Capability files parse | `lib/merge-capabilities.sh` |
| A `preflight:` line, if present, in the form `deploy` reads | `preflight`, `deploy` |

**Not v1:** whether the work is *right* - that stays with `verify` and
`review`. And not files outside the spec's claim (layer 3, which needs a format
that does not exist yet).

**Callers:** `progress` runs it and reports (it already reports the overview
cap; that check moves here so there is one copy); `ci` adds it as a step;
layer 1's hooks; and a person.

### The drift risk, and the rule that holds it

The checker is a second reader of formats the skills write. A second reader
that drifts is the defect this repo keeps finding - so the formats it checks
are **declared once and held from both sides**:

- Each check names its source in a declared list in the script, as the table
  above does. A seam test requires every named source to exist and to contain
  the format string the check matches - edit the template and not the
  checker, and the suite fails.
- **Every template state file passes** the checker as installed.
- **Every check is seen failing**: a test mutates one fixture per check and
  asserts the checker fails *and names that check* - the lint tests' pattern.
- **Run against a real project before it ships** - the 2026-09-30 run's
  project is still on disk. A check that fires on correct output from a real
  agent is a wrong check.

## Layer 1: git hooks

Every tool commits through git, so a git hook is the one enforcement point that
holds in Claude Code, Codex, Cursor, OpenCode and Gemini CLI alike.

**`install.sh --git-hooks`** (and `new-project.sh --git-hooks`) copies
`lib/git-pre-commit` to `.agents/git-hooks/pre-commit` and sets
`git config core.hooksPath .agents/git-hooks`.

- **pre-commit** runs `check-project --staged`, and refuses on exit 1. Exit 2
  passes with one line - failing open, as D20's hooks do.
- **No pre-push in v1.** CI runs the same check on the pushed tree; a second
  copy at push buys one round trip.

**What a git hook cannot do, stated so nothing leans on it:**

- **It cannot ask.** There is no UI, so the commit-on-`main` rule stays with
  D20's Claude Code hook, which asks. A git hook that refused it would break
  `scaffold`, `ci`, `distill`, `prototype`, `preflight` and `ship`, which commit
  on `main` by design (the `setup_commits` list in `tests/test-seams.sh`).
- **It can be skipped** with `--no-verify`. The hook is a tripwire for honest
  mistakes, not a wall. Where `--hooks` is also installed, its `PreToolUse`
  hook denies `--no-verify` and a change to `core.hooksPath`; elsewhere CI is
  the wall.
- **`core.hooksPath` is per-clone config.** The scripts travel with the repo;
  activating them does not. `progress` reports a project whose
  `.agents/git-hooks/` exists but is not the active path, so a fresh clone is
  named rather than silently unguarded.

**An existing hook manager wins.** If `core.hooksPath` is already set, or
`.husky/`, `.pre-commit-config.yaml` or `lefthook.yml` exists, `install.sh`
writes nothing to git config and prints the one line to add to that manager -
the same stance as a hand-written `CLAUDE.md` (report, never edit).

**Opt-in, like `--hooks`**: a project's git config is the user's.

## Open questions - answered, agreed 2026-10-14

1. **One flag or two? Two.** `--hooks` keeps D20's meaning, and git hooks are
   worth having in a project that never runs Claude Code. Where both are
   installed, `--hooks` adds the `--no-verify` and `core.hooksPath` denials.
2. **Multi-part products: one repository, so one hook.** Checked 2026-10-14 by
   running `new-project.sh --parts web,api`: the product root is the only git
   repository; each part is a directory with its own `blueprint/` and its own
   `.agents/bin/`. So the hook is installed once, at the root, and for each
   staged path runs the checker of the part it falls in (the nearest directory
   holding `blueprint/context/`), plus a root pass over the product-level
   files. **The root pass gains one check that already has a stated rule:**
   nothing under `blueprint/status/` is staged - it is never committed (`D9`).
3. **Should `ship` refuse on a failing checker? Yes, as one more item in its
   Step 1 safety pass**, not a new gate paragraph: exit 1 is named with the
   owning skill as the fix, exit 2 is reported and does not refuse. Every item
   passes through `ship`, and without this a project with no hooks installed
   is never checked at all.

**Then try it on a new multi-part project**, as the first real run: created with
`--hooks --git-hooks`, one small item per part taken through the loop headless
with `--setting-sources project,local`, plus one commit of a deliberately
malformed state file in each part and one staged `blueprint/status/` file.
Record it in `coverage.md`.

## Later layers, named so v1 leaves room

3. **More Claude Code hooks**, optional and failing open: `PreToolUse` on
   Edit/Write asks before writing outside the spec's claimed files; `Stop` will
   not end a turn while the checker fails; `SubagentStop` holds `build`'s
   packet to its files; `PreCompact` asks for a handoff. **The file-claim
   checks need `## Files and areas` in a machine-readable form first** - today
   it is free prose, and the `**Quick:**` line is the only list of files.
4. **Other tools' native hooks** - Codex, OpenCode, Gemini CLI - as thin
   wrappers over the same scripts, once 1-3 have run in real projects. Each is
   another format and another test matrix.

## Tests, when built

- `tests/test-scripts.sh`: the checker, one fixture per check, each seen
  failing; the template passes; `--staged` reads the index, not the tree.
- The git hook in a scratch repo: a bad state file refuses the commit, a good
  one passes, exit 2 passes with its line, an existing manager is left alone.
- `tests/test-seams.sh`: every check's declared source exists and still states
  the format; `progress` and `ci` name the checker.
- Rule 8 already requires both new scripts to be referenced.
