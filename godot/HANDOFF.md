# Handoff

## Resume here
1. Distance-to-reference audit against Koi - Aquarium (HAREPPO) Play listing and RYUKIN listing imagery. Original owner reference imagery is still missing, so the audit is PARTIAL.
2. Fix audit items in priority order (see below), then web export + phone QA + CSP test.

## Distance-to-reference audit (cycle 2, PARTIAL: original owner reference imagery missing)
Still reads worse than Koi - Aquarium listing imagery, in priority order:
1. Koi skin is still procedural: no photographic texture or scale sparkle; heads slightly blunt.
2. Nine large koi in a narrow phone pond still feel busy at times.
3. Stone ring remains heavier than the reference's full-bleed water, especially at the top.
4. Desktop: pond is large and fish read small; HUD text is tiny at 1440 wide.

## Security grades (cycle 2)
- Secrets in repo/history: PASS
- Unexpected network / telemetry: PASS (same-origin + blob only, CSP connect-src 'self', 0 violations)
- Third-party scripts/CDNs: PASS (none; official Godot template self-hosted)
- Injection sinks: PASS (plain Label, control/bidi chars stripped, 24 char cap; markup test literal)
- Local storage tampering: PASS (16 KB cap, type checks, clamps)
- CSP completeness: PARTIAL (style-src 'unsafe-inline' for the Godot shell; frame-ancestors impossible via meta on Pages)
- Error handling: PARTIAL (default Godot shell can show raw engine errors on boot failure; needs a custom shell)

## Performance
- Wasm 38.0 MB raw, 9.26 MB gzip -9. KIN VII is ~25 KB. Whether GitHub Pages serves .wasm gzipped is unverified.
- Swiftshader frame rate is not meaningful; real-phone frame cost still unmeasured.

## Failed approaches
- Side-view Godot aquarium with many fish: crowded and flat, never beat KIN VII.
- Keeping prototype only in scratch workspace: lost twice. Source now lives on this branch.

## How to build
- Godot 4.5.2 stable, export template web_nothreads_release.
- Frames: `xvfb-run godot --rendering-driver opengl3 --resolution 390x844 --write-movie /tmp/f.png --fixed-fps 30 --quit-after 90`
