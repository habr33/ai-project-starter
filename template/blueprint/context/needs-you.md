# Needs you

> **Work only a person can do.** An agent adds a line the moment it finds
> something it cannot do itself, so the next skill that needs the same account
> finds one line, not a second conversation. `prepare` reads this file;
> `progress` names the next item from it; `preflight` treats anything open and
> required as a blocker. **Loaded every session**, so it holds open lines only.

## How to write a line

One line each, with four things - a line missing any cannot be acted on:
**what** (the specific thing, not the category), **why it is yours** (spend,
credentials, a decision, hardware, system software, manual verification,
access), **what it blocks** (the item or skill, or "nothing yet, needed by
`deploy`" - blocking now and needed later both belong here, and saying which
keeps the list read), and **status** - `open`, `done`, or `dropped` with a
reason.

## Closing a line

**The skill that would have needed it closes it, on its next run**, after
checking - "installed" is proven by running it, not by the plan saying so.
`prepare` never closes anything: it reports a line that looks satisfied and
names the skill that owns it.

**Closed lines move to Done, and `ship` moves Done to
`blueprint/history/needs-you-done.md`**, so this file stays the open list. A
file that only grows stops being read - and `preflight` would block a release
on a requirement met months ago.

## Open

<!-- - [ ] **Postgres role for `appuser`** - system software; needs a superuser.
           Blocks `scaffold` on `api`. Fix: `sudo -u postgres createuser -s appuser` -->

_Nothing recorded yet._

## Done

<!-- Closed since the last `ship`. `ship` moves these to history. -->
