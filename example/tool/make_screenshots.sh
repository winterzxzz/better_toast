#!/bin/sh
# Regenerates every image in doc/screenshots/ from the real package.
#
# 1. tool/screenshots_test.dart renders PNG stills to build/screenshots/ and
#    the demo frames (25 fps) to build/demo/.
# 2. This script converts them to WebP: the phone stills, the promise and
#    positions composites, the banner and the animated demo.
#
# Needs Flutter, `cwebp`, `img2webp` and Python 3 with Pillow.
# Run from anywhere; it switches to the example directory.
set -e
cd "$(dirname "$0")/.."
rm -rf build/screenshots build/demo
flutter test tool/screenshots_test.dart
out=../doc/screenshots
mkdir -p "$out"

# Phone stills: 1170x2100 renders scaled to 585 px wide.
for name in types dark_bottom glass custom; do
  cwebp -quiet -q 82 -resize 585 0 "build/screenshots/$name.png" \
    -o "$out/$name.webp"
done

# Composites: promise sequence, positions + RTL, and the banner.
python3 - "$out" <<'PY'
import sys
from PIL import Image, ImageDraw

out = sys.argv[1]
bg = (238, 240, 250)
accent = (79, 70, 229)


def load(name):
    return Image.open(f"build/screenshots/{name}.png").convert("RGB")


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, img.width - 1, img.height - 1), radius, fill=255
    )
    return img, mask


def paste(canvas, img, xy, radius):
    img, mask = rounded(img, radius)
    canvas.paste(img, xy, mask)


def arrow(draw, cx, cy, size):
    draw.polygon(
        [(cx - size // 2, cy - size), (cx + size // 2, cy), (cx - size // 2, cy + size)],
        fill=accent,
    )


# promise.webp: top of the phone (status bar + toast) in three steps.
panels = [load(f"promise_{i}").crop((0, 0, 1170, 720)).resize((585, 360), Image.LANCZOS) for i in (1, 2, 3)]
pad, gap = 36, 72
w = 2 * pad + 3 * 585 + 2 * gap
h = 2 * pad + 360
canvas = Image.new("RGB", (w, h), bg)
draw = ImageDraw.Draw(canvas)
for i, panel in enumerate(panels):
    x = pad + i * (585 + gap)
    paste(canvas, panel, (x, pad), 28)
    if i < 2:
        arrow(draw, x + 585 + gap // 2, pad + 180, 18)
canvas.save(f"{out}/promise.webp", "WEBP", quality=85, method=6)

# positions.webp: tablet in LTR next to a phone in RTL.
height = 800
tablet = load("positions_ltr").resize((1280, height), Image.LANCZOS)
phone_src = load("positions_rtl")
phone = phone_src.resize((round(phone_src.width * height / phone_src.height), height), Image.LANCZOS)
pad = 32
canvas = Image.new("RGB", (3 * pad + tablet.width + phone.width, 2 * pad + height), bg)
paste(canvas, tablet, (pad, pad), 24)
paste(canvas, phone, (2 * pad + tablet.width, pad), 32)
canvas.save(f"{out}/positions.webp", "WEBP", quality=85, method=6)

# banner.webp: the four phone stills side by side.
names = ["types", "glass", "dark_bottom", "custom"]
w, h, gap = 390, 700, 24
canvas = Image.new("RGB", (gap + len(names) * (w + gap), h + 2 * gap), bg)
for i, name in enumerate(names):
    paste(canvas, load(name).resize((w, h), Image.LANCZOS), (gap + i * (w + gap), gap), 28)
canvas.save(f"{out}/banner.webp", "WEBP", quality=82, method=6)
PY

# demo.webp: animated, 585x1266, 40 ms per frame, loops forever. Lossless:
# lossy sub-frames leave ghost rectangles where toasts used to be.
# shellcheck disable=SC2046
img2webp -loop 0 -min_size -lossless -m 6 -d 40 \
  $(ls build/demo/frame_*.png) -o "$out/demo.webp"

ls -la "$out"
