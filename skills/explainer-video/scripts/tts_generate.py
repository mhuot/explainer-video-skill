"""Generate generic per-scene explainer narration WAVs with Kokoro.

After its model files are cached, Kokoro-82M inference runs locally without a
network connection. This template writes one 24 kHz WAV per scene plus a
``durations.json`` manifest from which composition timing can be derived.

Replace every placeholder in ``SCENE_NARRATIONS`` before running. Budget
approximately 2.55 words/second at speed 1.1. Write acronyms naturally
(``ECG``, ``NASA``); the sibling ``tts_pronounce.py`` decides word vs
letter-by-letter pronunciation from its lexicon at synthesis time. Unknown
acronyms are spelled letter by letter and reported after the run — classify
them in an optional ``pronunciation.local.json`` beside this script. Avoid
ALL-CAPS emphasis; an all-caps word reads as an acronym.
"""

import json
import re
import shutil
from collections.abc import Mapping
from pathlib import Path

import numpy as np
import soundfile
from kokoro import KPipeline

from tts_pronounce import load_local_lexicon, prepare_for_tts

OUTPUT_DIRECTORY = (
    Path(__file__).resolve().parent.parent / "production" / "assets" / "audio"
)
COMPOSITION_AUDIO_DIRECTORY = (
    Path(__file__).resolve().parent.parent / "video" / "assets" / "audio"
)
SAMPLE_RATE_HZ = 24_000
VOICE_NAME = "af_heart"
SPEECH_SPEED = 1.1
LOCAL_LEXICON_PATH = Path(__file__).with_name("pronunciation.local.json")
SCENE_ID_PATTERN = re.compile(r"^[a-z0-9][a-z0-9_-]*$")

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


def validate_scene_narrations() -> None:
    """Reject placeholders, unsafe IDs, and duplicate scene IDs."""
    if not SCENE_NARRATIONS:
        raise ValueError("SCENE_NARRATIONS must contain at least one scene")
    seen_ids: set[str] = set()
    for scene_id, narration_text in SCENE_NARRATIONS:
        if not SCENE_ID_PATTERN.fullmatch(scene_id):
            raise ValueError(
                f"invalid scene ID {scene_id!r}; use lowercase letters, "
                "numbers, underscores, or hyphens"
            )
        if scene_id in seen_ids:
            raise ValueError(f"duplicate scene ID: {scene_id}")
        seen_ids.add(scene_id)
        narration_text = narration_text.strip()
        if not narration_text:
            raise ValueError(f"narration is empty for {scene_id}")
        if narration_text.startswith("<") and narration_text.endswith(">"):
            raise ValueError(f"replace the narration placeholder for {scene_id}")


def synthesize_scene(
    pipeline: KPipeline,
    scene_id: str,
    narration_text: str,
    lexicon_overlay: Mapping[str, str],
) -> tuple[float, list[str]]:
    """Synthesize one scene's narration; return (duration seconds, unknown acronyms)."""
    narration_text = narration_text.strip()
    if not narration_text:
        raise ValueError(f"narration is empty for {scene_id}")
    if narration_text.startswith("<") and narration_text.endswith(">"):
        raise ValueError(f"replace the narration placeholder for {scene_id}")

    pronounced = prepare_for_tts(narration_text, lexicon_overlay)
    audio_chunks = [
        chunk_audio
        for _graphemes, _phonemes, chunk_audio in pipeline(
            pronounced.text, voice=VOICE_NAME, speed=SPEECH_SPEED
        )
    ]
    if not audio_chunks:
        raise RuntimeError(f"Kokoro produced no audio for {scene_id}")

    scene_audio = np.concatenate([np.asarray(chunk) for chunk in audio_chunks])
    output_path = OUTPUT_DIRECTORY / f"{scene_id}.wav"
    soundfile.write(output_path, scene_audio, SAMPLE_RATE_HZ)
    composition_path = COMPOSITION_AUDIO_DIRECTORY / output_path.name
    shutil.copy2(output_path, composition_path)
    duration_seconds = len(scene_audio) / SAMPLE_RATE_HZ
    print(f"{scene_id}: {duration_seconds:.2f}s -> {output_path.name}")
    return duration_seconds, pronounced.unknown


def main() -> None:
    """Generate all scene WAVs and the durations manifest."""
    validate_scene_narrations()
    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)
    COMPOSITION_AUDIO_DIRECTORY.mkdir(parents=True, exist_ok=True)
    lexicon_overlay = load_local_lexicon(LOCAL_LEXICON_PATH)
    pipeline = KPipeline(lang_code="a", repo_id="hexgrad/Kokoro-82M")
    scene_durations: dict[str, float] = {}
    unknown_acronyms: set[str] = set()
    for scene_id, narration_text in SCENE_NARRATIONS:
        duration_seconds, unknown = synthesize_scene(
            pipeline, scene_id, narration_text, lexicon_overlay
        )
        scene_durations[scene_id] = duration_seconds
        unknown_acronyms.update(unknown)
    manifest_path = OUTPUT_DIRECTORY / "durations.json"
    manifest_path.write_text(
        json.dumps(scene_durations, indent=2) + "\n", encoding="utf-8"
    )
    shutil.copy2(manifest_path, COMPOSITION_AUDIO_DIRECTORY / manifest_path.name)
    total_seconds = sum(scene_durations.values())
    print(f"total narration: {total_seconds:.2f}s -> {manifest_path}")
    if unknown_acronyms:
        tokens = ", ".join(sorted(unknown_acronyms))
        print(f"WARNING: unknown acronyms spelled letter-by-letter: {tokens}")
        print(
            "         classify them in tools/pronunciation.local.json "
            "(or the skill's shared lexicon) and re-run before deriving timing."
        )


if __name__ == "__main__":
    main()
