"""Generate the locked, per-scene narration and measured duration manifest."""

import json
from pathlib import Path

import numpy as np
import soundfile
from kokoro import KPipeline

OUTPUT_DIRECTORY = (
    Path(__file__).resolve().parent.parent / "production" / "assets" / "audio"
)
SAMPLE_RATE_HZ = 24_000
VOICE_NAME = "af_heart"
SPEECH_SPEED = 1.1

SCENE_NARRATIONS: list[tuple[str, str]] = [
    (
        "s1_question",
        "How does a question become a clear narrated explainer, while every "
        "word, motion, and second stays inspectable?",
    ),
    (
        "s2_context",
        "This skill treats video as teaching, not advertising. It sets "
        "context, walks through three visible steps, then explains the result.",
    ),
    (
        "s3_research_lock",
        "First, authoritative sources support each claim. One idea is assigned "
        "to each scene. Then narration locks, so pictures cannot rewrite the "
        "explanation.",
    ),
    (
        "s4_synthesize_measure",
        "Next, Kokoro creates one wave file per scene. Each is measured. Those "
        "durations determine scene starts, audio cues, and breathing room. "
        "Timing is evidence, not a guess.",
    ),
    (
        "s5_compose_source",
        "Measured durations drive readable H T M L. C S S sets design, S V G "
        "draws diagrams, and G S A P adds seek-safe motion. Unique audio IDs "
        "and local assets make the render reproducible.",
    ),
    (
        "s6_validate_enable",
        "Finally, HyperFrames lints and checks. Midpoint snapshots are "
        "inspected before rendering. F F probe, loudness, and final frames "
        "verify the result. Corrections become edits and rerenders.",
    ),
    (
        "s7_recap_credit",
        "Recap: source, lock, measure, compose, verify. The whole video remains "
        "editable source. Method credit: Idan Shimon.",
    ),
]


def synthesize_scene(pipeline: KPipeline, scene_id: str, text: str) -> float:
    chunks = [
        chunk_audio
        for _graphemes, _phonemes, chunk_audio in pipeline(
            text, voice=VOICE_NAME, speed=SPEECH_SPEED
        )
    ]
    if not chunks:
        raise RuntimeError(f"Kokoro produced no audio for {scene_id}")
    audio = np.concatenate([np.asarray(chunk) for chunk in chunks])
    soundfile.write(OUTPUT_DIRECTORY / f"{scene_id}.wav", audio, SAMPLE_RATE_HZ)
    return len(audio) / SAMPLE_RATE_HZ


def main() -> None:
    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")
    durations = {}
    for scene_id, text in SCENE_NARRATIONS:
        durations[scene_id] = synthesize_scene(pipeline, scene_id, text)
        print(f"{scene_id}: {durations[scene_id]:.3f}s")
    (OUTPUT_DIRECTORY / "durations.json").write_text(
        json.dumps(durations, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Total narration: {sum(durations.values()):.3f}s")


if __name__ == "__main__":
    main()
