# Checkpoint

- 2026-09-23 21:14 IST, cycle 4 (fish craft) candidate on branch godot-prototype, local commit only. Branch push is NOT approved yet; keep local.
- Trigger: Naksh saw the cycle 3 side by side and called the fish "lovecraftian horror", mostly the demekin.
- Done this cycle:
  - Bodies: soft rounded shading from a fake normal, one broad back specular, gentle rim. Scale pattern removed.
  - Veils: silky, mostly white on the ryukin, velvet black on the demekin; soft wide side falloff at the root, ragged soft trailing edge; rooted inside the body so no pinch shows.
  - Demekin rebuilt: long slim velvety body (len 124, w 44), blunt head, long taper into a 150 tail; smaller telescope eyes set on the head.
  - Ryukin: slimmer, longer 190 veil, small eyes set into the head.
  - Spine bend capped at 0.065 rad per joint (was 0.16 over 16 joints, which made banana/comma bodies).
  - Fish clipped to the glass with a soft fade just inside the rim.
- QA on the real web export (local Chrome): phone boot 4.2 s, desktop 4.4 s, 7 same-origin requests, 0 external, 0 CSP violations or console errors.
- Still worse than reference, in order:
  1. Ryukin body blooms too white and reads as a flat teardrop; reference has a round, peach-blushed body with visible head shape.
  2. Veils are still thin and faint next to his big layered, fluttering veils.
  3. The demekin's outline is smooth; his has a velvety, lumpy body with big dorsal and pectoral fins.
  4. The naming card covers the bottom of the bowl on phone, and fish often swim under it.
  5. Desktop bowl sits small in the frame; reference is a close macro.
- Live /godot/ is still the cycle 2 koi pond (cb9b55f). Replacing it needs a new owner go.
