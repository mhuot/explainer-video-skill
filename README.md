# explainer-video-skill

An agent skill — built for **[Microsoft Scout](https://learn.microsoft.com/en-us/microsoft-scout/overview)**,
usable by any AI agent that reads files and runs shell commands — that
produces **45–90 second narrated explainer videos entirely offline**:
"how X works" concept explainers and solution-preview demos, with no cloud
video services, no credits, no watermarks, and $0 per render.

> **Method credit:** [**Idan Shimon**](https://github.com/idanshimon)
> (Microsoft). His *"How AI Reads a Heart"* 58-second explainer was produced
> entirely by an AI agent driving an open-source, code-based video stack —
> OpenMontage, HyperFrames, Kokoro, FFmpeg — rendered locally, fully offline,
> at $0. His cardiology solution preview showed the companion use: a customer
> demo of a product dashboard, built as source code. As he put it: *"the
> entire video is source code — any scene, word, color, or timing is a
> one-line edit and a re-render. Iteration is minutes, not days."* This skill
> packages that method.

## What it produces

Two explainer shapes, one pipeline:

1. **Concept explainer** — how a system, model, or process works: hook →
   context → three diagram-led "how it works" steps → what it means → recap.
2. **Solution preview** — a guided video tour of a product/solution UI
   (dashboards, stat tiles, charts, tables) rebuilt as animated HTML — ideal
   for customer presentations and template showcases.

```
research → outline → locked script → kokoro TTS (per scene)
        → timing DERIVED from measured narration audio
        → HTML/CSS/GSAP scenes (HyperFrames), diagram/UI-mockup grammar
        → lint → browser check → snapshot eyeball
        → deterministic render (headless Chrome + FFmpeg)
        → ffprobe/frame/loudness self-review → packaging
```

Everything is auditable source: the script, the measured `durations.json`
timing, the decision log, the QA evidence, and the video itself — one
readable HTML file.

## Requirements

| What | Why |
| --- | --- |
| Microsoft Scout (Frontier) — or another file+shell agent | the agent is the orchestrator |
| macOS (Apple Silicon proven) or Linux | all tools are cross-platform |
| Node.js ≥ 22, Python 3.12 + [uv](https://docs.astral.sh/uv/), bun | HyperFrames CLI + kokoro TTS |
| ~4 GB disk | FFmpeg build, Kokoro-82M weights (~330 MB), headless Chrome |

## One-time install

### 1. Clone the toolchain

```bash
git clone https://github.com/calesthio/OpenMontage   ~/OpenMontage
git clone https://github.com/hexgrad/kokoro          ~/kokoro
git clone https://github.com/heygen-com/hyperframes  ~/hyperframes
git clone https://git.ffmpeg.org/ffmpeg.git          ~/FFmpeg
git clone git@github.com:mhuot/explainer-video-skill.git ~/explainer-video-skill
```

### 2. System packages + builds

```bash
brew install x264 espeak-ng
npm i -g bun

# FFmpeg — must include libx264 (renders fail without it):
mkdir -p ~/ffbuild && cd ~/ffbuild
PKG_CONFIG_PATH=/opt/homebrew/opt/x264/lib/pkgconfig ~/FFmpeg/configure \
  --disable-doc --disable-debug --enable-videotoolbox \
  --enable-gpl --enable-libx264 \
  --extra-cflags="-I/opt/homebrew/opt/x264/include" \
  --extra-ldflags="-L/opt/homebrew/opt/x264/lib"
make -j8 ffmpeg ffprobe

# HyperFrames CLI — build from the monorepo root:
cd ~/hyperframes && bun install && bun run build
```

### 3. Install the skill into Microsoft Scout

```bash
cd ~/explainer-video-skill && ./install.sh            # → ~/.copilot/skills/explainer-video/
./install.sh --synced                                 # → ~/.copilot/m-skills/ (cloud-synced across devices)
```

Scout discovers skills automatically from those directories
([docs](https://learn.microsoft.com/en-us/microsoft-scout/use-microsoft-scout)).
Other agents: point your agent's instruction file at
`~/explainer-video-skill/SKILL.md` — it's a plain-markdown runbook with exact
commands.

### 4. Scout permissions (recommended)

Builds, installs, and renders sit in Scout's *Prompt* tier — approve them
when asked, or add allow patterns in **Settings → Permissions** so the render
loop runs unattended:

```
node *
python *
~/ffbuild/ffmpeg *
~/ffbuild/ffprobe *
```

Keep video projects inside your Scout workspace directory so its file tools
cover them.

### 5. Verify

```bash
export PATH="$HOME/ffbuild:$PATH"
node ~/hyperframes/packages/cli/dist/cli.js doctor   # FFmpeg/FFprobe/Chrome ✓
```

## Usage

Ask Scout (or your agent):

> "Using the explainer-video skill, make a 60-second explainer of how our
> anomaly-detection pipeline works."

> "Create a solution-preview video of the cardiology dashboard for the
> customer meeting — calm pacing, Microsoft blue, narration only."

The agent researches the subject, proposes the arc and theme, locks a script,
synthesizes narration with kokoro, derives all timing from the measured
audio, authors the scenes (diagrams, step chips, animated UI mockups),
validates, renders, and self-reviews. A complete brief (subject, audience,
duration, tone) runs end-to-end; a thin brief gets one clarifying pass at the
outline stage.

## What's in this repo

| Path | What |
| --- | --- |
| `SKILL.md` | the skill — Scout-format frontmatter + the full production runbook |
| `install.sh` | installs into `~/.copilot/skills/` (default) or `~/.copilot/m-skills/` (`--synced`) |
| `templates/tts_generate.py` | kokoro TTS script — edit the scene narration list, run |
| `templates/composition-skeleton.html` | minimal seek-safe composition with an explainer step-scene and flow-diagram sample |
| `templates/decision-log.json` | append-only decision-log schema |
| `docs/method.md` | the explainer method: narrative arc, visual grammar, script budgets |

## Tool licenses

| Tool | License notes |
| --- | --- |
| Kokoro-82M | **weights Apache 2.0** — synthesized speech usable in your videos; disclose synthetic voice where the destination requires |
| HyperFrames | Apache 2.0, no per-render fees |
| FFmpeg | GPL when built with libx264 (fine for producing videos; matters only if you redistribute the binary) |
| OpenMontage | AGPLv3 — used as tooling/reference only; nothing from it ships in your video |
| GSAP 3 | standard GSAP license; vendored file, rendering only |
| Your videos | yours; music beds are pure synthesis, no third-party audio rights |

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| render: `Unrecognized option 'preset'` | rebuild FFmpeg with `--enable-gpl --enable-libx264` |
| CLI build: cannot resolve `@hyperframes/core` | build from the monorepo root: `bun run build` |
| `bun` not found after brew install | `npm i -g bun` |
| audio silent in render | every `<audio>`/`<video>` needs an `id` |
| element visible before its entrance on scrub | use GSAP `fromTo`, no CSS `transform:` initial states |
| black frames despite clean preview | background belongs on a full-bleed child, not the root |
| kokoro import errors | `brew install espeak-ng`; activate the venv |

## License

MIT (the skill and templates). Method credit: Idan Shimon.
