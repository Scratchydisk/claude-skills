#!/usr/bin/env bash
set -u

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
INSTALLER_SOURCE="$ROOT_DIR/scripts/install-opencode.sh"
TMP_ROOT=$(mktemp -d)
trap 'rm -rf "$TMP_ROOT"' EXIT

failures=0

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

[[ -x $INSTALLER_SOURCE ]] || fail 'repository installer is directly executable'
set +e
direct_help_output=$("$INSTALLER_SOURCE" --help 2>&1)
direct_help_status=$?
set -e
[[ $direct_help_status -eq 0 && $direct_help_output == *'Usage:'* ]] || fail 'repository installer runs directly'

make_checkout() {
  local checkout=$1
  mkdir -p "$checkout/scripts" "$checkout/skills/alpha" "$checkout/skills/beta"
  printf '%s\n' alpha >"$checkout/skills/alpha/SKILL.md"
  printf '%s\n' beta >"$checkout/skills/beta/SKILL.md"
  cp "$INSTALLER_SOURCE" "$checkout/scripts/install-opencode.sh"
  chmod +x "$checkout/scripts/install-opencode.sh"
}

run_installer() {
  local checkout=$1 config_home=$2 mode=${3-} path_prefix=${4-}
  local stdout_file stderr_file status command_path=$PATH
  stdout_file=$(mktemp "$TMP_ROOT/stdout.XXXXXX")
  stderr_file=$(mktemp "$TMP_ROOT/stderr.XXXXXX")
  [[ -n $path_prefix ]] && command_path="$path_prefix:$command_path"
  set +e
  if [[ $mode == home ]]; then
    env -u XDG_CONFIG_HOME HOME="$config_home" PATH="$command_path" "$checkout/scripts/install-opencode.sh" >"$stdout_file" 2>"$stderr_file"
  else
    XDG_CONFIG_HOME="$config_home" PATH="$command_path" "$checkout/scripts/install-opencode.sh" ${mode:+"$mode"} >"$stdout_file" 2>"$stderr_file"
  fi
  status=$?
  RUN_OUTPUT=$(<"$stdout_file")
  RUN_ERROR=$(<"$stderr_file")
  RUN_STATUS=$status
}

assert_status() {
  local label=$1 expected=$2
  [[ $RUN_STATUS -eq $expected ]] || fail "$label (status $RUN_STATUS, expected $expected; output: $RUN_OUTPUT)"
}

assert_output() {
  local label=$1 text=$2
  grep -Fq "$text" <<<"$RUN_OUTPUT" || fail "$label (missing: $text; output: $RUN_OUTPUT)"
}

assert_error() {
  local label=$1 text=$2
  grep -Fq "$text" <<<"$RUN_ERROR" || fail "$label (missing: $text; error: $RUN_ERROR)"
}

assert_not_output() {
  local label=$1 text=$2
  if grep -Fq "$text" <<<"$RUN_OUTPUT"; then
    fail "$label (unexpected stdout: $RUN_OUTPUT)"
  fi
}

assert_not_error() {
  local label=$1 text=$2
  if grep -Fq "$text" <<<"$RUN_ERROR"; then
    fail "$label (unexpected stderr: $RUN_ERROR)"
  fi
}

assert_link_target() {
  local label=$1 link=$2 target=$3 resolved
  [[ -L $link ]] || { fail "$label (not a symlink: $link)"; return; }
  resolved=$(cd "$(dirname "$link")" && cd -P "$(dirname "$(readlink "$link")")" 2>/dev/null && pwd -P)/$(basename "$(readlink "$link")")
  [[ $resolved == "$target" ]] || fail "$label (resolved $resolved, expected $target)"
}

case_dir="$TMP_ROOT/fresh"
make_checkout "$case_dir/checkout"
run_installer "$case_dir/checkout" "$case_dir/config"
assert_status 'fresh install succeeds' 0
for id in alpha beta; do
  destination="$case_dir/config/opencode/skills/$id"
  assert_output "fresh install reports LINK for $id" "LINK: $id: $destination"
  assert_link_target "fresh install links $id to canonical skill" "$destination" "$case_dir/checkout/skills/$id"
done
run_installer "$case_dir/checkout" "$case_dir/config"
assert_status 'second install succeeds' 0
for id in alpha beta; do
  assert_output "second install reports KEEP for $id" "KEEP: $id: $case_dir/config/opencode/skills/$id"
done

case_dir="$TMP_ROOT/managed-links"
make_checkout "$case_dir/checkout"
destination_dir="$case_dir/config/opencode/skills"
mkdir -p "$destination_dir"
ln -s "../../../checkout/skills/alpha" "$destination_dir/alpha"
ln -s "$case_dir/checkout/skills/beta" "$destination_dir/beta"
run_installer "$case_dir/checkout" "$case_dir/config"
assert_status 'managed relative and absolute links succeed' 0
assert_output 'relative managed link is kept' "KEEP: alpha: $destination_dir/alpha"
assert_output 'absolute managed link is kept' "KEEP: beta: $destination_dir/beta"
assert_link_target 'relative managed link resolves correctly' "$destination_dir/alpha" "$case_dir/checkout/skills/alpha"
assert_link_target 'absolute managed link resolves correctly' "$destination_dir/beta" "$case_dir/checkout/skills/beta"

for collision in foreign-link broken-link file directory; do
  case_dir="$TMP_ROOT/$collision"
  make_checkout "$case_dir/checkout"
  destination_dir="$case_dir/config/opencode/skills"
  mkdir -p "$destination_dir"
  case $collision in
    foreign-link) ln -s "$case_dir/checkout/skills/beta" "$destination_dir/alpha" ;;
    broken-link) ln -s "$case_dir/missing" "$destination_dir/alpha" ;;
    file) : >"$destination_dir/alpha" ;;
    directory) mkdir "$destination_dir/alpha" ;;
  esac
  run_installer "$case_dir/checkout" "$case_dir/config"
  assert_status "$collision collision exits 1" 1
  assert_error "$collision collision is reported on stderr" "COLLISION: alpha: $destination_dir/alpha"
  assert_not_output "$collision collision is not reported on stdout" "COLLISION: alpha: $destination_dir/alpha"
  case $collision in
    foreign-link|broken-link) [[ -L $destination_dir/alpha ]] || fail "$collision collision preserves symlink" ;;
    file) [[ -f $destination_dir/alpha && ! -L $destination_dir/alpha ]] || fail 'file collision preserves file' ;;
    directory) [[ -d $destination_dir/alpha && ! -L $destination_dir/alpha ]] || fail 'directory collision preserves directory' ;;
  esac
done

case_dir="$TMP_ROOT/home fallback with spaces"
make_checkout "$case_dir/checkout with spaces"
run_installer "$case_dir/checkout with spaces" "$case_dir/home with spaces" home
assert_status 'HOME fallback succeeds with spaces' 0
assert_link_target 'HOME fallback uses .config with spaces' "$case_dir/home with spaces/.config/opencode/skills/alpha" "$case_dir/checkout with spaces/skills/alpha"

case_dir="$TMP_ROOT/dry-run"
make_checkout "$case_dir/checkout"
run_installer "$case_dir/checkout" "$case_dir/config" --dry-run
assert_status 'dry run succeeds' 0
for id in alpha beta; do
  assert_output "dry run reports WOULD_LINK for $id" "WOULD_LINK: $id: $case_dir/config/opencode/skills/$id"
done
[[ ! -e $case_dir/config ]] || fail 'dry run does not create configuration directories or links'

case_dir="$TMP_ROOT/link failure"
make_checkout "$case_dir/checkout"
mkdir -p "$case_dir/bin"
printf '%s\n' '#!/usr/bin/env bash' 'exit 1' >"$case_dir/bin/ln"
chmod +x "$case_dir/bin/ln"
run_installer "$case_dir/checkout" "$case_dir/config" '' "$case_dir/bin"
assert_status 'link creation failure exits 1' 1
assert_error 'link creation failure is reported on stderr' "ERROR: alpha: cannot create link: $case_dir/config/opencode/skills/alpha"
assert_not_output 'link creation failure does not report LINK' "LINK: alpha: $case_dir/config/opencode/skills/alpha"
assert_not_error 'link creation failure does not report LINK' "LINK: alpha: $case_dir/config/opencode/skills/alpha"
[[ ! -e $case_dir/config/opencode/skills/alpha ]] || fail 'link creation failure does not create alpha link'

if [[ $failures -ne 0 ]]; then
  printf '%s\n' "$failures OpenCode installer contract test(s) failed"
  exit 1
fi
printf '%s\n' 'All OpenCode installer contract tests passed'
