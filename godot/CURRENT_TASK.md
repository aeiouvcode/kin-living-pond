# Current task

TWO WORKSTREAMS (Naksh, Sep 24 2:36-2:40 PM): fish design and fluid are built separately and integrated later, the way Hakozaki works. The fish needs a realistic 3D redesign to compete with RYUKIN, and the project should be showcased with a variety of settings (camera modes + FOV, quality, effect toggles, colour grading, fish count/size, tank/background, style modes like pixel/low-poly/wireframe driven by one motion rig).
- Fish lab: godot/labs/fish_lab.gd (+ fish_body/fish_fin shaders). Run: `godot --path godot -- --lab=fish --cam=34|top|side --kind=both|ryukin|demekin --tail=1 --fin=0.8 --fov=34 --bg=lilac|paper|night|mint --panel=1 --bright= --sat= --contrast=`. In-app Settings button opens the same knobs.
- Solo model tests (Hakozaki workflow, Sep 24 6:25 PM): every fish is tested alone on the debug stage (`--stage=debug`) and with tools/model_test.sh before any integration.
- Fluid lab: godot/labs/water_lab (water_lab.gd + water.gdshader), started cycle 16. Run: `godot --path godot -- --lab=water --floor=pebble|tile|sand --depth=1 --chroma=1 --glint=1 --drops=1.2 --wind=1 --warm=1`. Caustics are a ray-grid pass (caustics.gdshader) into a half-res SubViewport. Tap or drag to drop ripples.
- Bowl/pond scenes stay as they are until both labs are strong. Nothing live without a new go.

Naksh's call (Sep 24, 7:27 AM): build BOTH the koi pond and the glass bowl. root.gd hosts either one, with a chip (top right) to switch; the choice is saved locally.

Cycle 7 done: demekin veil stays a fan (min strand gap), velvety lumps, fuller fins, no pale ripple band. Cycle 8 done: fish stay above the naming card; closer desktop framing. Cycle 9 done: soft ragged demekin veil (no wedge), layered veil flutter. Cycle 10 done: fish keep apart along the whole body; slimmer ryukin, longer veil. Cycle 11 done: ruffled demekin outline, less depth fade, desktop fish sized to fit. Cycle 12 done: fish keep a visible gap (whole body + veil, look-ahead sidestep and yield); denser, bigger sakura (mostly flowers); first Clearwater-style caustics on the bowl floor. Cycle 13 done: inky demekin veil (no grey smear), wall margins scale with fish size and watch the veil tip. Next: black-fish ruffle at phone size, petal depth layering, boot splash colour. Water reference (Naksh said yes, Sep 24 12:41, to KIN studying Clearwater for its water pass): https://github.com/Aureliengmz/clearwater (MIT).

Cycle 3: rebuild KIN in Godot 4.5 (Compatibility / WebGL2) as a RYUKIN-style glass bowl, graded against Hakozaki's RYUKIN launch post (https://x.com/m_hakozaki/status/1767747010718040068). The koi pond build (main.gd / koi.gd) stays in the folder but is no longer the target. The live /godot/ preview and main's index.html (KIN VII) are only replaced with a new owner go.

## Target look (from the reference)
- Pastel periwinkle glass bowl seen from above, faint rim, rainbow glint top-right, strong bloom.
- Two fancy goldfish: white-peach ryukin (pink blush, glossy eyes, long translucent veil) and velvet black demekin (blue sheen, bulging eyes with thin orange rim).
- Sakura petals at several depths with blur; sparkles and dust motes.
- Fins lag on turns; fish turn toward/away from touch; slow, graceful swimming.

## Acceptance criteria
- B1 Phone 390x844 and desktop 1280x800 frames checked side by side with the reference each cycle; worse-list fixed in order.
- B2 Veil fins read as one soft sheet: no shards, no detached tails, no hard polygon edges.
- B3 Fish never swim through each other; stay inside the bowl.
- B4 Calm bond loop kept (feed, nuzzle, blossoms, daily return), saved locally only.
- B5 Security: same-origin engine files only, no secrets, sanitised name input, strict CSP verified in a browser.
- B6 Web export startup and frame cost measured on the real export.

## Non-goals
- Full 3D fluid simulation. Accounts, backend, analytics, ads.
