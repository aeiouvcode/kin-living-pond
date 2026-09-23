# Handoff

## Resume here
1. Distance-to-reference audit against Koi - Aquarium (HAREPPO) Play listing and RYUKIN listing imagery. Original owner reference imagery is still missing, so the audit is PARTIAL.
2. Fix audit items in priority order (see below), then web export + phone QA + CSP test.

## Distance-to-reference audit (cycle 1, PARTIAL: original owner reference imagery missing)
Compared at 390x844 against Koi - Aquarium (HAREPPO) listing screenshot 1 and RYUKIN listing imagery. Still reads worse, in priority order:
1. Koi bodies: reference fish have photographic skin, soft subsurface glow and wide soft fins; ours are procedural and slightly stiff at the head.
2. Water surface: reference water has a bright textured surface with light gradient; ours is darker by design but the bed still reads murky in the middle.
3. Bank frame: stone ring is busy and heavy compared with the reference's full-bleed water.
4. Lily pads read as flat clip art (uniform green, hard edges, no curl or sheen).
5. Touch water response not yet verified in frames (sim runs; no captured tap sequence).
6. Desktop frame not yet captured: Movie Maker ignored --resolution 1440x900 (handheld portrait orientation); capture from the web export instead.

## Failed approaches
- Side-view Godot aquarium with many fish: crowded and flat, never beat KIN VII.
- Keeping prototype only in scratch workspace: lost twice. Source now lives on this branch.

## How to build
- Godot 4.5.2 stable, export template web_nothreads_release.
- Frames: `xvfb-run godot --rendering-driver opengl3 --resolution 390x844 --write-movie /tmp/f.png --fixed-fps 30 --quit-after 90`
