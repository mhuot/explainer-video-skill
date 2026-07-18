# Changelog

## 1.0.0 — 2026-07-18

First public release.

- Skill restructured to the conventional Agent Skills layout:
  `skills/explainer-video/` with `scripts/`, `references/`, and `assets/`.
- Once-per-machine toolchain bootstrap moved from `SKILL.md` to
  `references/install.md` (progressive disclosure); `SKILL.md` now carries a
  short `doctor` environment check instead.
- Frontmatter gains `license: MIT` and `metadata.version`.
- Claude Code plugin packaging (`.claude-plugin/`) alongside `install.sh`
  for Scout, GitHub Copilot CLI, and Google Gemini CLI.
- `scripts/smoke_test.sh`: package validation plus optional
  HyperFrames lint/check against the bundled composition skeleton.
- Linux instructions validated end-to-end on a fresh Ubuntu 24.04 machine;
  fixes from that run (user-local bun install, shallow clones, harmless
  `sdk-playground` build failure, `t64` package names, zsh-safe commands).
- Demo production moved to
  [explainer-video-skill-demo](https://github.com/mhuot/explainer-video-skill-demo);
  repo history rewritten to exclude media, so clones are ~200 KB.
