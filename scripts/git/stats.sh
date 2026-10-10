#!/bin/sh
# git stats [--since=2026-10-10]   -> commits per author on develop (merge commits excluded)
. "$(dirname "$0")/lib.sh"
git fetch -q origin 2>/dev/null || true
REF=origin/develop; git rev-parse -q --verify "$REF" >/dev/null || REF=develop
echo "Commits per author on $REF (no merges) $*:"
git shortlog -sne --no-merges "$@" "$REF"
echo
echo "Open branches by last author:"
git for-each-ref --sort=-committerdate refs/remotes/origin/feature refs/remotes/origin/fix \
  --format='  %(refname:short)  - %(authorname), %(committerdate:relative)'
