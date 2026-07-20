"""Deterministic acronym/abbreviation pronunciation for TTS narration.

Canonical copy: ``shared/tts/tts_pronounce.py`` in the skill repository.
Each TTS-using skill vendors a byte-identical copy under its ``scripts/``
directory (the smoke test enforces sync), and project setup copies it next
to the TTS script so per-project runs stay self-contained and offline.
Edit only the canonical copy.

``prepare_for_tts`` rewrites narration text so the TTS engine speaks each
abbreviation the intended way, driven by a lexicon of ``{token: directive}``
entries:

- ``"word"`` — spoken as a word; the token passes through unchanged
  (``"NASA": "word"``).
- ``"letters"`` — spelled letter by letter as spaced characters
  (``"ECG": "letters"`` -> ``E C G``).
- ``/.../`` — Kokoro/misaki inline phoneme override; the token is emitted
  as ``[TOKEN](/.../)`` (``"SQL": "/ˈsikwəl/"``). Escape hatch for hard
  cases; confirm the result by ear. Plural occurrences need their own
  explicit entry.
- any other string — literal spoken replacement (``"NGINX": "engine X"``).

All-caps tokens absent from the lexicon are deterministically spelled
letter by letter (the safe default) and reported via
``PronunciationResult.unknown`` so authors can classify them. A project
may keep a ``pronunciation.local.json`` file (same schema) next to its TTS
script; the caller loads it with ``load_local_lexicon`` and passes it as
``overlay``, whose entries win over ``DEFAULT_LEXICON``.

Narration style note: write acronyms naturally (``ECG``, not ``E C G``)
and avoid ALL-CAPS emphasis — an all-caps word reads as an acronym here.

Requires only the standard library. ``python3 tts_pronounce.py
--self-test`` runs the unit checks without any TTS engine; passing
narration text as arguments prints the transformation.
"""

from __future__ import annotations

import json
import re
import sys
from collections.abc import Mapping
from dataclasses import dataclass, field
from pathlib import Path

DEFAULT_LEXICON: dict[str, str] = {
    # Spoken as words.
    "JSON": "word",
    "NASA": "word",
    "NATO": "word",
    "OK": "word",
    "RAID": "word",
    "RAM": "word",
    "REST": "word",
    "YAML": "word",
    # Spelled letter by letter. Contested pronunciations (SQL, GIF) default
    # to letters; a project overlay can specialize them.
    "AI": "letters",
    "API": "letters",
    "AWS": "letters",
    "CEO": "letters",
    "CLI": "letters",
    "CPU": "letters",
    "CSS": "letters",
    "CSV": "letters",
    "DNA": "letters",
    "ECG": "letters",
    "EKG": "letters",
    "FAQ": "letters",
    "GIF": "letters",
    "GPS": "letters",
    "GPU": "letters",
    "HTML": "letters",
    "HTTP": "letters",
    "HTTPS": "letters",
    "ICU": "letters",
    "ID": "letters",
    "IT": "letters",
    "LLM": "letters",
    "ML": "letters",
    "MRI": "letters",
    "PDF": "letters",
    "SDK": "letters",
    "SQL": "letters",
    "SSH": "letters",
    "TTS": "letters",
    "UI": "letters",
    "URL": "letters",
    "USB": "letters",
    "UX": "letters",
    # Custom spoken forms and mixed-case tokens.
    "IoT": "letters",
    "iOS": "letters",
    "K8s": "K eights",
    "NGINX": "engine X",
    "SaaS": "sass",
}

# Common roman numerals pass through untouched unless the lexicon says
# otherwise (an overlay entry like {"IV": "letters"} wins, e.g. medical IV).
_ROMAN_NUMERALS = frozenset(
    "II III IV VI VII VIII IX XI XII XIII XIV XV XVI XVII XVIII XIX XX".split()
)

_ALL_CAPS_TOKEN = re.compile(r"\b([A-Z]{2,})(s)?\b")
_OVERRIDE_SPAN = re.compile(r"\[[^\[\]]+\]\(/[^()]*/\)")
_PLACEHOLDER = re.compile(r"\x00(\d+)\x00")


@dataclass
class PronunciationResult:
    """Outcome of ``prepare_for_tts``."""

    text: str
    replacements: list[tuple[str, str]] = field(default_factory=list)
    unknown: list[str] = field(default_factory=list)


def load_local_lexicon(path: Path) -> dict[str, str]:
    """Load a project lexicon overlay; a missing file means no overlay."""
    if not path.is_file():
        return {}
    entries = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(entries, dict):
        raise ValueError(f"{path}: lexicon must be a JSON object")
    return entries


def _spell(token: str) -> str:
    """Render a token letter by letter ("ECG" -> "E C G")."""
    return " ".join(token)


def _is_phoneme_override(directive: str) -> bool:
    """True for a ``/.../``-wrapped misaki phoneme directive."""
    return len(directive) > 2 and directive.startswith("/") and directive.endswith("/")


def prepare_for_tts(
    text: str, overlay: Mapping[str, str] | None = None
) -> PronunciationResult:
    """Rewrite narration so the TTS engine speaks abbreviations as intended."""
    lexicon: dict[str, str] = dict(DEFAULT_LEXICON)
    if overlay:
        lexicon.update(overlay)

    result = PronunciationResult(text="")
    shelved: list[str] = []

    def _shelve(match: re.Match[str]) -> str:
        shelved.append(match.group(0))
        return f"\x00{len(shelved) - 1}\x00"

    def _resolve(token: str, plural: str) -> str | None:
        """Spoken form for a matched token, or None to leave it unchanged."""
        matched = token + plural
        subject, tail = matched, ""
        directive = lexicon.get(matched)
        if directive is None and plural:
            directive = lexicon.get(token)
            subject, tail = token, plural
            if directive is not None and _is_phoneme_override(directive):
                directive = None  # phoneme overrides never auto-pluralize
        if directive is None:
            if token in _ROMAN_NUMERALS:
                return None
            result.unknown.append(token)
            return _spell(token) + plural
        if directive == "word":
            return None
        if directive == "letters":
            return _spell(subject) + tail
        if _is_phoneme_override(directive):
            return f"[{matched}]({directive})"
        return directive + tail

    def _substitute(match: re.Match[str]) -> str:
        token, plural = match.group(1), match.group(2) or ""
        spoken = _resolve(token, plural)
        if spoken is None:
            return match.group(0)
        result.replacements.append((match.group(0), spoken))
        return spoken

    # Shelve existing phoneme-override spans so reruns are idempotent, run
    # the exact-token pass (mixed-case keys the all-caps regex cannot see),
    # shelve any overrides it produced, then run the all-caps pass.
    working = _OVERRIDE_SPAN.sub(_shelve, text)
    exact_keys = [key for key in lexicon if not re.fullmatch(r"[A-Z]{2,}", key)]
    if exact_keys:
        alternation = "|".join(
            re.escape(key) for key in sorted(exact_keys, key=len, reverse=True)
        )
        exact_pattern = re.compile(rf"(?<!\w)({alternation})(s)?(?!\w)")
        working = exact_pattern.sub(_substitute, working)
        working = _OVERRIDE_SPAN.sub(_shelve, working)
    working = _ALL_CAPS_TOKEN.sub(_substitute, working)
    result.text = _PLACEHOLDER.sub(lambda m: shelved[int(m.group(1))], working)
    return result


def _self_test() -> int:
    """Run unit checks without any TTS engine; return a process exit code."""
    failures = 0

    def check(label: str, condition: bool) -> None:
        nonlocal failures
        if condition:
            print(f"PASS {label}")
        else:
            failures += 1
            print(f"FAIL {label}")

    transformations = [
        ("word passthrough", "NASA and NATO agree, OK.", None, None),
        (
            "letters expansion",
            "The ECG feeds the AI.",
            "The E C G feeds the A I.",
            None,
        ),
        (
            "literal replacement",
            "NGINX proxies traffic.",
            "engine X proxies traffic.",
            None,
        ),
        ("plural letters", "Three ECGs arrived.", "Three E C Gs arrived.", None),
        ("possessive letters", "NASA's ECG's trace.", "NASA's E C G's trace.", None),
        ("roman numeral skipped", "World War II ended.", None, None),
        (
            "mixed-case exact tokens",
            "A SaaS product on iOS.",
            "A sass product on i O S.",
            None,
        ),
        ("hyphenated acronym", "An AI-powered tool.", "An A I-powered tool.", None),
        ("units untouched", "It runs at 3 GHz on 20 mAh.", None, None),
        ("lowercase words untouched", "Cats scan the barn.", None, None),
        (
            "overlay wins over default",
            "SQL and AI.",
            "sequel and AI.",
            {"SQL": "sequel", "AI": "word"},
        ),
        (
            "phoneme override emitted",
            "Use SQL now.",
            "Use [SQL](/ˈsikwəl/) now.",
            {"SQL": "/ˈsikwəl/"},
        ),
    ]
    for label, source, expected, overlay in transformations:
        outcome = prepare_for_tts(source, overlay)
        check(label, outcome.text == (expected if expected is not None else source))

    outcome = prepare_for_tts("XQJ appears twice: XQJ.")
    check("unknown spelled out", outcome.text == "X Q J appears twice: X Q J.")
    check("unknown reported", outcome.unknown == ["XQJ", "XQJ"])

    outcome = prepare_for_tts("Two SQLs.", {"SQL": "/ˈsikwəl/"})
    check("override plural needs explicit entry", outcome.text == "Two S Q Ls.")
    check("override plural reported unknown", outcome.unknown == ["SQL"])

    overlay = {"SQL": "/ˈsikwəl/"}
    once = prepare_for_tts("SQL meets ECG, NGINX, and SaaS.", overlay)
    twice = prepare_for_tts(once.text, overlay)
    check("idempotent", twice.text == once.text and not twice.replacements)

    outcome = prepare_for_tts("The ECG helps.")
    check("replacements audited", outcome.replacements == [("ECG", "E C G")])

    check(
        "missing overlay file", load_local_lexicon(Path("no-such-lexicon.json")) == {}
    )

    if failures:
        print(f"self-test: {failures} FAILURES above", file=sys.stderr)
        return 1
    print("self-test: all checks passed")
    return 0


def main(argv: list[str]) -> int:
    """CLI entry point: ``--self-test`` or narration text to transform."""
    if "--self-test" in argv:
        return _self_test()
    if not argv:
        print("usage: tts_pronounce.py --self-test | <narration text>", file=sys.stderr)
        return 2
    outcome = prepare_for_tts(" ".join(argv))
    print(outcome.text)
    if outcome.unknown:
        tokens = ", ".join(sorted(set(outcome.unknown)))
        print(
            f"WARNING unknown acronyms spelled letter-by-letter: {tokens}",
            file=sys.stderr,
        )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
