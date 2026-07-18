# The Explainer Method

Credit: **Idan Shimon** ([github.com/idanshimon](https://github.com/idanshimon)). Two of his productions define the two
shapes this skill produces:

- A 58-second **concept explainer** produced entirely by an AI agent driving
  an open-source, code-based video stack
  (OpenMontage → HyperFrames → Kokoro → FFmpeg), rendered locally without
  paid cloud generation, at $0. No video editor, no manual animation, no
  stock-footage licensing.
- A cardiology department AI **solution preview** — a customer-facing video
  demo of a product dashboard, built from animated HTML mockups of the real
  screens.

His framing is the method's core: **the entire video is source code.** Any
scene, word, color, or timing is a one-line edit and a re-render — no
re-shoots, no re-recording. Iteration is minutes, not days.

## Why explainers are different from promos

| | Explainer | Promo |
| --- | --- | --- |
| Goal | teach / preview | persuade |
| Opening | a question worth answering | a pain hook |
| Core | steps or a guided tour | features + comparison |
| Close | recap + "learn more" | call to action |
| Pacing | calm, breathing room | punchy |
| Claims | conservative, sourced; disclaimers for regulated subjects | competitive |

## The narrative arc

Hook (the question) → Context (why it matters) → **How it works** — three
steps, one idea per scene, each anchored by a numbered step chip → What it
means (the outcome) → Recap + close.

Script budget ≈ 2.55 words/second at Kokoro `af_heart` speed 1.1:
~125 words for 50 s, ~150 for 60 s, ~210 for 85 s.

## Visual grammar

1. **Step chips** — `01 / 02 / 03` in a consistent corner; the viewer always
   knows where they are.
2. **Flow diagrams** — SVG nodes and edges; edges draw with
   `strokeDashoffset` tweens *timed to the narration beat*, labels land as
   the voice reaches them.
3. **Animated UI mockups** (solution previews) — rebuild the key screens as
   HTML: stat tiles whose numbers matter, charts whose bars/arcs animate
   (`scaleX`, `strokeDashoffset`), tables that populate row by row, a
   highlight ring that guides the eye. Never a static screenshot.
4. **One accent color** on a neutral ground; a clear blue (`#0078d4`)
   suits customer-facing previews. All tokens in `:root` CSS vars — a re-skin
   is a five-line edit.
5. **Calm motion** — eased entrances, 0.4–0.6 s scene padding, no glitch
   effects. The subject is the star, not the animation.

## The timing discipline

Narration is synthesized first (Kokoro, one WAV per scene), durations are
measured into `durations.json`, and every scene boundary, audio start, and
timeline constant is **derived** from those measurements. A script change is
a re-measure and a re-derive — pacing never drifts out of sync with the
voice.

## Quality gates

HyperFrames audio without an explicit, non-empty `id` may play in a browser
preview but renders silently, so every `<audio>` receives a unique `id`.

`lint` (static rules) → `check` (real browser: runtime errors, layout,
motion, WCAG AA contrast) → `snapshot` at every scene midpoint (a human or
agent actually looks at the frames) → render → ffprobe + frame extraction +
loudness self-review. Nothing ships unreviewed.

## Reproducibility and network boundary

The render is local and deterministic after dependencies, Kokoro weights,
the headless browser, and GSAP are cached. Installing those resources and
the first model/browser use require network access; research may also be
online when the brief calls for current sources. Feedback submission is
optional, networked, and never a production gate. See the complete,
portable setup and platform commands in [`../SKILL.md`](../SKILL.md).
