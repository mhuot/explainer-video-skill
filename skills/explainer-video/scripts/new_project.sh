#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: new_project.sh [options] PROJECT_DIR

Create a new explainer-video project without overwriting existing files.

Options:
  --engine-image IMAGE  Pin a Skills Video Engine image.
  --gsap-source FILE    Copy an existing gsap.min.js instead of using the image.
  --offline             Require the engine image to already be cached.
  -h, --help            Show this help.
EOF
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_dir="$(cd "${script_dir}/.." && pwd)"
engine_image="ghcr.io/mhuot/skills-video-engine:0.3.1"
gsap_source=""
offline=false
target=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine-image)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      engine_image="$2"
      shift 2
      ;;
    --gsap-source)
      [[ $# -ge 2 ]] || { usage >&2; exit 2; }
      gsap_source="$2"
      shift 2
      ;;
    --offline)
      offline=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      [[ -z "${target}" ]] || { echo "Only one project directory is allowed" >&2; exit 2; }
      target="$1"
      shift
      ;;
  esac
done

[[ -n "${target}" ]] || { usage >&2; exit 2; }
if [[ ! "${engine_image}" =~ ^[A-Za-z0-9][A-Za-z0-9._/:@-]*$ ]]; then
  echo "Engine image contains unsupported characters: ${engine_image}" >&2
  exit 2
fi
if [[ -e "${target}" ]]; then
  echo "Refusing to overwrite existing path: ${target}" >&2
  exit 1
fi

project_name="$(basename "${target}")"
if [[ ! "${project_name}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "Project directory name may contain only letters, numbers, dots, dashes, and underscores" >&2
  exit 2
fi

target_parent="$(dirname "${target}")"
mkdir -p "${target_parent}"
staging="$(mktemp -d "${target_parent}/.${project_name}.tmp.XXXXXX")"
cleanup() {
  rm -rf -- "${staging:?}"
}
trap cleanup EXIT

mkdir -p \
  "${staging}/production/research" \
  "${staging}/production/script" \
  "${staging}/production/scene_plan" \
  "${staging}/production/checkpoints/frames" \
  "${staging}/production/assets/audio" \
  "${staging}/production/renders" \
  "${staging}/production/snapshots" \
  "${staging}/tools" \
  "${staging}/video/assets/audio"

install -m 0644 "${skill_dir}/scripts/tts_generate.py" "${staging}/tools/"
install -m 0644 "${skill_dir}/scripts/tts_pronounce.py" "${staging}/tools/"
install -m 0755 "${skill_dir}/scripts/engine.sh" "${staging}/tools/"
install -m 0644 "${skill_dir}/scripts/engine.ps1" "${staging}/tools/"
install -m 0644 "${skill_dir}/assets/composition-skeleton.html" "${staging}/video/index.html"
install -m 0644 \
  "${skill_dir}/assets/decision-log.json" \
  "${staging}/production/checkpoints/decision-log.json"

if [[ -n "${gsap_source}" ]]; then
  [[ -s "${gsap_source}" ]] || { echo "GSAP source is missing or empty: ${gsap_source}" >&2; exit 1; }
  install -m 0644 "${gsap_source}" "${staging}/video/assets/gsap.min.js"
else
  command -v docker >/dev/null || {
    echo "Docker is required to copy the bundled GSAP runtime" >&2
    exit 1
  }
  pull_policy="missing"
  if [[ "${offline}" == true ]]; then
    pull_policy="never"
  fi
  if ! docker run --rm \
      --network none \
      --pull "${pull_policy}" \
      --volume "${staging}:/project" \
      --workdir /project \
      "${engine_image}" \
      copy-gsap video/assets/gsap.min.js; then
    echo "Unable to copy GSAP from ${engine_image}." >&2
    echo "Ensure Docker can pull the image, or use --offline only after it is cached." >&2
    echo "Custom images must provide the copy-gsap command; --gsap-source remains available." >&2
    exit 1
  fi
  [[ -s "${staging}/video/assets/gsap.min.js" ]] || {
    echo "Engine did not provide video/assets/gsap.min.js" >&2
    exit 1
  }
fi

cat >"${staging}/video-project.json" <<EOF
{
  "schemaVersion": 1,
  "name": "${project_name}",
  "recipe": "explainer-video",
  "engineImage": "${engine_image}"
}
EOF

cat >"${staging}/.gitignore" <<'EOF'
.DS_Store
.venv/
__pycache__/
*.py[cod]
EOF

cat >"${staging}/README.md" <<EOF
# ${project_name}

Created with the explainer-video skill.

## Docker workflow

\`\`\`bash
ENGINE="./tools/engine.sh"
"\$ENGINE" python tools/tts_generate.py
"\$ENGINE" --workdir video hyperframes lint
"\$ENGINE" --workdir video hyperframes check
"\$ENGINE" --workdir video hyperframes render --quality high \\
  --output ../production/renders/master.mp4
\`\`\`

Edit \`tools/tts_generate.py\`, derive timing from
\`production/assets/audio/durations.json\`, and replace the starter composition
in \`video/index.html\`.
EOF

if [[ -e "${target}" ]]; then
  echo "Project path appeared during setup; refusing to overwrite: ${target}" >&2
  exit 1
fi
mv "${staging}" "${target}"
trap - EXIT

echo "Created explainer-video project: $(cd "${target}" && pwd)"
echo "Engine: ${engine_image}"
echo "Next: edit tools/tts_generate.py, then run the packaged project checker."
