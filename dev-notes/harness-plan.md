# Rules that execute in every tool - implementation plan (2026-10-14)

Implements `harness-design.md` (read it first) and `D23`, with the three answers
the user agreed on 2026-10-14. One branch off `main`, `harness`, one commit per
task. Every test is seen failing first; then the fix is broken in a copy and the
mutation checked to have changed what the assertion names. New tests go above
`finish` in each test file. Run `./check.sh` after every task and
`./tests/run.sh` once at the end (minutes - never two at once).

Rule 8 rejects a reference to a script that does not exist, so each script
lands before any doc or skill names it - and this plan names them without
their `.sh` extension until then.

## Task 1 - `lib/check-project` (design, *Layer 2*)

Bash + `python3`, like `lib/migrate-findings.sh` and
`lib/merge-capabilities.sh`; read both for the style.

- Usage: `check-project [--staged] [DIR]`, DIR defaulting to `.`. Exit 0
  clean, 1 with problems, 2 when it could not run (no python3, DIR is neither a
  part nor a product root).
- **A part** is a directory holding `blueprint/context/`; **a product root**
  holds `blueprint/orchestration.md`. At a root, check the root's own files,
  then every part one level down - so one call covers a whole product, for the
  hook and for CI alike.
- **`--staged` reads every checked file from the index** (`git show :<path>`),
  not the tree: what the commit will contain, whatever was staged.
- One line per problem: `<file>: <problem> - fix with <skill>`. *Changed in
  the building:* each check names its one repairing skill, and the seam test
  requires it to be in that file's writer column in `template/AGENTS.md` -
  reading the column at run time named up to eleven writers, which tells
  nobody which one to run.
- The checks are the design's table, plus at a root with `--staged`: no path
  under `blueprint/status/` other than `.gitkeep` is in the index (`D9`; the
  files are gitignored, so only `git add -f` gets one there).
- **Each check declares its source** in a list at the top of the script: the
  file that states the format and the exact string it matches. The overview
  cap's number is read from where `progress` reads it today.
- Writes nothing, so rule 16 has nothing to say.

**Tests** (`tests/test-scripts.sh`, new section *the project checker, D23*):
- a fresh single-part project and a fresh `--parts web,api` product pass;
- one mutated fixture per check, each failing **and naming that check and its
  skill**; a mutation in `api/` is reported under `api/`;
- `--staged`: a bad file in the tree but a good one in the index passes, and
  the reverse fails; a force-added `blueprint/status/web.md` fails at the root;
- exit 2 without python3 (PATH stripped) and outside a project.

**Seam test** (`tests/test-seams.sh`): every declared source exists and still
contains its string - so editing a template's format without the checker fails
the suite.

## Task 2 - install it, and the three callers (design, *Callers*; answer 3)

- `install.sh`: copy to `.agents/bin/check-project` beside the merge script
  (the `.gitignore` report already covers that directory). `new-project.sh`
  gets it through `install.sh`, at the root and in every part.
- `progress`: run it and report its lines; **its own overview-cap check moves
  into the checker**, so there is one copy. Update the seam test that holds
  `progress`'s number to the template's to hold the checker's instead.
- `ci`: the workflow runs it from the repository root, with the project's own
  verification command.
- `ship` Step 1: one more safety-pass item - exit 1 is a blocker naming the
  owning skill as the fix; exit 2 is reported and does not block. **Not** a new
  gate paragraph.
- `docs/anatomy.md`: the checker's row - what it reads, who runs it.

**Tests:** seam assertions that `progress`, `ci` and `ship` name the script and
that `ship` treats exit 2 as not blocking; `test-scripts.sh`: `install.sh`
writes it executable, and an upgrade refreshes it.

## Task 3 - `lib/git-pre-commit` and `--git-hooks` (design, *Layer 1*; answers 1-2)

- The hook: find the repository root, run its `.agents/bin/check-project
  --staged`; exit 1 refuses the commit, printing the lines; exit 2, or no
  checker there, passes with one line.
- `install.sh --git-hooks`: copy it to `.agents/git-hooks/pre-commit` and set
  `core.hooksPath .agents/git-hooks`. **Every refusal comes before the first
  write** (rule 16): the target is not a repository's top level - name the
  root and say to run it there; or a hook manager is present (`core.hooksPath`
  already set, `.husky/`, `.pre-commit-config.yaml`, `lefthook.yml`) - then
  write nothing to git config, print the line to add to that manager, and
  still install the rest.
- `new-project.sh --git-hooks`: once, at the root only - not per part, unlike
  `--hooks`.
- `progress`: report `.agents/git-hooks/` present but not the active
  `core.hooksPath` - a fresh clone, named rather than silently unguarded.
- Usage text, `README.md`, `docs/anatomy.md`.

**Tests** in a scratch repository: a bad staged state file refuses the commit
and a good one passes; a bad file in a part refuses a commit at the root; exit
2 passes with its line; each hook manager is left alone and its line printed;
a non-root target refuses with every file byte-identical; a re-run is
idempotent.

## Task 4 - `--hooks` holds the git hook in place (design, answer 1)

When `.agents/git-hooks/` is the active path, `lib/hook-main-commit.sh` also
denies a `git commit` with `--no-verify` or `-n`, and a `git config` that
changes `core.hooksPath`. Deny, not ask: unlike a commit on `main`, no skill
needs either. Without git hooks installed it stays silent on both.

**Tests** beside *the optional hooks, D20*: each form denied; `git log -n 3`
and a commit without the flag not; silent where git hooks are not installed.

## Task 5 - records

`D23` from proposed to built, with what the tests prove and what they do not;
the listing in `status.md` (two new scripts); `coverage.md` untouched until the
trial.

## Task 6 - the trial (design, *Then try it*)

A new `--parts web,api` product with `--hooks --git-hooks`; one small item per
part through the loop, headless with `--setting-sources project,local`; then in
each part a commit of a deliberately malformed state file, and one force-added
`blueprint/status/` file - each must be refused, naming its skill. Record what
held and what did not in `coverage.md`, and any pack finding as a fix with its
test. **Ask before starting: it spends real money** - the last full run of
one part cost about $14.60.
