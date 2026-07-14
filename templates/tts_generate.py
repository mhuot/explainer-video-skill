"""Generate per-scene explainer narration WAVs using kokoro (offline).

Runs Kokoro-82M locally with the ``af_heart`` voice and writes one 24 kHz WAV
per scene plus a ``durations.json`` manifest — the composition's timing is
DERIVED from these measured durations, never guessed.

Edit ``SCENE_NARRATIONS`` only. Budget ≈2.55 words/second at speed 1.1.
Write acronyms spaced for TTS ("E C G", "A I"); on-screen text uses the real
spelling.
"""

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

# Explainer arc: hook → context → steps 1..3 → what it means → recap.
SCENE_NARRATIONS: list[tuple[str, str]] = [
    ("s1_hook", "<the question this video answers>"),
    ("s2_context", "<why it matters / where this sits>"),
    ("s3_step1", "<how it works — first idea, one idea per scene>"),
    ("s4_step2", "<how it works — second idea>"),
    ("s5_step3", "<how it works — third idea>"),
    ("s6_meaning", "<the outcome for the user / patient / business>"),
    ("s7_recap", "<one-sentence summary and close>"),
]


def synthesize_scene(pipeline: KPipeline, scene_id: str, narration_text: str) -> float:
    """Synthesize one scene's narration; return its duration in seconds."""
    audio_chunks = [
        chunk_audio
        for _graphemes, _phonemes, chunk_audio in pipeline(
            narration_text, voice=VOICE_NAME, speed=SPEECH_SPEED
        )
    ]
    scene_audio = np.concatenate([np.asarray(chunk) for chunk in audio_chunks])
    output_path = OUTPUT_DIRECTORY / f"{scene_id}.wav"
    soundfile.write(output_path, scene_audio, SAMPLE_RATE_HZ)
    duration_seconds = len(scene_audio) / SAMPLE_RATE_HZ
    print(f"{scene_id}: {duration_seconds:.2f}s -> {output_path.name}")
    return duration_seconds


def main() -> None:
    """Generate all scene WAVs and the durations manifest."""
    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")
    scene_durations = {
        scene_id: synthesize_scene(pipeline, scene_id, narration_text)
        for scene_id, narration_text in SCENE_NARRATIONS
    }
    manifest_path = OUTPUT_DIRECTORY / "durations.json"
    manifest_path.write_text(json.dumps(scene_durations, indent=2) + "\n")
    total_seconds = sum(scene_durations.values())
    print(f"total narration: {total_seconds:.2f}s -> {manifest_path}")


if __name__ == "__main__":
    main()
