# Research brief

## Question

How does `explainer-video-skill` turn an explanatory question into a
reproducible narrated video?

## Audience and scope

For technically curious viewers who want to understand the method, not buy a
product. This production explains the concept-explainer path only. Research
was restricted to the requested authoritative local sources.

## Verified findings

1. The method uses the arc “hook → context → three steps → what it means →
   recap,” and distinguishes teaching from promotion through calm pacing and
   conservative claims.  
   **Sources:** `docs/method.md`,
   “Why explainers are different from promos” and “The narrative arc”;
   `SKILL.md`, “What an explainer is” and
   “Narrative arc.”
2. The script locks before synthesis. Kokoro generates one WAV per scene;
   measured durations determine scene boundaries, audio starts, and timeline
   constants rather than guessed timing.  
   **Sources:** `SKILL.md`, “Core
   principle” and Stages 3–4; `docs/method.md`,
   “The timing discipline”; `templates/tts_generate.py`.
3. The composition is readable HTML, CSS, SVG, and GSAP. Step chips, flow
   diagrams, and data motion are its visual grammar; a paused, seek-safe
   timeline makes rendering deterministic.  
   **Sources:** `SKILL.md`, “Visual
   grammar” and Stage 6; `templates/composition-skeleton.html`.
4. Every media element needs a unique explicit ID. GSAP must be vendored, and
   the final composition must avoid CDN dependencies.  
   **Sources:** `SKILL.md`, Stage 6;
   `README.md`, “Troubleshooting”;
   `templates/composition-skeleton.html`.
5. The mandatory review ladder is lint, browser check, midpoint snapshots,
   render, then ffprobe, extracted-frame, and loudness review.  
   **Sources:** `docs/method.md`, “Quality
   gates”; `SKILL.md`, Stages 7–8.
6. The result is auditable and locally rerenderable: words, colors, scene
   timing, and motion remain editable source.  
   **Sources:** `README.md`, “What it
   produces”; `docs/method.md`, opening.

## Credit

The repository credits **Idan Shimon** for the source-code-video method and
its concept-explainer precedent. The close credits him without turning the
video into a promotion.  
**Sources:** `README.md`, “Method credit”;
`SKILL.md`, opening credit;
`docs/method.md`, opening.

