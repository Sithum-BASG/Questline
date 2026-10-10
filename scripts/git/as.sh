#!/bin/sh
# git as R3  -> manual override: make R3 the identity in this clone (normally automatic from the branch)
. "$(dirname "$0")/lib.sh"
ql_valid_member "$1" || ql_die "Usage: git as R1|R2|R3|R4|R5|R6"
ql_set_identity "$1"
if git remote get-url origin >/dev/null 2>&1; then
  if git ls-remote --heads origin >/dev/null 2>&1; then echo "OK: Token works for origin"
  else echo "WARNING: Could not reach origin with $1's token - has $1 accepted the collaborator invite? Is the token correct and unexpired?"; fi
fi
