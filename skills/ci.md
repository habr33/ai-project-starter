---
name: ci
description: "Set up automatic checks that run on push and on pull requests, using the project's own verification command rather than an invented one. Detects the real stack and any existing workflow, asks which CI tool and runner - GitHub Actions, GitLab CI, Forgejo or Gitea Actions, Woodpecker, another tool, a self-hosted runner, or this machine - writes one config file, runs the same checks locally first to prove they pass, and stops before pushing or changing any remote setting. Use when the user runs `ci`, wants checks to run automatically, asks about a pipeline or a CI/CD tool, runs out of CI minutes on a free plan, wants to self-host CI or run it locally, or when review finds that nothing runs on push."
---

# ci - make the checks run without being asked

**Writes:** `dev-notes/status.md` · `blueprint/context/findings.md` · `blueprint/findings/`

Where this sits:

    `scaffold` -> ci -> `distill` -> the build loop

**This runs early, right after `scaffold`, not at the end.** Its only input is the
verification command, which `scaffold` writes - so there is nothing to wait for,
and waiting costs the whole build. Local checks only help the person who
remembers to run them; every item built before this exists is an item nobody
checked automatically.

**Re-run it whenever the checks change.** A second pass is a change to the
existing config, never a replacement, so the small pipeline written here is meant
to grow rather than to be right forever.

**It writes a config file locally and stops.** Pushing it, and any change to a
remote setting, needs a separate yes.

## Before you start

There must be something worth running. Read the verification command from
`AGENTS.md`. **If there is no verification command, stop** and say to run `setup`
or `scaffold` first - CI that runs nothing is worse than no CI, because it turns
a green tick into a lie.

**One test and a typecheck is enough to start.** That is what a freshly
scaffolded project has, and it is the point: the pipeline exists before the code
does, so the first real item is the first thing it protects. Waiting for a suite
"worth protecting" means the suite grows unprotected.

Check whether a workflow already exists. If so, this is a change to it, not a
replacement, and the existing one is preserved.

## Step 1 - find out what is really here

- the verification command, and whether it passes **from a clean checkout** -
  not merely in the working tree you are sitting in. **A runner has only what is
  committed**, and generated files are usually gitignored: route types, compiled
  protobufs, a generated client, anything a framework emits into a build
  directory. Locally they are already there and the command passes; on the runner
  they are absent and it fails, reporting a missing *symbol* rather than a
  missing *step*, which reads as broken code.

  **Check it, do not reason about it.** Move the build directory aside and run
  the command again. A command can pass in the
  working tree and fail on a clean checkout (a missing generated type, say) -
  Next generates route types into a gitignored directory, and
  the fix was a generation step at the front of the verify command, not anything
  in the workflow file.

  **The fix belongs in the verification command, not the pipeline.** A generation
  step added only to the workflow makes CI pass while the same clean checkout
  still fails for a human.
- the package manager and lockfile
- the runtime version - matched to what `AGENTS.md` records, not the newest
- any existing CI config, and what it currently runs
- whether there is a remote at all, and which host it is on. **This decides the
  file you write**, and there is no neutral format: GitHub Actions, GitLab CI and
  Forgejo Actions are different files in different places. **If there is no
  remote, stop and ask which host the repository will live on, before writing
  anything** - a config written for the wrong host is not adapted later, it is
  rewritten, and the user finds out when they first push. Recommend one, with
  the evidence (a logged-in CLI, the other projects' remotes), but let the user
  answer: "say which host you are assuming" is an instruction that is easily
  skipped, writing a GitHub workflow and explaining it afterwards
- **which CI tool runs it, and on what machine** - below. The host suggests a
  tool but does not decide it: a GitHub repository can run on its own runner,
  and any repository can run on this machine

### Pick the tool and the runner - the user's call

**Ask, with a recommendation and its evidence** - the remote's host, a
logged-in CLI (`gh`, `glab`, `tea`), a runner already registered, whether the
repository is public. Record the answer as `- CI tool: <tool> on <runner>` in
the Environments section of `AGENTS.md`, and the dependency install the
pipeline runs as `- Install:`. `.agents/bin/ci-checks.sh` reads `CI tool:`, and
it is how `dispatch` and `deploy` read every pipeline, whichever tool it is.

| `CI tool:` | Config | Results read by |
|---|---|---|
| `github-actions` | `.github/workflows/ci.yml` | `gh`, logged in |
| `forgejo-actions` | `.forgejo/workflows/ci.yml` (Gitea: `.gitea/workflows/`) | the API, with `FORGEJO_TOKEN` |
| `gitlab-ci` | `.gitlab-ci.yml` | `glab`, logged in |
| `woodpecker` | `.woodpecker/ci.yaml` | the API, with `WOODPECKER_SERVER` and `WOODPECKER_TOKEN` |
| `local` | none - `.agents/bin/ci-local.sh` is the pipeline | the results it writes in `.git/ci-local/` |
| `other: <name>` | that tool's own format | `- Read checks:` - a command the user gives, printing each job as `{"name","bucket"}`, written beside `CI tool:` |

**The runner is a separate question**, and it decides what CI costs:

- **hosted** - the tool's own machines. **On a free plan, minutes run out**:
  GitHub's free plan meters private repositories by the minute, every job is
  billed whole minutes, and a sharded suite multiplies it. **Estimate the
  month** - jobs per run × minutes per job × (pull requests + pushes to the
  default branch) - and say it beside the plan's allowance before writing the
  file. A public repository on GitHub's standard runners is not metered.
- **self-hosted** - the same config on a machine the user runs, labelled in
  `runs-on` or `tags`. No minutes to run out, and the machine is theirs to keep
  up. **Never on a public repository's pull requests from forks**: a fork's
  pull request runs its own code on that machine, with whatever it can reach.
  Use it for a private repository, or require approval for outside
  contributors' runs and keep the runner ephemeral, holding no secret a job
  does not need. **Registering a runner is the user's** - a remote setting and
  a machine; give the steps, do not do it.
- **this machine** - `local`: nothing runs without being asked, so say plainly
  that "without anyone asking" is lost - `dispatch` runs `ci-local.sh` before each
  merge instead, and that is the only gate.

**Whatever the tool, `.agents/bin/ci-local.sh` is the fallback**: when the
pipeline cannot start a job - minutes gone, a runner offline - `dispatch` and
`deploy` run the same jobs here, from a clean worktree of the commit.

**If the verification command fails locally, stop.** Setting up CI to run a
failing command just moves the failure somewhere less visible.

## Step 2 - decide what the pipeline does

Keep it to what the project actually has. For most projects that is one job:

1. check out the code
2. set up the recorded runtime version
3. install dependencies **from the lockfile**, not a fresh resolve
4. run the full verify command - the verification command, then the tests that
   need a browser, a database or a service. CI is where the whole suite runs -
   on every push to the default branch, and on a pull request whose diff needs
   it, below - which is what lets `build` run only a step's own. Where
   the browser tests get their own job, below, this job runs the verification
   command and that one runs the rest - each test once, not twice
5. run `.agents/bin/check-project.sh` from the repository root - the state files
   the skills write, in the form they write them; at a multi-part product's root
   it checks every part

**When the parts are in different ecosystems**, the pipeline sets up each
toolchain and runs each part's checks - Node plus the .NET SDK, `npm test` plus
`dotnet test`. Either one job doing both in sequence, or one job per part in
parallel.

**If a contract is generated between them** - `Kind:` in the product root's
`AGENTS.md` says which it is - **verify it is current**: run `Regenerate:` from
the directory that field names, and fail if the result differs from what is
committed at `File:` under `contracts/` at the product root. `architect` fills
both. A stale contract is a
runtime failure that no unit test on either side will catch, because each part is
individually correct against its own copy.

**Then do the same for the clients.** `Generate clients:` gives a command per
consuming part and the directory each runs from; run each one and fail on any
difference. A generated client drifts exactly the way the contract does, and a
part built against a stale client passes every check it owns - the contract
itself being current says nothing about what was generated from it.

**This job is the only check that runs without anyone asking.** `integrate`
makes the same check, but only when someone remembers to run it - so if the
contract check lives nowhere else, put it here.

**"Without anyone asking" is not "on every push".** The triggers below are pull
requests and pushes to the default branch, so **a feature branch gets nothing
until a pull request exists** - which is deliberate, and worth saying out loud
because it is the opposite of what a green local run suggests. Work the whole
build loop on a branch and CI has seen none of it. Say so when handing off, so
nobody reads a branch with no red marks as a branch that passed.

**If this project has a build, CI is where it happens.** Not a laptop, and not
the target. A developer's machine is not reproducible - it carries their runtime,
their environment and their uncommitted files, and "works on my machine" is
exactly this failure. The target is worse: see `deploy`.

Where there is a build worth keeping, add a second job that produces the artifact
**from the commit being tested** and stores it. That is what makes
"the artifact that was tested is the artifact that ships" a fact rather than a
hope - and it is the only version of that claim anyone can check afterwards.

Add a second job only when there is a real reason - that artifact, or a database
service the tests genuinely need.

**Browser tests run by default, database and all.** If the project has a
browser test tool, add a job that runs it: a database service container for the
tests that need one, the browser the tool installs, and the migrations applied
before the tests start. Leaving it out is the user's call, asked for by name
with its cost - never the default because it is more work. Browser tests tend
to cover the defects that matter most, and a suite CI never runs gates nothing.
**A job gated on a label or a manual start is a job left out** of every pull
request nobody remembered to label: the same call, the same cost said, the
same line in the `ci` row.

**Serve the browser tests a production build**, built once in the job - or
once for the whole run and handed to each job as an artifact. A dev server
compiles each route the first time a test reaches it and runs code production
never does, so it is both the slow way and the less true one.

**When the suite is long, split it** - over `Budget:` under Full verify in
`AGENTS.md`, or a few hundred browser tests: the test tool's own sharding
(`--shard=1/4`), one job per shard, **each with its own database service**, so
tests that cannot share one database still run at once - on separate
machines. Merge the shards' reports into one. That is the one matrix this
skill adds unasked: it changes how long the gate takes, not what it checks.

**Run what the diff needs on a pull request, and everything after the
merge** (`D40`). A whole suite on every pull request makes a stylesheet fix
wait as long as a migration. Start with a `scope` job, from a checkout with
full history (`fetch-depth: 0`): `.agents/bin/test-scope.sh --base
origin/<default branch>` on a pull request, `--push` on a push, its one word
as the job's output. The Verify job always runs; an `affected` job runs the
`Affected:` command under Full verify when the word is `affected`; the full
verify jobs - browser, shards - run when it is `full`, which every push to
the default branch is. **Record `Affected:` when it is missing**: the
runner's own selection - `vitest --changed $BASE`, `jest --changedSince`,
`playwright test --only-changed`, `pytest --testmon` - then the smoke tests
(a tag such as `@smoke`: sign-in, the main journey, a page per area), never
a whole browser suite. With no such selection, leave it out: any code change
is then `full` - slower, never wrong. A project path that needs everything or
nothing - global styles, a component catalogue - goes on a `- Scope: none
<globs> | full <globs>` line beneath it. **Never filter the workflow's
triggers by path**: a workflow that never started reports nothing, so a
required check waits forever or, made optional, gates nothing.

**End with one job that needs every other and fails unless each one
succeeded** - `if: always()`, then a step that checks each needed job's
result. **Name it `gate`.** With a scope job, "each one" is each the word
selected: `scope` and Verify must succeed, and so must `affected` or `full`
when chosen; one left out may be skipped, and nothing else may:

    gate:
      if: always()
      needs: [scope, verify, affected, full]
      runs-on: ubuntu-latest
      steps:
        - run: |
            need() { [ "$2" = success ] || { echo "$1: $2"; exit 1; }; }
            need scope "${{ needs.scope.result }}"
            need verify "${{ needs.verify.result }}"
            case "${{ needs.scope.outputs.level }}" in
              none) ;;
              affected) need affected "${{ needs.affected.result }}" ;;
              full) need full "${{ needs.full.result }}" ;;
              *) echo "no scope"; exit 1 ;;
            esac

**In another tool, keep the same jobs and the same gate.** Forgejo and Gitea
Actions read the workflow above nearly unchanged - `runs-on` names a label the
registered runner has. **Where a later job cannot be skipped by an earlier
job's output** - GitLab CI and Woodpecker decide which jobs exist before any
runs - each optional job reads the scope word from the `scope` job's artifact
and ends at once when the scope did not choose it, saying so in its log; and
`gate` is the last stage, run only when everything before it succeeded
(GitLab's default `when: on_success`, Woodpecker's default `status: success`).
For `local` there is no file: `ci-local.sh` runs these jobs in this order.

A skipped job reports success, even to a required check, and so does
a job skipped because one it needs failed; this job is the one to require
before merging, and it is what lets `dispatch` read one check instead of
trusting a green list.

**Branch on the platform:**

- **Web app, website, PWA** - the above, plus the production build if the verify
  command does not already cover it.
- **Expo / React Native** - typecheck and tests. A store build needs signing
  credentials, which belong in `deploy`, not here.
- **Flutter** - `flutter analyze` and `flutter test`. Same rule about builds.
- **Native mobile** - a CI runner needs the right OS image and signing setup;
  say what it would take rather than writing a config that cannot run.
- **Command-line tool, library, or service with no UI** - the five steps above
  and nothing else. There is no build to add unless the project genuinely has
  one, and **a typecheck or lint is not optional here even when there is no test
  suite**: for a project with no running app, static checks are the only thing
  standing between a push and a broken publish. For a library, run against every
  runtime version the plan says it must support - that is the one place a matrix
  earns its keep.

Do not add matrices - beyond the shard split above - coverage gates, security
scanners, or caching beyond the dependency cache the Rules ask for, just
because they exist. Each one is a thing that can break and needs maintaining.
Start with one job that works.

## Step 3 - show the config, then write it

Show the whole file and what each part does. Explain any decision that was not
obvious - why that runtime version, why that trigger.

Then write it, with:

- triggers on **pull requests and pushes to the default branch**
- **read-only permissions by default**; add a permission only when something
  genuinely needs it
- the exact runtime version recorded in `AGENTS.md`
- a **timeout**, so a hung job does not run indefinitely

## Step 4 - prove it, then stop

Run the same command sequence locally, in the same order the pipeline will, and
confirm it passes. **From a clean checkout** - the same check as Step 1, run
again now that the command may have changed: remove the build and dependency
directories, install from the lockfile, and run the sequence. Anything still
present from earlier work is something the runner will not have. **Time the
full verify part and write it as `Takes:`** under Full verify in `AGENTS.md`
- `~N min, <date>`; it is what `build` and `dispatch` read before starting one.

**`.agents/bin/ci-local.sh --push` is that run**, from a worktree of the
commit with no `.env` and a clean environment - but it tests only what is
committed, so the commands must be. Where they are not yet, run the sequence by
hand now and `ci-local.sh --push` after the commit below. For `local` it is the
pipeline itself; for any tool it is the proof the fallback works. **For
`other`, run `.agents/bin/ci-checks.sh --commit HEAD`** and confirm `Read
checks:` prints the form - a command that prints nothing gates nothing.

**Add `ci` to the Environments table in `AGENTS.md`.** It is an environment: a
different machine, a pinned runtime, and no `.env`. Recording the pin there is
what stops someone later "tidying" the workflow to a floating version the
project's own dependencies do not support.

Then **stop**. Report:

- what the config runs, and when - which diffs run less than the whole
  suite, as `test-scope.sh` gave them on a docs-only and a code change run
  here, and that every push to the default branch runs all of it
- **every test command the project has that the pipeline does not run**, and
  why. Browser tests are run by default, above; if the user chose to leave them
  out, say so here with the reason they gave. Record the answer in the `ci` row of the Environments table, so "CI is
  green" is never read as "the browser tests passed"
- that it passed locally
- **that nothing has been pushed**, and that pushing is the user's call
- what would still need doing on the remote by hand - requiring the check before
  merge is a repository setting, not a file; registering a self-hosted runner
- **the tool and runner chosen, the month's estimated minutes against the
  plan's allowance, and the fallback**: when the pipeline cannot start,
  `.agents/bin/ci-local.sh` runs it here

Record the verification command in `dev-notes/status.md` under running it by
hand, so the same checks can be run without the pipeline.

**Ask to commit what this run wrote, on `main`, locally** - the workflow file,
the `ci` row in `AGENTS.md`, the line in `dev-notes/status.md`, and any finding
recorded in `findings.md` and `findings/` - as one `ci: ...` commit. Step 3
showed the config but asked nothing, so this question is the yes. **Ask it
once**: where the main-commit hook is installed, run the commit and its prompt
is the question - do not ask in text as well.
**Committing is not pushing**, and pushing stays the user's separate call. Left
uncommitted, all of it is carried onto the first item's branch and merged as
part of that item.

**Then say what comes next: `distill`.** It generates the overview the build
loop reads, and it is the last planning step before `spec` starts on items.

**When this skill repairs a finding** - a `preflight` blocker such as no automated checks, or a verification command that skips some - **set it to `fixed`** in `blueprint/context/findings.md`, with the evidence in the **Resolution** line of its entry, `blueprint/findings/<ID>.md`: the workflow ran and failed on a deliberately broken check. **Never `closed`**: `preflight` re-checks it and closes it, because a repair is examined by something other than what made it. Left `open`, it blocks every later `dispatch` in this part.

## Rules

- **Never push, and never change a remote setting.** Branch protection,
  required checks and registering a runner are the user's to configure.
- **Never point a self-hosted runner at a public repository's fork pull
  requests.** Their code runs on that machine.
- **Never invent a check.** CI runs what the project has; a gap is reported as a
  gap.
- **Check full verify actually runs what the project has configured.** A
  linter, a formatter check, a type checker or a test suite that exists and is
  not in it is a check that gates nothing. **A browser or database suite that
  is in full verify and not in the verification command is where it belongs**,
  not a gap: the verification command runs after every build step. Anything
  else left out of full verify - it will be run by
  whoever remembers, which over time is nobody. Report it with what it would
  take to wire in, and **do not wire it in from here**: adding a gate can turn a
  green project red, which is a decision, not a detail. Say plainly which checks
  the pipeline enforces and which merely exist.
- **Preserve an existing workflow.** Change it deliberately, never overwrite it.
- **Never put a secret in the config.** Reference it by name from the host's
  secret store.
- **Prove it locally first.** A pipeline nobody has run is a guess. **Prove it
  the way CI will see it**: from a clean dependency install, and **without the
  local `.env`**. A project's `.env` supplies variables the runner will not have,
  so a proof that runs with it present says nothing about whether the pipeline
  works - it is the same shape as a test that passes because the fixture was
  already there.
- **Cache the dependency install** where the host offers it. Not correctness, but
  without it every run re-downloads the whole tree, and CI cost is paid on every
  push forever.

## Formatting

Match `blueprint/context/ai-interaction.md` when it exists; otherwise keep output short, scannable, and direct.
