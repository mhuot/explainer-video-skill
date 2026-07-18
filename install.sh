#!/usr/bin/env bash
# Install the explainer-video skill and its resources for one or more agents.
#
#   ./install.sh                 → all three agent targets below
#   ./install.sh --claude        → ~/.claude/skills/explainer-video/         (Claude Code)
#   ./install.sh --copilot       → ~/.copilot/skills/explainer-video/        (GitHub Copilot CLI + Scout)
#   ./install.sh --antigravity   → ~/.gemini/antigravity/global_skills/explainer-video/  (Google Gemini CLI)
#   ./install.sh --synced        → ~/.copilot/m-skills/explainer-video/      (Scout, cloud-synced across devices)
#
# Flags may be combined.
set -euo pipefail

SKILL_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="explainer-video"

CLAUDE_TARGET="${HOME}/.claude/skills/${SKILL_NAME}"
COPILOT_TARGET="${HOME}/.copilot/skills/${SKILL_NAME}"
ANTIGRAVITY_TARGET="${HOME}/.gemini/antigravity/global_skills/${SKILL_NAME}"
SYNCED_TARGET="${HOME}/.copilot/m-skills/${SKILL_NAME}"

TARGETS=()
if [[ $# -eq 0 ]]; then
  TARGETS=("${CLAUDE_TARGET}" "${COPILOT_TARGET}" "${ANTIGRAVITY_TARGET}")
else
  for install_flag in "$@"; do
    case "${install_flag}" in
      --claude)      TARGETS+=("${CLAUDE_TARGET}") ;;
      --copilot)     TARGETS+=("${COPILOT_TARGET}") ;;
      --antigravity) TARGETS+=("${ANTIGRAVITY_TARGET}") ;;
      --synced)      TARGETS+=("${SYNCED_TARGET}") ;;
      *)
        echo "Usage: $0 [--claude] [--copilot] [--antigravity] [--synced]" >&2
        exit 2
        ;;
    esac
  done
fi

install_to_target() {
  local target_dir="$1"

  if [[ "${target_dir}" == "${SKILL_SOURCE_DIR}" ]]; then
    echo "Error: install target must differ from the source checkout." >&2
    exit 1
  fi

  mkdir -p "${target_dir}/templates" "${target_dir}/docs"
  install -m 0644 "${SKILL_SOURCE_DIR}/SKILL.md" "${target_dir}/SKILL.md"
  install -m 0644 "${SKILL_SOURCE_DIR}/README.md" "${target_dir}/README.md"
  install -m 0644 "${SKILL_SOURCE_DIR}/LICENSE" "${target_dir}/LICENSE"
  install -m 0644 \
    "${SKILL_SOURCE_DIR}/templates/composition-skeleton.html" \
    "${SKILL_SOURCE_DIR}/templates/decision-log.json" \
    "${SKILL_SOURCE_DIR}/templates/tts_generate.py" \
    "${target_dir}/templates/"
  install -m 0644 "${SKILL_SOURCE_DIR}/docs/method.md" "${target_dir}/docs/"

  echo "Installed: ${target_dir}"
}

for target_dir in "${TARGETS[@]}"; do
  install_to_target "${target_dir}"
done

echo "For portable template commands, set EXPLAINER_VIDEO_SKILL_DIR to an installed directory, e.g.:"
printf '  export EXPLAINER_VIDEO_SKILL_DIR=%q\n' "${TARGETS[0]}"
echo "Verify tooling with:"
echo '  export PATH="${FFMPEG_BUILD_DIR:-$HOME/ffbuild}:$PATH"'
echo '  node "${HYPERFRAMES_DIR:-$HOME/hyperframes}/packages/cli/dist/cli.js" doctor'
