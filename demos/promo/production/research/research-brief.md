# Research brief — explainer-video-skill promo

Date: 2026-07-14  
Subject: `explainer-video-skill`  
Research boundary: authoritative local repository sources only.

## Audience and job

Developers, technical storytellers, and agent users who need a short concept
explainer or product walkthrough without handing production to a cloud video
service. The promo should persuade, but every claim below is grounded in the
subject repository.

## Verified product facts

| Fact | Authoritative local source |
| --- | --- |
| The skill targets 45–90 second narrated explainers produced locally. | `README.md:5` |
| It supports two shapes: concept explainers and solution previews. | `README.md:34-40`; `SKILL.md:35-39` |
| Its pipeline locks the script, synthesizes per-scene narration, derives timing from measured audio, animates HTML/CSS/GSAP, validates, renders, and self-reviews. | `README.md:42-49`; `docs/method.md:58-68` |
| The production record is auditable source, including script, measured timing, decisions, QA evidence, and HTML composition. | `README.md:51-53` |
| Concept explainers use numbered step chips and narration-synchronized diagrams. | `SKILL.md:56-61`; `docs/method.md:40-45` |
| Solution previews rebuild key screens as animated HTML cards with stats, charts, tables, and attention guidance. | `SKILL.md:62-68`; `docs/method.md:46-49` |
| Every media element needs a unique explicit ID; validation proceeds through lint, browser check, midpoint snapshots, render, and post-render QA. | `docs/method.md:64-72`; `SKILL.md:268-289` |
| Once dependencies, browser, and Kokoro model weights are cached, narration and rendering can run offline; installation and first-use downloads can require network. | `README.md:55-58`; `SKILL.md:20-27` |
| The workflow requires no cloud generation, telemetry, or feedback submission. | `SKILL.md:20-27`; `SKILL.md:346-349` |
| The stated output has no per-render credits or watermarks and costs $0 per render. | `README.md:5-7` |
| Idan Shimon originated the demonstrated method; his concept explainer and cardiology solution preview define the two shapes. | `README.md:9-17`; `docs/method.md:3-16` |

## Honest comparison

| Workflow | Fast hosted templates | No developer setup | Auditable timing/source | Local after caches | Concession |
| --- | ---: | ---: | ---: | ---: | --- |
| Generic cloud/template video workflow | ✓ | ✓ | varies | usually no | Better for one-click starts and nontechnical editors. |
| Traditional editor + manually managed VO | varies | ✓ | project-dependent | ✓ | Mature tools offer deep hand-crafted editing control. |
| explainer-video-skill | no | no | ✓ | ✓ | Requires Node, Python, Kokoro, HyperFrames, FFmpeg, and code authoring; it is not a one-click cloud template. |

The comparison avoids claiming universal speed or quality. The defensible
advantage is a measured, code-based, locally renderable, auditable workflow—not
that it replaces every editor or hosted template.

## Claims cleared for the locked script

- Production is organized as a readable local code pipeline.
- The two supported use cases are concept explainer and solution preview.
- Concept visuals include numbered steps and narration-timed diagrams.
- Solution previews can use animated HTML stats, charts, tables, and highlights.
- Timing is measured from per-scene Kokoro audio and synchronized across scene,
  audio, and GSAP timing surfaces.
- HyperFrames and FFmpeg render the composition locally.
- Setup requires developer tooling and is not one-click.
- The user keeps auditable source.
- The method avoids per-render credits and watermarks.
- Production can run offline after dependencies, browser, and model weights are
  cached.

## Language deliberately excluded

- No claim that all generic AI video tools guess timing.
- No guarantee that iteration is always faster than every editor.
- No claim that first-time setup is offline.
- No claim of zero total cost beyond the repository's narrower “$0 per render.”
- No claim that telemetry is technically impossible—only that it is not required
  and is not submitted in this production.
