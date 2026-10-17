#!/bin/bash
# Generates launcher + splash PNGs from the user-supplied SVG assets.
# Source of truth: assets/icon-source/*.svg (NEVER edit the SVGs here).
# Requires: python3 + cairosvg (`pip install cairosvg`).
set -euo pipefail
cd "$(dirname "$0")/.."

SRC_FG="assets/icon-source/icon-foreground.svg"
SRC_FULL="assets/icon-source/icon.svg"
OUT="assets/icon-generated"

[ -f "$SRC_FG" ] || { echo "missing $SRC_FG"; exit 1; }
[ -f "$SRC_FULL" ] || { echo "missing $SRC_FULL"; exit 1; }

mkdir -p "$OUT"/foreground "$OUT"/splash
python3 - "$SRC_FG" "$SRC_FULL" "$OUT" <<'EOF'
import sys
import cairosvg
src_fg, src_full, out = sys.argv[1], sys.argv[2], sys.argv[3]
# Adaptive-icon foreground @ xxxhdpi baseline (432dp), scaled per density.
cairosvg.svg2png(url=src_fg, write_to=f"{out}/foreground/ic_fg_432.png",
                 output_width=432, output_height=432)
# Full-bleed artwork for legacy icons + splash (white background baked in).
cairosvg.svg2png(url=src_full, write_to=f"{out}/splash/splash_1024.png",
                 output_width=1024, output_height=1024)
from PIL import Image
fg = Image.open(f"{out}/foreground/ic_fg_432.png")
for name, size in [("mdpi", 108), ("hdpi", 162), ("xhdpi", 216),
                   ("xxhdpi", 324), ("xxxhdpi", 432)]:
    fg.resize((size, size), Image.LANCZOS).save(
        f"{out}/foreground/ic_fg_{name}.png")
print("generated foreground densities + splash artwork")
EOF
ls -la "$OUT/foreground" "$OUT/splash"
