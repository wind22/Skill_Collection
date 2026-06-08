#!/usr/bin/env bash
set -euo pipefail

SOURCE="prompt"
DEST_DIR=""
SELECT_ALL="0"
LIST_ONLY="0"
ASSUME_YES="0"
OVERWRITE="no"
REQUESTED_SKILLS=()

usage() {
  cat <<'EOF'
Import locally installed skills into this collection.

Usage:
  ./scripts/import-local-skills.sh
  ./scripts/import-local-skills.sh --from codex --all
  ./scripts/import-local-skills.sh --from claude --skill my-skill

Options:
  --from codex|claude|DIR  Source skills directory. Default: interactive prompt.
  --dest DIR               Destination collection skills directory. Default: ../skills.
  --all                    Import every source skill.
  --skill NAME             Import one skill. Can be repeated.
  --list                   List source skills and exit.
  --yes                    Accept defaults for prompts.
  --overwrite              Replace existing collection skills after backing them up.
  --skip-existing          Skip skills that already exist. This is the default.
  -h, --help               Show this help.
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

info() {
  printf '%s\n' "$*"
}

has_tty() {
  [[ -r /dev/tty && -w /dev/tty ]]
}

prompt_read() {
  local prompt="$1"
  local reply=""

  if has_tty; then
    printf '%s' "${prompt}" > /dev/tty
    IFS= read -r reply < /dev/tty
  else
    printf '%s' "${prompt}" >&2
    IFS= read -r reply
  fi

  printf '%s' "${reply}"
}

script_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
  pwd
}

repo_root() {
  cd "$(script_dir)/.." >/dev/null 2>&1
  pwd
}

append_skill() {
  [[ -n "$1" ]] || die "--skill requires a non-empty name"
  REQUESTED_SKILLS+=("$1")
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --from)
      [[ $# -ge 2 ]] || die "--from requires codex, claude, or a directory"
      SOURCE="$2"
      shift 2
      ;;
    --dest)
      [[ $# -ge 2 ]] || die "--dest requires a directory"
      DEST_DIR="$2"
      shift 2
      ;;
    --all)
      SELECT_ALL="1"
      shift
      ;;
    --skill)
      [[ $# -ge 2 ]] || die "--skill requires a name"
      append_skill "$2"
      shift 2
      ;;
    --list)
      LIST_ONLY="1"
      shift
      ;;
    --yes|-y)
      ASSUME_YES="1"
      shift
      ;;
    --overwrite)
      OVERWRITE="yes"
      shift
      ;;
    --skip-existing)
      OVERWRITE="no"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        append_skill "$1"
        shift
      done
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      append_skill "$1"
      shift
      ;;
  esac
done

DEST_DIR="${DEST_DIR:-$(repo_root)/skills}"

resolve_source() {
  local answer=""

  case "${SOURCE}" in
    codex)
      printf '%s' "${CODEX_SKILLS_DIR:-${CODEX_HOME:-${HOME}/.codex}/skills}"
      return
      ;;
    claude)
      printf '%s' "${CLAUDE_SKILLS_DIR:-${CLAUDE_HOME:-${HOME}/.claude}/skills}"
      return
      ;;
    prompt)
      if [[ "${ASSUME_YES}" == "1" ]]; then
        printf '%s' "${CODEX_SKILLS_DIR:-${CODEX_HOME:-${HOME}/.codex}/skills}"
        return
      fi

      info "Import source:"
      info "  1. Codex       ${CODEX_SKILLS_DIR:-${CODEX_HOME:-${HOME}/.codex}/skills}"
      info "  2. Claude Code ${CLAUDE_SKILLS_DIR:-${CLAUDE_HOME:-${HOME}/.claude}/skills}"
      answer="$(prompt_read "Choose source [1]: ")"
      answer="${answer:-1}"
      case "${answer}" in
        1|codex|Codex) printf '%s' "${CODEX_SKILLS_DIR:-${CODEX_HOME:-${HOME}/.codex}/skills}" ;;
        2|claude|Claude) printf '%s' "${CLAUDE_SKILLS_DIR:-${CLAUDE_HOME:-${HOME}/.claude}/skills}" ;;
        *) die "unknown source choice: ${answer}" ;;
      esac
      return
      ;;
    *)
      printf '%s' "${SOURCE}"
      return
      ;;
  esac
}

SOURCE_DIR="$(resolve_source)"
[[ -d "${SOURCE_DIR}" ]] || die "source skills directory not found: ${SOURCE_DIR}"

SKILL_NAMES=()
SKILL_PATHS=()
SKILL_DESCRIPTIONS=()

read_description() {
  local file="$1"
  awk '
    NR == 1 && $0 == "---" { in_frontmatter = 1; next }
    in_frontmatter && $0 == "---" { exit }
    capture_description {
      if ($0 ~ /^[[:space:]]+/) {
        line = $0
        sub(/^[[:space:]]+/, "", line)
        if (line != "") {
          description = description ? description " " line : line
        }
        next
      }
      print description
      printed = 1
      exit
    }
    in_frontmatter && /^description:[[:space:]]*/ {
      sub(/^description:[[:space:]]*/, "")
      gsub(/^"/, "")
      gsub(/"$/, "")
      if ($0 == ">" || $0 == "|") {
        capture_description = 1
        next
      }
      print
      printed = 1
      exit
    }
    END {
      if (capture_description && description != "" && !printed) {
        print description
      }
    }
  ' "$file"
}

discover_skills() {
  local dir=""
  local name=""
  local skill_md=""
  local description=""

  for dir in "${SOURCE_DIR}"/*; do
    [[ -d "${dir}" ]] || continue
    name="$(basename "${dir}")"
    [[ "${name}" == .* || "${name}" == _* ]] && continue
    skill_md="${dir}/SKILL.md"
    [[ -f "${skill_md}" ]] || continue
    description="$(read_description "${skill_md}")"
    SKILL_NAMES+=("${name}")
    SKILL_PATHS+=("${dir}")
    SKILL_DESCRIPTIONS+=("${description:-No description}")
  done
}

print_skills() {
  local i=0

  if [[ "${#SKILL_NAMES[@]}" -eq 0 ]]; then
    info "No skills found in ${SOURCE_DIR}."
    return
  fi

  info "Skills from ${SOURCE_DIR}:"
  for ((i = 0; i < ${#SKILL_NAMES[@]}; i++)); do
    printf '  %2d. %-28s %s\n' "$((i + 1))" "${SKILL_NAMES[$i]}" "${SKILL_DESCRIPTIONS[$i]}"
  done
}

find_skill_index() {
  local query="$1"
  local i=0

  if [[ "${query}" =~ ^[0-9]+$ ]]; then
    if [[ "${query}" -ge 1 && "${query}" -le "${#SKILL_NAMES[@]}" ]]; then
      printf '%s' "$((query - 1))"
      return 0
    fi
  fi

  for ((i = 0; i < ${#SKILL_NAMES[@]}; i++)); do
    if [[ "${SKILL_NAMES[$i]}" == "${query}" ]]; then
      printf '%s' "${i}"
      return 0
    fi
  done

  return 1
}

array_contains() {
  local needle="$1"
  shift
  local item=""

  for item in "$@"; do
    [[ "${item}" == "${needle}" ]] && return 0
  done

  return 1
}

SELECTED_INDEXES=()

add_selected_index() {
  local index="$1"

  if ! array_contains "${index}" "${SELECTED_INDEXES[@]:-}"; then
    SELECTED_INDEXES+=("${index}")
  fi
}

select_all_skills() {
  local i=0
  SELECTED_INDEXES=()
  for ((i = 0; i < ${#SKILL_NAMES[@]}; i++)); do
    SELECTED_INDEXES+=("${i}")
  done
}

select_requested_skills() {
  local requested=""
  local index=""

  for requested in "${REQUESTED_SKILLS[@]}"; do
    if ! index="$(find_skill_index "${requested}")"; then
      die "skill not found: ${requested}"
    fi
    add_selected_index "${index}"
  done
}

select_interactive_skills() {
  local answer=""
  local normalized=""
  local part=""
  local index=""
  local parts=()

  print_skills
  [[ "${#SKILL_NAMES[@]}" -gt 0 ]] || exit 0

  answer="$(prompt_read "Choose skills by number/name, comma separated, or 'all': ")"
  answer="${answer:-all}"

  if [[ "${answer}" == "a" || "${answer}" == "A" || "${answer}" == "all" || "${answer}" == "ALL" || "${answer}" == "*" ]]; then
    select_all_skills
    return
  fi

  normalized="$(printf '%s' "${answer}" | tr ' ' ',')"
  IFS=',' read -r -a parts <<< "${normalized}"

  for part in "${parts[@]}"; do
    [[ -n "${part}" ]] || continue
    if ! index="$(find_skill_index "${part}")"; then
      die "skill not found: ${part}"
    fi
    add_selected_index "${index}"
  done

  [[ "${#SELECTED_INDEXES[@]}" -gt 0 ]] || die "no skills selected"
}

copy_one() {
  local skill_index="$1"
  local name=""
  local src=""
  local dest=""
  local backup=""
  local stamp=""

  name="${SKILL_NAMES[$skill_index]}"
  src="${SKILL_PATHS[$skill_index]}"
  dest="${DEST_DIR}/${name}"

  if [[ -e "${dest}" ]]; then
    if [[ "${OVERWRITE}" != "yes" ]]; then
      printf 'Skip %-28s -> %s (already exists)\n' "${name}" "${dest}"
      return
    fi

    stamp="$(date +%Y%m%d%H%M%S)"
    backup="${dest}.backup.${stamp}"
    mv "${dest}" "${backup}"
  fi

  mkdir -p "${dest}"
  cp -R "${src}/." "${dest}/"
  printf 'Imported %-26s -> %s\n' "${name}" "${dest}"
  if [[ -n "${backup}" ]]; then
    printf '  Backup: %s\n' "${backup}"
  fi
}

discover_skills

if [[ "${LIST_ONLY}" == "1" ]]; then
  print_skills
  exit 0
fi

[[ "${#SKILL_NAMES[@]}" -gt 0 ]] || die "no skills found in ${SOURCE_DIR}"

if [[ "${SELECT_ALL}" == "1" ]]; then
  select_all_skills
elif [[ "${#REQUESTED_SKILLS[@]}" -gt 0 ]]; then
  select_requested_skills
else
  select_interactive_skills
fi

mkdir -p "${DEST_DIR}"
info ""
info "Importing ${#SELECTED_INDEXES[@]} skill(s) into ${DEST_DIR}."

for index in "${SELECTED_INDEXES[@]}"; do
  copy_one "${index}"
done

info ""
info "Done. Review changes, commit, and push this repository when ready."
