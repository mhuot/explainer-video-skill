#!/usr/bin/env bash
# Install the explainer-video skill and its resources into Scout's skills directory.
#   ./install.sh            → ~/.copilot/skills/explainer-video/   (this machine)
#   ./install.sh --synced   → ~/.copilot/m-skills/explainer-video/ (cloud-synced)
set -euo pipefail

SKILL_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
  "")
    SKILL_TARGET_DIR="${HOME}/.copilot/skills/explainer-video"
    ;;
  --synced)
    SKILL_TARGET_DIR="${HOME}/.copilot/m-skills/explainer-video"
    ;;
  *)
    echo "Usage: $0 [--synced]" >&2
    exit 2
    ;;
esac

mkdir -p "${SKILL_TARGET_DIR}/templates" "${SKILL_TARGET_DIR}/docs"
if [[ "${SKILL_SOURCE_DIR}" != "${SKILL_TARGET_DIR}" ]]; then
  install -m 0644 "${SKILL_SOURCE_DIR}/SKILL.md" "${SKILL_TARGET_DIR}/SKILL.md"
  install -m 0644 "${SKILL_SOURCE_DIR}/README.md" "${SKILL_TARGET_DIR}/README.md"
  install -m 0644 "${SKILL_SOURCE_DIR}/LICENSE" "${SKILL_TARGET_DIR}/LICENSE"
  install -m 0644 \
    "${SKILL_SOURCE_DIR}/templates/composition-skeleton.html" \
    "${SKILL_SOURCE_DIR}/templates/decision-log.json" \
    "${SKILL_SOURCE_DIR}/templates/tts_generate.py" \
    "${SKILL_TARGET_DIR}/templates/"
  install -m 0644 "${SKILL_SOURCE_DIR}/docs/method.md" "${SKILL_TARGET_DIR}/docs/"
fi

echo "Installed skill and resources: ${SKILL_TARGET_DIR}"
echo "Microsoft Scout discovers it automatically in future conversations."
echo "For portable template commands, set:"
printf '  export EXPLAINER_VIDEO_SKILL_DIR=%q\n' "${SKILL_TARGET_DIR}"
echo "Verify tooling with:"
echo '  export PATH="${FFMPEG_BUILD_DIR:-$HOME/ffbuild}:$PATH"'
echo '  node "${HYPERFRAMES_DIR:-$HOME/hyperframes}/packages/cli/dist/cli.js" doctor'
