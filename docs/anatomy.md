# Anatomy — how each part does its job

`README.md` says what this is. `docs/walkthrough.md` says how to use it.
`dev-notes/` says why it is shaped this way. **This says how it works** — what
each part reads, what it writes, what stops it, and what it hands to.

Read this when you are changing the workflow rather than using it.

## The shape

Two rules explain almost everything else.

**Every piece of state is a file.** There is no daemon, no database, no session
memory. A cold session is the normal case, so anything that must survive one is
written down. This is why a cleared context costs nothing and why `- [x]` in a
spec is the resume mechanism rather than a nicety.

**Every skill states its preconditions.** Each opens with `## Before you start`,
naming what must already be true and what to run when it is not. Two kinds:
**blocking** — it stops, because proceeding would build confident output on a
placeholder; and **advisory** — it says what is missing and continues, which is
how `review` distinguishes "checked and consistent" from "there was nothing to
check against". Six skills are exempt and the exemption is declared in `check.sh`
rule 10: `setup`, `progress`, `preflight`, `debug`, `docs`, `prepare` — the entry
point for an existing project and the reporters, which work in any
state. **`ideate` was on that list and came off it**: it was exempt as a
greenfield entry point, and that stopped being true when it gained `--rescope`
and could run against a project with built work behind it. An exemption is a
claim about a skill, not a permanent property of it.

**Every skill is a worksheet, not a program.** A skill is markdown an agent
follows and a person can work through by hand. Nothing executes them, which means
**a gate holds only if the thing following it reads and obeys it.** That is the
load-bearing weakness of the whole design, and most of the discipline below
exists to compensate for it.

## The state, and who writes it

A file with readers and no writer is the most repeated defect in this workflow's
history — four separate instances. So every file has a declared writer, and
`check.sh` rule 12 enforces both halves: a file any skill reads must have a row,
and the row's writers must be exactly the skills whose own `**Writes:**` line
names that file. A skill that only reads a file can no longer pass as its writer
by mentioning it.

| File | Holds | Written by | Read by |
|---|---|---|---|
| `blueprint/project-plan.md` | the what and why | `ideate` `architect` `stack` `layout` `setup` | 12 skills |
| `blueprint/build-plan.md` | the checklist — per part, and **splitting the product's items across parts is `architect`'s job whenever there are parts**, because `ideate` writes the only initial set, and re-running it needs `--rescope` | `ideate` `architect` `spec` `ship` `setup` | `context` `progress` `monitor` `preflight` |
| `blueprint/context/project-overview.md` | the source of truth, generated | `context` | `spec` `build` `review` `progress` |
| `blueprint/context/fundamentals.md` | conventions that hold regardless of stack — **not loaded every session**; the three skills that need it read it | **the pack** — refreshed on every install | `spec` `build` `review` |
| `blueprint/context/coding-standards.md` | this project's own conventions, and the standards it follows | `scaffold` `setup` | `spec` `build` `review` `progress` |
| `blueprint/context/quality-bar.md` | performance, scale, security, availability — **product-level: in a multi-part product it lives at the product root, like the plan** | `architect` `setup` | `spec` `verify` `review` `preflight` `monitor` |
| `blueprint/context/principles.md` | the project's non-negotiable commitments — what it will never trade away. **Product-level, like the plan.** Never inferred from code: `setup` reports it unrecorded rather than writing one | `ideate` | `architect` `review` `preflight` |
| `blueprint/context/design.md` | visual decisions, measured values | `prototype` | `spec` `review` `ship` |
| `blueprint/context/current-work.md` | the one item in flight, steps ticked | `spec` `build` `ship` `rollback` | 7 skills |
| `blueprint/context/findings.md` | the findings **index**, loaded every session — one heading per live finding, and status lives only here. Code findings close through `review` (or `build`, at P2 or P3, with a test seen failing first); non-code ones through a `preflight` re-check | `review` `build` `ship` `verify` `preflight` `host` `docs` `ci` `deploy` `monitor` `migrate` | `spec` `progress` `ship` `preflight` |
| `blueprint/findings/` | each finding's full entry, `<ID>.md`, read on demand; and `backlog.md`, the unresolved P3s `ship` moves out of the index | `review` `build` `ship` `verify` `preflight` `host` `docs` `ci` `deploy` `monitor` `migrate` | `spec` `review` `progress` `preflight` |
| `blueprint/context/needs-you.md` | work only a person can do — accounts, spend, system software, hardware, manual checks, decisions | `stack` `scaffold` `setup` `spec` `host` `verify` `build` `architect` `ship` | `prepare` `progress` `preflight` |
| `blueprint/history/` | every completed item, archived — **and the only record of what each shipped feature was proved to do** | `ship` | `progress` `verify` `rollback` `docs` `preflight` |
| `blueprint/production-pending.md` | what production still needs for merged items — variables, migrations, accounts. `spec` names them, `ship` carries them, a production `deploy` ticks them off | `ship` `deploy` | `deploy` `progress` |
| `blueprint/orchestration.md` | the board — multi-part only; **one board, in the main checkout**, when parts work in git worktrees. The contract line is committed; `status/` is working state and gitignored | `orchestrate` + the scripts | `orchestrate` |
| `CHANGELOG.md` | what changed, for users | `docs` | `preflight` |
| `project-plan.md` · §8 Deployment | target host, build and start commands, env vars by name, storage, health check | `stack` `architect` `scaffold` | `host` `deploy` `preflight` |
| `AGENTS.md` · Environments | every place this code runs, and which hold real data | `scaffold` `host` | `deploy` `migrate` `preflight` `monitor` |

**`current-work.md` is the hinge.** Eleven skills touch it and four write it.
`spec` fills it, `build` ticks it, `ship` clears it, and `rollback` writes the
guarded plan for a reversal into it. That is why shipping in
one part of a multi-part product used to destroy another part's in-flight work,
and why the coordination board is one file per part rather than one file with
rows.

## Plan

| Part | Reads | Writes | Stops when | Hands to |
|---|---|---|---|---|
| `ideate` | nothing when the plan is empty; with `--rescope`, both plans, `history/` and current-work | project-plan, build-plan, **principles** | plan already filled and no `--rescope` | `architect`, or `setup` + `context` after a rescope |
| `architect` | project-plan, build-plan, **principles** | project-plan Architecture, **quality-bar**, decisions, each part's build-plan and needs-you | plan absent, or problem/features still placeholder | `stack` |
| `stack` | project-plan Architecture + **quality-bar** | project-plan Tech, decisions | Architecture section empty or placeholder | `layout` |
| `layout` | project-plan Tech + Architecture | project-plan Architecture (the tree), decisions | Tech or Architecture still placeholder | `scaffold` |
| `scaffold` | project-plan Tech + Architecture, incl. the layout | the app, AGENTS.md, **coding-standards**, decisions | Tech section empty or placeholder | `ci` |
| `ci` | AGENTS.md commands + runtime, contracts | one workflow file, its Environments row, status, findings→`fixed` | no verification command exists | `context` |
| `context` | both plans | project-overview | either plan missing | `prototype` or `spec` |
| `prototype` | project-plan UI/UX, project-overview | `prototypes/`, **design.md** | project-overview absent | `spec` |

**Why `architect` precedes `stack`.** Architecture is the design of the system;
technology is how it is implemented, and it is chosen *against* that design.
Reversed — as this pack had it until 2026-09-08 — the architecture becomes
whatever the chosen technology makes easy, and the questions that should have
ruled a technology out get asked afterwards, when the answer is a rewrite rather
than a choice. **The six shape questions are the seam**: more than one deployable
service, work outside a request, consistency across more than one write, a
dependency whose failure is unacceptable, real load, an unreliable external API.
`architect` asks them; `stack` reads the answers - "work outside a request" makes
a job runner a requirement before anyone is attached to a framework that has
none. **The answers are read together, not singly**: "consistent across more than
one write" is a transaction requirement that every relational database meets, and
it is the *load* answer that bears on concurrent writers. **The
quality bar works the same way** — written by `architect` as requirements, read by
`stack`, because a bar written after the choice only ratifies it.

**Why `layout` sits between `stack` and `scaffold`.** Where files physically sit
is a *framework convention*, not an architectural decision: a flat source root is
idiomatic in one ecosystem and broken in another, because a .NET `.csproj` globs
everything beneath it. That is knowable only once the framework is known, so it
cannot move earlier — and `scaffold` installs into a shape, so it cannot move
later without moving an installed framework and its lockfile instead of markdown.
**`architect` decides how many deployable parts and why; `layout` decides what the
directories are called.** Those look like one question and are not.

`prototype` sits after `context` because it reads `project-overview.md` for what
the screens must show.

**Three files are born here** that nothing else can produce: the quality bar, the
coding standards, and the design record. Each exists so a later lens checks
against *this project's* recorded values rather than a generic standard.

## Build — the loop, once per item

| Part | Reads | Writes | Stops when | Hands to |
|---|---|---|---|---|
| `spec` | build-plan, overview, standards, quality-bar, design, findings | **current-work**, build-plan | no overview; an item already in flight | `build` |
| `build` | current-work, overview, standards, findings | source, current-work ticks, findings→`fixed` | current-work holds no real spec | `verify` |
| `verify` | current-work done-whens; with `--all`, **every archived done-when under `history/`** | findings (a regression), needs-you (a could-not-verify) — never code | no spec and no `--all`, or no step ticked | `review` or back to `build`; a regression found by `--all` goes to **findings**, since there is no spec to return to |
| `review` | source, standards, quality-bar, **principles**, design, findings | **findings only** | *(advisory)* — reports missing bars | repairs, or `ship` |
| `ship` | current-work, findings, build-plan | history, build-plan, decisions, current-work reset, one commit | no completed spec; an open P0/P1 | `ci`, `deploy`, `integrate`, `docs` |

**Each of the four checks asks a different question**, and that separation is the
point:

- `build` — *does this step do what it said, and did it land?* Checks the diff is
  non-empty and the done-when on its own terms.
- `verify` — *does the running thing behave as the spec promised?* Read-only.
  **"Could not verify" is a valid result and never a pass.**
- `review` — *is the code sound?* Writes findings with durable IDs.
- `ship` — *is this safe to merge?* An open **or fixed** P0/P1 blocks it, because
  a repair is re-examined by something other than what made it.

**`debug` sits outside the line and is reached from inside it** — from `build`
after a step fails twice unexplained, from `verify` when a criterion fails for a
reason nobody can state, and from `deploy`, `monitor` and `integrate` when
something is already live. It edits no product code; it isolates and hands back.

## Operate

| Part | Reads | Writes | Stops when | Hands to |
|---|---|---|---|---|
| `preflight` | plan, overview, standards, findings, quality-bar, **principles**, history, CHANGELOG | **findings only** — blockers as P0/P1, and `closed` on a non-code repair it re-checked | *(no gate — it audits any state)* | the skill fixing each blocker |
| `host` | project-plan Deployment + Architecture | infrastructure, secrets, status, decisions, findings→`fixed` | plan names no service, database or domain | `deploy` |
| `deploy` | build output, env, migrations | the release, status (**the commit**), findings→`fixed` | *(advisory)* — names missing preflight/ci/host; **stops on a pending migration**, which is `migrate`'s | `monitor`, `docs` |
| `monitor` | signals, quality-bar, build-plan | status, findings→`fixed`, proposed plan items | nothing is deployed | `debug`, or `spec` |
| `migrate` | project-plan Tech + data model | the schema, status, decisions, findings→`fixed` | no database; no recent backup | `build` |
| `integrate` | contracts, each part | nothing — reports | single-part project | `deploy` |

**`preflight` is the only whole-project gate.** `ship` asks whether a change is
safe to merge; `deploy` asks whether a deployment will succeed. Neither asks
whether the product is fit for real people. A project with faultless code and no
backups passes `review` and fails here. It is allowed — required — to say no-go.

**`prepare` reports on you, not on the project.** Every other status skill asks
about the code: `progress` — *where am I?*, `review` — *is the code sound?*,
`preflight` — *can this face real users?* This one asks **whose turn is it, and
what do I need to get?** It reads `blueprint/context/needs-you.md`, which eight
skills write the moment they hit something an agent cannot do — an account, a
card, an SDK, a device, a decision. Read-only: it never buys, installs or
decides, which is the same boundary that makes `host` trustworthy.

Run it before anything expensive to interrupt — a stalled `scaffold` or a `host`
that needs a card you do not have costs far more than the seconds it takes.

**`monitor` is the only way in from outside.** Every other loop runs between the
plan and the code: `spec` reads the plan, `build` reads the spec, `review` reads
the code, `ship` updates the plan. Without monitor's deliberate
read-the-signals pass, a project can be perfectly executed against a plan nobody
ever checked against use.

## Around the loop

The skills a person reaches for between, beside or instead of the loop's steps.

| Part | Reads | Writes | Stops when | Hands to |
|---|---|---|---|---|
| `setup` | the existing repo, its config and conventions | AGENTS.md stack and commands, standards, quality-bar (discovered), needs-you; for a project with shipped features, **both plans**, after approval | *(no gate — it adopts any repo)* | `ci`, then `context` |
| `progress` | both plans, overview, current-work, findings, needs-you, history, git | nothing — read-only | *(no gate)* | the one next action |
| `prepare` | needs-you, the plan, quality-bar, the Environments table | nothing — read-only | *(no gate)* | the skill that owns each line |
| `debug` | the failure, current-work, the code | nothing — never product code | *(no gate)* | `spec` for a fix, or back to `build` |
| `docs` | README, dev-notes, plan, history, the code | README and API docs, decisions, status, CHANGELOG, findings→`fixed`; with `--check`, nothing | *(no gate)* | whatever the audit found |
| `rollback` | history archive, git history, current-work | current-work — a guarded `Type: Rollback` spec | the feature is not shipped; another item is in flight; it is a bad release (`deploy`) | `build`, then `ship` |
| `autopilot` | the range's own inputs, the board, the review queue | code on a branch through the skills in its range, the part's status | not explicitly asked; any preflight miss; unfrozen contract for a consumer; two packets waiting | a review packet, then `ship` |
| `orchestrate` | the board, every status file, each part's plan, current-work and findings | the contract line, committed on its own | no board; not run from the product root; placeholder `Owner:` | the next skill per part |

## The gates that actually hold

Ordered by how easy each is to walk past — which is the useful ordering, because
none of them execute:

1. **Read the diffs.** The comprehension gate. Everything else exists to make it
   possible, and it is the one thing that cannot be delegated — a subagent
   reporting "done" is not a substitute for having read what it did.
2. **A non-empty diff.** `build` confirms the change landed and the claimed files
   exist. A verification command that returns 0 for a step that wrote nothing is
   the worst available failure: every signal green, on top of nothing.
3. **The done-when on its own terms.** Not just that the suite is green — a
   runner configured to pass with no tests reports success for a step that added
   none.
4. **An open or fixed P0/P1 blocks the merge.**
5. **`preflight` may say no-go.**
6. **Autopilot's undo boundary.** *If the only way to undo a step is a backup, an
   invoice, or an apology, it does not run unattended.* Everything permitted is
   recoverable with `git reset`, `git checkout`, or deleting a directory.
   Permanently blocked: provisioning, production deploys, migrating real data,
   third-party accounts, and pushing.
7. **The review cap.** Autopilot refuses to start while two packets already wait.
   Three parts each running unattended produce three self-reviewed drafts at
   once — every gate technically satisfied and nobody has read anything.

## What holds this together mechanically

`check.sh` has 18 rules. Thirteen were added *after* a specific bug got through,
which is the only reason they are the right thirteen:

| Rule | Catches | Added because |
|---|---|---|
| 5 | a retired skill name | a stale plain-prose reference looks like ordinary text |
| 7 | a skill no route from an entry point reaches | `prototype` sat orphaned for the pack's whole life |
| 8 | a script nothing references | `convert-to-parts.sh` was built and unrouted within the hour |
| 9 | a board field with no writer | `Blocked on:` had four readers and nothing set it |
| 10 | a skill that states no preconditions | 7 of 25 had them, each written differently |
| 11 | frontmatter outside host limits | over the cap a skill **silently does not load** |
| 12 | a state file with no declared writer | the same defect, four separate times |
| 13 | a product-root file read as if it were the part's | `orchestrate` resolved the board to the part it ran in |
| 14 | a decision skill silent on re-deciding | `ideate` re-run erased the `- [x]` marks that are the resume mechanism |
| 15 | a mode missing from its skill's description | `docs --check` was reachable only by someone who already knew |
| 16 | a script that refuses after it has written | `convert-to-parts.sh` moved every file into a part, then refused `-api` - the third time |
| 17 | a contract field with no writer or no reader | `Kind:` appeared once in the pack, in the block that calls itself read |
| 18 | a template loading more than half the context budget | a real project loaded 160 KB before the user's first message, and no limit had ever been stated |

**One class was recorded here as unlintable for months and is now rule 13.** A
path that resolves to the wrong directory — every file valid, only the runtime
directory wrong — recurred six times, and no smarter check ever found it. What
did was **declaring the product-level files** in `template/AGENTS.md`: once that
list existed, the rule is one line of it per skill. A class becomes checkable at
the moment it is written down, which is the move to copy when the next one shows
up.

**One class is still not lintable.** A reader that runs before its writer *in
time* rather than in files — ordering is not expressed in anything a linter
reads. It is found the way the path one was before it had a rule: trace the loop
as a sequence and ask, at each step, *who writes this, and where does it actually
land?*

**Two owners, never one file.** `blueprint/context/fundamentals.md` is the
pack's — refreshed on every install, so an improvement reaches projects that
already exist — and `coding-standards.md` is the project's and is never
overwritten. **Where they disagree, the project's file wins**, which is also how
a project overrides a fundamental: state your version with the reason, because
deleting one from the pack's file just gets it back next install.

They were one file with a pack-owned half and a project-owned half, and that is
exactly why the fundamentals never reached any project created before they were
written: the installer only ever wrote a template file when it was absent.

**Installing is an upgrade path, not just a first run.** Skills are always
replaced from `skills/` — they are generated artifacts and a stale one is
indistinguishable from a current one. Skills the pack retired are removed by
name. Anything unrecognised is reported and left alone, because it is yours. And
a shape the pack no longer produces is named along with the skill that fixes it,
never rewritten in place.

## Changing the workflow's shape

Six kinds of change have broken this pack repeatedly, and each has one step
that is easy to skip and invisible afterwards. **The step is always a
declaration** - the rules here can only check what has been written down, which
is why every one of them is driven by a list in `template/AGENTS.md` rather than
by cleverness.

**Adding a state file** - a file skills read and write.

1. Add a row to the state/writer table in `template/AGENTS.md`. Rule 12 fails
   without it, in both directions.
2. Decide **part-level or product-level**, and say which. Part-level is the
   default. Product-level means adding it to the `<product root>/` list in the
   multi-part marker, after which rule 13 requires every skill naming it to say
   where it resolves.
3. Check the writer is reachable **on every route that needs it** - greenfield
   *and* brownfield. `coding-standards.md` had a writer for a year that only the
   brownfield path reached, so every project built from scratch used the
   placeholder.
4. Ship it in `template/` if projects should get one, and remember `install.sh`
   only refreshes pack-owned files - a project-owned file added later never
   reaches an existing project. Say so, or it freezes at install time.

**Adding a handoff between skills** - a new arrow in the loop.

1. Write the actual handoff in prose in the *source* skill, with the reason.
   A chain diagram is a declaration, not a handoff; rule 7 is satisfied by any
   mention, including one inside a diagram.
2. Add the pair to the `PAIRS` list in `tests/test-seams.sh`. **That list is the
   population** - four broken transitions survived because the population
   stopped at `review ship`.
3. Reconcile every declaration site, then verify by *count*, not by eye.

**Reordering the loop** - moving a skill to a different position.

1. Reconcile every chain diagram, then **verify by count**: `grep -c` the old
   transition across the repo and assert zero, in `tests/test-seams.sh`. Two
   moved skills produce four broken transitions, not two.
2. **Update the `PAIRS` list**, or the handoff test silently checks the old
   order. It kept passing after the 2026-09-08 reorder because each old
   successor was still mentioned somewhere in prose.
3. **Hunt the rationale, not just the arrows.** Every skill that explained *why*
   it sat where it did now explains a loop that does not exist, and a stale
   rationale is worse than a stale arrow - it reads as reasoning and teaches the
   wrong model. The reorder that put `architect` before `stack` left nine such
   claims, each individually true-sounding, in six files.
4. **Re-check who writes what.** `architect` opened the Deployment section
   because it now runs before `stack`; that changed a writer, which is rule 12's
   business, and nothing about the arrows would have shown it.
5. **Age the coverage table.** A skill that has run is not a skill that has run
   *in this order*. Say so in `dev-notes/coverage.md` rather than leaving a
   "yes" that means something it no longer means.

**Adding a skill** - see above, plus: something must route to it. `prototype`
existed unreachable for the pack's whole life. Rule 7 catches an orphan but is
satisfied by a passing mention, so check the routing by following the loop.

**Splitting or adding a part** - anything written before there were parts lands
in one part. `convert-to-parts.sh` lists what it moved; `architect` owns the
split. Nothing splits it automatically, and nothing can: telling a product
feature from a front-end-only one is judgement.

**Adding a linter rule** - a new class made checkable.

1. **Write the declaration first, then the rule.** Every cross-file rule here
   reads a list someone wrote down - `decision_skills`, the product-root marker,
   the contract table rule 17 reads. A rule clever enough to need no declaration
   is a rule that guesses.
2. **Run it before fixing anything.** Rule 13 found five more skills the moment
   it existed; rule 17 found nine missing bindings, one of them a field no file
   in the pack mentioned. What the rule finds on its first run is the argument
   for it, and it belongs in the decision entry.
3. **Update the count in all five places** - `AGENTS.md`, `README.md`, this
   file, `dev-notes/status.md`, and `check.sh`'s own OK line, which is what a
   person actually reads after a run. `tests/test-seams.sh` now takes the count
   from `check.sh`'s rule comments and holds the rest to it, so this is checked
   rather than remembered - and the OK line is held clause by clause, from a
   list with one entry per rule. **Declare the new rule's clause there**, even
   if the clause is "say nothing": that is the step that asks what the line
   should tell a reader, and a rule missing from the list fails by number.
4. **Negative-test it, then delete the rule and watch every one of those tests
   fail.** A rule that cannot fail reports everything clean; rule 12 shipped
   that way once, printing its error from a subshell and returning 0.

**The general rule behind all five:** when a mechanism spans files, the question
is *who writes this, on this route, and where does it actually land* - and the
answer is only trustworthy if you ran it. Every defect in this file was found by
comparing what a command produced against what was claimed.

## What is still unproven

Being honest about this is part of the design, not a caveat on it.

- **All 27 skills have now been run against real code**, three of them only
  partly - `host`, `deploy` and `orchestrate`, where the untested half needs a
  managed account or two sessions at once rather than more work here. **`layout` ran for the first time on 2026-09-08** against a
  Next.js project taken from `ideate` to `context`, and the whole reordered
  plan phase ran with it. **The pattern on first contact is roughly three real defects per
  skill**, and none of them were visible to any structural check: the last three
  skills to be run for the first time produced thirteen defects between them in
  a single day. What is left is not a list of skills but a list of resources - a
  device, an account, a delivery channel, two sessions at once.
- The gates are prose. `check.sh` verifies a gate **exists in the file**. Nothing
  verifies it **fired**. Only a real run can. `tests/run.sh` covers the pack's
  mechanics - the linter, the scripts, the cross-file invariants - and cannot
  cover whether a skill behaves well when an agent follows it.
- **`host`, `deploy`, `monitor` and `migrate` have touched a live service**, but
  only the self-managed shape. Managed platform, container, static host and
  serverless are written from knowledge rather than use.
- **A contract lives in `contracts/` and `integrate` has caught real drift**
  across it. `orchestrate`'s deadlock detection, freeze gate and review cap have
  fired against constructed board state, but never with two live sessions
  racing - which is the case they exist for.
