# Explainer Video Skill — Self Explainer

A 1920×1080 narrated concept explainer showing how the explainer-video
method turns a question into a measured, source-code video.

## Reproduce

The commands below use the environment variables set during installation.
Set them to match your local paths if they differ from the defaults:

```bash
export FFMPEG_BUILD_DIR="${FFMPEG_BUILD_DIR:-$HOME/ffbuild}"
export HYPERFRAMES_DIR="${HYPERFRAMES_DIR:-$HOME/hyperframes}"
export EXPLAINER_VIDEO_SKILL_DIR="${EXPLAINER_VIDEO_SKILL_DIR:-$HOME/explainer-video-skill}"
```

```bash
cd "$EXPLAINER_VIDEO_SKILL_DIR/demos/explainer"
export PATH="$FFMPEG_BUILD_DIR:$PATH"
mkdir -p production/assets/audio production/renders video/assets/audio
curl -fL https://cdn.jsdelivr.net/npm/gsap@3.13.0/dist/gsap.min.js \
  -o video/assets/gsap.min.js
PYTORCH_ENABLE_MPS_FALLBACK=1 \
  .venv/bin/python tools/tts_generate.py
cp production/assets/audio/*.wav video/assets/audio/

cd video
CLI="node $HYPERFRAMES_DIR/packages/cli/dist/cli.js"
$CLI lint
$CLI check
$CLI snapshot \
  --at 3.788,11.888,21.275,31.863,44.575,58.238,69.275 \
  --no-end --output ../production/checkpoints/qa-work
$CLI render --quality high \
  --output ../production/renders/explainer-video-self-explainer-v1.mp4

OUT="../production/renders/explainer-video-self-explainer-v1.mp4"
ffprobe -v error \
  -show_entries format=duration,size,bit_rate \
  -show_entries stream=codec_name,codec_type,width,height,r_frame_rate,sample_rate,channels \
  "$OUT"
ffmpeg -hide_banner -i "$OUT" -af volumedetect -f null -
```

Inspect all seven midpoint PNGs before rendering. After QA, remove the
transient snapshot directory; measured evidence is preserved in
`production/checkpoints/self-review.md`.
