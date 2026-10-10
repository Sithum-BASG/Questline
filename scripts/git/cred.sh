#!/bin/sh
# git credential helper: hands git the active member's GitHub username + token.
# If it can't, it says why on stderr (otherwise git would just ask for a username).
[ "$1" = "get" ] || exit 0
host=""
CR=$(printf '\r')
while IFS='=' read -r k v; do v=${v%"$CR"}; [ "$k" = "host" ] && host="$v"; done
[ "$host" = "github.com" ] || exit 0
why() { echo "questline: can't supply GitHub credentials - $*. Press Ctrl+C at the username prompt." >&2; exit 0; }
. "$(dirname "$0")/lib.sh"
unset GIT_DIR GIT_WORK_TREE; cd "$QL_TOP" || why "can't find the repo folder"
[ -f "$QL_DOC" ] || why "docs/VERSION-CONTROL.md not found in this clone"
M=${QL_AS:-$(ql_active)}
[ -n "$M" ] || why "no member selected (run: git task <ID>, or git as R5 for the very first commit)"
ql_load_ids
U=$(ql_field "$M" GH_USER); T=$(ql_token "$M")
case "$U$T" in *"<"*) why "$M's row in section 1 still has placeholders" ;; esac
[ -n "$U" ] || why "$M has no GitHub username in section 1"
[ -n "$T" ] || why "$M has no token in section 1"
echo "username=$U"
echo "password=$T"