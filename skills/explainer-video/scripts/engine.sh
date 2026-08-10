#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [--workdir relative/path] [--project-dir PATH] <engine command> [arguments...]" >&2
}

container_workdir="/project"
project_dir="${VIDEO_PROJECT_DIR:-${PWD}}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      requested_workdir="$2"
      if [[ "${requested_workdir}" == /* || "${requested_workdir}" == *".."* ]]; then
        echo "Workdir must be a relative path beneath the video project" >&2
        exit 2
      fi
      container_workdir="/project/${requested_workdir#./}"
      shift 2
      ;;
    --project-dir)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      project_dir="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

[[ $# -gt 0 ]] || { usage; exit 2; }
[[ -d "${project_dir}" ]] || {
  echo "Video project directory not found: ${project_dir}" >&2
  exit 1
}
command -v docker >/dev/null || {
  echo "Docker is required for the recommended engine profile" >&2
  exit 1
}

project_dir="$(cd "${project_dir}" && pwd)"
engine_image="${SKILLS_VIDEO_ENGINE_IMAGE:-ghcr.io/mhuot/skills-video-engine:0.3.1}"
docker_args=(
  run --rm --init
  --shm-size=1g
  --network none
  --volume "${project_dir}:/project"
  --workdir "${container_workdir}"
)
if [[ "$(uname -s)" != MINGW* && "$(uname -s)" != MSYS* ]]; then
  docker_args+=(--user "$(id -u):$(id -g)")
fi

exec docker "${docker_args[@]}" "${engine_image}" "$@"
