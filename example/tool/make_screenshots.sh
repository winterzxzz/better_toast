#!/bin/sh
# Converts the PNGs from screenshots_test.dart into the published WebP files.
# Needs `cwebp` and Python 3 with Pillow. Run from the example directory.
set -e
cd "$(dirname "$0")/.."
flutter test tool/screenshots_test.dart --update-goldens
out=../doc/screenshots
mkdir -p "$out"
for f in build/screenshots/*.png; do
  name=$(basename "$f" .png)
  cwebp -quiet -q 82 -resize 585 0 "$f" -o "$out/$name.webp"
done
python3 - "$out" <<'PY'
import sys
from PIL import Image

out = sys.argv[1]
names = ["types", "dark_bottom", "glass", "custom"]
shots = [Image.open(f"build/screenshots/{n}.png").convert("RGB") for n in names]
w, h = 390, 700
gap = 24
banner = Image.new("RGB", (gap + len(shots) * (w + gap), h + 2 * gap), (238, 240, 250))
for i, shot in enumerate(shots):
    banner.paste(shot.resize((w, h), Image.LANCZOS), (gap + i * (w + gap), gap))
banner.save(f"{out}/banner.webp", "WEBP", quality=82)
PY
ls -la "$out"
