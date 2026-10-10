#!/bin/sh
# One-time setup per clone:   sh scripts/git/setup.sh
set -e
. "$(dirname "$0")/lib.sh"
[ -n "$QL_TOP" ] || ql_die "Run this inside the questline repo."
cd "$QL_TOP"

git config --local include.path ../.gitconfig          # team aliases (git as, git pr, ...)
git config --local core.hooksPath .githooks            # commit rules + Co-authored-by stripping
git config --local pull.ff only
git config --local merge.ff false
git config --local push.autoSetupRemote true
git config --local core.autocrlf input

# Credentials come from the active member's token, never from a saved login.
git config --local --unset-all credential.helper 2>/dev/null || true
git config --local --add credential.helper ''
git config --local --add credential.helper "!sh \"$QL_TOP/scripts/git/cred.sh\""
git config --local credential.useHttpPath false

if ! git check-ignore -q docs/VERSION-CONTROL.md; then
  echo "WARNING: docs/VERSION-CONTROL.md is not git-ignored - add it to .gitignore before filling in tokens."
fi
[ -f docs/VERSION-CONTROL.md ] || echo "WARNING: Put the filled-in VERSION-CONTROL.md at docs/VERSION-CONTROL.md"
chmod +x .githooks/* 2>/dev/null || true
echo "OK: Setup done. Start a phase with: git phase <n> - identity is set per task by: git task <ID> (first commit only: git as R5)."
