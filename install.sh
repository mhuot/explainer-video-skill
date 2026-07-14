#!/usr/bin/env bash
# Install the explainer-video skill into Microsoft Scout's skills directory.
#   ./install.sh            → ~/.copilot/skills/explainer-video/   (this machine)
#   ./install.sh --synced   → ~/.copilot/m-skills/explainer-video/ (cloud-synced)
set -euo pipefail

SKILL_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${1:-}" == "--synced" ]]; then
  SKILL_TARGET_DIR="${HOME}/.copilot/m-skills/explainer-video"
else
  SKILL_TARGET_DIR="${HOME}/.copilot/skills/explainer-video"
fi

mkdir -p "${SKILL_TARGET_DIR}"
cp "${SKILL_SOURCE_DIR}/SKILL.md" "${SKILL_TARGET_DIR}/SKILL.md"

echo "Installed: ${SKILL_TARGET_DIR}/SKILL.md"
echo "Microsoft Scout discovers it automatically in future conversations."
echo "Verify tooling with:"
echo '  export PATH="$HOME/ffbuild:$PATH"'
echo '  node ~/hyperframes/packages/cli/dist/cli.js doctor'
