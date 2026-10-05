import json
import sys
from pathlib import Path


def format_time(seconds: float) -> str:
    """Convierte segundos a HH:MM:SS."""
    seconds = max(0, int(seconds))
    hours, remainder = divmod(seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    return f"{hours:02d}:{minutes:02d}:{seconds:02d}"


def convert_json_to_txt(json_path: Path) -> None:
    txt_path = json_path.with_suffix(".txt")

    with json_path.open("r", encoding="utf-8") as file:
        data = json.load(file)

    segments = data.get("segments", [])
    output_lines: list[str] = []

    previous_speaker = None
    paragraph_parts: list[str] = []
    paragraph_start = 0.0

    def flush_paragraph() -> None:
        nonlocal paragraph_parts

        if not paragraph_parts:
            return

        speaker = previous_speaker or "SPEAKER_UNKNOWN"
        text = " ".join(paragraph_parts).strip()

        output_lines.append(
            f"[{format_time(paragraph_start)}] {speaker}: {text}"
        )
        output_lines.append("")
        paragraph_parts = []

    for segment in segments:
        text = str(segment.get("text", "")).strip()

        if not text:
            continue

        speaker = segment.get("speaker") or "SPEAKER_UNKNOWN"
        start = float(segment.get("start", 0.0))

        if speaker != previous_speaker:
            flush_paragraph()
            previous_speaker = speaker
            paragraph_start = start

        paragraph_parts.append(text)

    flush_paragraph()

    txt_path.write_text(
        "\n".join(output_lines).strip() + "\n",
        encoding="utf-8",
    )

    print(f"TXT creado: {txt_path}")


def main() -> None:
    if len(sys.argv) != 2:
        print("Uso: python json_a_txt.py archivo.json")
        raise SystemExit(1)

    json_path = Path(sys.argv[1])

    if not json_path.exists():
        print(f"No existe: {json_path}")
        raise SystemExit(1)

    convert_json_to_txt(json_path)


if __name__ == "__main__":
    main()