# Checkpoint

- 2026-09-24 08:12 IST, cycle 7: demekin craft.
  - Veil: minimum strand gap grows toward the tip (demekin 0.05*w, ryukin 0.035*w) and the push is re-centred, so the veil stays a fan on hard turns instead of folding into a dark whip.
  - Demekin body: subtle velvety lumps along the mid-body, slightly fuller tail end; wider, longer pectorals (0.25*w, 0.09*len); fuller dorsal (0.11*w).
  - Found the pale band across the demekin's back: water-surface ripple highlight plus bloom haze in bowl_comp. Ripple specular 0.35 -> 0.18, bloom mix 0.12 -> 0.08. Black fish now stays velvet black.
  - Web QA: phone boot 5.6 s, desktop 4.1 s, 14 same-origin requests, 0 external, 0 CSP errors; toggle + reload OK.
- Still worse than reference, in order:
  1. Naming card covers the bottom of the bowl on phone; fish swim under it (ryukin hidden behind it in some desktop frames too).
  2. Desktop bowl sits small in the frame; the reference is a close macro.
  3. Veils are one sheet; his flutter in layers.
  4. Demekin lumps are subtle; his has a visible velvet texture and a bigger dorsal.

- 2026-09-24 07:55 IST, cycle 6: fish craft pass on the bowl.
  - Ryukin: rounder egg body (pow 0.6, 0.62 head), peach body with less white specular, len 104 / w 62 / tail 185, wider veil fan.
  - Veil: strand ordering pass so strands never cross; fins fade fully to their side edges (no hard polygon edge).
  - Demekin: rounded snout cap (half-ellipse fan) replaces the flat cut head; wider veil fan; tail 160.
  - Koi pond: unchanged, no regression in the phone frame.
  - Web QA: phone boot 5.4 s, desktop 4.3 s, 14 same-origin requests, 0 external, 0 CSP errors; toggle and reload work on both.
- Still worse than reference, in order:
  1. Demekin veil can collapse into one dark whip on hard turns (strands follow one path); needs a minimum strand spacing.
  2. Demekin still reads flat: no velvety lumps, small dorsal, pectorals are thin grey paddles.
  3. Naming card covers the bottom of the bowl on phone; fish swim under it.
  4. Desktop bowl sits small in the frame; the reference is a close macro.
  5. Veils lack the layered flutter of his (one sheet only).

- 2026-09-24 07:33 IST, cycle 5: both variants in one build. main.tscn -> root.gd, which loads main.gd (koi pond) or bowl.gd (glass bowl). Switch chip top right, label names the other scene; choice saved in user://kin_scene.cfg; each scene keeps its own save. Render a given scene with `-- --scene=pond|bowl`. Web QA: toggle works by real click on phone and desktop, choice survives reload, all requests same-origin, 0 CSP errors.
- Open next: demekin veil still folds into dark shards sometimes (seen on web at DPR 2); then the bowl list below; koi pond gets its own distance audit next.

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
