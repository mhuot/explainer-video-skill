# Changelog

## Unreleased

- Windows guidance: `references/install.md` gains a **Windows (WSL2)**
  section (WSL2 Ubuntu + the existing Debian/Ubuntu path; keep projects in
  the WSL filesystem, not `/mnt/c`; native Windows unsupported — the
  tooling is bash-based). README requirements row updated to match.

- Acronym/abbreviation pronunciation layer: `shared/tts/tts_pronounce.py`
  (canonical, stdlib-only) with an embedded lexicon of word / letters /
  literal-replacement / phoneme-override directives, vendored byte-identically
  into `skills/explainer-video/scripts/` and copied beside `tts_generate.py`
  at project setup. Narration is now written naturally ("ECG", not "E C G");
  unknown all-caps tokens are deterministically spelled letter by letter and
  reported after the run, and projects specialize via an optional
  `tools/pronunciation.local.json` overlay. The smoke test gains the module's
  `--self-test` and a `cmp` sync check between the vendored copy and the
  canonical.

- Second demo:
  [disc-golf-explainer-demo](https://github.com/mhuot/disc-golf-explainer-demo)
  — 66.1 s disc golf explainer produced with the skill and its design-system
  components; includes graded edit-after-creation teaching exercises.

- Added community and security infrastructure (issue templates, PR template, SECURITY.md).
- GitHub Actions CI: shellcheck + smoke test on Ubuntu and macOS, with an
  install → `--version` → `--uninstall` lifecycle exercise and
  mutual-exclusion guard test.
- `install.sh` gains `--version` (source vs installed comparison) and
  `--uninstall` (combinable with target flags; mutually exclusive with
  `--version`).
- README badges: CI status, MIT license (static — the annotated LICENSE
  defeats GitHub auto-detection), and version from the latest git tag.
- `assets/spatial-components.html`: layout-only templates (step chip, flow
  diagram, annotated UI mockup) — spatial structure only, timing still
  derived from measured audio.
- SKILL.md: explicit three-point snapshot QA checklist (contrast, overlap,
  composition) for vision-capable agents, with `--describe` as the optional
  networked alternative.
- `AGENTS.md`: contributor instructions for AI agents — verification gates,
  branch hygiene, resource-integration checklist, release procedure, and
  the design principles reviews enforce.

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
