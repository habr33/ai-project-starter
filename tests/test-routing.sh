#!/usr/bin/env bash
# Does a realistic user prompt reach the right skill?
#
# An agent picks a skill by matching the user's words against 27 `description:`
# lines, and nothing else in this repo looks at those lines as a set. The linter
# checks one description at a time - length, modes named, on one line - so a
# skill whose description omits the words people actually type to enter it
# passes every rule while being unreachable in practice. That is what this file
# is for.
#
# **The ranker here is TF-IDF, and TF-IDF is not an agent.** It cannot weigh
# context, cannot read the rest of a skill, and has no idea what the user was
# doing a minute ago. So a rank from it is not evidence about routing. What it
# is evidence about is *vocabulary*: if a skill loses its own canonical prompt to
# a rival, the rival's description carries more of that prompt's words than the
# skill's does. That is a fact about the text, it is deterministic, and it is
# the only part claimed here.
#
# Read every result below as "the description does/does not carry these words",
# never as "an agent would/would not route here".
#
# Two things are gated:
#
#   1. **No two descriptions collide.** A regression guard: a new skill whose
#      description reads like an existing one is ambiguous to any matcher.
#   2. **Every skill wins its own declared prompt**, unless it is on
#      `known_misses` with a reason. That list is the rule - see below.
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

cd "$REPO" || exit 1

# --- the declared prompt list ------------------------------------------------
#
# One realistic prompt per skill, in the words a user would actually type -
# deliberately NOT a paraphrase of the description, which would prove only that
# a sentence matches itself.
#
# **Every skill must appear here**, which is what makes adding a skill force the
# question "what would someone type to get this?" - asked once, while the
# description is being written, instead of never. A prompt naming a skill that
# does not exist is an error too: a stale entry after a rename is dead config,
# and dead config hides the thing it was meant to check.
prompts=$(cat <<'PROMPTS'
ideate      | i have a rough notion for an app and no idea what the first version should contain
architect   | before we pick any technology, what are the screens and the data model going to be
stack       | what should i build this with
layout      | where should the source files actually sit in this repo
scaffold    | create the actual app now that we know the framework
ci          | i want the checks to run automatically on every pull request
context     | regenerate the overview, i just edited both planning docs
prototype   | can i see roughly how the screens will look before we write any code
spec        | break down the next thing on the build plan into steps i can build
build       | implement the current spec, one step at a time
verify      | can you run the app and show me it works, not just that the tests pass
review      | give this a security review and write down what you find
ship        | this item is built and reviewed, wrap it up and merge it
docs        | the readme is still the template boilerplate, write a real one
preflight   | are we ready to put this in front of real users
host        | i need somewhere to deploy this and a real database
deploy      | push the release out to production
migrate     | i need to add a column to an existing table without losing data
monitor     | the site is down and i need to know why
rollback    | undo the feature we merged last week
debug       | a test is failing and i cannot work out why
progress    | where do things stand and what is next
prepare     | what do i need to buy or install before we can carry on
setup       | i just installed this into an existing repo, configure it to match
integrate   | the web part and the api part each work alone but something breaks between them
orchestrate | which part should i run next, and why is the api waiting
autopilot   | run architect through review unattended
PROMPTS
)

# --- where the ranker and an agent are known to disagree ---------------------
#
# A skill here loses its own prompt to lexical noise rather than to a real
# ambiguity, and the fix would be to write the description for the ranker
# instead of for the agent that reads it. Each entry says which skill wins and
# why that is an artifact.
#
# **An entry that no longer misses is an error**, the same way a retired name
# that is still a live skill is: it means a description changed and nobody
# revisited the excuse written against it.
known_misses=$(cat <<'MISSES'
stack  | "build this with" is the ordinary English for choosing a stack, and `build` is a skill whose description says "build" nine times. The word is owned by the wrong skill lexically and cannot be taken back without making `build`'s description worse.
MISSES
)

# The line above which two descriptions are treated as interchangeable. The
# worst real pair sits at 0.28 (`review` <-> `ship`, which share the whole
# vocabulary of closing out an item), so this leaves headroom without being a
# guard that can never fire.
collision_limit=0.40

# Below this gap to the winner, second place is a tie and not a result.
#
# **This number was measured, not chosen.** Every description shares one IDF
# table, so adding a word to any skill reweights every other skill's score -
# and the first thing this file did on a real repo was demonstrate it. Adding
# *down* to `monitor` (the fix below) diluted that word's weight, which was the
# only term separating `spec` from `progress` on spec's own prompt, and spec
# went from first to second on a margin of **0.0003**. Asserting who wins that
# is asserting floating-point noise, and it would make every description edit
# break an unrelated skill.
#
# The line sits between the two real cases: `spec` lost by 0.0003, `monitor`
# lost by 0.0332 before its description was fixed. A margin of 0.02 keeps the
# finding and drops the noise, with a factor of 100 between them and 1.7x of
# headroom on the side that matters. Raise it past ~0.03 and the monitor class
# of defect stops being visible at all.
tie_margin=0.02

# --- the ranker --------------------------------------------------------------
#
# Written out once and called twice. python3 only, like the rest of the pack.
cat > "$TEST_TMP/rank.py" <<'RANKER'
import sys, os, re, math, glob

# Ordinary English that says nothing about which skill is wanted. Dropping it is
# what stops every prompt matching every description on "the" and "is".
STOP = set("""a an and are as at be been before but by can do does for from has
have how i if in into is it its of on one or should that the their then there
these this to up use used using want wants what when where which who why with
without you your""".split())

def toks(s):
    """Lowercase word stems. The suffix strip is crude on purpose: it has to be
    the same two lines a reader can check by hand, not a real stemmer."""
    out = []
    for w in re.findall(r"[a-z0-9]+", s.lower()):
        if w in STOP or len(w) < 2:
            continue
        for suf in ("ing", "ed", "es", "s"):
            if len(w) > len(suf) + 3 and w.endswith(suf):
                w = w[:-len(suf)]
                break
        out.append(w)
    return out

def load(repo):
    docs = {}
    for f in sorted(glob.glob(os.path.join(repo, "skills", "*.md"))):
        name = os.path.basename(f)[:-3]
        with open(f) as fh:
            for line in fh:
                if line.startswith("description:"):
                    docs[name] = line.split(":", 1)[1].strip().strip('"')
                    break
    return docs

def vectors(docs):
    """TF-IDF over the descriptions, each vector normalised so a comparison is a
    cosine. The skill's own name is tokenised in with its description - a user
    who types the name should reach it."""
    tf = {n: {} for n in docs}
    for n, d in docs.items():
        for t in toks(n.replace("-", " ")) + toks(d):
            tf[n][t] = tf[n].get(t, 0) + 1
    df = {}
    for n in tf:
        for t in tf[n]:
            df[t] = df.get(t, 0) + 1
    N = len(tf)
    idf = {t: math.log((N + 1) / (df[t] + 1)) + 1 for t in df}
    vec = {}
    for n in tf:
        v = {t: (1 + math.log(c)) * idf[t] for t, c in tf[n].items()}
        norm = math.sqrt(sum(x * x for x in v.values())) or 1.0
        vec[n] = {t: x / norm for t, x in v.items()}
    return vec, idf

def cos(a, b):
    small, big = (a, b) if len(a) < len(b) else (b, a)
    return sum(x * big.get(t, 0.0) for t, x in small.items())

def qvec(prompt, idf):
    """A word the prompt uses that appears in no description gets weight 0 - it
    cannot discriminate, and pretending otherwise would hide exactly the case
    this file exists to find."""
    tf = {}
    for t in toks(prompt):
        tf[t] = tf.get(t, 0) + 1
    v = {t: (1 + math.log(c)) * idf.get(t, 0.0) for t, c in tf.items()}
    norm = math.sqrt(sum(x * x for x in v.values())) or 1.0
    return {t: x / norm for t, x in v.items()}

repo, mode = sys.argv[1], sys.argv[2]
docs = load(repo)
vec, idf = vectors(docs)

if mode == "skills":
    for n in sorted(docs):
        print(n)

elif mode == "collide":
    # The worst pair, printed as "<score> <a> <b>" so the caller can both
    # threshold it and name it in the failure.
    names = sorted(docs)
    worst = (0.0, "-", "-")
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            s = cos(vec[names[i]], vec[names[j]])
            if s > worst[0]:
                worst = (s, names[i], names[j])
    print("%.3f %s %s" % worst)

elif mode == "rank":
    # "<skill> <verdict> <rank> <winner> <gap>" per declared prompt, where the
    # gap is the winner's score minus this skill's. Rank 0 means the skill has
    # no description at all, which is a different bug and says so.
    #
    # The verdict, not the rank, is what the caller gates on. Ranking second by
    # 0.0003 and ranking second by 0.03 are not the same result, and only the
    # second one is about the text - see the tie margin in the caller.
    tie = float(sys.argv[3])
    for line in sys.stdin:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        want, prompt = (x.strip() for x in line.split("|", 1))
        q = qvec(prompt, idf)
        scored = sorted(((cos(q, vec[n]), n) for n in docs), reverse=True)
        order = [n for _, n in scored]
        pos = order.index(want) + 1 if want in order else 0
        mine = dict((n, s) for s, n in scored).get(want, 0.0)
        gap = scored[0][0] - mine
        verdict = "win" if pos == 1 else ("tie" if gap < tie else "miss")
        print(want, verdict, pos, order[0], "%.4f" % gap)
RANKER

# --- 1. the list is complete -------------------------------------------------

section "every skill has a declared prompt, and every prompt a skill"
# Without this, adding a skill silently skips the routing check for it - and a
# check that quietly covers 26 of 27 things is worse than one that covers none,
# because it reads as covering all of them.
skills=$(python3 "$TEST_TMP/rank.py" "$REPO" skills)
declared=$(printf '%s\n' "$prompts" | sed 's/ *|.*//' | sed 's/ *$//' | sort)

assert_eq "no skill is missing a prompt" "" \
  "$(comm -23 <(printf '%s\n' "$skills") <(printf '%s\n' "$declared") | tr '\n' ' ' | sed 's/ *$//')"
assert_eq "no prompt names a skill that does not exist" "" \
  "$(comm -13 <(printf '%s\n' "$skills") <(printf '%s\n' "$declared") | tr '\n' ' ' | sed 's/ *$//')"
assert_eq "every prompt is on one line with one skill" \
  "$(printf '%s\n' "$skills" | wc -l | tr -d ' ')" \
  "$(printf '%s\n' "$prompts" | grep -c '|' | tr -d ' ')"

# A prompt that just quotes the description proves only that a string matches
# itself. None may repeat a long phrase from the skill it points at.
echoed=""
while IFS='|' read -r want prompt; do
  want="${want// /}"; prompt="$(printf '%s' "$prompt" | sed 's/^ *//; s/ *$//')"
  [ -n "$want" ] || continue
  desc=$(awk '/^description:/{sub(/^description: */,""); print; exit}' "skills/$want.md" | tr 'A-Z' 'a-z')
  # Any run of five consecutive prompt words appearing verbatim in the
  # description is a quote, not a user talking.
  set -- $prompt
  while [ "$#" -ge 5 ]; do
    case "$desc" in *"$1 $2 $3 $4 $5"*) echoed="$echoed $want" ;; esac
    shift
  done
done <<< "$prompts"
assert_eq "no prompt quotes its own description" "" "$echoed"

# --- 2. no two descriptions collide -----------------------------------------

section "no two descriptions are interchangeable"
worst=$(python3 "$TEST_TMP/rank.py" "$REPO" collide)
worst_score=${worst%% *}
assert_ok "the closest pair ($worst) is under $collision_limit" \
  python3 -c "import sys; sys.exit(0 if float(sys.argv[1]) < float(sys.argv[2]) else 1)" \
  "$worst_score" "$collision_limit"

# --- 3. every skill wins its own prompt -------------------------------------

section "each skill's description carries the words of its own prompt"
printf '%s\n' "$prompts" > "$TEST_TMP/prompts.txt"
python3 "$TEST_TMP/rank.py" "$REPO" rank "$tie_margin" < "$TEST_TMP/prompts.txt" > "$TEST_TMP/ranked.txt"

missed=""
while read -r skill verdict pos winner gap; do
  [ -n "$skill" ] || continue
  case "$verdict" in
    win)
      _name="$skill wins its own prompt"; _ok ;;
    tie)
      # Not a pass by luck: the description does carry the prompt's words, and
      # which of two near-identical scores lands on top is not a fact about it.
      _name="$skill ties \`$winner\` on its own prompt (gap $gap)"; _ok ;;
    *)
      missed="$missed $skill"
      excuse=$(printf '%s\n' "$known_misses" | grep "^$skill  *|" || true)
      if [ -n "$excuse" ]; then
        _name="$skill loses to \`$winner\` by $gap for a declared reason"; _ok
      else
        _name="$skill wins its own prompt"
        _no "ranked $pos, behind \`$winner\` by $gap - more than the $tie_margin tie margin, so its description really is carrying more of that prompt's words. Fix the description, or add $skill to known_misses with the reason."
      fi ;;
  esac
done < "$TEST_TMP/ranked.txt"

# ...and the other direction. An excuse outlives the problem it was written for:
# a description gets rewritten, the skill starts winning, and the note stays
# behind saying it cannot - which is how the next reader learns something false.
stale=""
while IFS='|' read -r skill _; do
  skill="${skill// /}"
  [ -n "$skill" ] || continue
  case " $missed " in *" $skill "*) ;; *) stale="$stale $skill" ;; esac
done <<< "$known_misses"
assert_eq "no known_misses entry has stopped missing" "" "$stale"

# Every excuse has to say something. A bare skill name on the list is a silent
# exemption, which is the same as no check at all for that skill.
thin=""
while IFS='|' read -r skill reason; do
  skill="${skill// /}"
  [ -n "$skill" ] || continue
  [ "${#reason}" -ge 40 ] || thin="$thin $skill"
done <<< "$known_misses"
assert_eq "every known_misses entry gives a reason" "" "$thin"

finish
