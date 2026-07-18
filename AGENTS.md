# Working on this repo (instructions for AI agents)

This repo packages the `explainer-video` agent skill: `skills/explainer-video/`
(SKILL.md + `scripts/`, `references/`, `assets/`), `install.sh`, and Claude Code
plugin manifests in `.claude-plugin/`. Contributors to this repo are usually AI
agents. These rules exist because each one was violated at least once; reviews
enforce them.

## Before you start

- Work from current `main` HEAD. Check `git log --oneline -10` and the latest
  GitHub Actions runs before proposing or implementing anything — do not
  recommend work that already exists.
- Create a **fresh branch per task**. Never push to a branch that was already
  merged or deleted; work pushed there has been orphaned before and required
  SHA-level recovery.

## Verify before you ship

- Run both, locally, before every commit:
  - `shellcheck install.sh skills/explainer-video/scripts/smoke_test.sh`
  - `bash skills/explainer-video/scripts/smoke_test.sh`
- CI runs triggered by bot pushes sit at `action_required` and never execute.
  If you cannot see your own CI run complete, say so explicitly in your
  summary — never imply tests passed when they did not run.
- If you changed `install.sh` behavior, exercise the full lifecycle:
  install → `--version` → `--uninstall` → reinstall, plus invalid-flag and
  combined-flag cases.

## Integration checklist for skill resources

Adding, renaming, or removing any file under `skills/explainer-video/`
requires touching every one of these, in the same commit:

1. `install.sh` — the explicit per-file install list
2. `scripts/smoke_test.sh` — the `required_file` list
3. `SKILL.md` — reference the resource (`$EXPLAINER_VIDEO_SKILL_DIR/...` or
   backtick-quoted path); the smoke test validates these references resolve
4. `README.md` — the "What's in this repo" table if user-visible
5. `CHANGELOG.md` — under an `Unreleased` heading

## Releases and versioning

`metadata.version` in SKILL.md frontmatter, `version` in
`.claude-plugin/plugin.json`, the `CHANGELOG.md` heading, and the git tag
(`vX.Y.Z`) move **together** in one release commit. The README version badge
reads the latest tag.

## Design principles you must not violate

- **Timing is derived, never copied.** All scene/audio timing comes from
  measured narration WAVs (`durations.json`). Never add templates, examples,
  or code with hardcoded timeline values. Spatial (layout-only) templates are
  fine — see `assets/spatial-components.html` for the pattern.
- **No required cloud services.** Production must work offline after cached
  setup. Network-using features must be optional and labeled.
- **Explicit commands, no wrappers.** SKILL.md carries raw shell commands so
  every flag lands in the auditable production record. Do not abstract them
  behind wrapper scripts.
- **No media or large binaries in this repo.** History was rewritten to purge
  them; renders and demo media belong in
  [explainer-video-skill-demo](https://github.com/mhuot/explainer-video-skill-demo).
- **LICENSE keeps its method-credit lines.** GitHub license detection fails on
  it by design; the README uses a static MIT badge for this reason.
- **Sourced claims only.** Anything stated as fact in SKILL.md or references
  (voice lists, platform policies, tool behavior) must come from upstream
  docs or a validated run, not memory.

## Commits

- Conventional commits (`feat:`, `fix:`, `docs:`, `ci:`, `refactor:`), atomic —
  one logical change per commit, so individual changes can be reverted.
- Python must be pylint/black compliant and run in a uv-managed venv.
