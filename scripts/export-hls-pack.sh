#!/usr/bin/env bash
set -euo pipefail

source_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_skill="${source_root}/skills/explainer-video"
destination_root="${1:-${HOME}/hls-skills}"
destination_skill="${destination_root}/skills/explainer-video"

if [[ ! -f "${destination_skill}/skill.yaml" ]]; then
  echo "HLS explainer-video package not found: ${destination_skill}" >&2
  exit 1
fi

# The HLS package intentionally maintains Microsoft-specific SKILL.md,
# README.md, setup.md, metadata, and branded assets. Sync only shared runtime
# resources whose behavior must remain identical across distributions.
for file in \
  scripts/engine.sh \
  scripts/new_project.sh \
  scripts/project_check.sh; do
  install -m 0755 "${source_skill}/${file}" "${destination_skill}/${file}"
done
for file in \
  scripts/engine.ps1 \
  scripts/new_project.ps1 \
  scripts/project_check.ps1 \
  scripts/tts_pronounce.py; do
  install -m 0644 \
    "${source_skill}/${file}" \
    "${destination_skill}/${file}"
done

source_version="$(
  awk '/^  version:/{gsub(/"/, "", $2); print $2; exit}' "${source_skill}/SKILL.md"
)"
hls_version="$(
  awk '/^version:/{print $2; exit}' "${destination_skill}/skill.yaml"
)"
hls_skill_version="$(
  awk '/^  version:/{gsub(/"/, "", $2); print $2; exit}' \
    "${destination_skill}/SKILL.md"
)"
if [[ "${source_version}" != "${hls_version}" || "${hls_version}" != "${hls_skill_version}" ]]; then
  echo "Version mismatch: source ${source_version}, HLS manifest ${hls_version}, HLS skill ${hls_skill_version}" >&2
  echo "Update the Microsoft-tailored SKILL.md and skill.yaml before publishing." >&2
  exit 1
fi

echo "Synchronized shared explainer-video runtime assets to ${destination_skill}"
echo "Review HLS-specific SKILL.md, setup.md, README.md, tts_generate.py, and skill.yaml separately."
