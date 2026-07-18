# Environment bootstrap (once per machine)

Read this only when the toolchain is not yet installed — if
`node "$HYPERFRAMES_DIR/packages/cli/dist/cli.js" doctor` already passes
FFmpeg, FFprobe, Node, and Chrome, skip this file entirely.

## System packages

Choose one system-package block.

```bash
# macOS (Homebrew)
brew install node uv x264 pkg-config nasm espeak-ng libsndfile
npm install --global bun
```

```bash
# Debian/Ubuntu Linux
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
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"
```

On Linux, bun's user-local installer avoids the sudo that a global npm
install would need. The additional Linux libraries support Puppeteer's
headless Chrome; on Ubuntu 24.04 some names resolve to `t64` packages
automatically.

## Source tools

Clone HyperFrames and FFmpeg from their public repositories if absent
(`--depth 1` is sufficient — both build from a snapshot):

```bash
git clone --depth 1 https://github.com/heygen-com/hyperframes "$HOME/hyperframes"
git clone --depth 1 https://git.ffmpeg.org/ffmpeg.git "$HOME/FFmpeg"
export HYPERFRAMES_DIR="${HYPERFRAMES_DIR:-$HOME/hyperframes}"
export FFMPEG_SOURCE_DIR="${FFMPEG_SOURCE_DIR:-$HOME/FFmpeg}"
export FFMPEG_BUILD_DIR="${FFMPEG_BUILD_DIR:-$HOME/ffbuild}"
```

## Build FFmpeg

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

Linux (do not use the macOS-only VideoToolbox/Homebrew flags):

```bash
mkdir -p "$FFMPEG_BUILD_DIR" && cd "$FFMPEG_BUILD_DIR"
"$FFMPEG_SOURCE_DIR/configure" \
  --disable-doc --disable-debug --enable-gpl --enable-libx264
make -j"$(nproc)" ffmpeg ffprobe
./ffmpeg -hide_banner -encoders | grep libx264
```

## Build HyperFrames and verify

```bash
cd "$HYPERFRAMES_DIR"
bun install
bun run build
test -f packages/cli/dist/cli.js
export PATH="$FFMPEG_BUILD_DIR:$PATH"
node "$HYPERFRAMES_DIR/packages/cli/dist/cli.js" doctor
```

`bun run build` may exit non-zero because the optional `sdk-playground`
package fails on Node 22; that is harmless. `test -f
packages/cli/dist/cli.js` is the real success gate.

`doctor` may download Chrome on first use. FFmpeg, FFprobe, Node, and Chrome
must all pass before production.

**Scout / GitHub Copilot note:** builds and installs (`npm i`, `bun install`,
`make`) sit in Scout's *Prompt* permission tier — approve them when asked, or
pre-add allow patterns in **Settings → Permissions** (e.g. `node *`,
`python *`, `$FFMPEG_BUILD_DIR/ffmpeg *`,
`$FFMPEG_BUILD_DIR/ffprobe *`) so the render loop
runs unattended. Keep the video project inside your Scout workspace
directory so file tools cover it.
