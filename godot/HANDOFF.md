# Handoff

## Resume here
1. Distance-to-reference audit against Koi - Aquarium (HAREPPO) Play listing and RYUKIN listing imagery. Original owner reference imagery is still missing, so the audit is PARTIAL.
2. Fix audit items in priority order (see below), then web export + phone QA + CSP test.

## Open audit items (priority order)
1. Fish read as good but slightly plastic; add subtle blur/fog for deep fish and softer scale pattern.
2. Pond floor pebbles read as mosaic tiles; soften and shrink.
3. Shore stones too uniform and glossy; vary size and add moss/grass between.
4. Onboarding card height; verify on phone.
5. Web export size (~37 MB Wasm, ~9 MB gzip) and cold start still unmeasured for this build.

## Failed approaches
- Side-view Godot aquarium with many fish: crowded and flat, never beat KIN VII.
- Keeping prototype only in scratch workspace: lost twice. Source now lives on this branch.

## How to build
- Godot 4.5.2 stable, export template web_nothreads_release.
- Frames: `xvfb-run godot --rendering-driver opengl3 --resolution 390x844 --write-movie /tmp/f.png --fixed-fps 30 --quit-after 90`
