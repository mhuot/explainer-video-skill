#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: project_check.sh [--docker] [PROJECT_DIR]" >&2
}

check_docker=false
project_dir="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --docker)
      check_docker=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      usage
      exit 2
      ;;
    *)
      project_dir="$1"
      shift
      [[ $# -eq 0 ]] || { usage; exit 2; }
      ;;
  esac
done

project_dir="$(cd "${project_dir}" && pwd)"
failed=0

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1" >&2; failed=1; }
warn() { printf 'WARN %s\n' "$1"; }

for required in \
  video-project.json \
  video/index.html \
  video/assets/gsap.min.js \
  production/assets/audio \
  production/renders \
  production/snapshots; do
  if [[ -e "${project_dir}/${required}" ]]; then
    pass "${required}"
  else
    fail "missing ${required}"
  fi
done

if [[ -f "${project_dir}/tools/tts_generate.py" ]]; then
  pass "tools/tts_generate.py"
elif [[ -f "${project_dir}/narration.json" ]]; then
  pass "narration.json"
else
  warn "no narration generator; pre-authored audio is still supported"
fi

for writable in production/assets/audio production/renders production/snapshots; do
  if [[ -w "${project_dir}/${writable}" ]]; then
    pass "writable ${writable}"
  else
    fail "not writable ${writable}"
  fi
done

if command -v python3 >/dev/null; then
  if python3 - "${project_dir}/video-project.json" <<'PY'
import json
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
if manifest.get("schemaVersion") != 1:
    raise SystemExit("schemaVersion must be 1")
if manifest.get("recipe") != "explainer-video":
    raise SystemExit("recipe must be explainer-video")
PY
  then
    pass "video-project.json schema"
  else
    fail "invalid video-project.json"
  fi
else
  warn "python3 unavailable; skipped JSON schema validation"
fi

if [[ "${check_docker}" == true ]]; then
  if command -v docker >/dev/null && docker version >/dev/null 2>&1; then
    pass "Docker engine"
  else
    fail "Docker engine unavailable"
  fi
  engine_image="${SKILLS_VIDEO_ENGINE_IMAGE:-ghcr.io/mhuot/skills-video-engine:0.3.1}"
  if docker image inspect "${engine_image}" >/dev/null 2>&1; then
    pass "Skills Video Engine image ${engine_image}"
  else
    fail "missing Engine image; run: docker pull ${engine_image}"
  fi
fi

if [[ "${failed}" -ne 0 ]]; then
  echo "project check: failures above" >&2
  exit 1
fi

echo "project check: ready"
