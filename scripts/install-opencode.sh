#!/usr/bin/env bash
set -u

usage() {
  printf '%s\n' 'Usage: install-opencode.sh [--dry-run|--help]'
}

dry_run=0
case $# in
  0) ;;
  1)
    case $1 in
      --dry-run) dry_run=1 ;;
      --help) usage; exit 0 ;;
      *)
        printf 'ERROR: unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
    esac
    ;;
  *)
    printf 'ERROR: unknown argument: %s\n' "$1" >&2
    usage >&2
    exit 2
    ;;
esac

script_dir=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
root_dir=$(cd -P "$script_dir/.." && pwd -P)
skills_dir="$root_dir/skills"

if [[ ! -d $skills_dir ]]; then
  printf 'ERROR: missing skills directory: %s\n' "$skills_dir" >&2
  exit 1
fi

config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
destination_dir="$config_home/opencode/skills"
failed=0

resolve_link_directory() {
  local link=$1 target link_dir
  target=$(readlink "$link") || return 1
  if [[ $target == /* ]]; then
    cd -P "$target" 2>/dev/null && pwd -P
    return
  fi
  link_dir=$(cd -P "$(dirname "$link")" 2>/dev/null && pwd -P) || return 1
  cd -P "$link_dir/$target" 2>/dev/null && pwd -P
}

while IFS= read -r -d '' skill_dir; do
  id=$(basename "$skill_dir")
  canonical_target=$(cd -P "$skill_dir" && pwd -P)
  destination="$destination_dir/$id"

  if [[ -L $destination ]]; then
    resolved_target=$(resolve_link_directory "$destination") || resolved_target=
    if [[ $resolved_target == "$canonical_target" ]]; then
      printf 'KEEP: %s: %s\n' "$id" "$destination"
    else
      printf 'COLLISION: %s: %s\n' "$id" "$destination" >&2
      failed=1
    fi
  elif [[ -e $destination ]]; then
    printf 'COLLISION: %s: %s\n' "$id" "$destination" >&2
    failed=1
  elif [[ $dry_run -eq 1 ]]; then
    printf 'WOULD_LINK: %s: %s\n' "$id" "$destination"
  else
    if ! mkdir -p "$destination_dir"; then
      printf 'ERROR: cannot create destination directory: %s\n' "$destination_dir" >&2
      exit 1
    fi
    ln -s "$canonical_target" "$destination"
    printf 'LINK: %s: %s\n' "$id" "$destination"
  fi
done < <(find -P "$skills_dir" -mindepth 1 -maxdepth 1 -type d -print0)

exit "$failed"
