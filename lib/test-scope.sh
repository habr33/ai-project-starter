#!/usr/bin/env bash
# test-scope.sh - which tests does this diff need before it merges?
#
# Usage (from the project, or from a part's directory):
#   .agents/bin/test-scope.sh --base origin/main      # a pull request
#   .agents/bin/test-scope.sh --push                  # a push to main
#
# Prints one word, and the reason on stderr:
#   none      only docs or workflow state changed - Verify alone
#   affected  the Affected command under Full verify in AGENTS.md: the
#             tests the runner selects for the changed files, plus smoke
#   full      full verify - the whole suite
#
# full when: a push to the default branch (the backstop after every merge);
# the spec's **Reach:** line says wide; a file that can change what any test
# does - a manifest or lockfile, CI, test or build config, a migration,
# AGENTS.md; a path the project's `- Scope:` line marks full; no Affected
# command recorded; or anything this script cannot read. It never guesses
# smaller. Run from a part's directory it reads only that part's files.
#
# `- Scope: none storybook/** | full src/styles/**` under Full verify adds
# the project's own paths. A pattern with no / matches a file's name.
# Exit: 0 with a verdict; 2 bad usage. Reads only.
set -uo pipefail
base="" push=0
while [ $# -gt 0 ]; do
  case "$1" in
    --base) base="${2:-}"; shift 2 || { echo "test-scope: usage: --base REF | --push" >&2; exit 2; } ;;
    --push) push=1; shift ;;
    -h|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "test-scope: usage: --base REF | --push (got $1)" >&2; exit 2 ;;
  esac
done
say() { echo "$1"; echo "test-scope: $1 - $2" >&2; exit 0; }
[ "$push" = 1 ] && say full "a push to the default branch runs the whole suite"
[ -n "$base" ] || { echo "test-scope: usage: --base REF | --push" >&2; exit 2; }
files="$(git diff --name-only --relative "$base...HEAD" 2>/dev/null)" \
  || say full "cannot diff against $base - running everything"
reach="$(git show HEAD:./blueprint/context/current-work.md 2>/dev/null | grep -m1 -E '^\*\*Reach:\*\*' || true)"
case "$reach" in *wide*) say full "the spec's Reach line says wide: ${reach#\*\*Reach:\*\* }" ;; esac
agents=""; [ -f AGENTS.md ] && agents="$(cat AGENTS.md)"
python3 -c '
import sys, fnmatch, re
files = [f for f in sys.argv[1].splitlines() if f]
agents = sys.argv[2]
def field(name):
    m = re.search(r"^\s*- " + name + r":\s*(.*)$", agents, re.M)
    v = m.group(1).strip() if m else ""
    return "" if (not v or v.startswith("<") or v.lower() in ("none", "\"none\"")) else v
FULL = """package.json package-lock.json npm-shrinkwrap.json pnpm-lock.yaml
pnpm-workspace.yaml yarn.lock bun.lock bun.lockb .nvmrc .node-version
.tool-versions .python-version requirements*.txt pyproject.toml poetry.lock
uv.lock Pipfile Pipfile.lock setup.py setup.cfg Gemfile Gemfile.lock go.mod
go.sum Cargo.toml Cargo.lock *.csproj *.fsproj *.sln Directory.*.props
global.json composer.json composer.lock pubspec.yaml pubspec.lock Dockerfile
docker-compose*.y*ml compose*.y*ml Makefile AGENTS.md playwright.config.*
vitest.config.* vite.config.* jest.config.* cypress.config.* karma.conf.*
pytest.ini conftest.py tox.ini tsconfig*.json babel.config.* .babelrc
schema.prisma .env.example .github/* .gitlab-ci.yml .forgejo/* .woodpecker*
migrations/* */migrations/*""".split()
NONE = """*.md *.txt *.rst docs/* blueprint/* dev-notes/* LICENSE* .gitignore
.editorconfig""".split()
scope = field("Scope")
for part in scope.split("|"):
    w = part.split()
    if w and w[0] == "full": FULL += w[1:]
    elif w and w[0] == "none": NONE = w[1:] + NONE
def hit(f, pats):
    name = f.rsplit("/", 1)[-1]
    return next((p for p in pats
                 if fnmatch.fnmatchcase(f if "/" in p else name, p.replace("**", "*"))), None)
code = []
for f in files:
    p = hit(f, FULL)
    if p:
        print("full"); print(f"test-scope: full - {f} can change what any test does ({p})", file=sys.stderr); sys.exit(0)
    if not hit(f, NONE): code.append(f)
if not code:
    print("none"); print(f"test-scope: none - {len(files)} file(s), docs and workflow state only: Verify alone", file=sys.stderr); sys.exit(0)
if not field("Affected"):
    print("full"); print("test-scope: full - code changed and AGENTS.md records no Affected command", file=sys.stderr); sys.exit(0)
print("affected"); print(f"test-scope: affected - {len(code)} code file(s), e.g. {code[0]}: the Affected command, the whole suite after the merge", file=sys.stderr)
' "$files" "$agents" || say full "the scope reader failed - running everything"
