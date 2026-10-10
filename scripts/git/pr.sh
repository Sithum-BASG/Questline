#!/bin/sh
# git pr --body-file pr.md [--title "..."] [--partial]
#     -> push the current phase branch and open its PR (as the phase's PR owner, runbook section 8).
#       The body is a short plain description of what was done, written by whoever opens the PR.
#       Refuses if a task in the phase has no commits yet, unless --partial.
# git pr --milestone "M1: schema and RLS tests passing" --body-file pr.md   -> develop -> main (as R6)
# git pr --release   --body-file pr.md                                     -> release/v1.0 -> main (as R5)
# git pr --backmerge --body-file pr.md                                     -> release/v1.0 -> develop (as R5)
. "$(dirname "$0")/lib.sh"
command -v gh >/dev/null 2>&1 || ql_die "GitHub CLI (gh) is not installed - https://cli.github.com"
ql_load_ids
STOP="STOP: PR opened. STOP here - the PR is reviewed and merged manually on GitHub. Don't start the next phase until it's merged."

MODE=phase; MTITLE=""; TITLE=""; BODYFILE=""; PARTIAL=""
while [ $# -gt 0 ]; do
  case "$1" in
    --milestone) MODE=milestone; MTITLE="$2"; shift ;;
    --release)   MODE=release ;;
    --backmerge) MODE=backmerge ;;
    --title)     TITLE="$2"; shift ;;
    --body-file) BODYFILE="$2"; shift ;;
    --partial)   PARTIAL=1 ;;
    *) ql_die "Unknown option '$1'" ;;
  esac
  shift
done
[ -n "$BODYFILE" ] && [ -s "$BODYFILE" ] || ql_die "Write the PR description first (a few plain sentences on what was done) and pass it: git pr --body-file pr.md"
# PowerShell can write UTF-16 or a BOM and CRLF line endings - convert to plain UTF-8 with LF.
NORM="$(git rev-parse --git-dir)/pr-body.normalized.md"
case "$(head -c 2 "$BODYFILE" | od -An -tx1 | tr -d ' \n')" in
  fffe|feff) iconv -f UTF-16 -t UTF-8 "$BODYFILE" ;;
  *) cat "$BODYFILE" ;;
esac | awk 'NR==1{sub(/^\357\273\277/, "")} {sub(/\r$/, "")} 1' > "$NORM"
[ -s "$NORM" ] || ql_die "The PR description file is empty or unreadable: $BODYFILE"
BODYFILE="$NORM"
if grep -qiE 'co-authored-by|generated (with|by)|cursoragent' "$BODYFILE"; then ql_die "Remove co-author / AI attribution lines from the PR description"; fi

case "$MODE" in
  milestone) [ -n "$MTITLE" ] || ql_die "Usage: git pr --milestone \"M1: schema and RLS tests passing\" --body-file pr.md"
    GH_TOKEN=$(ql_token R6) gh pr create --base main --head develop --title "${TITLE:-$MTITLE}" --body-file "$BODYFILE" && echo "$STOP"; exit $? ;;
  release)
    GH_TOKEN=$(ql_token R5) gh pr create --base main --head release/v1.0 --title "${TITLE:-Release v1.0.0}" --body-file "$BODYFILE" && echo "$STOP"; exit $? ;;
  backmerge)
    GH_TOKEN=$(ql_token R5) gh pr create --base develop --head release/v1.0 --title "${TITLE:-Bring release fixes back into develop}" --body-file "$BODYFILE" && echo "$STOP"; exit $? ;;
esac

BR=$(git branch --show-current)
N=$(ql_phase_of_branch "$BR"); [ -n "$N" ] || ql_die "PRs are opened from phase branches (you are on '$BR'). Run: git phase <number>"
ql_phase_info "$N"
[ -z "$(git status --porcelain)" ] || ql_die "Uncommitted changes - commit them to their task first."
git fetch -q origin 2>/dev/null || true

DONE=$(git log "origin/$PHASE_BASE..HEAD" --format='%(trailers:key=Task,valueonly)' | sort -u)
TASKS=$(awk -v n="$N" '
    { sub(/\r$/, "") }
    /<!-- TASKS:START -->/ {on=1; next} /<!-- TASKS:END -->/ {on=0}
    on && /^### Phase [0-9]+/ { split($0, h, " "); ph = h[3] }
    on && ph == n && /^\| *T[0-9][0-9][0-9] *\|/ { split($0, c, "|"); gsub(/[ `]/, "", c[2]); gsub(/^ +| +$/, "", c[4]); print c[2] "\t" c[4] }' "$QL_DOC")
MISSING=""
OLDIFS=$IFS; IFS='
'
for line in $TASKS; do
  T=${line%%	*}
  printf '%s\n' "$DONE" | grep -qx "$T" || MISSING="$MISSING $T"
done
IFS=$OLDIFS
if [ -n "$MISSING" ] && [ -z "$PARTIAL" ]; then
  ql_die "These tasks have no commits yet:$MISSING - finish them (git task <ID>), or if the user explicitly wants a partial PR: git pr --partial --body-file pr.md"
fi

QL_AS="$PHASE_PR" git push -q -u origin "$BR" || exit 1
GH_TOKEN=$(ql_token "$PHASE_PR") gh pr create --base "$PHASE_BASE" --head "$BR" --title "${TITLE:-Phase $N: $PHASE_NAME}" --body-file "$BODYFILE" || exit 1
echo "$STOP"
