#!/usr/bin/env python3
"""Convert a Godot `--write-movie` PNG sequence into an optimised GIF.

Usage:
    python tools/frames_to_gif.py docs/gif/frames/f.png docs/screenshots/demo.gif

The sequence keeps only the frames that actually differ, so the pauses
between animations cost almost nothing in file size.
"""

from __future__ import annotations

import os
import sys

from PIL import Image


def collect_frames(pattern: str) -> list[str]:
    directory = os.path.dirname(pattern) or "."
    prefix = os.path.basename(pattern).split(".")[0]
    names = sorted(
        n for n in os.listdir(directory)
        if n.startswith(prefix) and n.lower().endswith(".png")
    )
    return [os.path.join(directory, n) for n in names]


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 1

    pattern = sys.argv[1]
    output = sys.argv[2]
    width = int(sys.argv[3]) if len(sys.argv) > 3 else 760
    fps = float(sys.argv[4]) if len(sys.argv) > 4 else 15.0
    colors = int(sys.argv[5]) if len(sys.argv) > 5 else 96

    frames = collect_frames(pattern)
    if not frames:
        print("no frames found for", pattern)
        return 1

    os.makedirs(os.path.dirname(output) or ".", exist_ok=True)

    base = Image.open(frames[0]).convert("RGB")
    height = int(round(base.height * width / base.width))
    duration = int(round(1000.0 / fps))

    kept: list[Image.Image] = []
    durations: list[int] = []
    previous_bytes = None

    for path in frames:
        image = Image.open(path).convert("RGB")
        image = image.resize((width, height), Image.LANCZOS)
        current = image.tobytes()
        if current == previous_bytes:
            durations[-1] += duration
            continue
        previous_bytes = current
        kept.append(image)
        durations.append(duration)

    # No dithering: the UI is mostly flat dark surfaces and sharp glyphs,
    # where dithering hurts legibility more than it helps the palette.
    palette = kept[0].convert("P", palette=Image.ADAPTIVE, colors=colors)
    palette_frames = []
    for image in kept:
        quantized = image.quantize(palette=palette, dither=Image.NONE)
        palette_frames.append(quantized)

    palette_frames[0].save(
        output,
        save_all=True,
        append_images=palette_frames[1:],
        duration=durations,
        loop=0,
        optimize=True,
        disposal=2,
    )

    size_kb = os.path.getsize(output) / 1024.0
    print(
        "wrote %s: %d frames kept out of %d, %d x %d, %.1f KB"
        % (output, len(kept), len(frames), width, height, size_kb)
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
