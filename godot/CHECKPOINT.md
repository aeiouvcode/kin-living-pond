# Checkpoint

- 2026-09-23 20:35 IST, cycle 3 candidate on branch godot-prototype (local commit, not pushed yet).
- Done this cycle: RYUKIN-style bowl (bowl.gd), goldfish.gd spring-chain veil (9 strands x 14 points, pinned open root, per-joint bend cap, lateral smoothing), eyes as separate glossy quads for both fish, fish separation, fish scale tied to bowl radius, bigger bowl on phone (macro feel), near-camera blurred petals, bloom composite.
- Web export QA (local Chrome, real export): phone 390x844 boot 3.9 s, desktop 1280x800 boot 4.7 s, 7 same-origin requests, 0 external, 0 CSP violations or console errors.
- Still worse than reference, in order:
  1. Bodies are flat, patterned ribbons; reference bodies are soft, volumetric, glossy with no scale pattern.
  2. Veils read as striped paper fans at the root; reference veils are long, silky, flowing, mostly white.
  3. Demekin reads as a round blob; reference is a long velvety body with big tail.
  4. Desktop leaves the bowl small in the frame; reference is a close macro.
  5. Naming card covers the bottom third on phone.
- Live /godot/ is still cycle 2 koi pond (cb9b55f). Replacing it needs a new owner go.
