# Checkpoint

- 2026-09-23 20:06 IST, cycle 3 in progress on branch godot-prototype.
- Done: bowl.gd scene, goldfish.gd (spring-chain veil, 9 strands x 14 points, lateral smoothing so strands never cross), fish2 shader (ragged soft veil edge, strong root), petals, bloom composite, fish separation with positional nudge, fish scale tied to bowl radius.
- Rendered: phone 390x844 at 3/6/10 s and desktop 1280x800 at 5 s with Godot --write-movie (override.cfg sets desktop viewport; --resolution is ignored in movie mode).
- Open (worse than reference, in order):
  1. Demekin veil still pinches into a bow-tie near the root on turns; hard dark triangle at times.
  2. Ryukin eyes read as dark crescents, not glossy round eyes.
  3. Bodies are flat 2D ribbons; reference has volumetric, glossy bodies with soft shading.
  4. Composition: reference is a close macro with big fish and big blurred petals; ours shows the whole small bowl on phone.
  5. Petals are small and mostly in focus; need depth blur and larger near-camera petals.
- Web export not yet rebuilt for cycle 3; live /godot/ is still the cycle 2 koi pond (cb9b55f).
