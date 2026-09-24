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

## D13 - The contract block's fields are declared, and rule 17 binds them (2026-09-23)

`template/product/AGENTS.md` carries the contract between the parts as five
fields, under a paragraph that says **"These are read, not decorative."** They
were not. `Kind:` appeared **exactly once in the whole pack** - in that block -
written by no skill and read by none, while `ci` branched on "if a contract is
generated between them" in prose. It was fixed in `seams-E` as a one-off.

**This is rule 9's class in a file rule 9 does not read**, so it was left open
as item 2 under *Still open* rather than patched again. Closed here by the move
this repo keeps making: **declare the fields, and let the rule follow.** A
`| Field | Written by | Read by |` table now sits beside the block, and rule 17
reads it.

**Writing the rule found two more orphans**, which is the whole argument for it:
`Regenerate:` had readers that only ever said "the regeneration command", and
**`Generate clients:` was referenced nowhere in the pack at all** - a command
the block promises `ci` will run, that no skill had ever been told to run. Nine
bindings were missing in total, across `architect`, `ci` and `integrate`.

**The binding must be the literal `Field:`, not a paraphrase.** That is the
strict part, and it is strict because the paraphrase is exactly what hid the
original defect: every sentence around `Kind:` described the right work, and
nothing was bound to the field. A rule satisfied by "if a contract is generated"
would have passed the bug it exists to catch.

**Rejected: inferring the fields from the block alone**, with no table. It would
have caught `Generate clients:` having no reader only by guessing which skills
ought to read it. The table is a claim someone has to write down, and writing it
is the moment the question gets asked - the same reason `decision_skills` is a
list rather than a heuristic.

**The rule count now lives in five files.** Adding this rule meant editing
`AGENTS.md`, `README.md`, `docs/anatomy.md`, `dev-notes/status.md` and
`check.sh`'s own OK line, and nothing checked that they agreed. `test-seams.sh`
now takes the count from `check.sh`'s rule comments - asserting they run 1..n
with no gaps, so a deleted rule cannot leave the maximum unchanged - and holds
the four prose files to it.

**The OK line needed a list, not a count.** It first held only by a grep for
this rule's own phrase, which could not see a recurrence: cutting rule 12's
clause out of the OK line left the whole suite green. A count would not work
either - four rules say nothing there, so the clauses have never numbered the
same as the rules. So `test-seams.sh` declares one clause per rule number,
including the four declared silent, and reports the numbers whose clause has
gone missing. Same move as `decision_skills` and the contract table: the list
is the rule, and a rule 18 absent from it fails by number.

## D14 - The always-loaded context has a budget, and the pack states it (2026-09-23)

Every file `CLAUDE.md` imports is paid for by every session before the user
types a word, and those files grow by accretion: closed findings, Done lines,
an overview restating other files, and the pack's own `fundamentals.md`, which
is the same in every project. Nothing in the pack had ever said how much was
too much, so nothing could notice.

**The budget is 48 KB, declared in `template/AGENTS.md`**, and it is held in two
places: rule 18 keeps the template's own imports under half of it, and
`progress` reports a project over it with the three largest files named. Half,
because the other half is what the project's overview, standards and open
items grow into; the seed sits just under it, so the next thing added to the
loaded set has to be argued for.

- **`fundamentals.md` is no longer imported.** Only `spec`, `build` and
  `review` act on it, so they read it. `install.sh` reports an older
  `CLAUDE.md` still importing it.
- **Closed needs-you lines leave the loaded file.** `ship` - already the skill
  that archives - moves Done lines to `blueprint/history/needs-you-done.md`.
  Deleting them was rejected: when something was settled is worth keeping.
- **The overview is capped at 8 KB**, and `context` links to each record
  instead of restating it.

**Rejected: a byte cap enforced by the project's own tooling.** The pack ships
no runtime into projects; `progress` is the thing run constantly, so it is
where the number is read.

## D15 - The findings ledger is an index, and findings have an end state (2026-09-23)

The ledger loaded every finding's full prose every session. Nothing ever
removed an unresolved P3, and a repaired one waited as `fixed` for a `review`
pass that had nothing left to learn from it - so the ledger only grew.

**Split, not trimmed.** `blueprint/context/findings.md` is now the index: one
`### F-03 [P0] open - <title>` heading and a `File:` line per live finding.
The entry - found, why it matters, suggested fix, resolution - is
`blueprint/findings/F-03.md`, read by whoever acts on it. **Status lives only in
the index**, so the two cannot disagree; the invariant "a session never misses
an open blocker" holds, because every open P0 and P1 heading is still loaded.
The heading is the same machine-readable line it always was.

**An end state, in three parts:**

- **`build` may close a P2 or P3 it repaired** - only when the repair's test
  was written from the finding's reproduction and seen failing with the repair
  reverted. `build` already required that run; it was evidence nobody could
  act on. P0 and P1 still wait for `review`: the relaxation is fenced by
  severity, where a wrong close costs least.
- **`ship` moves every unresolved P3 to `blueprint/findings/backlog.md`**, which
  is not loaded, and names each one. `review` still closes them there.
- **`spec` offers a tidy item at five or more**, and `progress` and `preflight`
  count them - a backlog nothing brings back would be deletion by another name.

**Rejected: expiring P3s by age.** It needs a counter nothing maintains; moving
them at every `ship` needs none, and a P3 is by definition a follow-up.
**Rejected: one detail file for all entries.** Archiving would mean cutting
blocks out of a shared file; one file per ID is a delete.

## D16 - One copy of the skills in a project, linked for Claude Code (2026-09-23)

A project held two identical skill trees, `.claude/skills` and
`.agents/skills`. Nothing loads both, so it cost no context, but every
repo-wide search hit each passage twice, and a hand edit to one copy made the
tools quietly disagree.

**Checked, not assumed:** Claude Code 2.1.280 in a project holding only
`.agents/skills` listed none of its skills; with `.claude/skills` a directory
symlink to `../.agents/skills`, it listed the skill and ran it by `/name`. So
`install.sh` writes one copy to `.agents/skills` and links `.claude/skills` to
it - one link, which git stores as a link.

- **Where a symlink does not work** - Windows without symlink support, where
  `ln -s` copies or git checks a link out as a plain file - it copies, and the
  report says so. A plain file where the link should be is repaired.
- **An old two-copy install is converted only when nothing is lost**: a skill
  only `.claude/skills` has moves into `.agents/skills`; one that differs
  between the two keeps the old shape, named in the report. A framework's
  generated skill, with its `references/`, survives the conversion.
- **`AGENTS.md` tells a tool with no skill support where each `SKILL.md` is.**
  Instruction, not integration - no `/name`, no description matching - but it
  costs one line.

**Rejected: relying on `.agents/skills` alone** - Claude Code does not read it.
**Rejected: gitignoring the second copy** - a fresh clone would have no skills
until someone knew to run `install.sh`.

## D17 - prototype starts from a design kit, not a blank page (2026-09-23)

`prototype` wrote a theme from nothing, asked about "feel" without recommending
anything, and called anything beyond two or three mockups a design system it
should not build. So each project's agent invented its own tokens and
components, partially, and the parts nobody thought of - navigation on a
phone, an empty state, a focus ring, the password-reset journey - were the parts
that shipped missing or were invented per feature.

**The pack now ships `blueprint/design-kit/`**, pack-owned and refreshed on
install:

- **`tokens.json`** (W3C Design Tokens format) and **`tokens.css`**, one set:
  a neutral slate scale and one brand hue, colour roles for light and dark,
  type, spacing, radii, shadows, motion, sizes, breakpoints and layers.
  Components use only the `--color-*` roles, so a re-theme is one file.
- **`components.css`** and **`components.html`** - every core component in
  every state: navigation (top bar, sidebar, mobile menu, breadcrumbs, tabs,
  pagination, menus), buttons, links, forms, alerts, toasts, badges, loading,
  empty and error states, dialogs, tables, lists and cards.
- **`ux-checklist.md`** - navigation by product type, the screens every product
  needs, the journeys to walk end to end, the WCAG 2.2 AA floor, breakpoints.

**`prototype` now classifies the product, recommends two or three directions as
token changes with reasons, maps the navigation and the screens, copies the kit
and changes values - never names - and records the navigation map, screens and
journeys in `design.md`.** `spec` turns each journey an item passes through into
a done-when; `review` reports a literal where a token belongs.

**Held by tests, not by the prose:** the two token files agree in every mode,
every `var()` is defined, the components hold no colour literal, and every
colour pair a component draws meets WCAG AA in both modes. Writing those found
three defects before anything shipped: a dark block missing a role, so every
hover fell back to its light value; line-height tokens used under the wrong
name; and a light input border at 2.56:1.

**Default look: neutral and brand-swappable**, chosen over a Material-like
baseline (heavier on the web) and over names without values (today's blank
page by another route).

**Rejected: a generator from `tokens.json` to CSS.** It would be a script in
every project; the test holds the two files in step in the pack, and a project
changes `theme.css`, not the JSON.

## D18 - Design is required wherever there is a UI (2026-09-25)

`prototype` was optional: `architect` called skipping it "a legitimate choice",
and `context` named it only when the first item was a screen with no visual
reference. So a project with a UI could reach `spec` with no `design.md`, and
then every item answered the same questions itself - the empty state, the error
message, the navigation on a phone - and the first screen built became the look
by accident. D17 gave `prototype` a kit worth starting from; leaving it
skippable meant the kit reached only the projects that asked for it.

**`spec` now stops on a project with a UI and no
`blueprint/context/design.md`**, and names `prototype`. A UI is the plan's
platform rendering: a web app, a content website, a PWA or a mobile app.

**Three things pass, on purpose:** a CLI, a library or an API with no UI, since
there is nothing to design; a **fix**, which repairs what exists and must not
wait on design work - it notes the missing record instead; and `--preview`,
which writes nothing.

**An app that already has a look is recorded, not redesigned.** Without that, a
project adopted through `setup` had no route past the gate: `prototype` stopped
on a shipped look, and `spec` stopped without the record. `prototype` now reads
the look from the code, names each value against the kit's token for the same
role, measures the contrast actually drawn, and marks a required screen the app
lacks as missing rather than not applicable.

**Rejected: required for every project.** A CLI has no screens, and a gate that
asks for a design record it cannot have is a gate people learn to walk past.
**Rejected: an advisory note in `spec`.** That is what "optional, decide
deliberately" already was.
