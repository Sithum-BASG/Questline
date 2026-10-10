# Shared helpers for the Questline git aliases. Sourced, not run.
# Credentials are read from the "Team credentials" table in docs/VERSION-CONTROL.md
# (between <!-- TEAM:START --> and <!-- TEAM:END -->). That file is git-ignored once filled in.
QL_DIR=$(cd "$(dirname "$0")" && pwd)
# git sets a relative GIT_DIR for credential helpers (during push) and hooks; ignore it for these lookups.
QL_TOP=$( unset GIT_DIR GIT_WORK_TREE; cd "$QL_DIR" && git rev-parse --show-toplevel 2>/dev/null || true )
[ -n "$QL_TOP" ] || QL_TOP=$(cd "$QL_DIR/../.." && pwd)
QL_DOC=$( unset GIT_DIR GIT_WORK_TREE; cd "$QL_TOP" && git config --get questline.doc 2>/dev/null || true )
[ -n "$QL_DOC" ] || QL_DOC="$QL_TOP/docs/VERSION-CONTROL.md"

ql_die() { echo "ERROR: $*" >&2; exit 1; }

# Parses the team table into R1_NAME, R1_GH_USER, R1_EMAIL, R1_TOKEN ... R6_*
ql_load_ids() {
  [ -f "$QL_DOC" ] || ql_die "Can't find $QL_DOC (the version control doc with the team credentials table)."
  eval "$(awk '
    { sub(/\r$/, "") }
    /<!-- TEAM:START -->/ {on=1; next}
    /<!-- TEAM:END -->/   {on=0}
    on && /^\|[ ]*R[1-6][ ]*\|/ {
      n = split($0, c, "|")
      for (i = 2; i <= 6; i++) { gsub(/^[ \t`]+|[ \t`]+$/, "", c[i]); gsub(/'"'"'/, "", c[i]) }
      printf "%s_NAME='"'"'%s'"'"'\n%s_GH_USER='"'"'%s'"'"'\n%s_EMAIL='"'"'%s'"'"'\n%s_TOKEN='"'"'%s'"'"'\n", c[2], c[3], c[2], c[4], c[2], c[5], c[2], c[6]
    }' "$QL_DOC")"
}

# ql_field R3 TOKEN  -> value of R3_TOKEN
ql_field() { eval "printf '%s' \"\${${1}_${2}}\""; }

ql_valid_member() { case "$1" in R1|R2|R3|R4|R5|R6) return 0;; *) return 1;; esac; }

ql_active() { git config --get questline.member 2>/dev/null; }

# Sets $M to the active member and loads credentials (call directly, not inside $(...))
ql_require_active() {
  M=$(ql_active)
  [ -n "$M" ] || ql_die "No member selected. Run: git as R1   (R1-R6 = whoever is doing this work)"
  ql_load_ids
  [ -n "$(ql_token "$M")" ] || ql_die "$M has no token in the team credentials table"
}

ql_token() { ql_field "$1" TOKEN; }

# ql_task_info T014 -> TASK_OWNER (R5), TASK_PHASE (7)   - from the task tables in section 9
ql_task_info() {
  [ -f "$QL_DOC" ] || ql_die "Can't find $QL_DOC"
  _r=$(awk -v id="$1" '
    { sub(/\r$/, "") }
    /<!-- TASKS:START -->/ {on=1; next}
    /<!-- TASKS:END -->/   {on=0}
    on && /^### Phase [0-9]+/ { split($0, h, " "); ph = h[3] }
    on && $0 ~ "^\\| *" id " *\\|" { n = split($0, c, "|"); gsub(/[ `]/, "", c[3]); print ph " " c[3]; exit }
  ' "$QL_DOC")
  [ -n "$_r" ] || ql_die "Task $1 not found in docs/VERSION-CONTROL.md section 9"
  TASK_PHASE=${_r%% *}; TASK_OWNER=${_r#* }
  ql_valid_member "$TASK_OWNER" || ql_die "Task $1 has no valid owner in section 9 ('$TASK_OWNER')"
}

# ql_phase_info 7 -> PHASE_NAME, PHASE_BRANCH, PHASE_BASE, PHASE_PR (owner who opens the PR)
ql_phase_info() {
  [ -f "$QL_DOC" ] || ql_die "Can't find $QL_DOC"
  _r=$(awk -v n="$1" '
    { sub(/\r$/, "") }
    /<!-- PHASES:START -->/ {on=1; next}
    /<!-- PHASES:END -->/   {on=0}
    on && /^\| *[0-9]+ *\|/ { split($0, c, "|"); for (i=2;i<=6;i++) gsub(/^[ `]+|[ `]+$/, "", c[i]); if (c[2] == n) { print c[4] "|" c[5] "|" c[6] "|" c[3]; exit } }
  ' "$QL_DOC")
  [ -n "$_r" ] || ql_die "Phase $1 not found in docs/VERSION-CONTROL.md section 8"
  PHASE_BRANCH=${_r%%|*}; _r=${_r#*|}; PHASE_BASE=${_r%%|*}; _r=${_r#*|}; PHASE_PR=${_r%%|*}; PHASE_NAME=${_r#*|}
}

# phase/07-progression-ui -> 7
ql_phase_of_branch() {
  case "$1" in phase/[0-9][0-9]-*) _p=${1#phase/}; _p=${_p%%-*}; printf '%s' "${_p#0}" ;; esac
}

# ql_set_identity R5 [quiet] -> author name/email + token for R5 in this clone
ql_set_identity() {
  _m="$1"
  ql_valid_member "$_m" || ql_die "Unknown member '$_m'"
  ql_load_ids
  _n=$(ql_field "$_m" NAME); _e=$(ql_field "$_m" EMAIL); _u=$(ql_field "$_m" GH_USER); _t=$(ql_token "$_m")
  case "$_n$_e$_u$_t" in *"<"*|"") ql_die "$_m still has placeholders in the team credentials table (docs/VERSION-CONTROL.md section 1)";; esac
  git config --local questline.member "$_m"
  git config --local user.name "$_n"
  git config --local user.email "$_e"
  git config --local questline.email "$_e"
  [ "$2" = "quiet" ] || echo "OK: Identity: $_m - $_n