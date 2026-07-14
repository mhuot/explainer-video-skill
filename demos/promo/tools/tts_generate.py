"""Generate the locked per-scene promo narration with local Kokoro."""

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
SPEECH_SPEED = 1.33
NARRATION_GAIN = 1.4

SCENE_NARRATIONS: list[tuple[str, str]] = [
    (
        "s1_fragmented",
        "Generic A I video workflows scatter the job across prompts, voice "
        "tracks, editors, and timing adjusted by guesswork.",
    ),
    (
        "s2_reveal",
        "explainer-video turns production into one readable local pipeline: "
        "research, lock the script, synthesize, measure, animate, validate, "
        "render, review.",
    ),
    (
        "s3_concept",
        "Teach a system with a concept explainer: numbered steps, diagrams "
        "drawn with the narration, and one clear idea per scene.",
    ),
    (
        "s4_preview",
        "Show a product with a solution preview: animated HTML stats, charts, "
        "tables, and highlights that guide the viewer through the interface.",
    ),
    (
        "s5_measured",
        "Timing is measured, not eyeballed. Kokoro creates per-scene audio. "
        "Durations set scenes, audio starts, and the G S A P timeline before "
        "HyperFrames and F F mpeg render locally.",
    ),
    (
        "s6_tradeoff",
        "Setup takes developer tools; this is not a one-click cloud template. "
        "In return, keep auditable source, avoid per-render credits and "
        "watermarks, and work offline after dependencies are cached.",
    ),
    (
        "s7_cta",
        "Choose concept or preview. Lock the words. Measure the voice. Render "
        "the explanation. Explore explainer-video-skill, using the method "
        "demonstrated by Idan Shimon.",
    ),
]


def synthesize_scene(pipeline: KPipeline, scene_id: str, narration_text: str) -> float:
    """Synthesize one scene and return its measured duration."""
    audio_chunks = [
        chunk_audio
        for _graphemes, _phonemes, chunk_audio in pipeline(
            narration_text, voice=VOICE_NAME, speed=SPEECH_SPEED
        )
    ]
    if not audio_chunks:
        raise RuntimeError(f"Kokoro produced no audio for {scene_id}")

    scene_audio = np.concatenate([np.asarray(chunk) for chunk in audio_chunks])
    scene_audio = np.clip(scene_audio * NARRATION_GAIN, -1.0, 1.0)
    output_path = OUTPUT_DIRECTORY / f"{scene_id}.wav"
    soundfile.write(output_path, scene_audio, SAMPLE_RATE_HZ)
    duration_seconds = len(scene_audio) / SAMPLE_RATE_HZ
    print(f"{scene_id}: {duration_seconds:.3f}s -> {output_path.name}")
    return duration_seconds


def main() -> None:
    """Write narration WAVs and their measured duration manifest."""
    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")
    scene_durations = {
        scene_id: synthesize_scene(pipeline, scene_id, narration_text)
        for scene_id, narration_text in SCENE_NARRATIONS
    }
    manifest_path = OUTPUT_DIRECTORY / "durations.json"
    manifest_path.write_text(
        json.dumps(scene_durations, indent=2) + "\n", encoding="utf-8"
    )
    print(
        f"total narration: {sum(scene_durations.values()):.3f}s -> "
        f"{manifest_path}"
    )


if __name__ == "__main__":
    main()
