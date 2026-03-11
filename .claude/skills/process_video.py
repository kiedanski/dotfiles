# /// script
# dependencies = ["faster-whisper>=1.0.0"]
# ///
"""
Extract audio, transcribe with Whisper, and extract thumbnail previews from a video.

Usage:
  uv run process_video.py --video /path/to/video.mp4 --output /tmp/out/ [--interval 5] [--model base]

Outputs to <output>/:
  transcript.json   — list of {start, end, text} segments + metadata
  thumbs/           — thumb_NNNN.jpg at 480px wide, one per interval seconds
"""

import argparse
import json
import os
import subprocess
import sys


def get_duration(video_path: str) -> float:
    result = subprocess.run(
        ["ffprobe", "-v", "quiet", "-print_format", "json", "-show_format", video_path],
        capture_output=True, text=True, check=True,
    )
    return float(json.loads(result.stdout)["format"]["duration"])


def extract_audio(video_path: str, out_path: str) -> None:
    subprocess.run(
        ["ffmpeg", "-y", "-i", video_path, "-vn", "-ar", "16000", "-ac", "1", "-f", "wav", out_path],
        check=True, capture_output=True,
    )


def transcribe(audio_path: str, model_size: str) -> tuple[list[dict], str]:
    from faster_whisper import WhisperModel
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    segments, info = model.transcribe(audio_path, beam_size=5)
    result = [{"start": round(s.start, 2), "end": round(s.end, 2), "text": s.text.strip()} for s in segments]
    return result, info.language


def detect_scenes(video_path: str, threshold: float = 0.35) -> list[float]:
    """Returns sorted list of timestamps (seconds) where scene changes occur."""
    result = subprocess.run(
        [
            "ffmpeg", "-i", video_path,
            "-vf", f"select=gt(scene\\,{threshold}),showinfo",
            "-vsync", "vfr", "-f", "null", "-",
        ],
        capture_output=True, text=True,  # no check=True — output is on stderr
    )
    timestamps = []
    for line in result.stderr.splitlines():
        if "showinfo" in line and "pts_time:" in line:
            for part in line.split():
                if part.startswith("pts_time:"):
                    try:
                        timestamps.append(float(part.split(":")[1]))
                    except ValueError:
                        pass
    return sorted(timestamps)


def extract_thumbnails(video_path: str, out_dir: str, interval: float) -> list[dict]:
    """Returns list of {timestamp, path} dicts."""
    os.makedirs(out_dir, exist_ok=True)
    subprocess.run(
        [
            "ffmpeg", "-y", "-i", video_path,
            "-vf", f"fps=1/{interval},scale=480:-2",
            "-q:v", "5",
            os.path.join(out_dir, "thumb_%04d.jpg"),
        ],
        check=True, capture_output=True,
    )
    thumbs = sorted(f for f in os.listdir(out_dir) if f.endswith(".jpg"))
    return [
        {"timestamp": i * interval, "path": os.path.join(out_dir, f)}
        for i, f in enumerate(thumbs)
    ]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--interval", type=float, default=5.0)
    parser.add_argument("--model", default="base", choices=["tiny", "base", "small", "medium"])
    args = parser.parse_args()

    if not os.path.isfile(args.video):
        print(json.dumps({"error": f"file not found: {args.video}"}))
        sys.exit(1)

    os.makedirs(args.output, exist_ok=True)

    print("Probing video...", file=sys.stderr)
    duration = get_duration(args.video)

    print("Extracting audio...", file=sys.stderr)
    audio_path = os.path.join(args.output, "audio.wav")
    extract_audio(args.video, audio_path)

    print(f"Transcribing with whisper/{args.model}...", file=sys.stderr)
    segments, language = transcribe(audio_path, args.model)

    print(f"Extracting thumbnails every {args.interval}s...", file=sys.stderr)
    thumb_dir = os.path.join(args.output, "thumbs")
    thumbs = extract_thumbnails(args.video, thumb_dir, args.interval)

    print("Detecting scene changes...", file=sys.stderr)
    scene_changes = detect_scenes(args.video)
    print(f"Found {len(scene_changes)} scene changes", file=sys.stderr)

    result = {
        "video": args.video,
        "duration": duration,
        "language": language,
        "thumbnail_interval": args.interval,
        "thumbnails": thumbs,
        "scene_changes": scene_changes,
        "transcript": segments,
    }

    out_json = os.path.join(args.output, "transcript.json")
    with open(out_json, "w") as f:
        json.dump(result, f, indent=2)

    print(f"Done. Output: {out_json}", file=sys.stderr)
    # Print JSON to stdout for easy capture
    print(json.dumps(result))


if __name__ == "__main__":
    main()
