#!/usr/bin/env bash
set -euo pipefail

DEFAULT_REPO_URL="https://github.com/wind22/Skill_Collection.git"
DEFAULT_INSTALL_ROOT="${SKILL_COLLECTION_HOME:-${HOME}/.skill-collection}"

REPO_URL="${DEFAULT_REPO_URL}"
REF=""
INSTALL_ROOT="${DEFAULT_INSTALL_ROOT}"
UPDATE="1"
PASSTHROUGH=()

usage() {
  cat <<'EOF'
Skill Collection bootstrap

This is a compatibility entrypoint. The real installer is ./setup.

Usage:
  ./install.sh --host auto
  curl -fsSL https://raw.githubusercontent.com/wind22/Skill_Collection/main/install.sh \
    | bash -s -- --host auto

Bootstrap options:
  --repo URL             Git repository to clone. Default: wind22/Skill_Collection.
  --ref REF              Git ref to checkout.
  --install-root DIR     Persistent clone location. Default: ~/.skill-collection.
  --no-update            Do not pull when the clone already exists.

All other options are passed to ./setup.
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

script_dir() {
  local source="${BASH_SOURCE[0]:-$0}"

  if [[ -n "${source}" && -f "${source}" ]]; then
    cd "$(dirname "${source}")" >/dev/null 2>&1
    pwd -P
  else
    pwd -P
  fi
}

LOCAL_DIR="$(script_dir)"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || die "--repo requires a git URL"
      REPO_URL="$2"
      shift 2
      ;;
    --repo=*)
      REPO_URL="${1#--repo=}"
      shift
      ;;
    --ref)
      [[ $# -ge 2 ]] || die "--ref requires a git ref"
      REF="$2"
      shift 2
      ;;
    --ref=*)
      REF="${1#--ref=}"
      shift
      ;;
    --install-root)
      [[ $# -ge 2 ]] || die "--install-root requires a directory"
      INSTALL_ROOT="$2"
      shift 2
      ;;
    --install-root=*)
      INSTALL_ROOT="${1#--install-root=}"
      shift
      ;;
    --no-update)
      UPDATE="0"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      PASSTHROUGH+=("$1")
      shift
      ;;
  esac
done

if [[ -x "${LOCAL_DIR}/setup" && -d "${LOCAL_DIR}/skills" ]]; then
  exec "${LOCAL_DIR}/setup" "${PASSTHROUGH[@]}"
fi

command -v git >/dev/null 2>&1 || die "git is required to clone ${REPO_URL}"

if [[ -d "${INSTALL_ROOT}/.git" ]]; then
  if [[ "${UPDATE}" == "1" ]]; then
    printf 'Updating %s...\n' "${INSTALL_ROOT}"
    if [[ -n "${REF}" ]]; then
      git -C "${INSTALL_ROOT}" fetch --depth 1 origin "${REF}"
      git -C "${INSTALL_ROOT}" checkout --detach FETCH_HEAD
    else
      git -C "${INSTALL_ROOT}" pull --ff-only
    fi
  fi
elif [[ -e "${INSTALL_ROOT}" ]]; then
  die "${INSTALL_ROOT} exists but is not a git checkout"
else
  printf 'Cloning %s -> %s...\n' "${REPO_URL}" "${INSTALL_ROOT}"
  mkdir -p "$(dirname "${INSTALL_ROOT}")"
  if [[ -n "${REF}" ]]; then
    git clone --single-branch --depth 1 --branch "${REF}" "${REPO_URL}" "${INSTALL_ROOT}"
  else
    git clone --single-branch --depth 1 "${REPO_URL}" "${INSTALL_ROOT}"
  fi
fi

[[ -x "${INSTALL_ROOT}/setup" ]] || die "setup not found or not executable at ${INSTALL_ROOT}/setup"

exec "${INSTALL_ROOT}/setup" "${PASSTHROUGH[@]}"
