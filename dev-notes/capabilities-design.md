# Living capability specs - design (2026-09-30)

Item 6 of the agreed order, first half. Agreed with the user section by section;
the implementation plan follows this file.

## The problem

What a project does *now* exists only as a pile of archives under
`blueprint/history/`. Two things pay for that:

- **`spec` never reads what already holds.** A new item can contradict a shipped
  behaviour and nothing asks, until something breaks after the merge.
- **`verify --all` guesses supersession at read time.** It walks every archive
  and judges, claim by claim, whether later work superseded it, cut it or
  rolled it back (`skills/verify.md`, Step 1). The judgment is redone on every
  run and recorded nowhere.

OpenSpec's answer: a change declares its deltas, and archiving it merges them
into a per-capability file that always says what is true now. This pack already
has the carry-over shape twice - `ship` carries a spec's `## Decisions` to
`dev-notes/decisions.md` and its `## Production needs` to
`blueprint/production-pending.md`. This is the third.

**Success:** `spec` writes against the current claims and declares what it
changes; `ship` merges; `verify --all` proves the result without judging
supersession; an existing project gets there without a hand migration.

## 1. The capability file

`blueprint/capabilities/<name>.md`, one per capability. Part-level in a
multi-part product, like the findings; not loaded - read on demand.

    # Capability: accounts

    - **accounts.1** - A signed-out visit to /settings lands on /login, then on /settings after sign-in. *Since:* features/03-auth
    - **accounts.2** - Changing the password signs out every other device. *Since:* features/03-auth · *Changed:* features/07-roles

    ## Removed
    - accounts.3 - removed by features/09-sso

- **A claim is one observable behaviour** - the done-when standard.
- **IDs are never reused.** A removed claim leaves a tombstone under
  `## Removed`. The next ID is one past the highest in the file, tombstones
  included.
- **Provenance is the archive name** - `<dir>/<file without .md>`, the key
  `ship` already prefixes findings with. The file holds no history; the
  archives are the history.

## 2. The spec's `## Behaviour changes`

A section beside `## Decisions` and `## Production needs`:

    ## Behaviour changes
    - Adds to `accounts`: <claim> - Step 2
    - Changes `accounts.2` from "<old text>" to "<new text>" - Step 3
    - Removes `lists.4`: <why>
    - New capability `billing`: <claim> - Step 1

- **Every added or changed claim names the build step whose done-when proves
  it**, so nothing enters a capability file that `verify` has not seen hold.
- **A change carries the old text and the new** - the capability file keeps
  only the current text, and without the old one a rollback has nothing to
  restore.
- **"None" is an answer** - a fix that restores a claim already held.
- **`spec` reads before it writes.** Step 3 lists `blueprint/capabilities/`,
  opens the files for the areas the item touches, and writes the section
  against them. With no capability files but existing archives, it says
  `verify --all` would seed them and does not block. Step 4, the red-team,
  asks: *does this item contradict an existing claim it did not declare as
  changed or removed?*

By item type:

| Type | Behaviour changes |
|---|---|
| Feature | adds, changes, removes |
| Fix | usually adds the regression's claim; changes one only when the intended behaviour itself was wrong |
| Quick fix | may add a claim, nothing more - anything more disqualifies `--quick` |
| Rollback | the inverse of the target's, written by `rollback` (section 4) |
| Abandon | nothing merges |

## 3. `ship` merges

A paragraph in `ship` Step 2, beside the other carry-overs, in the same commit.
The merge is `lib/merge-capabilities <spec-or-archive> <archive name>` (a `.sh` under `lib/`; named here without the extension until it exists, because `check.sh` rejects a reference to a missing script):

- **Checks everything before writing anything.** Every `Changes` or `Removes`
  ID exists and is not a tombstone; every `Changes` old text matches the file's
  current text - a mismatch means another item changed that claim since this
  spec was written; every named step is ticked. A failure names the line and
  exits non-zero with every file byte-identical. `ship` runs it before its
  other Step 2 writes, so a refusal leaves nothing half-merged.
- **Then merges.** Adds get the next ID and `*Since:* <archive name>`; changes
  replace the text and append `*Changed:* <archive name>`; removes become
  tombstones; a new capability creates its file under `# Capability: <name>`.
- **Prints the IDs it assigned**, which `ship` names in its report and shows
  with the rest of Step 2's changes.
- **`--abandon` merges nothing** - the section stays in the archive under
  `history/abandoned/` for `spec`'s resume.
- **A missing section - not "None" - is missing evidence** at Step 1, and
  `ship` stops there as for any other.

The skills keep the judgment - what counts as a claim, which step proves it,
the seeding questions. The script keeps the arithmetic, which two agents doing
by hand would get wrong with nothing to notice. Bash with `python3`, like
`lib/migrate-findings.sh`.

## 4. `rollback` writes the inverse

Step 3 writes the rollback spec's section from the target's archive:

- each claim it added becomes a `Removes`
- each it changed becomes a `Changes` from its new text back to its old
- each it removed becomes an `Adds` with the original text, under a new ID -
  the tombstone stays

Step 2's review of what was built on top covers claims: a later item that
changed one of the target's claims is named and asked about, never silently
reverted. The rollback then merges through `ship` like any item.

## 5. `verify --all` and seeding

**It reads the capability files.** Every claim outside `## Removed` is a check,
grouped by capability. Rolled back and superseded fall out of the files. Two
checks stay: a claim whose `Since:` item has left `build-plan.md` (an
`ideate --rescope` with no rollback) is *no longer applicable*; a claim with no
observable behaviour is *could not verify*.

**Seeding is per archive, not per project.** An archive `ship` merged has a
`## Behaviour changes` section; one from before this change does not. So:

1. **Archives without the section** are walked exactly as today - the README
   skip, the rollback skip, the superseded and cut judgments unchanged.
2. **Then it offers to seed**, every line shown before any is written:
   - a claim that **held** - seeded, at its current text, under the archive
     that last set that text
   - a claim that **failed** - reported as a regression; the user says whether
     it is still intended (seeded, so it keeps failing visibly) or no longer
     wanted (left out)
   - **could not verify, no longer applicable, rolled back** - left out, with
     the reason
3. **On a yes, it appends a `## Behaviour changes` section to each seeded
   archive**, in `ship`'s format, with `Left out: <claim> - <reason>` lines, and
   runs the merge script on it. The section is what marks the archive done, so
   it is never walked or asked about again - and `rollback` of an old feature
   now finds the section it reads.

A mixed project - new items merged by `ship`, old archives not yet seeded -
needs no special case: any archive without the section is walked.

**Known limit:** a seeded claim is always an `Adds`, never a `Changes`, so
rolling back an old item that had superseded an earlier claim removes the claim
rather than restoring the earlier text. `rollback`'s Step 2 says so where it
applies.

## 6. Declarations

- `template/AGENTS.md`: a row for `blueprint/capabilities/`, writers `ship`,
  `verify`; `verify` added to the `blueprint/history/` row.
- `Writes:` lines: `ship` gains `blueprint/capabilities/`; `verify` gains it
  and `blueprint/history/`. Rule 10 binds the two to the table.
- **Rule 18:** 235 bytes of headroom measured today; the row and the added
  writer cost about 140. The same amount of prose is cut from
  `template/AGENTS.md` so the headroom does not shrink.
- `lib/merge-capabilities` is named by `ship` and `verify` (rule 9), and
  refuses only before its first write (rule 16).
- `docs/anatomy.md`'s table, `D21` in `dev-notes/decisions.md`, and
  `dev-notes/status.md`.

## 7. Tests

Each seen failing first; then the fix broken in a copy, checking the mutation
changed what the assertion names.

- **`tests/test-scripts.sh`, the merge script:** adds, changes and removes;
  the next ID past a tombstone; a new capability; "None"; refuses a stale old
  text, an unknown ID and a tombstone ID with every file byte-identical; a
  rollback's inverse round-trips a feature's claims to their prior text.
- **`tests/test-seams.sh`, *behaviour travels from spec to capabilities*:** the
  spec template has the section; `ship`, `rollback` and `verify` name it;
  `ship` and `verify` name the script; `verify --all` states the per-archive
  seeding rule; `rollback` writes the old text back; `spec`'s red-team asks the
  undeclared-contradiction question.

## Out of scope

- The second half of item 6, a Claude Code plugin package.
- `progress` or `review` reading capability files - nothing needs them yet.
- A lint rule tying claims to done-whens - the spec's red-team and the merge
  script's step check cover it.

## Unproven until a real run

No agent has written the section, merged it through `ship`, or seeded a
project. The tests prove the script and the wording.
