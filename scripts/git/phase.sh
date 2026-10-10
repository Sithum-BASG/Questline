#!/bin/sh
# git phase 7 [--anyway]
#   -> switch to the phase branch (phase/07-progression-ui), creating it from its base if needed
#   -> refuses while any PR is still open (the previous phase must be merged first)
#   -> phases 14-16 start from release/v1.0, which is cut from develop the first time
. "$(dirname "$0")/lib.sh"
N="$1"; ANYWAY=""; [ "$2" = "--anyway" ] && ANYWAY=1
case "$N" in ''|*[!0-9]*) ql_die "Usage: git phase <number>   e.g. git phase 7" ;; esac
ql_load_ids; ql_phase_info "$N"
[ -z "$(git status --porcelain)" ] || ql_die "You have uncommitted changes. Commit them to their task first."
git fetch -q origin 2>/dev/null || true

if [ -z "$ANYWAY" ] && command -v gh >/dev/null 2>&1; then
  OPEN=$(GH_TOKEN=$(ql_token "$PHASE_PR") gh pr list --state open --json number,isDraft,headRefName \
         -q '.[] | select(.isDraft == false) | "#\(.number) \(.headRefName)"' 2>/dev/null)
  if [ -n "$OPEN" ] && ! printf '%s' "$OPEN" | grep -q " $PHASE_BRANCH\$"; then
    echo "ERROR: A PR is still waiting for review/merge:" >&2; echo "$OPEN" | sed 's/^/  /' >&2
    ql_die "Stop until it's merged on GitHub. (Only if the user explicitly says to continue: git phase $N --anyway)"
  fi
fi

if [ "$PHASE_BASE" = "release/v1.0" ] && ! git show-ref --verify --quiet refs/remotes/origin/release/v1.0; then
  echo "Feature freeze: cutting release/v1.0 from develop"
  git switch -q develop && git pull -q --ff-only && git branch release/v1.0 2>/dev/null
  QL_AS="$PHASE_PR" git push -q -u origin release/v1.0 || ql_die "Couldn't push release/v1.0"
fi

if git show-ref --verify --quiet "refs/remotes/origin/$PHASE_BRANCH" || git show-ref --verify --quiet "refs/heads/$PHASE_BRANCH"; then
  git switch -q "$PHASE_BRANCH" && (git pull -q --ff-only 2>/dev/null || true)
  echo "OK: Continuing $PHASE_BRANCH - Phase $N: $PHASE_NAME"
else
  git switch -q "$PHASE_BASE" && (git pull -q --ff-only 2>/dev/null || true)
  git switch -q -c "$PHASE_BRANCH" || exit 1
  echo "OK: Created $PHASE_BRANCH from $PHASE_BASE - Phase $N: $PHASE_NAME"
fi
git config --local --unset questline.task 2>/dev/null || true

echo "Tasks in this phase ([x] = has commits on this branch):"
DONE=$(git log "origin/$PHASE_BASE..HEAD" --format='%(trailers:key=Task,valueonly)' 2>/dev/null | sort -u)
NEXT=""
for T in $(awk -v n="$N" '
    { sub(/\r$/, "") }
    /<!-- TASKS:START -->/ {on=1; next} /<!-- TASKS:END -->/ {on=0}
    on && /^### Phase [0-9]+/ { split($0, h, " "); ph = h[3] }
    on && ph == n && /^\| *T[0-9][0-9][0-9] *\|/ { split($0, c, "|"); gsub(/[ `]/, "", c[2]); print c[2] }' "$QL_DOC"); do
  ql_task_info "$T"
  if printf '%s\n' "$DONE" | grep -qx "$T"; then echo "  [x] $T ($TASK_OWNER)"; else echo "  [ ] $T ($TASK_OWNER)"; [ -n "$NEXT" ] || NEXT="$T"; fi
done
if [ -n "$NEXT" ]; then echo "Next: git task $NEXT"; else echo "All tasks have commits. When the phase's Done when is true: git pr"; fi
