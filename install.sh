#!/usr/bin/env bash
# Install, uninstall, or version-check the explainer-video skill.
#
#   ./install.sh                           → install to all three default targets
#   ./install.sh --claude                  → ~/.claude/skills/explainer-video/
#   ./install.sh --copilot                 → ~/.copilot/skills/explainer-video/
#   ./install.sh --antigravity             → ~/.gemini/antigravity/global_skills/explainer-video/
#   ./install.sh --synced                  → ~/.copilot/m-skills/explainer-video/
#
#   ./install.sh --uninstall               → remove from all three default targets
#   ./install.sh --uninstall --claude      → remove from Claude only
#
#   ./install.sh --version                 → print source version; compare against installed targets
#
# Target flags may be combined with each other and with --uninstall.
set -euo pipefail

SKILL_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="explainer-video"

CLAUDE_TARGET="${HOME}/.claude/skills/${SKILL_NAME}"
COPILOT_TARGET="${HOME}/.copilot/skills/${SKILL_NAME}"
ANTIGRAVITY_TARGET="${HOME}/.gemini/antigravity/global_skills/${SKILL_NAME}"
SYNCED_TARGET="${HOME}/.copilot/m-skills/${SKILL_NAME}"
DEFAULT_TARGETS=("${CLAUDE_TARGET}" "${COPILOT_TARGET}" "${ANTIGRAVITY_TARGET}")

SKILL_PACKAGE_DIR="${SKILL_SOURCE_DIR}/skills/${SKILL_NAME}"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
MODE=install
TARGETS=()

for arg in "$@"; do
  case "${arg}" in
    --uninstall)   MODE=uninstall ;;
    --version)     MODE=version ;;
    --claude)      TARGETS+=("${CLAUDE_TARGET}") ;;
    --copilot)     TARGETS+=("${COPILOT_TARGET}") ;;
    --antigravity) TARGETS+=("${ANTIGRAVITY_TARGET}") ;;
    --synced)      TARGETS+=("${SYNCED_TARGET}") ;;
    *)
      echo "Usage: $0 [--uninstall] [--version] [--claude] [--copilot] [--antigravity] [--synced]" >&2
      exit 2
      ;;
  esac
done

# Default to all three standard targets when no target flag is given (and not --version).
if [[ "${MODE}" != version && ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=("${DEFAULT_TARGETS[@]}")
fi

# ---------------------------------------------------------------------------
# Helper: read the version string from a SKILL.md frontmatter block.
# Prints the version, or "(unknown)" if not found.
# ---------------------------------------------------------------------------
read_version() {
  local skill_md="$1"
  local ver
  ver="$(awk '/^---$/{count++; next} count==1 && /^  version:/{print; exit}' "${skill_md}" \
        | sed 's/.*version:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}/\1/')"
  printf '%s' "${ver:-"(unknown)"}"
}

# ---------------------------------------------------------------------------
# --version
# ---------------------------------------------------------------------------
if [[ "${MODE}" == version ]]; then
  src_ver="$(read_version "${SKILL_PACKAGE_DIR}/SKILL.md")"
  printf 'source:  %s\n' "${src_ver}"
  for target_dir in "${DEFAULT_TARGETS[@]}" "${SYNCED_TARGET}"; do
    label="${target_dir/#"${HOME}"/"~"}"
    if [[ -f "${target_dir}/SKILL.md" ]]; then
      inst_ver="$(read_version "${target_dir}/SKILL.md")"
      if [[ "${inst_ver}" == "${src_ver}" ]]; then
        printf 'installed (%s): %s  ✓\n' "${label}" "${inst_ver}"
      else
        printf 'installed (%s): %s  ← update available (%s)\n' "${label}" "${inst_ver}" "${src_ver}"
      fi
    else
      printf 'not installed: %s\n' "${label}"
    fi
  done
  exit 0
fi

# ---------------------------------------------------------------------------
# --uninstall
# ---------------------------------------------------------------------------
uninstall_from_target() {
  local target_dir="$1"
  local label="${target_dir/#"${HOME}"/"~"}"
  if [[ -d "${target_dir}" ]]; then
    rm -rf "${target_dir}"
    echo "Uninstalled: ${label}"
  else
    echo "Not installed (skipping): ${label}"
  fi
}

# ---------------------------------------------------------------------------
# install
# ---------------------------------------------------------------------------
install_to_target() {
  local target_dir="$1"

  if [[ "${target_dir}" == "${SKILL_PACKAGE_DIR}" ]]; then
    echo "Error: install target must differ from the source checkout." >&2
    exit 1
  fi

  mkdir -p "${target_dir}/scripts" "${target_dir}/references" "${target_dir}/assets"
  install -m 0644 "${SKILL_PACKAGE_DIR}/SKILL.md" "${target_dir}/SKILL.md"
  install -m 0644 "${SKILL_SOURCE_DIR}/README.md" "${target_dir}/README.md"
  install -m 0644 "${SKILL_SOURCE_DIR}/LICENSE" "${target_dir}/LICENSE"
  install -m 0644 "${SKILL_PACKAGE_DIR}/scripts/tts_generate.py" "${target_dir}/scripts/"
  install -m 0755 "${SKILL_PACKAGE_DIR}/scripts/smoke_test.sh" "${target_dir}/scripts/"
  install -m 0644 \
    "${SKILL_PACKAGE_DIR}/assets/composition-skeleton.html" \
    "${SKILL_PACKAGE_DIR}/assets/decision-log.json" \
    "${target_dir}/assets/"
  install -m 0644 \
    "${SKILL_PACKAGE_DIR}/references/method.md" \
    "${SKILL_PACKAGE_DIR}/references/install.md" \
    "${target_dir}/references/"

  echo "Installed: ${target_dir}"
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
for target_dir in "${TARGETS[@]}"; do
  if [[ "${MODE}" == uninstall ]]; then
    uninstall_from_target "${target_dir}"
  else
    install_to_target "${target_dir}"
  fi
done

if [[ "${MODE}" == install ]]; then
  echo "For portable template commands, set EXPLAINER_VIDEO_SKILL_DIR to an installed directory, e.g.:"
  printf '  export EXPLAINER_VIDEO_SKILL_DIR=%q\n' "${TARGETS[0]}"
  echo "Verify tooling with:"
  # shellcheck disable=SC2016  # intentional: print literal $VAR syntax for the user to copy
  echo '  export PATH="${FFMPEG_BUILD_DIR:-$HOME/ffbuild}:$PATH"'
  # shellcheck disable=SC2016  # intentional: print literal $VAR syntax for the user to copy
  echo '  node "${HYPERFRAMES_DIR:-$HOME/hyperframes}/packages/cli/dist/cli.js" doctor'
fi
