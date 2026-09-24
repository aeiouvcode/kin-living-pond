# Handoff

Labs (branch-only): `-- --lab=fish` (godot/labs/fish_lab.gd) and `-- --lab=water` (godot/labs/water_lab/). Fish debug stage: `--lab=fish --stage=debug`; contact sheet: `GODOT=<binary> godot/tools/model_test.sh ryukin out.png` (needs Pillow). Water lab has launch-arg settings (floor, depth, chroma, glint, drops, wind).

Project: /godot (Godot 4.5.2, Compatibility renderer). main.tscn -> root.gd, which hosts main.gd (koi pond) or bowl.gd (glass bowl); chip switches. Movie render: add `-- --scene=pond` or `-- --scene=bowl`.
Render frames: `xvfb-run -a godot --rendering-driver opengl3 --write-movie /tmp/mv/f.png --fixed-fps 30 --quit-after 240` (phone viewport from project.godot). For desktop, write an override.cfg with `[display] window/size/viewport_width=1280 / viewport_height=800`, render, then delete it.
Web build: ./build.sh, then QA CSP, phone and desktop frames on the export.
Deploy: live /godot/ on main = two-scene build from c11 (main b74a131, pck md5 1aa3fd49), approved by Naksh Sep 24 12:23 ("Sure this works"). Further live updates need a new go; branch pushes continue each cycle.
Next: fix the CHECKPOINT open list in order, rebuild web export, QA, send side-by-side audit. Branch pushes are allowed (hold lifted Sep 24); main and live /godot/ still need a new owner go.
Fresh workspace setup: clone branch godot-prototype; download Godot_v4.5.2-stable_linux.x86_64.zip and the export templates .tpz from github.com/godotengine/godot-builds releases (4.5.2-stable); unzip templates/web* into ~/.local/share/godot/export_templates/4.5.2.stable/; run `godot --headless --import` once in /godot; pip install playwright and `playwright install chromium` for browser QA. Branch pushes go only through the signed-in github.dev / GitHub web editor in the cloud browser (no token anywhere). godot/tools/mkpush.py is retired and must not be used.

Credits: bowl caustics in shaders/bowl_bg.gdshader are adapted from the technique in Clearwater (MIT, https://github.com/Aureliengmz/clearwater) and Evan Wallace's WebGL Water. No code copied verbatim; written for Godot canvas shaders.
