# explainer-video-skill promo

A self-contained 59.8-second promotional production for
`explainer-video-skill`. It contrasts fragmented generic video work with a
measured local code pipeline, demonstrates concept-explainer and
solution-preview motifs, gives a real setup concession, and credits the method
demonstrated by Idan Shimon.

Final master:
`production/renders/explainer-video-promo-v1.mp4`

## Reproduce exactly

The commands below use the locally proven tools requested for this production.
Kokoro packages and model weights must already be present in the shared promo
skill environment; no demo virtual environment is created.

```bash
cd /Users/mhuot/explainer-video-skill/demos/promo
export PATH="/Users/mhuot/ffmpeg-build:$PATH"
export PYTORCH_ENABLE_MPS_FALLBACK=1

# Recreate measured, gain-corrected per-scene narration.
/Users/mhuot/promo-video-skill/.venv/bin/python tools/tts_generate.py
cp production/assets/audio/s*.wav video/assets/audio/

# Recreate the deterministic 59.8-second music bed.
/Users/mhuot/ffmpeg-build/ffmpeg -hide_banner -y \
  -f lavfi \
  -i "aevalsrc=0.055*(sin(2*PI*73.42*t)+0.55*sin(2*PI*110*t)+0.28*sin(2*PI*146.84*t))+0.012*sin(2*PI*(0.35*t)*t):s=48000:d=59.8" \
  -af "highpass=f=45,lowpass=f=1000,afade=t=in:st=0:d=1.5,afade=t=out:st=56.3:d=3.5,pan=stereo|c0=c0|c1=c0" \
  -c:a pcm_s16le production/assets/audio/music-bed.wav
cp production/assets/audio/music-bed.wav video/assets/audio/

# Validate the composition.
cd video
node /Users/mhuot/hyperframes/packages/cli/dist/cli.js lint
node /Users/mhuot/hyperframes/packages/cli/dist/cli.js check

# Recreate and visually review all exact scene-midpoint snapshots.
node /Users/mhuot/hyperframes/packages/cli/dist/cli.js snapshot \
  --at 3.5,11.15,18.713,25.75,34.513,44.725,54.8 \
  --no-end --describe false

# Render the master.
node /Users/mhuot/hyperframes/packages/cli/dist/cli.js render \
  --quality high \
  --output ../production/renders/explainer-video-promo-v1.mp4

# Probe duration, streams, and loudness.
cd ..
/Users/mhuot/ffmpeg-build/ffprobe -v error \
  -show_entries format=duration,size,bit_rate \
  -show_entries stream=index,codec_type,codec_name,width,height,r_frame_rate,sample_rate,channels \
  -of json production/renders/explainer-video-promo-v1.mp4
/Users/mhuot/ffmpeg-build/ffmpeg -hide_banner \
  -i production/renders/explainer-video-promo-v1.mp4 \
  -af volumedetect -f null -

# Extract the final encoded frame for visual review.
/Users/mhuot/ffmpeg-build/ffmpeg -hide_banner -y \
  -ss 59.766 \
  -i production/renders/explainer-video-promo-v1.mp4 \
  -frames:v 1 final-frame.png
```

Delete `video/snapshots/` and `final-frame.png` after review; they are transient
QA artifacts. The vendored `video/assets/gsap.min.js` makes composition runtime
offline and does not use a CDN. Do not run optional HyperFrames feedback: it is
not a production gate and was not used here.

## Production record

- Research and source citations: `production/research/research-brief.md`
- Locked narration: `production/script/script.md`
- Measured timing: `production/assets/audio/durations.json`
- Scene plan: `production/scene_plan/scene-plan.md`
- Decisions: `production/checkpoints/decision-log.json`
- Final QA: `production/checkpoints/self-review.md`
