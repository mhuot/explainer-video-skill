# explainer-video-skill

An agent skill — usable by any AI agent that reads files and runs shell
commands — that produces **45–90 second narrated explainer videos locally**:
"how X works" concept explainers and solution-preview demos, with no cloud
video services, no credits, no watermarks, and $0 per render.

> **Method credit:** [**Idan Shimon**](https://github.com/idanshimon).
> His 58-second concept explainer was produced entirely by an
> AI agent driving an open-source, code-based video stack —
> OpenMontage, HyperFrames, Kokoro, FFmpeg — rendered locally without paid
> cloud generation, at $0. His cardiology solution preview showed the companion use: a customer
> demo of a product dashboard, built as source code. As he put it: *"the
> entire video is source code — any scene, word, color, or timing is a
> one-line edit and a re-render. Iteration is minutes, not days."* This skill
> packages that method.

## Dogfood demos: teaching and promotion

**Promo sells; explainer teaches.** These two productions use both skills on
the same subject so the difference is concrete:

| Job | Produced with | Watch | Source and reproduction |
| --- | --- | --- | --- |
| Teach how `explainer-video` works | `explainer-video` | [73.8s final MP4](demos/explainer/production/renders/explainer-video-self-explainer-v1.mp4) | [`demos/explainer/`](demos/explainer/) |
| Promote `explainer-video` | `promo-video` | [59.8s final MP4](demos/promo/production/renders/explainer-video-promo-v1.mp4) | [`demos/promo/`](demos/promo/) |

See the [demo matrix and source index](demos/README.md) for both production
records and the companion `promo-video-skill` row.

## What it produces

Two explainer shapes, one pipeline:

1. **Concept explainer** — how a system, model, or process works: hook →
   context → three diagram-led "how it works" steps → what it means → recap.
2. **Solution preview** — a guided video tour of a product/solution UI
   (dashboards, stat tiles, charts, tables) rebuilt as animated HTML — ideal
   for customer presentations and template showcases.

```
research → outline → locked script → Kokoro TTS (per scene)
        → timing DERIVED from measured narration audio
        → HTML/CSS/GSAP scenes (HyperFrames), diagram/UI-mockup grammar
        → lint → browser check → snapshot eyeball
        → deterministic render (headless Chrome + FFmpeg)
        → ffprobe/frame/loudness self-review → packaging
```

Everything is auditable source: the script, the measured `durations.json`
timing, the decision log, the QA evidence, and the video itself — one
readable HTML file.

Once dependencies, the browser, and model weights are cached, narration and
rendering can run offline. Installation, first model use, optional online
research, and optional feedback need network access. The workflow does not
require telemetry or feedback submission.

## What is a skill?

A **skill** is a plain-text runbook (`SKILL.md`) that an AI agent discovers
automatically and uses as a set of step-by-step instructions. No SDK, no
plugin, no API key — it is just a markdown file the agent reads.

Agents that natively discover directory-based skills:

| Agent | Skill directory | Documentation |
| --- | --- | --- |
| **GitHub Copilot CLI** | `~/.copilot/skills/` | [Copilot CLI skills docs](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills) |
| **Scout** (GitHub Copilot cloud agent) | `~/.copilot/skills/` or `~/.copilot/m-skills/` (cloud-synced) | [Scout docs](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/cloud-agent) |
| **Claude Code** | `~/.claude/skills/` | [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code/overview) |
| **Google Gemini CLI** (Antigravity) | `~/.gemini/antigravity/global_skills/` | [Gemini CLI repo](https://github.com/google-gemini/gemini-cli) |

Any other agent: point its instruction file at an installed `SKILL.md`.
`install.sh` copies the right files to each location.

## Requirements

| What | Why |
| --- | --- |
| Any file+shell agent (Scout, GitHub Copilot CLI, Claude Code, Gemini CLI) | the agent is the orchestrator |
| macOS or Debian/Ubuntu Linux | both bootstrap paths are documented below |
| Node.js ≥ 22, Python 3.12 + [uv](https://docs.astral.sh/uv/), bun | HyperFrames CLI + Kokoro TTS |
| ~4 GB disk | FFmpeg build, Kokoro-82M weights (~330 MB), headless Chrome |

## One-time install

### 1. Clone the required source tools

```bash
git clone https://github.com/heygen-com/hyperframes "$HOME/hyperframes"
git clone https://git.ffmpeg.org/ffmpeg.git "$HOME/FFmpeg"
export HYPERFRAMES_DIR="${HYPERFRAMES_DIR:-$HOME/hyperframes}"
export FFMPEG_SOURCE_DIR="${FFMPEG_SOURCE_DIR:-$HOME/FFmpeg}"
export FFMPEG_BUILD_DIR="${FFMPEG_BUILD_DIR:-$HOME/ffbuild}"
```

Clone or download this repository from the URL where you found it; it may
live anywhere. OpenMontage inspired the governance conventions, but no
reference or private repository is required to use the skill. Kokoro is
installed from PyPI in the project environment rather than from a source
checkout.

### 2. System packages

macOS with Homebrew:

```bash
brew install node uv x264 pkg-config nasm espeak-ng libsndfile
npm install --global bun
```

Debian/Ubuntu Linux:

```bash
sudo apt-get update
ASOUND_PACKAGE=libasound2
apt-cache show libasound2t64 >/dev/null 2>&1 && ASOUND_PACKAGE=libasound2t64
sudo apt-get install -y build-essential curl git pkg-config nasm yasm \
  libx264-dev espeak-ng libespeak-ng1 libsndfile1 ca-certificates \
  fonts-liberation "$ASOUND_PACKAGE" libatk-bridge2.0-0 libatk1.0-0 libcups2 \
  libdbus-1-3 libdrm2 libgbm1 libgtk-3-0 libnspr4 libnss3 libx11-xcb1 \
  libxcomposite1 libxdamage1 libxfixes3 libxkbcommon0 libxrandr2 xdg-utils
curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh
sudo -E bash nodesource_setup.sh
rm nodesource_setup.sh
sudo apt-get install -y nodejs
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
npm install --global bun
```

Confirm `node --version` is 22 or newer and `uv --version` succeeds (start a
new shell after the uv installer if needed). The additional Linux libraries
support Puppeteer's headless Chrome.

### 3. Build FFmpeg with libx264

The platform-specific configure flags are intentionally different.

macOS:

```bash
mkdir -p "$FFMPEG_BUILD_DIR" && cd "$FFMPEG_BUILD_DIR"
X264_PREFIX="$(brew --prefix x264)"
PKG_CONFIG_PATH="$X264_PREFIX/lib/pkgconfig" "$FFMPEG_SOURCE_DIR/configure" \
  --disable-doc --disable-debug --enable-videotoolbox \
  --enable-gpl --enable-libx264 \
  --extra-cflags="-I$X264_PREFIX/include" \
  --extra-ldflags="-L$X264_PREFIX/lib"
make -j"$(sysctl -n hw.ncpu)" ffmpeg ffprobe
./ffmpeg -hide_banner -encoders | grep libx264
```

Linux:

```bash
mkdir -p "$FFMPEG_BUILD_DIR" && cd "$FFMPEG_BUILD_DIR"
"$FFMPEG_SOURCE_DIR/configure" \
  --disable-doc --disable-debug --enable-gpl --enable-libx264
make -j"$(nproc)" ffmpeg ffprobe
./ffmpeg -hide_banner -encoders | grep libx264
```

### 4. Build HyperFrames

```bash
cd "$HYPERFRAMES_DIR"
bun install
bun run build
test -f packages/cli/dist/cli.js
```

This install and HyperFrames' first browser launch require network access.

### 5. Install the skill

```bash
cd /path/to/explainer-video-skill
./install.sh                 # all three agents below
./install.sh --claude        # Claude Code            → ~/.claude/skills/explainer-video/
./install.sh --copilot       # GitHub Copilot CLI + Scout → ~/.copilot/skills/explainer-video/
./install.sh --antigravity   # Google Gemini CLI      → ~/.gemini/antigravity/global_skills/explainer-video/
./install.sh --synced        # Scout, cloud-synced    → ~/.copilot/m-skills/explainer-video/
```

Each target gets `SKILL.md`, `README.md`, `LICENSE`, `templates/`, and
`docs/`, so resource references work even if the source clone is elsewhere.
Set `EXPLAINER_VIDEO_SKILL_DIR` to an installed directory when running
template commands.

Agent discovery paths:

- **Scout and GitHub Copilot CLI:** `~/.copilot/skills/` ([Copilot docs](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills))
- **Claude Code:** `~/.claude/skills/` ([Claude Code docs](https://docs.anthropic.com/en/docs/claude-code/overview))
- **Google Gemini CLI:** `~/.gemini/antigravity/global_skills/` ([Gemini CLI repo](https://github.com/google-gemini/gemini-cli))
- **Other agents:** point your instruction file at any installed `SKILL.md`

### 6. Scout permissions (recommended)

Builds, installs, and renders sit in Scout's *Prompt* tier — approve them
when asked, or add allow patterns in **Settings → Permissions** so the render
loop runs unattended:

```
node *
python *
/absolute/path/to/ffbuild/ffmpeg *
/absolute/path/to/ffbuild/ffprobe *
```

Keep video projects inside your Scout workspace directory so its file tools
cover them.

### 7. Verify

```bash
export PATH="$FFMPEG_BUILD_DIR:$PATH"
node "$HYPERFRAMES_DIR/packages/cli/dist/cli.js" doctor
# FFmpeg, FFprobe, Node, and Chrome must pass.
```

### 8. Create a video project's Python environment

Run this in each video project. It explicitly selects Python 3.12 and
installs every third-party import used by the TTS template:

```bash
cd /path/to/video-project
uv venv --python 3.12 .venv
uv pip install --python .venv/bin/python "kokoro>=0.9.4,<1" numpy soundfile
export EXPLAINER_VIDEO_SKILL_DIR="/path/to/installed-or-source/explainer-video-skill"
mkdir -p tools
cp "$EXPLAINER_VIDEO_SKILL_DIR/templates/tts_generate.py" tools/
mkdir -p video/assets
curl -fL https://cdn.jsdelivr.net/npm/gsap@3.15.0/dist/gsap.min.js \
  -o video/assets/gsap.min.js
```

The final command vendors GSAP once; renders never load it from a CDN.

## Usage

Ask your agent:

> "Using the explainer-video skill, make a 60-second explainer of how our
> anomaly-detection pipeline works."

> "Create a solution-preview video of the cardiology dashboard for the
> customer meeting — calm pacing, blue accent, narration only."

The agent researches the subject, proposes the arc and theme, locks a script,
synthesizes narration with Kokoro, derives all timing from the measured
audio, authors the scenes (diagrams, step chips, animated UI mockups),
validates, renders, and self-reviews. A complete brief (subject, audience,
duration, tone) runs end-to-end; a thin brief gets one clarifying pass at the
outline stage.

## How this compares to other approaches

| Approach | Fast start | No code required | Auditable source | Local after setup | Notes |
| --- | :---: | :---: | :---: | :---: | --- |
| **Cloud / template video services** (Synthesia, Runway, Lumen5) | ✓ | ✓ | — | usually no | Best for one-click starts and non-technical editors |
| **Traditional editor + manual VO** (Premiere, DaVinci) | — | ✓ | project-dependent | ✓ | Deep hand-crafted control; timing is manual |
| **explainer-video-skill** | — | — | ✓ | ✓ (after caches) | Requires Node, Python, and code authoring; not one-click |

The defensible advantage of this skill is a **measured, code-based, locally
renderable, auditable workflow** — any scene, word, color, or timing stays
editable source and re-renders in minutes. It is not a replacement for
hosted templates or hand-crafted editing.

## What's in this repo

| Path | What |
| --- | --- |
| [`SKILL.md`](SKILL.md) | the skill — agent frontmatter + the full production runbook |
| [`install.sh`](install.sh) | installs the skill and resources locally or synced |
| [`templates/tts_generate.py`](templates/tts_generate.py) | generic Kokoro TTS script — edit the scene narration list, run |
| [`templates/composition-skeleton.html`](templates/composition-skeleton.html) | minimal seek-safe composition with an explainer step-scene and flow-diagram sample |
| [`templates/decision-log.json`](templates/decision-log.json) | append-only decision-log schema |
| [`docs/method.md`](docs/method.md) | the explainer method: narrative arc, visual grammar, script budgets |
| [`demos/README.md`](demos/README.md) | cross-dogfood matrix and compact demo index |
| [`demos/explainer/`](demos/explainer/) | explainer-produced teaching video: source, production record, and final render |
| [`demos/promo/`](demos/promo/) | promo-produced promotional video: source, production record, and final render |

## External resources

| Resource | Link |
| --- | --- |
| **HyperFrames** — HTML/CSS/GSAP → MP4 renderer | [github.com/heygen-com/hyperframes](https://github.com/heygen-com/hyperframes) |
| **Kokoro** — local TTS model | [PyPI: kokoro](https://pypi.org/project/kokoro/) · [Model weights: hexgrad/Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) |
| **FFmpeg** — video encoding and audio processing | [ffmpeg.org](https://ffmpeg.org/) |
| **GSAP** — animation library (vendored for offline rendering) | [gsap.com](https://gsap.com/) |
| **uv** — fast Python package and environment manager | [docs.astral.sh/uv](https://docs.astral.sh/uv/) |
| **bun** — fast JavaScript runtime / package manager | [bun.sh](https://bun.sh/) |
| **GitHub Copilot CLI skills** | [docs.github.com](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills) |
| **Claude Code** | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code/overview) |
| **Google Gemini CLI** | [github.com/google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) |

## Tool licenses

| Tool | License notes |
| --- | --- |
| Kokoro Python code | **Apache 2.0** |
| Kokoro-82M model weights | **Apache 2.0** |
| HyperFrames | Apache 2.0, no per-render fees |
| FFmpeg | GPL when built with libx264 (fine for producing videos; matters only if you redistribute the binary) |
| OpenMontage | AGPLv3 — acknowledged as a process influence; no checkout is required |
| GSAP 3 | standard GSAP license; vendored file, rendering only |
| Output videos | review all input licenses; ownership depends on inputs and applicable law |

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| render: `Unrecognized option 'preset'` | rebuild FFmpeg with `--enable-gpl --enable-libx264` |
| CLI build: cannot resolve `@hyperframes/core` | build from the monorepo root: `bun run build` |
| `bun` not found after brew install | `npm i -g bun` |
| HyperFrames audio plays in a browser preview but renders silently | give every `<audio>` an explicit, non-empty, unique `id` (and every `<video>` an `id`) |
| element visible before its entrance on scrub | use GSAP `fromTo`, no CSS `transform:` initial states |
| black frames despite clean preview | background belongs on a full-bleed child, not the root |
| Kokoro import/G2P errors | install `espeak-ng` with Homebrew or apt; use the project's `.venv` |

## YouTube synthetic-content disclosure

YouTube requires disclosure for realistic, meaningfully generated or altered
content that could be mistaken for real events or a real person's actions.
It does **not** say every synthetic narration requires disclosure: its
examples exempt cloning one's own voice for voiceovers, while impersonating
a real person requires disclosure. Evaluate the finished video, not merely
the use of Kokoro; disclose when required or when uncertain. Disclosure does
not by itself restrict audience or monetization. See YouTube's official
[AI disclosure policy](https://support.google.com/youtube/answer/14328491).

## License

MIT (the skill and templates). Method credit: Idan Shimon.
