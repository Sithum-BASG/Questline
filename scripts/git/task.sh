#!/bin/sh
# git task T014  -> work on task T014: its commits go under the task's owner (name, email, token)
. "$(dirname "$0")/lib.sh"
T="$1"; case "$T" in T[0-9][0-9][0-9]) ;; *) ql_die "Usage: git task T014" ;; esac
ql_load_ids; ql_task_info "$T"
BR=$(git branch --show-current)
if [ "$TASK_PHASE" = "0" ]; then
  [ "$BR" = "main" ] || ql_die "$T is the first commit and belongs on main"
else
  P=$(ql_phase_of_branch "$BR")
  [ "$P" = "$TASK_PHASE" ] || { ql_phase_info "$TASK_PHASE"; ql_die "$T belongs to Phase $TASK_PHASE ($PHASE_BRANCH). Run: git phase $TASK_PHASE"; }
fi
ql_set_identity "$TASK_OWNER" quiet
git config --local questline.task "$T"
echo "OK: Task $T - commits go under $TASK_OWNER ($(git config user.name))"
