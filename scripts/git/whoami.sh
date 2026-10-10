#!/bin/sh
# git whoami -> current branch, phase, task and the identity commits will use
. "$(dirname "$0")/lib.sh"
BR=$(git branch --show-current)
echo "Branch : $BR"
P=$(ql_phase_of_branch "$BR"); [ -n "$P" ] && echo "Phase  : $P"
echo "Task   : $(git config --get questline.task || echo '- (run git task <ID>)')"
echo "Member : $(ql_active || true)"
echo "Author : $(git config user.name) <$(git config user.email)>"
