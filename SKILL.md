---
description: "Produce a 45–90 second narrated explainer video ('how X works' or a solution preview) entirely offline: kokoro TTS narration, HTML/CSS/GSAP scenes rendered by HyperFrames, FFmpeg encode and QA, OpenMontage-style production governance. Use when asked to explain how something works as a video, create a solution/demo preview video, or make an explainer for a customer presentation."
---

# Explainer Video Production (offline, local toolchain)

Method credit: **Idan Shimon** (Microsoft, github.com/idanshimon). His
*"How AI Reads a Heart"* 58-second explainer — produced entirely by an AI
agent driving OpenMontage, HyperFrames, Kokoro, and FFmpeg, fully offline at
$0 — defined this format, and his cardiology solution preview showed the
companion use: a video demo of a product dashboard built as source code.
The operating premise is his: **the entire video is source code — any scene,
word, color, or timing is a one-line edit and a re-render.**

Written for **Microsoft Scout** (custom skill, `~/.copilot/skills/`) and any
other agent that can read files and run shell commands. Canonical home:
`~/explainer-video-skill` — `templates/` has the TTS script, a composition
skeleton, and the decision-log schema; `README.md` covers install.

**Core principle: the script locks first; every downstream number is DERIVED
from measured narration audio, never guessed.**

## What an explainer is (vs. marketing)

An explainer teaches or previews; it does not sell. No pain-hook theatrics,
no competitor table, no hard CTA. The two shapes:

1. **Concept explainer** ("How AI reads a heart") — how a system, model, or
   process works, step by step.
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

Script budget: ≈2.55 words/second at kokoro `af_heart` speed 1.1 → 115–130
words for 45–50 s, ~150 for 60 s, ~210 for 85 s. Write acronyms spaced for
TTS ("E C G", "A I"); on-screen text uses real spelling.

## Visual grammar (explainer-specific)

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
  theme: light or dark neutral ground, ONE accent (Microsoft-adjacent
  `#0078d4` blue works well for solution previews), a sans stack
  (`"Segoe UI", system-ui, sans-serif`) for prose + a mono for data/code.
  `lint` prints a `system_font_will_alias` info naming the exact bundled
  fonts the renderer substitutes — read it and keep preview/render
  consistent.
- **Calm pacing** — explainers breathe: 0.4–0.6 s scene padding, eased
  entrances, no glitch/flicker effects.

## Tool profiles

| Tool | Location | License | Role | Invocation |
| --- | --- | --- | --- | --- |
| OpenMontage | `~/OpenMontage` | AGPLv3 (tooling only; nothing ships in the video) | Production governance: stage order, decision log, approval gates, post-render self-review | Read `AGENT_GUIDE.md` + `pipeline_defs/animated-explainer.yaml`; the agent is the orchestrator |
| kokoro | `~/kokoro` | code MIT-ish, **weights Apache 2.0** | Narration TTS → 24 kHz WAV per scene | Python venv; `KPipeline(lang_code="a")`, voice `af_heart`, `speed=1.1` |
| HyperFrames | `~/hyperframes` | Apache 2.0 | HTML/CSS/GSAP composition → deterministic MP4 via headless Chrome | `node ~/hyperframes/packages/cli/dist/cli.js <cmd>` |
| FFmpeg | built from `~/FFmpeg` source | GPL build (libx264) | Music synth (`aevalsrc`), encode, ffprobe QA, loudness, packaging | build dir on `PATH` before HyperFrames commands |
| bun / Node ≥22 / Python 3.12 (uv venv) / espeak-ng | — | — | build + runtimes | `npm i -g bun`; `brew install espeak-ng` |
| gsap 3 | vendored `gsap.min.js` | GSAP standard license | scene animation | copy into `video/assets/` — never a CDN script (offline determinism) |

## Environment bootstrap (once per machine)

```bash
brew install x264 espeak-ng
npm i -g bun
# FFmpeg MUST include libx264 or renders fail with "Unrecognized option 'preset'":
mkdir -p ~/ffbuild && cd ~/ffbuild
PKG_CONFIG_PATH=/opt/homebrew/opt/x264/lib/pkgconfig ~/FFmpeg/configure \
  --disable-doc --disable-debug --enable-videotoolbox \
  --enable-gpl --enable-libx264 \
  --extra-cflags="-I/opt/homebrew/opt/x264/include" \
  --extra-ldflags="-L/opt/homebrew/opt/x264/lib"
make -j8 ffmpeg ffprobe
# HyperFrames CLI: build from the MONOREPO ROOT (packages/cli alone fails
# on unresolved @hyperframes/core):
cd ~/hyperframes && bun install && bun run build
# Verify:
export PATH="$HOME/ffbuild:$PATH"
node ~/hyperframes/packages/cli/dist/cli.js doctor   # FFmpeg/FFprobe/Chrome ✓
```

**Microsoft Scout note:** builds and installs (`npm i`, `bun install`,
`make`) sit in Scout's *Prompt* permission tier — approve them when asked, or
pre-add allow patterns in **Settings → Permissions** (e.g. `node *`,
`python *`, `~/ffbuild/ffmpeg *`, `~/ffbuild/ffprobe *`) so the render loop
runs unattended. Keep the video project inside your Scout workspace
directory so file tools cover it.

## Project layout (one git repo per video, atomic commits)

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
    assets/audio/                 # kokoro WAVs + durations.json
    renders/
  tools/tts_generate.py           # from templates/, edit SCENE_NARRATIONS only
  video/
    index.html                    # the composition
    assets/gsap.min.js            # vendored
    assets/audio/                 # WAV copies (composition-relative paths)
```

## Stages

1. **Research** — mine the subject's own sources (repo, docs, the actual
   product screens for a preview). Every scripted claim gets a source line
   in `research-brief.md`. For clinical/regulated subjects (like a
   cardiology AI): claims must be conservative, no outcome promises, and the
   close should carry the customer's own disclaimer language if provided.
2. **Proposal** — arc + scene list + theme + duration; log decisions
   (`pipeline_selection`, `voice_selection`, `music_selection`,
   `output_profile`, `approval_gates` — schema in
   `templates/decision-log.json`). Changed decisions are APPENDED with the
   same (category, subject), never edited.
3. **Script lock** — the words are final before any audio or visuals exist.
4. **Narration + timing derivation** — copy
   `~/explainer-video-skill/templates/tts_generate.py`, edit
   `SCENE_NARRATIONS`, run in the venv
   (`PYTORCH_ENABLE_MPS_FALLBACK=1 python tools/tts_generate.py`; first run
   downloads Kokoro-82M ~330 MB, then fully offline). Then derive:

   ```
   n_start[0] = 0.5
   scene_start[i] = n_start[i] - 0.15..0.4
   n_start[i+1] = n_start[i] + dur[i] + 0.4..0.6   # explainers breathe
   TOTAL = last n_end + 0.8..1.0 (fade)
   ```

   The numbers land in THREE places that must agree: scene
   `data-start/duration`, `<audio data-start>`, and the JS scene constants.
5. **Music** — optional for explainers; when used, a synthesized `aevalsrc`
   pad at `data-volume` 0.10–0.14, faded in/out. Solution previews often
   read better with narration only.
6. **Composition** — start from
   `~/explainer-video-skill/templates/composition-skeleton.html`. The
   non-negotiables (each one is a debugged failure, not a preference):
   - every `<video>/<audio>` has an `id` — missing id = SILENT render
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
   export PATH="$HOME/ffbuild:$PATH"; cd video
   node ~/hyperframes/packages/cli/dist/cli.js lint
   node ~/hyperframes/packages/cli/dist/cli.js check
   node ~/hyperframes/packages/cli/dist/cli.js snapshot --at <every scene midpoint>
   # then actually LOOK at each frame against the scene plan
   ```
8. **Render + self-review** —

   ```bash
   node ~/hyperframes/packages/cli/dist/cli.js render --quality high \
     --output ../production/renders/<name>-v1.mp4
   ffprobe -v error -show_entries format=duration <out>   # ±0.1s of plan
   ffmpeg -i <out> -af volumedetect -f null -             # max < 0 dB
   # extract 3-4 frames, view them, write checkpoints/self-review.md
   ```
9. **Packaging** — Teams/SharePoint/email preview: the H.264+AAC master
   plays everywhere in the Microsoft ecosystem as-is. For YouTube/Stream
   publication, make a derivative: stream-copy video, two-pass `loudnorm`
   audio to −14 LUFS / −1 dBTP, `-movflags +faststart`. Never re-encode the
   video stream for packaging — fix only audio and the container.

## Failure modes (already paid for)

| Symptom | Cause → fix |
| --- | --- |
| render: `Unrecognized option 'preset'` | ffmpeg built without libx264 → rebuild `--enable-gpl --enable-libx264` |
| CLI build: cannot resolve `@hyperframes/core` | built `packages/cli` alone → root `bun run build` |
| `bun` missing after brew install | `npm i -g bun` |
| audio silent in render, fine in preview | `<audio>` missing `id` |
| element visible before its entrance when scrubbing | CSS transform + `.to()` → `fromTo` |
| frame renders black though preview is fine | background on composition root → full-bleed child |
| upload plays quiet on YouTube/Stream | master < −14 LUFS → loudnorm derivative |
| kokoro import errors | espeak-ng missing or venv not active |

## Non-negotiables

- Locked script before any asset; measured durations before any timing.
- Truthful, sourced claims — especially for clinical/regulated subjects.
- $0 cloud generation; network only for one-time tool/weight setup.
- One repo per video; atomic conventional commits; Python in a venv,
  black+pylint clean.
- The subject's owner signs off before the video ships to customers or
  official channels.
