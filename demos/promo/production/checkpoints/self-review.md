# Post-render self-review

Review date: 2026-07-14  
Master: `production/renders/explainer-video-promo-v1.mp4`  
Planned duration: 59.800 s

## Gate evidence

### Script and measured timing

- The 156-word narration was locked in `production/script/script.md` before
  audio or composition work.
- The first calibration at speed 1.1 measured 68.975 s of narration, so the
  append-only decision log records a move to speed 1.33 rather than silently
  changing the words.
- Final per-scene narration measures 56.675 s total:
  `6.450, 8.000, 6.525, 6.950, 9.975, 9.850, 8.925`.
- The composition total of 59.800 s is derived from the measured clips, lead,
  0.300 s inter-scene gaps, visual pre-roll, and closing tail.
- Section starts, section durations, seven narration audio starts/durations,
  and JavaScript `S1`…`S7` constants were checked for exact agreement.
- All eight audio elements (seven voice clips plus music) have non-empty,
  unique explicit IDs and are direct children of the composition root.

### Static and browser validation

- `hyperframes lint`: **0 errors**, one accepted
  `timeline_track_too_dense` warning. The single-file seven-scene timeline is
  deliberate: the decision log selects an atelier monolithic composition so
  timing can be audited in one source file.
- `hyperframes check`: **passed**.
  - Runtime: 0 errors, 0 warnings
  - Layout: 0 issues across 9 samples
  - Motion: 0 errors, 0 warnings
  - Contrast: 40/40 text checks pass WCAG AA
- GSAP is vendored at `video/assets/gsap.min.js`; the composition contains no
  CDN or network script reference.

### Midpoint snapshot review

Snapshots were captured at the exact scene midpoints:
`3.500, 11.150, 18.713, 25.750, 34.513, 44.725, 54.800`.

Visual review result: **pass**. Every frame was full-size and styled; headings,
secondary copy, step chips, flow nodes, UI rows, waveform timing surfaces,
comparison concession, and CTA were legible with no clipping or unintended
overlap. Scene 2 showed all eight pipeline chips by its midpoint. Scene 5
showed all three synchronized timing surfaces and its measurement cursor.
Scene 6 showed both the hosted-template advantage and the developer-tool setup
concession. The warm-paper/cobalt/vermilion editorial system is visibly
distinct from the existing dark green terminal promo and the companion
explainer template.

### Render and encoded-master review

The gain-corrected final render completed in **42.0 s**. FFprobe reported:

| Check | Result |
| --- | --- |
| Encoded duration | 59.840 s (plan +0.040 s; within ±0.1 s) |
| File size | 5,437,910 bytes |
| Overall bit rate | 726,993 b/s |
| Video | H.264, 1920×1080, 30/1 fps |
| Audio | AAC, 48 kHz, stereo |

Rendered-master frames were extracted and visually reviewed at
`3.000, 11.150, 18.713, 25.750, 34.513, 44.725, 54.800`, plus the final encoded
frame at `59.766`. They matched the reviewed snapshots, showed no broken or
unstyled frames, and the final frame showed the intentional near-complete fade
to ink with the Idan Shimon credit still faintly present.

### Loudness

The initial master measured -29.4 dB mean, so it was rejected. Narration gain
was moved into the reproducible TTS source generator (1.4× with clipping
protection), assets were regenerated, and the master was re-rendered.

- Final `mean_volume`: **-26.6 dB**
- Final `max_volume`: **-6.2 dB**

This is within the promo-video method's normal pre-normalization mean range,
leaves 6.2 dB peak headroom, and keeps narration above the music bed mixed at
0.12.

## Truthfulness and release decision

- Claims are limited to the source-cleared list in the research brief.
- The comparison gives hosted templates a real one-click advantage and states
  the Node/Python/video-tooling setup cost on screen.
- No optional feedback or telemetry command was invoked.
- Method originator Idan Shimon is credited in the close and production record.
- **QA disposition: PASS.** The master is ready for repository delivery.
- **Publication caveat:** the repository owner should approve before use on
  official channels.

Transient midpoint and extracted QA PNGs were removed after this written
evidence was recorded.

