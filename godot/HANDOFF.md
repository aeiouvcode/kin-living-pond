# Handoff

Project: /godot (Godot 4.5.2, Compatibility renderer). main.tscn -> bowl.gd.
Render frames: `xvfb-run -a godot --rendering-driver opengl3 --write-movie /tmp/mv/f.png --fixed-fps 30 --quit-after 240` (phone viewport from project.godot). For desktop, write an override.cfg with `[display] window/size/viewport_width=1280 / viewport_height=800`, render, then delete it.
Web build: ./build.sh, then QA CSP, phone and desktop frames on the export.
Deploy: only with owner go; the live /godot/ on main is cycle 2.
Next: fix the CHECKPOINT open list in order, rebuild web export, QA, push branch, send side-by-side audit.
