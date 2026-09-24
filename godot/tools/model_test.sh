#!/bin/bash
# Solo model test contact sheet (Hakozaki workflow: test every model alone
# before it goes into a scene). Usage: tools/model_test.sh ryukin|demekin out.png
# Needs GODOT (path to the Godot 4.5.2 binary), xvfb-run and python3 + Pillow.
set -e
KIND=${1:-ryukin}; OUT=${2:-/tmp/model_test_$KIND.png}
GODOT=${GODOT:-godot}
cd "$(dirname "$0")/.."
VIEWS=("side 0 studio 0" "side 90 studio 0" "top 0 studio 0" "34 30 studio 0" "34 30 back 0" "side 0 studio 1" "top 0 studio 1" "34 30 flat 0")
i=0
for v in "${VIEWS[@]}"; do
  set -- $v
  d=/tmp/mt/$i; rm -rf $d; mkdir -p $d
  timeout 120 xvfb-run -a "$GODOT" --path . --rendering-driver opengl3 --resolution 390x844 --write-movie $d/f.png --fixed-fps 30 --quit-after 45 -- --lab=fish --kind=$KIND --cam=$1 --turn=$2 --light=$3 --sil=$4 >/dev/null 2>&1
  i=$((i+1))
done
python3 - "$OUT" "$KIND" <<'PY'
import sys
from PIL import Image, ImageDraw
out, kind = sys.argv[1], sys.argv[2]
labels = ["side", "side 90", "top", "3/4", "3/4 backlit", "side silhouette", "top silhouette", "3/4 flat light"]
tiles = []
for i in range(8):
    im = Image.open(f"/tmp/mt/{i}/f00000040.png").convert("RGB")
    im = im.crop((0, 211, 390, 633))  # middle half of the phone frame
    tiles.append(im)
W, H = 390, 422
sheet = Image.new("RGB", (W * 4, H * 2 + 30), (250, 248, 244))
d = ImageDraw.Draw(sheet)
d.text((10, 8), f"KIN model test: {kind}", fill=(40, 36, 70))
for i, im in enumerate(tiles):
    x, y = (i % 4) * W, 30 + (i // 4) * H
    sheet.paste(im, (x, y))
    d.text((x + 8, y + 6), labels[i], fill=(40, 36, 70))
sheet.save(out)
print(out)
PY
