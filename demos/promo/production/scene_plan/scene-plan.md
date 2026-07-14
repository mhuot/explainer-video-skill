# Scene plan — measured lock

Measured narration source:
`production/assets/audio/durations.json` generated from the locked script with
Kokoro `af_heart` at speed 1.33.

## Derived timing

Derivation uses a 0.50 s opening lead, 0.30 s between narration clips, visuals
landing 0.25 s before narration (except scene 1), and a 0.825 s closing tail.

| Scene | Visual start | Narration start | Measured VO | Scene duration | Midpoint |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 Fragmented | 0.000 | 0.500 | 6.450 | 7.000 | 3.500 |
| 2 Reveal | 7.000 | 7.250 | 8.000 | 8.300 | 11.150 |
| 3 Concept | 15.300 | 15.550 | 6.525 | 6.825 | 18.713 |
| 4 Preview | 22.125 | 22.375 | 6.950 | 7.250 | 25.750 |
| 5 Measured | 29.375 | 29.625 | 9.975 | 10.275 | 34.513 |
| 6 Trade-off | 39.650 | 39.900 | 9.850 | 10.150 | 44.725 |
| 7 CTA | 49.800 | 50.050 | 8.925 | 10.000 | 54.800 |

Composition total: **59.800 s**. Narration ends at 58.975 s; final fade
completes at 59.800 s.

The same visual starts are used for section `data-start`, section duration
boundaries, and JavaScript constants `S1`…`S7`. The narration starts and
measured durations are copied exactly to the seven direct-root audio elements.

## Visual and motion beats

### 1 — Fragmented workflow

- Oversized “GENERIC AI / VIDEO WORKFLOW” headline on warm paper.
- Four disconnected cards—PROMPTS, VOICE, EDITOR, TIMING—enter from opposing
  directions.
- Vermilion dotted routing ends at “GUESSWORK?” rather than forming a flow.

### 2 — Reveal the product

- A cobalt field cuts in sharply.
- `explainer-video` lands as the hero lockup.
- Eight compact source-to-video stage chips form one readable rail; a bright
  progress line connects them.

### 3 — Concept explainer

- Editorial split: numbered `01 / 02 / 03` chips at left.
- An SVG source→model→meaning diagram draws in sync, with one highlighted idea.
- On-screen proof line: “ONE IDEA / EACH SCENE.”

### 4 — Solution preview

- Animated HTML UI on the left: stat tile, table rows, and a chart that grows.
- A sharp annotation panel on the right names the use case.
- Highlight ring guides attention without implying a real product screenshot.

### 5 — Measured local pipeline

- A waveform/ruler occupies the center.
- Three synchronized surfaces—SCENES, AUDIO, GSAP—snap to one vertical timing
  cursor.
- Local tool chips identify Kokoro, HyperFrames, and FFmpeg.

### 6 — Honest comparison

- Two-column comparison with explicit concessions.
- “ONE-CLICK START” favors hosted templates; “AUDITABLE SOURCE” and “LOCAL
  AFTER CACHES” favor explainer-video.
- Footer states the real cost: “SETUP: NODE + PYTHON + VIDEO TOOLING.”

### 7 — CTA and credit

- Two shape cards: CONCEPT and PREVIEW.
- Four-beat CTA: LOCK → MEASURE → RENDER → EXPLAIN.
- Final lockup credits “Method demonstrated by Idan Shimon.”
- Warm-paper frame fades fully to ink at the exact composition end.

## Snapshot review targets

At each midpoint verify the intended information hierarchy, full-frame styling,
no clipping, correct use-case motif, and readable secondary contrast. Snapshot
PNGs are transient QA artifacts and are removed after evidence is recorded.
