# Coverage - what has actually been run

**Which skills have been exercised against real code, on what, and what is still
unproven.** The chronological record of those runs is a local working diary and
is not published, so answering "has `rollback` ever run?" from it meant reading
thousands of lines and reconstructing the answer.

That reconstruction was got wrong three times in one file: the open items said
**13 skills unrun** in one bullet and **23** in another while the header said
**every skill has run**, and a later pass listed `autopilot` as never run when it
had been. This table exists so the question has one answer.

**Update it in the same change as the run**, not afterwards. A coverage table
that lags is worse than none, because it is believed.

Legend: **yes** - run against real code and the result checked · **partial** -
run, but a named part of it never exercised · **no** - never run in a real
conversation.

## The projects

Real projects, named here by what they are rather than what they are called.

| | what it is | what it was for |
|---|---|---|
| cli | TypeScript CLI, 4 items, 35 tests | the whole plan-and-build loop, `ci`, `debug`, `host` stopping |
| static-site | vanilla HTML/CSS/JS, one screen | `prototype`, and the first real `host` + `deploy` - live on a VPS |
| static-app | vanilla web, 4 items, 21 tests | full loop to production; replaced static-site at the same domain |
| library | TypeScript library | `stack`'s library branch and `scaffold` with no scaffolder |
| two-part-api | TS API + PostgreSQL, static web client, **two parts** | `architect`'s two-part path, `migrate`, `integrate`, `contracts/` |
| brownfield-nextjs | an existing Next.js + Prisma project, not built here | `preflight` against something it should fail |
| django-phone | Django 5.2 + SQLite, phone-first web app | **the first non-JavaScript project** - `architect`, `scaffold` and `setup` against a Python ecosystem |
| react-dotnet | React 19 + **ASP.NET Core 10** on SQLite, **two parts**, contract by OpenAPI codegen | **the two-ecosystem path** — `architect`'s React+ASP.NET branch, `convert-to-parts.sh` on a planned project, `integrate`'s contract check across two languages |
| throwaways | Vite, Expo, Flutter, one autopilot run | `scaffold` per stack; `autopilot stack..review` |
| django-loop | Django 6.1 + SQLite web app, skill-mastery tracker | **the whole loop on the current pack** - `ideate` through `ship`, item 1 merged, CI green. The first end-to-end run since the day's fixes |
| three-part-scratch | 3-part scratch product (web, api, worker) | **the coordination mechanisms** - deadlock, freeze gate, review cap; found the board naming parts that do not exist |
| two-part-autopilot | a real two-part product | **a full unattended `autopilot` run** across parts |
| expo-workspace | an existing npm workspace - two Expo apps, a Next.js web app, an Express API and a shared library; the code came before the workflow | **the brownfield route on a multi-part repository** - `install.sh` and `setup`, adopted as a single-part install at the root; later `progress` |
| nextjs-app | Next.js 16 + PostgreSQL 18 + Drizzle, recipe and meal planning | **the reordered loop end to end in one project** - `ideate` to a merged, reviewed, documented item |
| cms-rr | React Router 8 + PostgreSQL CMS on a shared self-managed VPS, login item | **the whole loop with a user who knew nothing of the argument** - `ideate` to a shipped login feature, `autopilot`, and an independent review that found a P1 the run's own review missed. **Then `host`, `deploy` and `monitor` on a shared VPS**: the first deploy's own verification found a P0 no test could see, and a restore drill took production down |
| abandon-run | a scratch ES-module project, one item part-built on a branch | **`ship --abandon` and `spec`'s resume, end to end** - the park-and-resume round trip, with a four-entry ledger and a half-built step in a new file |
| layout-move | a seeded two-part product, moved before any code existed | **`layout`'s documented move of a seeded part** - the four steps, and `seed-part.sh`'s refusal |
| paperlog | an existing Express + SQLite JSON API, no workflow in it | **`setup`'s adoption route** - filling plan sections 5 and 6 from the code, then `context`'s check against the result |

## Plan

| skill | run | where | what it proved, or found |
|---|---|---|---|
| `ideate` | yes | cli, static-app, django-loop, nextjs-app, cms-rr | **2026-09-07: interviewed a real user for the first time.** The owner's answers changed the project twice - a CLI became a web app when sync surfaced, and "track or help?" was a fork I could not resolve for them. **Step 2's scope-cutting earned its keep**; the `--rescope` mode is still unexercised. **2026-09-08 on nextjs-app:** the scope cut earned its keep again - the owner picked every option and four were moved out, two with reasons that stuck **2026-09-16 on cms-rr:** a real user named the technology up front; recorded as constraints, not chosen here. Cut scope out loud and left hosted-versus-one-site open as a question |
| `architect` | yes | cli, two-part-api, react-dotnet, django-loop, nextjs-app, cms-rr | Two-part decision for a real reason. **react-dotnet: its layout options were JS-shaped** — "flat" breaks .NET. **That finding split `layout` out and moved this skill ahead of `stack`** (D8). **First run in the new order 2026-09-08 on nextjs-app**: the six questions produced three yeses that were all the same dependency, which is the result that stops a queue being invented. Two defects — the third question's stated consequence was **factually wrong** (transactions, not storage engines), and nothing said what heading level Step 3's output uses, so it broke the plan's numbered structure **2026-09-16 on cms-rr:** settled one site per installation. **Its own example, "measured server-side", was copied into the bar** - the phrase the reorder's headline result rested on. Now asks the user where performance is measured **2026-09-22: the contract block's fields checked against their writers.** `Kind:` appeared **exactly once in the pack** - in `template/product/AGENTS.md` - written by no skill and read by none, in a block whose own text says "These are read, not decorative". It is also the field `ci` branches on ("if a contract is generated between them"). architect now sets it; `ci` reads it instead of inferring |
| `stack` | yes | cli, library, react-dotnet, django-loop, nextjs-app, cms-rr | **Had no CLI option**; now 7 platforms. **react-dotnet: it never checks a version against the installed runtime**. **First run in the new order 2026-09-08**: the bar-check worked as designed and **eliminated a client-rendered SPA on a requirement rather than on taste** — an SPA has no server-side page render, so the 400ms line is meaningless against it. Two defects — Step 1 still interviewed for the bar `architect` had already written, and **nothing reconciled the data model against a library that owns part of it** (Better Auth vs a hand-written `User`), a seam the reorder itself created **2026-09-16 on cms-rr:** checked the VPS over SSH and pinned exact versions, but **ruled a framework out on size and memory without naming a bar line** - now required at the gate and in each decision entry. It also wrote decisions.md undeclared; now declared |
| `layout` | yes | nextjs-app, cms-rr | **First run 2026-09-08.** Step 3's trap check earned the skill: `node --test` does not resolve tsconfig path aliases, so colocating tests beside their subject was **forced, not preferred** - a separate `tests/` tree would have made every import `../../src/...`. Also found that node executes every file inside any directory named `test`. **Half-verified its own decision**: it checked the test runner and not the typechecker, and `scaffold` then hit `allowImportingTsExtensions` **2026-09-16 on cms-rr:** probed the tree in a Node 26 container. **A hosting question mid-skill became destructive work on a shared server** with no skill in charge - server changes now route to `host` **2026-09-22 on layout-move: the move of a seeded part ran for the first time.** `seed-part.sh`'s refusal fired as documented, and `Product root:` came back `../..` - correct for two levels down. But the move **silently replaces the part's description with the template placeholder**: step 2 deletes the listing line and step 3 re-seeds it, so a line reading "the reader-facing site: article pages, search, and the home feed" came back as `<what this part is>`, with nothing reporting it. Now kept in step 1 and written back in step 4 |
| `scaffold` | yes | Vite, Expo, cli, library, django-loop, nextjs-app, cms-rr | 4 gaps: engine check, exit codes lie, agent files, no-scaffolder path. **2026-09-08 on nextjs-app:** caught `--agents-md` defaulting on in create-next-app, which would have overwritten the workflow's own entry point. Its `preflight` findings later became the production-shaping fixes to this skill **2026-09-16 on cms-rr:** proved every check could fail by planting errors. **Committed the plans unprompted** (now its instruction), and wrote "accessibility: not recorded" before `prototype` existed (now points at design.md) |
| `ci` | yes | cli, brownfield-nextjs, django-loop, nextjs-app, cms-rr | **Pipeline executed on a real runner and passed** (2026-09-06, 1m12s). **2026-09-08 on nextjs-app:** the verify command passed locally and **failed on a clean checkout** - gitignored route types - which is now a rule here **2026-09-16 on cms-rr:** proved from a clean clone; first real run green in 23s. **Wrote a GitHub workflow with no remote without asking the host** (now a stop), and left the browser tests out silently (now reported) **2026-09-22:** now reads `Kind:` from the product root's AGENTS.md to decide whether there is a regeneration to check, instead of leaving "if a contract is generated" to inference |
| `context` | yes | cli, static-app, django-loop, nextjs-app, cms-rr | -. **2026-09-08 on nextjs-app:** found three plan contradictions, including a hand-written `User` table the chosen auth library owns **2026-09-16 on cms-rr:** **reported "no contradictions" on a plan stale against the repository, then wrote the corrections into the overview before the plan** - both fixed |
| `prototype` | yes | static-site, cms-rr | **5 of 10 contrast values were wrong** until measured **2026-09-16 on cms-rr:** rendered and screenshotted every mockup, measured contrast. **Wrote design.md before the user saw the mockups** (steps swapped), and its HTML failed the project's lint (now excluded) |

## Build

| skill | run | where | what it proved, or found |
|---|---|---|---|
| `spec` | yes | cli, static-site, static-app, django-loop, nextjs-app, cms-rr | Planned items and the ad-hoc fix mode. **2026-09-08 on nextjs-app:** Step 4's red-team found a broken step order that would have redirected to a route built one step later. **`--preview` still never run** **2026-09-16 on cms-rr:** red-teamed its own step order. **Its decisions - UUID ids, logout-all, a cookie path - had no home that survived `ship`** (now a Decisions section) **2026-09-22 on abandon-run: the resume from an abandoned archive ran for the first time.** Its written order - restore the spec, then check out the branch - **makes git refuse the checkout**, because the branch carries its own committed `current-work.md`. The branch already holds the spec and the ledger, so there is nothing to copy; now checkout first, and strip the abandon record when restoring from the archive instead. **`--preview` still never run** |
| `build` | yes | all, django-loop, nextjs-app, cms-rr | Done-when check and the two-failure stop both fired. **2026-09-08 on nextjs-app:** five steps, each proven at its own done-when. Surfaced that per-step approval is oversold - it earns its keep on step 1 and is ceremony by step 3 **2026-09-16 on cms-rr:** every new test seen failing under a mutation. **A step built but awaiting approval existed only in the conversation** (now a marker in current-work) |
| `verify` | yes | all, django-loop, nextjs-app, cms-rr | `--manual` run once on static-site. **Never run on a simulator or device.** 2026-09-08 on nextjs-app: 5/5 done-whens, the quality-bar number **measured rather than asserted**. **`--all` still never run**, and reviewing it found it would read the archive directory's own README as an archive **2026-09-16 on cms-rr:** every done-when re-run on the final code, including a p95 against the bar and JavaScript-off login |
| `review` | yes | all, django-loop, nextjs-app, cms-rr | Found defects the spec red-team missed, twice. **2026-09-08 on nextjs-app:** nine findings, none blocking. Measured a 20,000-row write on an unauthenticated endpoint rather than asserting it **2026-09-16 on cms-rr:** the in-run review found a P1 (memory exhaustion from a huge login body). **An independent review in a fresh session then found a P1 the self-review missed** - rate limits bypassed by 100 concurrent requests - confirming `autopilot.md`'s warning on real code **2026-09-17 on cms-rr:** the item's core new file held raw NUL/DEL bytes in a regex, so git called it binary - `git diff` and the pull request showed "Binary files differ" and **the item's main change reached a reviewer as nothing at all**. Step 1 now checks the changed set for it |
| `ship` | yes | cli, static-site, static-app, django-loop, nextjs-app, cms-rr | Feature and fix archives; open P2/P3 carried across merges. **Push never run**. **2026-09-08 on nextjs-app:** its safety pass caught pack skill files committed onto a feature branch - a squash-merge would have folded a pack update into the item and regressed two skills **2026-09-16 on cms-rr:** archived 11 findings and carried two. **Merged locally, so CI never saw the item** (now offers the PR route), and **the item's decisions never reached decisions.md** (now written at ship) **2026-09-22 on abandon-run: `--abandon` ran for the first time.** Three defects, each seen happening: the `wip:` commit that exists so parking does not lose work **left an untracked new file behind while reporting `1 file changed`**; Step 3 archived the findings **from `main`, where the ledger is the stub**, because only the spec's read was branch-qualified - a P1 stayed on the parked branch and "remove them from the ledger" was a no-op that read as success; and archived IDs **were not prefixed** as the merge path prefixes them, so the next item's first finding is `F-01` again and the abandon reason cites an `F-01` that now means two things |
| `debug` | yes | cli | Routed to correctly after two failures. **I wrote the bug, so it could not surprise me** |

## Operate

| skill | run | where | what it proved, or found |
|---|---|---|---|
| `preflight` | yes | brownfield-nextjs, static-app, nextjs-app, cms-rr | Returned **no-go** as predicted; found 3 gaps in itself. **2026-09-08 on nextjs-app:** correct NO-GO. Found three things that were cheap at `scaffold` and retrofits by then, which became the `scaffold` fixes **2026-09-16 on cms-rr:** first-release audit on a live server: seven findings, no-go, two P1. **A P1 the user deferred to `monitor` had no status saying so** - `accepted` ("not fixing") was the only way past `ship`, and the finding was archived before `monitor` repaired it. `deferred` now exists. |
| `host` | partial | cli (stopped), static-site VPS, **django-loop**, cms-rr | **Only the self-managed shape.** Managed, container, static-host and serverless rows are written from knowledge **2026-09-16 on cms-rr:** a **shared** VPS with another site on it, Caddy by `import` rather than owning the Caddyfile, PostgreSQL installed from scratch on 954 MB, systemd, no Docker. Setup script idempotent across two runs; a missing `libatomic1` broke Node and was caught by the script checking `node --version`. **A restore drill killed production** for a minute with `pkill -f` - now a rule. |
| `deploy` | partial | static-site, static-app, **django-loop**, cms-rr | Self-managed only. Rollback tested both directions (~700ms) **2026-09-16 on cms-rr:** first real deploy of a Node app to a self-managed server, built from a clean clone, migrations routed to `migrate`. **Its own verification found a P0 the whole loop had missed**: behind a TLS-terminating proxy the framework compared its `http://` origin with the browser's `https://` and rejected every form post. Health check, pages and redirects all passed. `preflight` now checks the proxy seam. Rollback drilled: 5 s back, 3 s forward, proven by the old bug reappearing. |
| `monitor` | yes | static-site, local rig, cms-rr | 3 checks on a timer. **2026-09-07: delivery closed** - a webhook channel stood up, service killed, and the alert message proven to arrive and be recorded. Detection-without-delivery is no longer the gap **2026-09-16 on cms-rr:** UptimeRobot on a `/healthz` that queries the database, keyword alerting, certificate expiry, backup heartbeat plumbed but deliberately unset. **Alert delivery proven by accident** - a monitor aimed at the wrong hostname sent a real down email. |
| `migrate` | yes | two-part-api, cms-rr | Against real rows; the naive `ADD COLUMN NOT NULL` failed exactly as written **2026-09-16 on cms-rr:** applied the first migration to production from `deploy`, after a fresh backup, as the service user; re-ran it to prove it was a no-op. |
| `docs` | yes | static-app, nextjs-app, cms-rr | Wrote the changelog from the archive. **2026-09-08 on nextjs-app:** replaced a template README that `preflight` blocked on, and caught two decisions the code carried with nothing explaining them **2026-09-16 on cms-rr:** rewrote a template README and **ran every command in it**; caught that `verify` excludes the browser tests. |
| `rollback` | yes | brownfield-nextjs | **Ran 2026-09-06.** Five defects, incl. Step 2 stopping where Step 3 must write - its deliverable was unreachable for the case it exists for |

## Multi-part

| skill | run | where | what it proved, or found |
|---|---|---|---|
| `integrate` | yes | two-part-api, react-dotnet | Caught contract drift both parts' own checks passed on — now proven **across two ecosystems**, C# to TypeScript |
| `orchestrate` | partial | two-part-api, three-part-scratch, two-part-autopilot | Contract line on two-part-api. **2026-09-07: deadlock detection, the freeze gate and the review cap all fired for the first time** against constructed board state on three-part-scratch. Step 1's drift check caught status files claiming items no build plan held. **Still unproven with two live sessions**: I wrote the board I then read, so nothing could surprise me |

## Not on the linear path

| skill | run | where | what it proved, or found |
|---|---|---|---|
| `autopilot` | yes | a throwaway, three-part-scratch, two-part-autopilot, nextjs-app, cms-rr | One range on a throwaway; found the empty-diff bug. **2026-09-07: a full unattended `spec..review` over a real two-part product** - preflight enforced, part claimed on the board, branch and 4 checkpoint commits, 7 tests, done-whens re-run by hand, 3 findings with IDs, review packet, board left `waiting`, and the cap then refusing the next run at depth 2. **Found the circular branch precondition** that made its own headline usage unreachable. **2026-09-08 on nextjs-app:** ran `build..review` - a range that was illegal until that run showed `build` had to be a legal start **2026-09-16 on cms-rr:** `build..review` from step 5 on a login feature; **stopped correctly** on a spec-locked cookie path that looped JavaScript logins, found by driving a browser. **Ticked a step awaiting approval silently** (now asks) |
| `setup` | yes | brownfield-nextjs, expo-workspace | **Ran 2026-09-06.** Found `ci` unreachable on the brownfield route, and that template files froze at install time forever. **2026-09-11 on expo-workspace:** a code-first npm workspace adopted single-part. Backfilled coding standards and a quality bar from the code - most bar rows honestly left unmeasured - recorded four contradictions in the existing docs as UNDECIDED rather than resolving them by guess, and opened 14 `needs-you.md` lines, 2 blocking. Its report named `context` then `ci`, because **Step 5 named `ci` as the next skill, Step 7 named only `context`, and the skill's own chain puts `ci` first** - the file disagreed with itself about what comes next. **Fixed 2026-09-15**: Step 7 now names every remaining step in the chain's order, with a seams test proven to fail on the old text **2026-09-22 on paperlog: the adoption route's sections 5 and 6 ran for the first time.** Sections 5 and 6 each carry **a second seeded paragraph** below the obvious one - the note that 5 is filled after 6, and the note that `layout` adds the directory tree. "Replace the seeded instruction *sentence*" leaves both, `context` reads seeded text as unfilled "whatever has been added around it", and it routes to `architect` and `stack` - the two skills this very route says never run. Now: replace every seeded paragraph, naming those two |
| `progress` | yes | brownfield-nextjs, nextjs-app, expo-workspace | **Ran 2026-09-06.** Four defects: template residue, an mtime freshness check a hand edit defeats, an invalid archive count, no finished-plan state. **2026-09-08 on nextjs-app:** caught an overview stale *in content* while its timestamp looked fine, and product code committed to `main` with no spec. **2026-09-14 on expo-workspace:** caught that `context` and `ci` never ran after `setup` - `setup`'s report had named both, and the session's closing summary after a push dropped them. Recovering a handoff a conversation lost is what this skill is for |
| `prepare` | yes | brownfield-nextjs, nextjs-app | **Ran 2026-09-06.** Four defects, incl. reporting "nothing is blocking" when a user-owned file was broken. **2026-09-08 on nextjs-app:** found an empty `BETTER_AUTH_SECRET` that stops the very next item, and a hostname nobody had ever chosen - neither recorded anywhere |

## The honest summary

**All 27 run.** Three only partly - `host`, `deploy`, `orchestrate`. **Every
skill in the plan-and-build loop has run against one project** - nextjs-app,
taken from `ideate` to a merged, reviewed, documented item under the reordered
loop. That is the first time the whole loop has been exercised end to end in one
project rather than assembled from several.

**The reordered plan phase found six defects in one pass** - roughly the usual
rate for first contact, and none of them visible to any structural check. Two are
worth repeating because of where they came from: the third shape question
**stated something untrue** about what its answer settles, and **nothing
reconciled the data model against a library that owns part of it**. The second is
a seam the reorder created: the model is now written before the stack, so a
library chosen later can own tables the plan already described.

**What is left is not a list of skills. It is resources**, and that distinction
is the one `prepare` was built to make: most of these are things only a person
can supply, and no amount of work on the pack closes them. Listed in the order
they would hurt:

1. ~~**CI has never executed anywhere.**~~ **Closed 2026-09-06** - a pipeline
   `ci` generated ran on GitHub Actions and passed in 1m12s. It is the one item
   on this list that was closed by getting a resource: a repository with a
   remote.
2. ~~**Monitoring alerts have no delivery channel.**~~ **Closed 2026-09-07** - a
   webhook channel, a killed service, and one alert message proven to arrive.
   The channel was local, which proves the wiring and not a hosted provider.
3. **Every hosting shape but self-managed.** Managed platform, container, static
   host and serverless are written from knowledge, not use. **Static host was
   set up and then deliberately skipped (2026-09-07)** - the page, a health
   endpoint and a commit-stamping Pages pipeline were built and ready, and the
   run was dropped rather than publish a throwaway public repo to close one
   table row. A decision, not a gap nobody got to. **Container is the same
   shape**: adding the user to the `docker` group is a root-equivalent privilege
   change to test a row that changes nothing shipped.
4. **The multi-part coordination mechanisms.** ~~Never fired.~~ **Fired
   2026-09-07** - deadlock, freeze gate and the cap, plus a measured proof that
   separate status files survive 600 concurrent writes where the rejected shared
   table is truncated to empty. What is still missing is two *agent sessions* at
   once, not two writers.
5. **Mobile.** Nothing has run on a simulator or a device.
6. **The interviews.** `ideate` and `stack` have never faced someone whose
   answers I did not already know.

**The two-ecosystem path is no longer written-from-knowledge.** react-dotnet
(2026-09-06) built React + ASP.NET Core end to end: `convert-to-parts.sh` on a
planned project, a build-time OpenAPI contract, a generated TypeScript client,
one `make verify` across both, and `integrate` catching a C#-to-TypeScript
rename. It found six defects. What it did **not** cover: `orchestrate` with two
sessions at once, and anything rendered — no browser existed on that machine.

**None of this is visible to `check.sh` or `tests/run.sh`.** Both check that the
pack is internally consistent. Whether a skill behaves well when an agent follows
it is answered only by running it against something real.
