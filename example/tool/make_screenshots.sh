#!/bin/sh
# Regenerates every image in doc/screenshots/ from the real package.
#
# 1. tool/screenshots_test.dart renders the marketing stills (1290x2796) and
#    the banner (1600x700) to build/screenshots/, and the demo frames
#    (645x1398, 25 fps) to build/demo/. Every toast in them is a real
#    better_toast toast; the backgrounds, phone and captions are widgets.
# 2. This script scales the stills to 645 px wide and encodes everything as
#    WebP.
#
# Needs Flutter, `cwebp`, `img2webp` and Python 3 with Pillow.
# Run from anywhere; it switches to the example directory.
set -e
cd "$(dirname "$0")/.."
rm -rf build/screenshots build/demo build/scaled
flutter test tool/screenshots_test.dart
out=../doc/screenshots
mkdir -p "$out" build/scaled

# Downscale the 3x stills with a Lanczos filter: sharper text than cwebp's
# own resize.
python3 - <<'PY'
import glob
import os

from PIL import Image

for path in sorted(glob.glob("build/screenshots/0*.png")):
    image = Image.open(path).convert("RGB")
    size = (image.width // 2, image.height // 2)
    name = os.path.basename(path)
    image.resize(size, Image.LANCZOS).save(f"build/scaled/{name}")
PY

# Stills: high quality and sharp YUV so gradients stay smooth and text
# edges stay clean.
for png in build/scaled/0*.png; do
  name=$(basename "$png" .png)
  cwebp -quiet -q 90 -m 6 -sharp_yuv "$png" -o "$out/$name.webp"
done
cwebp -quiet -q 90 -m 6 -sharp_yuv build/screenshots/banner.png \
  -o "$out/banner.webp"

# demo.webp: animated, 645x1398, 40 ms per frame, loops forever. Lossless:
# lossy sub-frames leave ghost rectangles where toasts used to be.
# shellcheck disable=SC2046
img2webp -loop 0 -min_size -lossless -m 6 -d 40 \
  $(ls build/demo/frame_*.png) -o "$out/demo.webp"

ls -la "$out"
