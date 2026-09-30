# Living capability specs - implementation plan (2026-10-01)

Implements `capabilities-design.md` (read it first; section numbers below are its).
One branch off `main`, `capabilities`, one commit per task. Every test is seen
failing first; then the fix is broken in a copy and the mutation checked to have
changed what the assertion names. New tests go above `finish` in each test file.
Run `./check.sh` after every task and `./tests/run.sh` once at the end (minutes -
never two at once).

Rule 9 rejects a reference to a script that does not exist, so the script comes
first and the skills name it after.

## Task 1 - `lib/merge-capabilities.sh` (design 3)

Bash + `python3`, like `lib/migrate-findings.sh`; read that for the style.

- Usage: `merge-capabilities.sh <spec-or-archive> <archive-name> [--target DIR]`;
  reads `## Behaviour changes`, writes `blueprint/capabilities/<name>.md`.
- **Parse first, check everything, then write** (rule 16: no refusal after the
  first write; add an `after-write:` comment only if one is unavoidable).
  Refuse, naming the line, with every file byte-identical, on: unknown ID, tombstone
  ID, `Changes` old text not matching current, missing section (distinct from
  `None`), step not ticked.
- Merge: adds take next ID (past tombstones) and `*Since:*`; changes replace text
  and append `*Changed:*`; removes become tombstones under `## Removed`; a new
  capability creates its file.
- Print assigned IDs, one per line.
- `None` merges nothing and exits 0.

**Tests** (`tests/test-scripts.sh`, new block *the capability merge, D21*): adds,
changes, removes; ID past a tombstone; new capability; `None`; each refusal leaves
all files byte-identical (compare checksums); a rollback's inverse round-trips a
feature's claims to their prior text.

## Task 2 - the spec side (design 2)

- `template/blueprint/` spec template (find it: grep `## Production needs` under
  `template/` and `skills/spec.md`): add `## Behaviour changes` beside
  `## Decisions`.
- `skills/spec.md` Step 3: list `blueprint/capabilities/`, read the files for the
  touched areas, write the section against them; the per-type table; the
  no-capabilities-but-archives case says `verify --all` would seed and does not
  block. Step 4: the undeclared-contradiction question.
- A quick fix may add a claim, nothing more (extends the `--quick` limits; `build`
  and `ship` already re-check them - add the clause there only if they list limits
  by name).

## Task 3 - `ship` and `rollback` (design 3, 4)

- `skills/ship.md` Step 2: a carry-over paragraph beside Decisions and Production
  needs. Run the script *before* Step 2's other writes; show the assigned IDs; a
  missing section is missing evidence at Step 1. `--abandon` merges nothing.
  Add `blueprint/capabilities/` to its `Writes:` line.
- `skills/rollback.md` Step 2: later items that changed the target's claims are
  named and asked about. Step 3: write the inverse section (adds -> removes,
  changes -> changes back, removes -> adds under a new ID). State the seeded-claim
  limit where it applies.

## Task 4 - `verify --all` and seeding (design 5)

- `skills/verify.md` Step 1: read capability files as the check list; keep the two
  remaining judgments (`Since:` item gone from `build-plan.md`; no observable
  behaviour). Per-archive seeding: archives lacking the section are walked as
  today, then seeding is offered with every line shown first; on yes, append the
  section (with `Left out:` lines) and run the script. `Writes:` gains
  `blueprint/capabilities/` and `blueprint/history/`.

## Task 5 - declarations (design 6)

- `template/AGENTS.md`: row for `blueprint/capabilities/` (writers `ship`,
  `verify`); add `verify` to the `blueprint/history/` row (rule 10 binds the
  table to the `Writes:` lines). **Rule 18:** cut the same number of bytes of
  prose from `template/AGENTS.md`; measure with rule 18's loop (headroom was 235
  bytes, the addition about 140).
- `docs/anatomy.md` table rows; `dev-notes/decisions.md` `D21`.
- `install.sh` needs nothing unless it lists state directories - grep first.

## Task 6 - seam tests (design 7)

`tests/test-seams.sh`, *behaviour travels from spec to capabilities*: the spec
template has the section; `ship`, `rollback`, `verify` name it; `ship` and
`verify` name the script; `verify --all` states the per-archive seeding rule;
`rollback` writes the old text back; `spec`'s red-team asks the question.
Wording tests join lines with `tr` - mutate a word that sits on one line.

## Task 7 - close out

`./check.sh`, then `./tests/run.sh` once. Update `dev-notes/status.md`: what
shipped, **unproven against an agent**, and the out-of-scope items (plugin
package). Do not commit or push without being asked.

## Watch for

- A rule-count or skill-count changes nowhere here (no new skill, no new rule);
  if a check claims otherwise, find out why.
- Rule 13: any skill naming `blueprint/capabilities/` must say where it resolves
  in a multi-part product (part-level, like findings) - if the table declares it
  a product-root file, it must be named as one.
- Public starter: no project names or sizes in examples.
