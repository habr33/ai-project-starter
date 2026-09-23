# Needs you

> **Work only a person can do**, added the moment an agent finds it - so the
> next skill needing the same account finds one line, not a new conversation.
> `preflight` treats an open required line as a blocker. **Loaded every
> session**, so it holds open lines only.

## How to write a line

One line each, with four things - a line missing any cannot be acted on:
**what** (the specific thing, not the category), **why it is yours** (spend,
credentials, a decision, hardware, system software, manual verification,
access), **what it blocks** (the item or skill, or "nothing yet, needed by
`deploy`" - blocking now and needed later both belong here, and saying which
keeps the list read), and **status** - `open`, `done`, or `dropped` with a
reason.

## Closing a line

**Opening a line is for the skills named as its writers; any of them may close
any line**, once it has checked - "installed" is proven by running it, not by
the plan saying so - recording which skill closed it and the evidence. The
skill that would have needed it closes it on its next run at the latest.
`prepare` never closes anything: it reports a line that looks satisfied and
names the skill that owns it.

**Closed lines move to Done, and `ship` moves Done to
`blueprint/history/needs-you-done.md`**, so this file stays the open list.

## Open

<!-- - [ ] **Postgres role for `appuser`** - system software; needs a superuser.
           Blocks `scaffold` on `api`. Fix: `sudo -u postgres createuser -s appuser` -->

_Nothing recorded yet._

## Done

<!-- Closed since the last `ship`. `ship` moves these to history. -->
