# Explainer Video Skill — Self Explainer

A 1920×1080 narrated concept explainer showing how the explainer-video
method turns a question into a measured, source-code video.

## Reproduce

The commands below use the existing local toolchain and cached Kokoro model.

```bash
cd /Users/mhuot/explainer-video-skill/demos/explainer
export PATH="/Users/mhuot/ffmpeg-build:$PATH"
mkdir -p production/assets/audio production/renders video/assets/audio
cp /Users/mhuot/hyperframes/node_modules/.bun/gsap@3.15.0/node_modules/gsap/dist/gsap.min.js \
  video/assets/gsap.min.js
PYTORCH_ENABLE_MPS_FALLBACK=1 \
  /Users/mhuot/promo-video-skill/.venv/bin/python tools/tts_generate.py
cp production/assets/audio/*.wav video/assets/audio/

cd video
CLI="node /Users/mhuot/hyperframes/packages/cli/dist/cli.js"
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

