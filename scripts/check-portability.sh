#!/usr/bin/env bash
set -u

usage() {
  printf '%s\n' 'Usage: check-portability.sh [--root PATH|--help]'
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
root_dir=$(cd "$script_dir/.." && pwd -P)

case $# in
  0) ;;
  1)
    if [[ $1 == --help ]]; then
      usage
      exit 0
    fi
    if [[ $1 == --root ]]; then
      printf '%s\n' 'ERROR: --root requires a path' >&2
      usage >&2
      exit 2
    fi
    printf 'ERROR: unknown argument: %s\n' "$1" >&2
    usage >&2
    exit 2
    ;;
  2)
    if [[ $1 != --root ]]; then
      printf 'ERROR: unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2
    fi
    if [[ ! -d $2 ]]; then
      printf 'ERROR: --root is not a directory: %s\n' "$2" >&2
      exit 2
    fi
    root_dir=$(cd "$2" && pwd -P)
    ;;
  *)
    if [[ $1 == --root ]]; then
      printf '%s\n' 'ERROR: --root requires a path' >&2
    else
      printf 'ERROR: unknown argument: %s\n' "$1" >&2
    fi
    usage >&2
    exit 2
    ;;
esac

skills_dir="$root_dir/skills"
if [[ ! -d $skills_dir ]]; then
  printf 'ERROR: missing skills directory: %s\n' "$skills_dir" >&2
  exit 1
fi

errors=0
skill_count=0

error() {
  printf 'ERROR: %s: %s\n' "$1" "$2"
  errors=1
}

warn() {
  printf 'WARN: %s: %s\n' "$1" "$2"
}

check_frontmatter() {
  local id=$1 file=$2 line name= description= in_frontmatter=0 closed_frontmatter=0

  while IFS= read -r line || [[ -n $line ]]; do
    if [[ $in_frontmatter -eq 0 ]]; then
      [[ $line == '---' ]] || break
      in_frontmatter=1
      continue
    fi
    if [[ $line == '---' ]]; then
      closed_frontmatter=1
      break
    fi
    if [[ $line =~ ^name:[[:space:]]*(.*)$ ]]; then
      name=${BASH_REMATCH[1]}
    elif [[ $line =~ ^description:[[:space:]]*(.*)$ ]]; then
      description=${BASH_REMATCH[1]}
    fi
  done <"$file"

  [[ $in_frontmatter -eq 0 || $closed_frontmatter -eq 1 ]] || error "$id" 'unclosed YAML frontmatter'
  [[ -n $name ]] || error "$id" 'missing name'
  [[ -n $description ]] || error "$id" 'missing description'
  if [[ -n $name ]]; then
    if [[ ${#name} -gt 64 || ! $name =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
      error "$id" 'invalid OpenCode name'
    fi
    [[ $name == "$id" ]] || error "$id" 'name does not match directory'
  fi
}

check_forbidden_paths() {
  local id=$1 file=$2 path line line_number=0
  local paths=(
    '.claude/skills/' '~/.claude/skills/' '.codex/skills/'
    '~/.codex/skills/' '.opencode/skills/' '~/.config/opencode/skills/'
  )
  while IFS= read -r line || [[ -n $line ]]; do
    line_number=$((line_number + 1))
    for path in "${paths[@]}"; do
      [[ $line == *"$path"* ]] && error "$id" "forbidden runtime path $path at $file:$line_number"
    done
  done <"$file"
}

check_references() {
  local id=$1 skill_dir=$2 file=$3 line_number=0 line token reference
  while IFS= read -r line || [[ -n $line ]]; do
    line_number=$((line_number + 1))
    while IFS= read -r token || [[ -n $token ]]; do
      case $token in
        references/*|scripts/*)
          reference=$token
          while [[ $reference == *. ]]; do
            reference=${reference%.}
          done
          [[ -f $skill_dir/$reference ]] || error "$id" "missing referenced file $reference at $file:$line_number"
          ;;
      esac
    done < <(printf '%s' "$line" | tr -c '[:alnum:]_./-' '\n')
  done <"$file"
}

check_host_wording() {
  local id=$1 file=$2 phrase line line_number=0 in_frontmatter=0 first_line=1
  local phrases=('Claude Code tool' 'Read tool' 'Edit tool' 'Glob' 'Task tool')
  while IFS= read -r line || [[ -n $line ]]; do
    line_number=$((line_number + 1))
    if [[ $first_line -eq 1 && $line == '---' ]]; then
      in_frontmatter=1
      first_line=0
      continue
    fi
    first_line=0
    if [[ $in_frontmatter -eq 1 ]]; then
      [[ $line == '---' ]] && in_frontmatter=0
      continue
    fi
    for phrase in "${phrases[@]}"; do
      [[ $line == *"$phrase"* ]] && warn "$id" "host-specific wording $phrase at $file:$line_number"
    done
  done <"$file"
}

while IFS= read -r -d '' skill_dir; do
  skill_count=$((skill_count + 1))
  id=$(basename "$skill_dir")
  skill_file="$skill_dir/SKILL.md"
  if [[ ! -f $skill_file ]]; then
    error "$id" 'missing SKILL.md'
    continue
  fi
  check_frontmatter "$id" "$skill_file"
  check_forbidden_paths "$id" "$skill_file"
  check_references "$id" "$skill_dir" "$skill_file"
  check_host_wording "$id" "$skill_file"
done < <(find -P "$skills_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

if [[ $errors -ne 0 ]]; then
  exit 1
fi

printf 'PASS: %s skills checked\n' "$skill_count"
