# /// script
# dependencies = []
# ///
"""
Extract full-resolution frames from a video at specific timestamps.

Usage:
  uv run extract_frames.py --video /path/to/video.mp4 --output /tmp/out/ --timestamps 10.5 45.2 120.0

Outputs:
  frame_10.50s.jpg, frame_45.20s.jpg, … at 1280px wide
"""

import argparse
import json
import os
import subprocess
import sys


def extract_frame(video_path: str, timestamp: float, out_path: str, width: int = 1280) -> None:
    subprocess.run(
        [
            "ffmpeg", "-y",
            "-ss", str(timestamp),
            "-i", video_path,
            "-frames:v", "1",
            "-vf", f"scale={width}:-2",
            "-q:v", "2",
            out_path,
        ],
        check=True, capture_output=True,
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--timestamps", nargs="+", type=float, required=True)
    parser.add_argument("--width", type=int, default=1280)
    args = parser.parse_args()

    if not os.path.isfile(args.video):
        print(json.dumps({"error": f"file not found: {args.video}"}))
        sys.exit(1)

    os.makedirs(args.output, exist_ok=True)

    results = []
    for ts in sorted(args.timestamps):
        out_path = os.path.join(args.output, f"frame_{ts:.2f}s.jpg")
        try:
            extract_frame(args.video, ts, out_path, args.width)
            results.append({"timestamp": ts, "path": out_path, "ok": True})
            print(f"Extracted t={ts}s → {out_path}", file=sys.stderr)
        except subprocess.CalledProcessError as e:
            results.append({"timestamp": ts, "path": None, "ok": False, "error": e.stderr.decode()})
            print(f"Failed t={ts}s: {e.stderr.decode()}", file=sys.stderr)

    print(json.dumps(results))


if __name__ == "__main__":
    main()
