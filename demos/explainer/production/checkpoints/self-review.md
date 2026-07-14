# Self-review

## Result

**PASS** — final master:
`production/renders/explainer-video-self-explainer-v1.mp4`

The script was shortened after the first synthesis exceeded the requested
runtime, then relocked before composition. Final narration is 70.050 seconds;
measured padding produces a planned composition of 73.750 seconds.

## Timing evidence

| Scene | WAV duration | Narration start | Scene start | Scene duration | Midpoint |
| --- | ---: | ---: | ---: | ---: | ---: |
| Question | 6.975 | 0.500 | 0.100 | 7.375 | 3.788 |
| Context | 8.425 | 7.875 | 7.475 | 8.825 | 11.888 |
| Research + lock | 9.550 | 16.700 | 16.300 | 9.950 | 21.275 |
| Synthesize + measure | 10.825 | 26.650 | 26.250 | 11.225 | 31.863 |
| Compose as source | 13.800 | 37.875 | 37.475 | 14.200 | 44.575 |
| Validate + enable | 12.725 | 52.075 | 51.675 | 13.125 | 58.238 |
| Recap + credit | 7.750 | 65.200 | 64.800 | 8.950 | 69.275 |

The measured manifest, seven `<audio>` durations, seven scene boundaries, and
JS constants were compared. All seven audio durations match
`durations.json`. The composition has 143 unique IDs, including seven unique,
explicit audio IDs. No HTTP, HTTPS, or CDN reference exists in `index.html`;
GSAP is vendored locally.

## Validation

- HyperFrames `lint`: 0 errors, 2 advisory warnings. The warnings report a
  301-line composition and seven clips on one track; both are intentional for
  the required single readable composition.
- HyperFrames `check`: passed; 0 runtime, layout, or motion errors; 70/70
  WCAG AA text checks passed. Three informational connector heuristics were
  reported for the nested edit/rerender loop SVG; final-render pixels show
  the directed source → edit → rerender cycle correctly attached.
- Every measured midpoint was captured and visually inspected. The seven
  frames match the scene plan: no black frames, clipping, overflow, accidental
  overlap, missing labels, or incomplete diagram draws. The three source-card
  paths in scene 3 and the directed loop in scene 6 were specifically
  re-inspected after their endpoint geometry was corrected.

## Render QA

- Rendered by HyperFrames 0.7.57 at high quality in 23.8 seconds.
- ffprobe runtime: **73.792 s**, +0.042 s from plan and within ±0.1 s.
- File: 5,960,598 bytes; 646,205 bit/s.
- Video: H.264, 1920×1080, 30 fps.
- Audio: AAC stereo, 48 kHz.
- FFmpeg volumedetect: mean −29.5 dB; max −7.1 dB, safely below 0 dB.
- Corrected final encoded frames at 21.3 and 58.2 seconds were visually
  inspected; the unchanged approved frames retain the typography,
  warm-neutral palette, remaining diagrams, recap, and Idan Shimon credit.
- SHA-256:
  `950ac8c02630f4b0b30c732da6587903cb8c7a684088c0b8e0c65e5a99b62020`

No optional feedback or telemetry command was invoked. Transient QA frames
were removed after inspection.
