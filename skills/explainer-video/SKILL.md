---
name: explainer-video
description: "Produce a 45–90 second narrated explainer video, how-it-works video, product walkthrough, solution preview, or customer-presentation video with local Kokoro TTS, HTML/CSS/GSAP scenes rendered by HyperFrames, FFmpeg encoding and QA, and auditable production gates. Use when asked to explain a concept or process as a video, make an explainer, preview a solution or demo, or create a narrated product tour."
license: MIT
metadata:
  version: "1.0.3"
---

# Explainer Video Production (local, offline-capable toolchain)

Method credit: **Idan Shimon** (github.com/idanshimon). His
58-second concept explainer — produced entirely by an AI agent driving
OpenMontage, HyperFrames, Kokoro, and FFmpeg locally at $0 — defined this
format, and his cardiology solution preview showed the companion use: a
video demo of a product dashboard built as source code.
The operating premise is his: **the entire video is source code — any scene,
word, color, or timing is a one-line edit and a re-render.**

Written for **Scout**, **Claude Code**, **GitHub Copilot CLI**, and
**Google Gemini CLI** (all four discover this skill natively via
`install.sh`) — and any other agent that can read files and run shell
commands. Do not assume a clone under `~`: set
`EXPLAINER_VIDEO_SKILL_DIR` to the directory containing this `SKILL.md`.
Its `scripts/` directory has the TTS script and its acronym-pronunciation
helper; `assets/` has the composition
skeleton and decision-log schema; `references/` has the method deep-dive
(`method.md`) and the once-per-machine toolchain bootstrap (`install.md`).

The production phase can run offline after packages, Kokoro weights, and
HyperFrames' browser are cached. Installation, first model/browser use,
online research, and optional feedback require network. No cloud generation,
telemetry, or feedback submission is required.

**Core principle: the script locks first; every downstream number is DERIVED
from measured narration audio, never guessed.**

## What an explainer is (vs. marketing)

An explainer teaches or previews; it does not sell. No pain-hook theatrics,
no competitor table, no hard CTA. The two shapes:

1. **Concept explainer** ("How an anomaly detector works") — how a system,
   model, or process works, step by step.
2. **Solution preview** (cardiology dashboard demo) — a guided tour of a
   product/solution UI, built as animated HTML mockups of the real screens.

## Narrative arc (5–7 scenes, 45–90 s)

| Scene | Role | Time share |
| --- | --- | --- |
| Hook | The question the video answers ("What happens in the 10 seconds after an ECG is taken?") | ~12% |
| Context | Why it matters / where this sits | ~15% |
| How it works — steps 1..3 (or tour stops 1..3) | The core: one idea per scene, diagram- or UI-led | ~50% |
| What it means | The outcome for the user/patient/business | ~13% |
| Recap + close | One-sentence summary, title card, "learn more" pointer | ~10% |

Script budget: ≈2.55 words/second at Kokoro `af_heart` speed 1.1 → 115–130
words for 45–50 s, ~150 for 60 s, ~210 for 85 s. Write acronyms naturally
("ECG", "AI") in both the script and on-screen text — at synthesis time
`tools/tts_pronounce.py` derives the spoken form (word vs letter-by-letter)
from its lexicon, and unknown acronyms are spelled letter by letter and
reported. Classify domain terms in an optional
`tools/pronunciation.local.json` (`{"NASA": "word", "ECG": "letters",
"NGINX": "engine X"}`). Avoid ALL-CAPS emphasis: an all-caps word is
treated as an acronym.

## Visual grammar (explainer-specific)

See `$EXPLAINER_VIDEO_SKILL_DIR/assets/spatial-components.html` for pure layout templates of these elements. **Rule:** copy ONLY their spatial CSS/HTML structure; never copy timing. All timing must be derived from your measured audio.

- **Step chips** — a numbered chip (`01`, `02`, `03`) anchors each
  how-it-works scene; consistent position, animated per-scene.
- **Flow diagrams** — SVG nodes + edges; draw edges with `stroke-dasharray`
  → `strokeDashoffset` tweens; label nodes as narration reaches them.
- **Annotated UI mockups** — for solution previews, rebuild the key screens
  as HTML cards (stat tiles, charts, patient/entity tables) and animate
  attention: a highlight ring, a rising chart path, a callout that lands in
  sync with the narration beat.
- **Data motion** — animate the *numbers* (bar widths via `scaleX`, gauge
  arcs via `strokeDashoffset`); never fake it with a static screenshot.
- **Design tokens** — all theme in `:root` CSS vars. Default explainer
  theme: light or dark neutral ground, ONE accent (a clear
  blue such as `#0078d4` works well for solution previews), a sans stack
  (`"Segoe UI", system-ui, sans-serif`) for prose + a mono for data/code.
  `lint` prints a `system_font_will_alias` info naming the exact bundled
  fonts the renderer substitutes — read it and keep preview/render
  consistent.
- **Calm pacing** — explainers breathe: 0.4–0.6 s scene padding, eased
  entrances, no glitch/flicker effects.

## Tool profiles

| Tool | Location | License | Role | Invocation |
| --- | --- | --- | --- | --- |
| Kokoro | PyPI package + cached `hexgrad/Kokoro-82M` | code **Apache 2.0**; weights **Apache 2.0** | Narration TTS → 24 kHz WAV per scene | Python 3.12 uv venv; `KPipeline(lang_code="a")`, voice `af_heart`, `speed=1.1` |
| HyperFrames | `$HYPERFRAMES_DIR` | Apache 2.0 | HTML/CSS/GSAP composition → deterministic MP4 via headless Chrome | `node "$HYPERFRAMES_DIR/packages/cli/dist/cli.js" <cmd>` |
| FFmpeg | `$FFMPEG_SOURCE_DIR`; binary in `$FFMPEG_BUILD_DIR` | GPL build (libx264) | Music synth (`aevalsrc`), encode, ffprobe QA, loudness, packaging | put build dir on `PATH` |
| bun / Node ≥22 / Python 3.12 + uv / espeak-ng | — | various | build + runtimes | install per `references/install.md` |
| gsap 3 | vendored `gsap.min.js` | GSAP standard license | scene animation | copy into `video/assets/` — never a CDN script (offline determinism) |

The stage order, append-only decisions, approval gates, and self-review rules
are fully specified here; OpenMontage is acknowledged as an influence but is
not a required checkout or reference repository.

## Environment check (once per machine)

Prefer the versioned Docker engine:

```bash
docker pull ghcr.io/mhuot/skills-video-engine:0.3.1
"$EXPLAINER_VIDEO_SKILL_DIR/scripts/engine.sh" hyperframes --version
```

On Windows PowerShell:

```powershell
docker pull ghcr.io/mhuot/skills-video-engine:0.3.1
& "$env:EXPLAINER_VIDEO_SKILL_DIR\scripts\engine.ps1" hyperframes --version
```

The launchers are bundled with the skill and invoke the pinned image directly;
do not require the user to clone the Engine repository or enter WSL. Check
Docker and the Engine once before creating the project.

Otherwise, validate the native toolchain:

```bash
export FFMPEG_BUILD_DIR="${FFMPEG_BUILD_DIR:-$HOME/ffbuild}"
export HYPERFRAMES_DIR="${HYPERFRAMES_DIR:-$HOME/hyperframes}"
export PATH="$FFMPEG_BUILD_DIR:$PATH"
node "$HYPERFRAMES_DIR/packages/cli/dist/cli.js" doctor
```

FFmpeg, FFprobe, Node, and Chrome must all pass before production (other
`doctor` rows are optional components this skill does not use). If any of
the four fail, follow
`$EXPLAINER_VIDEO_SKILL_DIR/references/install.md` — the full
once-per-machine bootstrap: system packages (macOS/Linux), source-building
FFmpeg with libx264, building the HyperFrames CLI, and agent permission
tips. Do not load that file when `doctor` already passes.

## Project layout (one git repo per video, atomic commits)

When the user requests a new explainer and no project exists, collect the
missing brief fields and project location, then create and check the starter
project:

```bash
"$EXPLAINER_VIDEO_SKILL_DIR/scripts/new_project.sh" customer-explainer
cd customer-explainer
"$EXPLAINER_VIDEO_SKILL_DIR/scripts/project_check.sh" --docker .
```

Run these commands on the user's behalf rather than asking them to operate the
skill's internal scripts. Report the project path and surface actionable
readiness failures.

The scaffolder copies the packaged tools and starter assets, pins the engine
in `video-project.json`, copies GSAP from that image with networking disabled,
and refuses to overwrite an existing path. Use `--offline` or `-Offline` to
require the image to already be cached.

```
<project>/
  .venv/                          # uv venv, python 3.12
  production/
    research/research-brief.md    # verified facts; for solution previews: the real screens/data model
    proposal.md                   # arc, scene list, theme, duration target
    script/script.md              # LOCKED narration
    scene_plan/scene-plan.md      # per-scene visual + motion notes
    checkpoints/decision-log.json # append-only; (category, subject) is the key
    checkpoints/self-review.md    # post-render evidence
    assets/audio/                 # Kokoro WAVs + durations.json
    renders/
  tools/tts_generate.py           # from scripts/, edit SCENE_NARRATIONS only
  tools/tts_pronounce.py          # from scripts/, acronym pronunciation (do not edit)
  tools/pronunciation.local.json  # optional project lexicon overlay
  video/
    index.html                    # the composition
    assets/gsap.min.js            # vendored
    assets/audio/                 # WAV copies (composition-relative paths)
```

If scaffolding is not appropriate, use this manual fallback:

```bash
cd <project>
mkdir -p tools
cp "$EXPLAINER_VIDEO_SKILL_DIR/scripts/tts_generate.py" tools/
cp "$EXPLAINER_VIDEO_SKILL_DIR/scripts/tts_pronounce.py" tools/
mkdir -p video/assets
docker run --rm --network none \
  --volume "$PWD:/project" --workdir /project \
  ghcr.io/mhuot/skills-video-engine:0.3.1 \
  copy-gsap video/assets/gsap.min.js
```

For the native profile only, initialize the per-video environment:

```bash
uv venv --python 3.12 .venv
uv pip install --python .venv/bin/python "kokoro>=0.9.4,<1" numpy soundfile
```

Keep `.venv/` out of version control. Preserve the vendored GSAP file with the
project; scaffolding and rendering do not contact a CDN.

## Stages

1. **Research** — mine the subject's own sources (repo, docs, the actual
   product screens for a preview). Every scripted claim gets a source line
   in `research-brief.md`. For clinical/regulated subjects (like a
   cardiology AI): claims must be conservative, no outcome promises, and the
   close should carry the customer's own disclaimer language if provided.
2. **Proposal** — arc + scene list + theme + duration; log decisions
   (`pipeline_selection`, `explainer_shape`, `voice_selection`, `music_selection`,
   `output_profile`, `approval_gates` — schema in
   `$EXPLAINER_VIDEO_SKILL_DIR/assets/decision-log.json`). Changed
   decisions are APPENDED with the same (category, subject), never edited.
3. **Script lock** — the words are final before any audio or visuals exist.
4. **Narration + timing derivation** — copy
   `$EXPLAINER_VIDEO_SKILL_DIR/scripts/tts_generate.py`, edit
   `SCENE_NARRATIONS`, then run one profile:

   ```bash
   # Docker profile
   "$HOME/skills-video-engine/scripts/engine.sh" python tools/tts_generate.py

   # Native profile
   PYTORCH_ENABLE_MPS_FALLBACK=1 .venv/bin/python tools/tts_generate.py
   ```

   The first native run downloads Kokoro-82M weights; later inference can
   use the local cache. The engine image already contains the weights. If the run prints an
   unknown-acronym WARNING, classify those tokens in
   `tools/pronunciation.local.json` and re-run before deriving timing.
   Then derive:

   ```
   n_start[0] = 0.5
   scene_start[i] = n_start[i] - 0.15..0.4
   n_start[i+1] = n_start[i] + dur[i] + 0.4..0.6   # explainers breathe
   TOTAL = last n_end + 0.8..1.0 (fade)
   ```

   The numbers land in THREE places that must agree: scene
   `data-start/duration`, `<audio data-start>`, and the JS scene constants.
5. **Music** — optional for explainers. Solution previews often read better
   with narration only. When music is requested, synthesize a deterministic
   pad locally; do not leave the recipe implicit:

   ```bash
   TOTAL=60.0
   FADE_OUT=56.5
   mkdir -p production/assets/audio
   "$FFMPEG_BUILD_DIR/ffmpeg" -y -f lavfi \
     -i "aevalsrc=0.035*sin(2*PI*110*t)+0.025*sin(2*PI*164.81*t)+0.02*sin(2*PI*220.6*t):s=48000:d=${TOTAL}" \
     -af "lowpass=f=1400,afade=t=in:st=0:d=2,afade=t=out:st=${FADE_OUT}:d=3.5" \
     -c:a pcm_s16le production/assets/audio/music.wav
   ```

   Set `TOTAL` from narration-derived timing and `FADE_OUT=TOTAL-3.5`.
   Include the WAV as a direct-root audio element on track 8 at
   `data-volume` 0.10–0.14.
6. **Composition** — start from
   `$EXPLAINER_VIDEO_SKILL_DIR/assets/composition-skeleton.html`. The
   non-negotiables (each one is a debugged failure, not a preference):
   - every `<video>/<audio>` has an explicit, non-empty `id`; in HyperFrames,
     audio without one may play in a browser preview but renders SILENT
   - entrances are `tl.fromTo(...)`; never a CSS `transform:` initial state
     on a tweened element
   - background fill on a full-bleed child, never the composition root
   - media elements are direct children of the root; distinct audio tracks
     (7 = narration, 8 = music)
   - one paused GSAP timeline, registered synchronously under the
     composition id; finite repeats only; no `Date.now`/`Math.random`/CDN
   - animate only transforms/opacity (+ `strokeDashoffset` for SVG draws)
   - unique `id`s everywhere; `check` enforces WCAG AA contrast and prints
     compliant colors on failure
   - intentional overlaps get `data-layout-allow-*` attributes
7. **Validation ladder** (cheap → expensive; fix everything before render):

   ```bash
   # Docker profile, from the project root
   ENGINE="$HOME/skills-video-engine/scripts/engine.sh"
   mkdir -p production/renders production/snapshots
   "$ENGINE" --workdir video hyperframes lint
   "$ENGINE" --workdir video hyperframes check
   "$ENGINE" --workdir video hyperframes snapshot --at <every scene midpoint>

   # Native profile
   export PATH="$FFMPEG_BUILD_DIR:$PATH"; cd video
   CLI="node $HYPERFRAMES_DIR/packages/cli/dist/cli.js"
   $CLI lint
   $CLI check
   $CLI snapshot --at <every scene midpoint>
   ```
   
   **Snapshot QA Checklist:** Use your vision capabilities (or the `--describe` hook) to review each extracted frame:
   - [ ] **Contrast**: Is all text readable against its background?
   - [ ] **Overlap**: Does text fit within its container without clipping or overlapping other elements?
   - [ ] **Composition**: Are the step chips, flow nodes, and UI mockups positioned cleanly?
   
   Fix any issues in the HTML/CSS before proceeding.

8. **Render + self-review** —

   ```bash
   # Docker profile, from the project root
   ENGINE="$HOME/skills-video-engine/scripts/engine.sh"
   "$ENGINE" --workdir video hyperframes render --quality high \
     --output ../production/renders/explainer-v1.mp4
   "$ENGINE" ffprobe -v error \
     -show_entries format=duration,size,bit_rate \
     -show_entries stream=codec_name,width,height,r_frame_rate \
     production/renders/explainer-v1.mp4
   "$ENGINE" ffmpeg -i production/renders/explainer-v1.mp4 \
     -af volumedetect -f null -

   # Native profile, from video/
   OUT="../production/renders/explainer-v1.mp4"
   mkdir -p ../production/renders ../production/checkpoints/frames
   $CLI render --quality high --output "$OUT"
   "$FFMPEG_BUILD_DIR/ffprobe" -v error \
     -show_entries format=duration,size,bit_rate \
     -show_entries stream=codec_name,width,height,r_frame_rate "$OUT"
   "$FFMPEG_BUILD_DIR/ffmpeg" -i "$OUT" \
     -af volumedetect -f null -
   for t in 3 15 30 45; do
     "$FFMPEG_BUILD_DIR/ffmpeg" -y -ss "$t" -i "$OUT" \
       -frames:v 1 "../production/checkpoints/frames/qa-${t}.png"
   done
   ```

   Choose frame times that fall within the actual runtime, view every
   extracted image, confirm duration is within ±0.1 s of plan and
   `max_volume` is below 0 dB, then write
   `production/checkpoints/self-review.md`.
   When a Skills Video Studio project uses ordered
   `video/compositions/*.html` files, rerender only the changed composition
   names with Studio's `render_segments` API or MCP tool. Studio reuses cached
   unchanged segments and assembles the complete master after the changed
   renders succeed. Use the normal full render for single-composition
   projects.
9. **Packaging** — Teams/SharePoint/email preview: the H.264+AAC master
   plays everywhere on most video platforms and players as-is. For YouTube/Stream
   publication, make a derivative: stream-copy video, two-pass `loudnorm`
   audio to −14 LUFS / −1 dBTP, `-movflags +faststart`. First measure with
   JSON output:

   ```bash
   "$FFMPEG_BUILD_DIR/ffmpeg" -i master.mp4 \
     -af loudnorm=I=-14:TP=-1:LRA=11:print_format=json -f null -
   ```

   Copy `input_i`, `input_tp`, `input_lra`, `input_thresh`, and
   `target_offset` from that output into pass two:

   ```bash
   "$FFMPEG_BUILD_DIR/ffmpeg" -i master.mp4 \
     -map 0:v:0 -map 0:a:0 -c:v copy \
     -af "loudnorm=I=-14:TP=-1:LRA=11:measured_I=<input_i>:measured_TP=<input_tp>:measured_LRA=<input_lra>:measured_thresh=<input_thresh>:offset=<target_offset>:linear=true" \
     -c:a aac -b:a 384k -ar 48000 -movflags +faststart output.mp4
   "$FFMPEG_BUILD_DIR/ffmpeg" -i output.mp4 \
     -af loudnorm=I=-14:TP=-1:LRA=11:print_format=summary -f null -
   ```

   Never re-encode the video stream solely for packaging.

   For YouTube, assess disclosure under the official
   [AI disclosure policy](https://support.google.com/youtube/answer/14328491).
   Realistic, meaningfully generated/altered content that could be mistaken
   for real events or a real person's actions requires disclosure. YouTube
   exempts examples such as cloning one's own voice for voiceovers, so
   Kokoro narration is not categorically “yes”; impersonating a real person
   is. Disclose when required or uncertain. The label itself does not limit
   audience or monetization.

10. **Optional feedback** — only with the user's informed choice, the
    HyperFrames CLI may support a `feedback` command. It is not a quality
    gate, may use the network and transmit the supplied rating/comment, and
    must never be invoked as telemetry by default.

## Failure modes (already paid for)

| Symptom | Cause → fix |
| --- | --- |
| render: `Unrecognized option 'preset'` | ffmpeg built without libx264 → rebuild `--enable-gpl --enable-libx264` |
| CLI build: cannot resolve `@hyperframes/core` | built `packages/cli` alone → root `bun run build` |
| root `bun run build` exits 1 at `sdk-playground` | upstream Node 22 issue → harmless; gate on `test -f packages/cli/dist/cli.js` |
| TTS: `✘ No package installer found` (spaCy) | uv venvs ship without pip → harmless; narration generates correctly |
| `bun` missing after brew install | `npm i -g bun` |
| audio silent in render, fine in preview | `<audio>` missing `id` |
| element visible before its entrance when scrubbing | CSS transform + `.to()` → `fromTo` |
| frame renders black though preview is fine | background on composition root → full-bleed child |
| upload plays quiet on YouTube/Stream | master < −14 LUFS → loudnorm derivative |
| Kokoro import errors | espeak-ng missing or venv not active |

## Non-negotiables

- Locked script before any asset; measured durations before any timing.
- Truthful, sourced claims — especially for clinical/regulated subjects.
- No required cloud generation. Be explicit when installation, model/browser
  downloads, online research, or optional feedback use the network.
- Do not submit telemetry or feedback unless the user opts in.
- One repo per video; atomic conventional commits; Python in a 3.12 uv venv.
- The subject's owner signs off before the video ships to customers or
  official channels.
