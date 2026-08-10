#!/usr/bin/env bash
# Smoke test for the explainer-video skill package.
#
# Always validates the package itself (structure, frontmatter, resource
# integrity). When HYPERFRAMES_DIR and FFMPEG_BUILD_DIR resolve to a built
# toolchain, additionally runs the HyperFrames validation ladder against the
# bundled composition skeleton.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1" >&2; FAILED=1; }

# --- Package structure -----------------------------------------------------
for required_file in \
  SKILL.md \
  scripts/tts_generate.py \
  scripts/tts_pronounce.py \
  scripts/engine.sh \
  scripts/engine.ps1 \
  scripts/new_project.sh \
  scripts/new_project.ps1 \
  scripts/project_check.sh \
  scripts/project_check.ps1 \
  assets/composition-skeleton.html \
  assets/spatial-components.html \
  assets/decision-log.json \
  references/method.md \
  references/install.md; do
  if [[ -f "${SKILL_DIR}/${required_file}" ]]; then
    pass "exists: ${required_file}"
  else
    fail "missing: ${required_file}"
  fi
done

# --- Project scaffolder ----------------------------------------------------
SCAFFOLD_ROOT="$(mktemp -d)"
trap 'rm -rf "${SCAFFOLD_ROOT}"' EXIT
printf 'window.gsap={};\n' >"${SCAFFOLD_ROOT}/gsap.min.js"
mkdir -p "${SCAFFOLD_ROOT}/bin"
cat >"${SCAFFOLD_ROOT}/bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
volume=""
while [[ $# -gt 0 ]]; do
  if [[ "$1" == "--volume" ]]; then
    volume="$2"
    shift 2
  else
    shift
  fi
done
[[ "${volume}" == *":/project" ]]
project_root="${volume%:/project}"
mkdir -p "${project_root}/video/assets"
printf 'window.gsap={};\n' >"${project_root}/video/assets/gsap.min.js"
EOF
chmod +x "${SCAFFOLD_ROOT}/bin/docker"
if PATH="${SCAFFOLD_ROOT}/bin:${PATH}" \
  "${SKILL_DIR}/scripts/new_project.sh" \
  "${SCAFFOLD_ROOT}/image-backed" >/dev/null; then
  pass "new_project.sh copies GSAP from the engine image"
else
  fail "new_project.sh failed to use image-bundled GSAP"
fi
if "${SKILL_DIR}/scripts/new_project.sh" --offline \
  --gsap-source "${SCAFFOLD_ROOT}/gsap.min.js" \
  "${SCAFFOLD_ROOT}/example" >/dev/null; then
  pass "new_project.sh creates an offline project"
else
  fail "new_project.sh failed"
fi
if "${SKILL_DIR}/scripts/project_check.sh" "${SCAFFOLD_ROOT}/example" >/dev/null; then
  pass "project_check.sh accepts the scaffold"
else
  fail "project_check.sh rejected the scaffold"
fi
for runner in tools/engine.sh tools/engine.ps1; do
  if [[ -f "${SCAFFOLD_ROOT}/example/${runner}" ]]; then
    pass "new_project.sh includes ${runner}"
  else
    fail "new_project.sh omitted ${runner}"
  fi
done
if "${SKILL_DIR}/scripts/new_project.sh" --offline \
  --gsap-source "${SCAFFOLD_ROOT}/gsap.min.js" \
  "${SCAFFOLD_ROOT}/example" >/dev/null 2>&1; then
  fail "new_project.sh overwrote a non-empty project"
else
  pass "new_project.sh refuses to overwrite"
fi
if "${SKILL_DIR}/scripts/new_project.sh" --offline \
  --gsap-source "${SCAFFOLD_ROOT}/missing-gsap.min.js" \
  "${SCAFFOLD_ROOT}/broken" >/dev/null 2>&1; then
  fail "new_project.sh accepted a missing GSAP source"
elif [[ -e "${SCAFFOLD_ROOT}/broken" ]]; then
  fail "new_project.sh left a partial project after failure"
else
  pass "new_project.sh cleans up failed scaffolds"
fi

if command -v pwsh >/dev/null; then
  POWERSHELL_ROOT="$(mktemp -d)"
  printf 'window.gsap={};\n' >"${POWERSHELL_ROOT}/gsap.min.js"
  mkdir -p "${POWERSHELL_ROOT}/bin"
  cp "${SCAFFOLD_ROOT}/bin/docker" "${POWERSHELL_ROOT}/bin/docker"
  if PATH="${POWERSHELL_ROOT}/bin:${PATH}" \
    pwsh -NoProfile -File "${SKILL_DIR}/scripts/new_project.ps1" \
    "${POWERSHELL_ROOT}/image-backed" >/dev/null; then
    pass "new_project.ps1 copies GSAP from the engine image"
  else
    fail "new_project.ps1 failed to use image-bundled GSAP"
  fi
  if pwsh -NoProfile -File "${SKILL_DIR}/scripts/new_project.ps1" \
    -Offline -GsapSource "${POWERSHELL_ROOT}/gsap.min.js" \
    "${POWERSHELL_ROOT}/example" >/dev/null; then
    pass "new_project.ps1 creates an offline project"
  else
    fail "new_project.ps1 failed"
  fi
  if pwsh -NoProfile -File "${SKILL_DIR}/scripts/project_check.ps1" \
    "${POWERSHELL_ROOT}/example" >/dev/null; then
    pass "project_check.ps1 accepts the scaffold"
  else
    fail "project_check.ps1 rejected the scaffold"
  fi
  rm -rf "${POWERSHELL_ROOT}"
else
  echo "SKIP pwsh not found — PowerShell scaffold checks skipped"
fi

if grep -R -q "cdn.jsdelivr.net" \
  "${SKILL_DIR}/SKILL.md" \
  "${SKILL_DIR}/scripts/new_project.sh" \
  "${SKILL_DIR}/scripts/new_project.ps1"; then
  fail "scaffolding still references jsDelivr"
else
  pass "scaffolding has no jsDelivr dependency"
fi
rm -rf "${SCAFFOLD_ROOT}"
trap - EXIT

# --- Frontmatter -----------------------------------------------------------
frontmatter="$(awk '/^---$/{count++; next} count==1' "${SKILL_DIR}/SKILL.md")"
if [[ "$(head -c 3 "${SKILL_DIR}/SKILL.md")" == "---" && "$(head -n 1 "${SKILL_DIR}/SKILL.md")" == "---" ]]; then
  pass "frontmatter starts at byte 0"
else
  fail "frontmatter must start at byte 0 with ---"
fi
if grep -q '^name: explainer-video$' <<<"${frontmatter}"; then
  pass "frontmatter name"
else
  fail "frontmatter name missing or not 'explainer-video'"
fi
if grep -q '^description: .' <<<"${frontmatter}"; then
  pass "frontmatter description"
else
  fail "frontmatter description missing"
fi

# --- Resource integrity ----------------------------------------------------
if command -v python3 >/dev/null; then
  if python3 -c "import json,sys; json.load(open('${SKILL_DIR}/assets/decision-log.json'))" 2>/dev/null; then
    pass "decision-log.json parses as JSON"
  else
    fail "decision-log.json is not valid JSON"
  fi
  if python3 -c "import ast; ast.parse(open('${SKILL_DIR}/scripts/tts_generate.py').read())" 2>/dev/null; then
    pass "tts_generate.py parses as Python"
  else
    fail "tts_generate.py has a syntax error"
  fi
  if python3 "${SKILL_DIR}/scripts/tts_pronounce.py" --self-test >/dev/null 2>&1; then
    pass "tts_pronounce.py self-test"
  else
    fail "tts_pronounce.py self-test failed"
  fi
else
  echo "SKIP python3 not found — JSON/Python parse checks skipped"
fi

# --- Vendored-copy sync ----------------------------------------------------
# scripts/tts_pronounce.py must stay byte-identical to the repo-level
# canonical. Standalone installs don't ship shared/, so skip there.
CANONICAL_PRONOUNCE="${SKILL_DIR}/../../shared/tts/tts_pronounce.py"
if [[ -f "${CANONICAL_PRONOUNCE}" ]]; then
  if cmp -s "${CANONICAL_PRONOUNCE}" "${SKILL_DIR}/scripts/tts_pronounce.py"; then
    pass "vendored tts_pronounce.py matches shared/tts canonical"
  else
    fail "vendored tts_pronounce.py differs from shared/tts/tts_pronounce.py — re-copy the canonical"
  fi
else
  echo "SKIP shared/tts canonical not present (standalone install) — sync check skipped"
fi

# Every skill-relative resource path mentioned in SKILL.md must exist.
# Only paths with a file extension count, and not ones inside a larger path
# (e.g. the project-layout `video/assets/...` examples).
while IFS= read -r referenced_path; do
  if [[ -e "${SKILL_DIR}/${referenced_path}" ]]; then
    pass "SKILL.md reference resolves: ${referenced_path}"
  else
    fail "SKILL.md references missing file: ${referenced_path}"
  fi
done < <(python3 -c "
import re
text = open('${SKILL_DIR}/SKILL.md').read()
anchored = re.findall(r'\\\$EXPLAINER_VIDEO_SKILL_DIR/((?:scripts|assets|references)/[\w.-]+\.[a-z]+)', text)
quoted = re.findall(r'\`((?:scripts|assets|references)/[\w.-]+\.[a-z]+)\`', text)
print('\n'.join(sorted(set(anchored + quoted))))
")

# --- Optional toolchain ladder --------------------------------------------
HYPERFRAMES_DIR="${HYPERFRAMES_DIR:-$HOME/hyperframes}"
FFMPEG_BUILD_DIR="${FFMPEG_BUILD_DIR:-$HOME/ffbuild}"
CLI_JS="${HYPERFRAMES_DIR}/packages/cli/dist/cli.js"

if [[ -f "${CLI_JS}" && -x "${FFMPEG_BUILD_DIR}/ffmpeg" ]]; then
  export PATH="${FFMPEG_BUILD_DIR}:${PATH}"
  WORKDIR="$(mktemp -d)"
  trap 'rm -rf "${WORKDIR}"' EXIT
  mkdir -p "${WORKDIR}/video/assets/audio"
  cp "${SKILL_DIR}/assets/composition-skeleton.html" "${WORKDIR}/video/index.html"
  # The skeleton references example narration WAVs; stub them with silence so
  # lint/check validate the composition itself, not the missing narration.
  while IFS= read -r wav_path; do
    "${FFMPEG_BUILD_DIR}/ffmpeg" -y -f lavfi -i anullsrc=r=24000:cl=mono \
      -t 1 -c:a pcm_s16le "${WORKDIR}/video/${wav_path}" >/dev/null 2>&1
  done < <(grep -oE 'assets/audio/[A-Za-z0-9._-]+\.wav' \
    "${SKILL_DIR}/assets/composition-skeleton.html" | sort -u)
  # Vendor GSAP as a real project would: prefer HyperFrames' local copy,
  # fall back to the CDN.
  gsap_local="$(find "${HYPERFRAMES_DIR}/node_modules" -path '*gsap/dist/gsap.min.js' 2>/dev/null | head -1)"
  if [[ -n "${gsap_local}" ]]; then
    cp "${gsap_local}" "${WORKDIR}/video/assets/gsap.min.js"
  fi
  if [[ ! -s "${WORKDIR}/video/assets/gsap.min.js" ]]; then
    echo "SKIP could not vendor gsap.min.js (offline?) — lint/check skipped"
    rm -rf "${WORKDIR}"; trap - EXIT
    WORKDIR=""
  fi
  if [[ -n "${WORKDIR}" ]]; then
  if (cd "${WORKDIR}/video" && node "${CLI_JS}" lint >/dev/null 2>&1); then
    pass "hyperframes lint on composition skeleton"
  else
    fail "hyperframes lint failed on composition skeleton"
  fi
  if (cd "${WORKDIR}/video" && node "${CLI_JS}" check >/dev/null 2>&1); then
    pass "hyperframes check on composition skeleton"
  else
    fail "hyperframes check failed on composition skeleton"
  fi
  fi
else
  echo "SKIP toolchain not found (HYPERFRAMES_DIR/FFMPEG_BUILD_DIR) — lint/check skipped"
fi

if [[ "${FAILED}" -eq 0 ]]; then
  echo "smoke test: all checks passed"
else
  echo "smoke test: FAILURES above" >&2
  exit 1
fi
