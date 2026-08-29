#!/usr/bin/env bash
set -u

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
CHECKER="$ROOT_DIR/scripts/check-portability.sh"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT

failures=0

make_skill() {
  local root=$1 id=$2 body=${3-}
  mkdir -p "$root/skills/$id"
  printf '%s\n' '---' "name: $id" 'description: A fixture skill.' '---' "$body" >"$root/skills/$id/SKILL.md"
}

run_case() {
  local label=$1 expected_status=$2 expected_text=$3 root=$4
  local output status
  set +e
  output=$("$CHECKER" --root "$root" 2>&1)
  status=$?
  set -e
  if [[ $status -ne $expected_status ]]; then
    printf 'FAIL: %s (status %s, expected %s)\n%s\n' "$label" "$status" "$expected_status" "$output"
    failures=$((failures + 1))
  elif ! grep -Fq "$expected_text" <<<"$output"; then
    printf 'FAIL: %s (diagnostic missing: %s)\n%s\n' "$label" "$expected_text" "$output"
    failures=$((failures + 1))
  else
    printf 'PASS: %s\n' "$label"
  fi
}

run_args_case() {
  local label=$1 expected_status=$2 expected_text=$3
  shift 3
  local output status
  set +e
  output=$("$CHECKER" "$@" 2>&1)
  status=$?
  set -e
  if [[ $status -ne $expected_status ]]; then
    printf 'FAIL: %s (status %s, expected %s)\n%s\n' "$label" "$status" "$expected_status" "$output"
    failures=$((failures + 1))
  elif ! grep -Fq "$expected_text" <<<"$output"; then
    printf 'FAIL: %s (diagnostic missing: %s)\n%s\n' "$label" "$expected_text" "$output"
    failures=$((failures + 1))
  else
    printf 'PASS: %s\n' "$label"
  fi
}

new_root() {
  local root
  root=$(mktemp -d "$TMP_ROOT/case.XXXXXX")
  mkdir -p "$root/skills"
  printf '%s\n' "$root"
}

run_args_case 'no arguments uses repository root' 0 'PASS:'
case_root=$(new_root); make_skill "$case_root" cli-skill
run_args_case '--root PATH' 0 'PASS: 1 skills checked' --root "$case_root"
run_args_case '--help' 0 'Usage:' --help
run_args_case 'unknown argument' 2 'ERROR: unknown argument' --unknown
run_args_case 'missing --root value' 2 'ERROR: --root requires a path' --root

case_root=$(new_root); mkdir -p "$case_root/skills/missing-file"
run_case 'missing SKILL.md' 1 'ERROR: missing-file: missing SKILL.md' "$case_root"

case_root=$(new_root); mkdir -p "$case_root/skills/missing-name"
printf '%s\n' '---' 'description: A fixture skill.' '---' >"$case_root/skills/missing-name/SKILL.md"
run_case 'missing name' 1 'ERROR: missing-name: missing name' "$case_root"

case_root=$(new_root); mkdir -p "$case_root/skills/missing-description"
printf '%s\n' '---' 'name: missing-description' '---' >"$case_root/skills/missing-description/SKILL.md"
run_case 'missing description' 1 'ERROR: missing-description: missing description' "$case_root"

case_root=$(new_root); make_skill "$case_root" wrong-name
sed -i 's/name: wrong-name/name: other-name/' "$case_root/skills/wrong-name/SKILL.md"
run_case 'name and directory mismatch' 1 'ERROR: wrong-name: name does not match directory' "$case_root"

for id in Uppercase has_under two--parts trailing-; do
  case_root=$(new_root); make_skill "$case_root" "$id"
  run_case "invalid OpenCode name: $id" 1 "ERROR: $id: invalid OpenCode name" "$case_root"
done

long_id=$(printf 'a%.0s' {1..65})
case_root=$(new_root); make_skill "$case_root" "$long_id"
run_case 'invalid OpenCode name: 65 characters' 1 "ERROR: $long_id: invalid OpenCode name" "$case_root"

for path in '.claude/skills/' '~/.claude/skills/' '.codex/skills/' '~/.codex/skills/' '.opencode/skills/' '~/.config/opencode/skills/'; do
  case_root=$(new_root); make_skill "$case_root" forbidden "refer to $path in this body"
  run_case "forbidden runtime path: $path" 1 "ERROR: forbidden: forbidden runtime path" "$case_root"
done

case_root=$(new_root); make_skill "$case_root" missing-reference 'See references/not-there.md for details.'
run_case 'missing relative references target' 1 'ERROR: missing-reference: missing referenced file' "$case_root"

case_root=$(new_root); make_skill "$case_root" warning-only 'Use the Claude Code tool, Read tool, Edit tool, Glob, and Task tool when exploring.'
run_case 'warning-only host tool phrases' 0 'WARN:' "$case_root"

case_root=$(new_root); make_skill "$case_root" valid-skill 'Use the relevant project command.'
run_case 'valid skill' 0 'PASS: 1 skills checked' "$case_root"

if [[ $failures -ne 0 ]]; then
  printf '%s\n' "$failures portability contract test(s) failed"
  exit 1
fi
printf '%s\n' 'All portability contract tests passed'
