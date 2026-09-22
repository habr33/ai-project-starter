# Decisions

Why this repo is shaped the way it is. Read this before changing its shape.

Entries are numbered permanently. A superseded decision is marked, never deleted.

## D1 - A new repo, not a rewrite of the pack this replaces (2026-08-31)

This grew out of an earlier private pack that worked and was well tested. It
covered idea through merged code, with a generator, a linter, and a
hash-manifest installer behind it.

Reviewing it turned up three things: the cold start was circular (`stack` told
you what to scaffold but was unreachable until after you had scaffolded), the
lifecycle stopped at merge, and the machinery had outgrown the job.

**Chose: a new repo, leaving that one untouched as reference.** The content here
is written fresh; the workflow design is carried over because it is good.

## D2 - Plain-name cross-references, so no generator is needed (2026-08-31)

The old pack templated `{{skill:build}}` into `/build`, `$build`, or `` `build` ``
per tool, needing a renderer, a partial system, a path registry, and a linter to
keep the adapters honest.

**Chose: write cross-references as plain names.** `` `build` `` reads correctly in
Claude Code, Codex, Cursor, and on paper. One `skills/` directory, fanned out to
both adapter trees by `cp`, so there is only ever one copy to edit.

**Cost:** no per-tool phrasing at all. Acceptable - the old pack's own adapters
were byte-identical anyway, and its tool-specific references caused a real bug
(stale `/status` after a rename, wrong for every tool but one, caught by nobody).

## D3 - The command creates the directory (2026-08-31)

The cold-start problem had two possible fixes: install skills globally into
`~/.claude/skills/` so they exist everywhere, or have the setup command create
the project directory itself.

**Chose: create the directory.** Project-based, nothing leaks into unrelated
projects, and there is never a moment with a tool open in an empty folder.

**Consequence:** the framework scaffolder can no longer run normally, since the
directory is not empty by the time a stack is chosen. `scaffold` handles that by
building into a temporary directory and moving the result in.

## D4 - No source directory is created up front (2026-08-31)

`create-next-app` makes `src/app/`, Flutter makes `lib/`, Expo makes `app/`.

**Chose: create none.** `scaffold` creates the source layout later, using the
framework's own convention, and records where it actually is in `AGENTS.md`. An
empty `src/` that Flutter ignores is clutter, and insisting on one means fighting
every framework's tooling and documentation.

## D5 - A thin update story (2026-08-31)

The old pack had a sha256 manifest, conflict detection, timestamped backups, and
atomic writes.

**Chose: `install.sh --force` re-copies skills; owned files are never touched.**
No manifest, no conflict detection, no backups.

**Cost:** a locally edited skill is overwritten by `--force` without warning. The
project is a git repo; that is what shows you the change. Revisit if this ever
actually costs someone work.

## D6 - autopilot is included, but gated (2026-08-31)

It was nearly dropped as too risky for a starter, especially with `deploy`,
`host`, and `migrate` now in scope.

**Chose: keep it, gated on complete information.** A hard preflight checklist,
and any miss stops the run before it begins. Its scope is the build loop only,
and its never-do list names every outward-facing skill explicitly.

## D7 - Standards are opt-in per project (2026-08-31)

The old pack's coding standards were OWASP-flavoured without naming OWASP, so
there was no external bar to check against - only judgment, restated.

**Chose: `setup` asks which standards apply and records them; `review` audits
against exactly what is recorded and names the source on each finding.** A
personal tool and a payment system need different bars, and imposing the stricter
one produces noise that trains people to ignore findings. Recording none is a
legitimate answer.

## D8 - Architecture before technology, and layout after both (2026-09-08)

The loop ran `ideate -> stack -> architect -> scaffold` for its whole life. The
justification was real: `architect`'s first decision was code layout, and a
layout turns on the language - React + Express shares a workspace, React +
ASP.NET shares nothing. So `stack` had to come first.

**That justification was about the wrong decision.** Code layout is a framework
convention, not architecture. The architectural questions - how many things
deploy, is there work outside a request, must data be consistent across more than
one write, whose failure is unacceptable - are the ones a technology should be
chosen *against*, and asking them second meant asking them once the answer was a
rewrite rather than a choice. Every real project built with this pack got a
single-file database because the stack question came first and nothing had yet
asked whether that was safe.

**Chose: split the two decisions and put them either side of `stack`.**
`architect` runs second and asks six shape questions and writes the quality bar
as numbers, before any technology exists to bias them. `stack` runs third and
reads both as inputs, saying which line of the bar each choice answers and
stopping if nothing in reach meets it. **`layout` is a new skill, the 27th**, and
runs fourth: it decides directory names in the framework's own terms, which is
knowable only once the framework is known and expensive once `scaffold` has
installed into it.

The rejected alternative was folding layout into `scaffold`. It fails on
approval: `scaffold` runs a long list of install commands, and a layout decided
inside it is one nobody was asked about before a lockfile existed.

This moved nine documented claims that were individually true and collectively a
loop that no longer exists. `tests/test-seams.sh` now asserts no file attributes
the directory layout to `architect`, and pins the handoff pairs to the new order.

## D9 - The board's status files are working state; its contract line is committed (2026-09-15)

From a git worktree the board resolves under the main checkout, so worktree
sessions edited tracked `blueprint/status/` files there that nothing committed.
**Committing them was the wrong fix, found by reading what the skills do with
git**: `ship` clears its packet *after* its one commit, so the main checkout was
dirty after every ship; `ship` stages everything, so the next part's commit swept
in another part's state; and `autopilot` refuses on unrelated uncommitted changes,
which another part's status write is. Having each writer commit instead puts
several sessions on the main checkout's index at once - the race worktrees exist
to remove.

**Chose: gitignore `blueprint/status/`; keep `orchestration.md` tracked.** The
contract line is a decision, and `orchestrate` commits it on its own, naming the
one file. A fresh clone has no status files, and a missing one reads as `idle`.
`lib/seed-product-root.sh` writes the ignore line for both creation routes;
`install.sh` prints the commands that untrack an older product and runs none of
them, because the index is the user's.

**The files are ignored, not the directory.** The first version ignored
`/blueprint/status/`, and running `spec` in a fresh clone of a real two-part
product failed on its first claim - the directory did not exist. A tracked
`.gitkeep` keeps it; no test here had cloned the product.

The resolution was also fixed for the shapes it assumed away, each run before
changing it: in a submodule the shared git directory's parent is
`.git/modules/`, so it now follows `core.worktree`; a worktree of a bare
repository has no main checkout, and the command now stops instead of choosing
one whose removal would take the board with it.

## D10 - Every skill declares what it writes (2026-09-15)

Rule 12 checked that a declared writer *mentioned* its file, which every reader
does - a reader listed as a writer passed, and a writer the table left out was
never looked for. A write-verb heuristic was tried and was wrong in both
directions.

**Chose: a `**Writes:**` line under every skill's heading**, with `nothing` as a
valid answer, checked against `template/AGENTS.md`'s table in both directions. The
rejected alternative was a readers column in that table: it would force the
question per file, far from the steps that do the writing, and it grows a
user-facing file every project loads. A declaration beside the instructions is
the one someone editing those instructions sees.

Writing the lines down was itself the audit: seven skills wrote state files the
table did not credit - `rollback`, `build`, `architect`, `ideate`, `host`,
`migrate`, `ci` between them - and `docs/anatomy.md` called `verify` read-only
while it raises findings. `orchestration.md` and `status/` now have rows, which
retired rule 12's `state_declared_elsewhere` list.

## D11 - Principles are their own file, and only `ideate` writes them (2026-09-22)

A review against public prior art (GitHub's spec-kit) named a gap: nothing here
holds project-level, non-negotiable commitments - "no ads, ever", "nothing
leaves this machine" - the way spec-kit's constitution does. The closest
existing file, `blueprint/context/quality-bar.md`, is a numeric bar `architect`
writes and `preflight` checks the running project against.

**Considered folding this into `quality-bar.md`** - one more section, no new
file, no new row anywhere. Rejected: that file answers *what number does this
project hit*, and a commitment is not a number - "no ads" is not a performance
target that can be missed by degree, it either holds or it does not. Merging
the two would make `architect` (who writes the bar) also the owner of
commitments that are properly `ideate`'s, since they are decided at the same
time as the problem and the users, not at the same time as the structure.

**Chose: a third file, `blueprint/context/principles.md`, written once by
`ideate`** in the same step as the two plans, following the same
already-exists discipline. Read by `architect` (a structure must not quietly
design around one), `review` (a violation is a finding), and `preflight` (a
blocker, at the same standing as a missed quality-bar line).

**Asymmetric with `quality-bar.md` on one point, deliberately**: `setup`
discovers a quality bar for an existing project by measuring what is already
true. It does not write a principles file, and says so - a commitment cannot be
read off the code, because the absence of ads today is not the same claim as a
promise never to add them. An existing project's principles are unrecorded
until someone states them through `ideate --rescope`, and that gap is reported,
not filled in on its behalf. **That makes the rescope path the only door**, so
its "leave `principles.md` alone" rule is scoped to a file that already exists;
stated unqualified, it closed the door `setup` sends people to.

## D12 - The routing eval ranks descriptions, and a small gap is a tie (2026-09-21)

`tests/test-routing.sh` is the only thing here that reads the 27 `description:`
lines as a set - the linter checks one at a time, so a skill whose description
omits the words people actually type stays lintable and unreachable. That is
what it found on `monitor`, which lost "the site is down and i need to know
why" to `prepare` by 0.0332.

**All 27 descriptions share one IDF table, so editing any one reweights every
other skill.** Adding *down* to `monitor` diluted the only term separating
`spec` from `progress`, and `spec` fell from first to second on a margin of
**0.0003**.

**Considered gating top-1 strictly** - every skill must win its own prompt,
full stop. Rejected: on those numbers it gates on noise, and every future
description edit would break an unrelated skill. **Chose a `tie_margin`, and
measured it rather than picking it**: 0.0003 for the `spec` noise against
0.0332 for the real `monitor` miss is a factor of 100, so the line sits at
0.02. Checked by raising it to 0.05 and watching the unfixed `monitor` pass as
a tie - the defect class really does go invisible above ~0.03.

**It ranks with TF-IDF, which is not an agent.** A result there is evidence
about a description's vocabulary, never about how an agent would route. A skill
may be excused by name on `known_misses` with a reason; only `stack` is, because
"build this with" is lexically owned by `build`. Prompts that paraphrase their
own description prove only that a sentence matches itself, so the file rejects
any prompt repeating five consecutive words of it.
