# Checkpoint

- 2026-09-25 19:00 IST, cycle 38: fluid turn - avoid muddy canopy.
  - Hard critique: canopy still reads as haze, not a tree. Tested stronger branch weight and lower leaf coverage, then three separate blossom clusters attached to the forks. The solo water render became a flat, dark stencil, and Pond Next darkened a swath beneath the peach veil. Reverted that model. Kept only a modest reduction in shared bough and blossom colour weight (0.72/0.66 to 0.66/0.59). Solo water at 390x844 and Pond Next at 390x844 and 1280x800 visually checked, no shader errors. This does not solve tree legibility; it merely reduces the muddy cast.
  - Worse-list: reflected tree needs a spatial composition redesign; narrow white ryukin stripe remains; actual fin intersections and real-device GPU cost unmeasured; Pond Next settings panel absent.
  - Security A- for arithmetic-only shader constants: clean diff, no network, secrets, telemetry, persistence, or new input. Browser/export checks not repeated; main/live untouched.
  - Branch sync parked under parent's no-browser direction until local midnight; c26-c38 local only.
  - Web-surface audit following parent checklist: `build.sh` now reapplies title/description, generated favicon and CSP after replacing raw engine error text with a short, safe failure notice; copies `404.html` into the export. Local Web Next run succeeded at 390x844 and 1280x800 with no page errors, screenshots inspected. Forced 503 on index.pck showed the friendly failure notice and no injected secret/path in page text. Static localhost serves a generic 404, so nested hosted 404 behavior remains unverified. Legacy root index.html still lacks favicon/description and controlled WebGL failure UI; tracked in FEATURE-MAP.md rather than claimed fixed.

- 2026-09-25 18:00 IST, cycle 37: fish turn - restore peach ryukin body form.
  - Hard critique: four earlier light-net passes left a white body stripe, so I rendered the same deterministic phone frame with fish caustics off, specular off, and backlight off. Neither caustics nor specular removed the stripe; backlight changed the bright region. A warmer pond-only body base (0.84, 0.64, 0.62) and lower ryukin backlight (0.25 of solo value) now make a peach body with stronger form at phone size. The 390x844 debug solo keeps the old defaults; Pond Next 390x844 and 1280x800 rendered without shader errors. Controlled before/after phone frames show the change. A narrow white line remains, so this is a clear improvement, not full elimination.
  - Highest-level fix: body shader exposes base color and backlight strength as material parameters; Pond Next configures the look, rather than changing shared shader constants or layering another caustic cap. `FEATURE-MAP.md` added at repo root to map routes and triggers under Naksh's new guidance.
  - Worse-list: remaining bright stripe on ryukin; canopy still looks like haze; actual fin-mesh intersections and real-device GPU cost unmeasured; no Pond Next settings panel.
  - Security A- for local material parameters and documentation: clean diff; no new network, secrets, telemetry, persistence, third-party loads, or input sinks. Browser/export QA not repeated. Main/live unchanged.
  - Browser push paused under parent's no-browser instruction until local midnight; c26-c37 local only.

- 2026-09-25 16:57 IST, cycle 36: fluid turn - quieter floor light net.
  - Hard critique: the caustic folds were still the main pattern, swallowing the softer canopy and peach veil. Tried raising the branch reflection weight in solo water from 0.42 to 0.68, but the phone render became a broad muddy band, not an identifiable tree; reverted that experiment. Kept a quieter floor pass: diffuse caustic multiplier 0.22 to 0.18, base 0.74 to 0.77, and additive cusp 0.055 to 0.04. Solo water and integrated Pond Next at 390x844 and 1280x800 rendered and visually checked. Net stays visible but is a little less dominant; the persistent bright patch on the ryukin body is unchanged, so c35's cap did not address its source. No shader errors.
  - Worse-list: (1) white ryukin body patch, likely separate lighting path, needs controlled component test; (2) canopy still reads as haze, not tree; (3) fin mesh intersections not measured; (4) real-phone GPU cost and pond settings panel still open.
  - Security A- for a local shader-only arithmetic change: diff check clean; no new network, input, storage, telemetry, scripts, or secrets. Browser/export security and real phone performance not tested this cycle. Main/live untouched.
  - Branch push parked: parent barred browser sessions until local midnight after budget exhaustion; c26-c36 local only.

- 2026-09-25 14:56 IST, cycle 34: fluid turn - less bruised canopy reflection.
  - Hard critique: c28's darker branch colour made the left of the pond look like a mauve shadow rather than a reflected tree. Shifted branches toward warm brown and lowered their weight, with blossoms more coral than purple. Rendered solo water and Pond Next at 390x844 and 1280x800; the left reads warmer and the demekin less stained. This is a small colour correction, not a solved tree silhouette; caustics remain the main visual pattern. No shader errors.
  - Security A: procedural shader colour constants only, no new network, secrets, telemetry, persistence, file I/O, input sink, or bridge. Real-phone GPU FPS unknown. Main/live unchanged.
  - Browser budget exhausted until Naksh local midnight, no push. c26-c34 local only.
- Still worse, in order:
  1. Real phone GPU frame rate unknown.
  2. Fin-mesh collisions unmeasured and white-hot fish body patches persist.
  3. Canopy still not an unmistakable tree at phone size.
  4. No pond settings panel.

- 2026-09-25 13:55 IST, cycle 33: fish turn - cap caustic emission on translucent fins.
  - Hard critique: floor hot knots were softened in c32, but the fish fin shader still sampled the raw light-net texture and could flare white independently. Added a pond-only cap to that fin emission, leaving the body and solo-fish defaults unchanged. Ryukin debug stage and Pond Next rendered and visually checked at 390x844 and 1280x800. The veil stays peach across the sampled frames; bright caustic wash is reduced, but the overhead body still has white-hot patches and there is no pixel-perfect proof for every swimming angle. No shader errors.
  - Security A: bounded shader uniform and one material value, no new network, secrets, telemetry, persistence, file I/O, input sink, or bridge. Actual phone GPU FPS and fin-mesh collisions remain unmeasured. Main/live untouched.
  - Browser budget exhausted until Naksh local midnight, so no push. c26-c33 local only.
- Still worse, in order:
  1. Real-phone GPU frame rate unmeasured.
  2. Fin-mesh collisions unmeasured; ryukin body white-hot patches persist.
  3. Canopy reads as mauve shadow at phone size.
  4. No pond settings panel.

- 2026-09-25 12:55 IST, cycle 32: fluid turn - soften caustic blowout.
  - Hard critique: the brightest fold knots still compete with the ryukin's peach veil, especially on desktop. Reduced the floor light-net term (0.24 to 0.22), capped its contribution at 2.15 rather than 2.5, and trimmed additive cusp and bloom energy. Rendered water solo and Pond Next at 390x844 and 1280x800. The caustic lattice remains visible, but hot knots are less stark; the change is modest and does not eliminate white spots under the fish. No shader errors.
  - Security A: shader arithmetic constants only; no new external requests, secrets, persistence, telemetry, file I/O, input sink, or bridge. Real-device GPU FPS unknown. Main/live untouched.
  - Browser daily budget exhausted; no push attempted. c26-c32 local only.
- Still worse, in order:
  1. Real-phone GPU frame rate unmeasured.
  2. True fin-mesh collision and veil over brightest caustics unverified.
  3. Canopy still reads as a mauve shadow on phone.
  4. No pond settings panel.

- 2026-09-25 11:55 IST, cycle 31: fish turn - safer space for veil tips.
  - Hard critique: centerline clearance was based on a 0.75 hard gap even though each fluttering veil can extend about 0.3 sideways; tight turns might brush. Increased soft/hard/feeding gaps to 1.65/0.9/0.72, preserving right of way but giving both fins margin. In 90 simulated seconds at phone and desktop sizes, sampled closest centerline gaps were 0.877 and 0.875 respectively (2-second reporting windows), up from the old reported 0.73; both test pellets were eaten within about 7 seconds. Solo ryukin debug and Pond Next renders at 390x844 and 1280x800 were inspected. No visible crossing in sampled frames, but the test samples centerlines, not cloth geometry, so a true tip collision guarantee is not proven.
  - Security A: numeric steering constants only, no new network, secrets, telemetry, persistence, file I/O, input sink, or bridge. Real phone GPU FPS remains unmeasured. Main/live untouched.
  - Parent says browser daily budget exhausted until Naksh local midnight; no push attempted. c26-c31 local only.
- Still worse, in order:
  1. Real-device GPU frame rate unmeasured.
  2. True fin-mesh intersection not measured; bright caustic can wash the peach veil.
  3. Canopy shadow is still impressionistic rather than a tree on phone.
  4. No pond settings panel.

- 2026-09-25 10:54 IST, cycle 30: fluid turn - keep the black fish clear beneath the canopy.
  - Hard critique: c28's stronger reflected boughs helped the solo water but painted a mauve shadow through the demekin. Reduced only the over-fish surface bough coefficient from 0.45 to 0.13 (blossom from 0.30 to 0.26); left the floor reflection intact. Rendered water alone and Pond Next at 390x844 and 1280x800; the demekin reads darker, the tree still shows on the floor. The reflection is still an impressionistic mauve band, not a clearly readable tree at phone size, and caustics still dominate. No shader errors.
  - Security A: shader constant changes only; no network, secrets, persistence, telemetry, file I/O, JS bridge, or input sink. Real GPU FPS not measured. Main/live untouched.
  - Cloud-browser daily budget exhausted; parent directed no sessions until local midnight. c26-c30 remain local only, no push attempted.
- Still worse, in order:
  1. Real-device GPU frame rate unmeasured.
  2. Tight-turn veil-tip brushes and occasional pale-caustic wash.
  3. Canopy reads as mauve shadow, not tree, on phone.
  4. No pond settings panel.

- 2026-09-25 09:53 IST, cycle 29: fish turn - tip coverage over pale stones.
  - Hard critique: after c27's warm colour, the veil tip still faded too transparent over pale pebbles. Added a pond-only coverage uniform that lifts the tip alpha taper from 0.45 to 0.70; solo model defaults remain unchanged. Tested ryukin alone on the debug stage and Pond Next at 390x844 and 1280x800. The veil reads as a sheet against stones without becoming opaque; it still loses contrast where a very bright caustic crosses. Tip brushes on tight turns are not solved by this visual pass. No shader errors.
  - Security A: one bounded shader uniform and material value, no external request, secret, input sink, telemetry, persistence, JS bridge, or file I/O. Software llvmpipe renders do not give real-phone FPS. Main/live untouched.
  - Push remains blocked: GitHub Mobile device verification timed out. The lease was released; parent will coordinate a fresh login if Naksh is ready. c26-c29 local only.
- Still worse, in order:
  1. Real-phone GPU frame rate unmeasured.
  2. Tip brushes on tight turns; bright caustics still flatten the ryukin veil in places.
  3. Canopy can read as a mauve shadow and darken the black fish.
  4. No on-screen pond settings panel.

- 2026-09-25 08:56 IST, cycle 28: fluid turn - canopy branch visibility.
  - Hard critique: the c26 canopy was still pink haze on the phone. Its softened forks needed their own reflection weight instead of borrowing the sparse blossom mask. The shared shader now exposes bough coverage separately; the floor and over-fish surface reflect it even through gaps in the blossoms. Thickened the forks and muted their colour rather than making scratch-like dark hairlines. Rendered solo water and Pond Next, including 390x844 phone and 1280x800 desktop. The stronger final phone render gives a mauve forked band to the left, but it remains impressionistic and can darken the demekin side; the high caustic contrast still leads the image. No shader errors.
  - Security A: procedural shader functions only, no network, telemetry, persistence, new input sinks, file I/O, secrets, or bridges. Real GPU FPS remains unknown. Main/live unchanged.
  - Push blocker: config-c loaded GitHub signed out; stopped before any edit and reported to parent. c26-c28 are local only.
- Still worse, in order:
  1. Real phone GPU frame rate unknown.
  2. Ryukin veil translucency over pale stones and tight-turn tip brushes.
  3. Canopy still reads as a mauve shadow more than an obvious tree; stronger reflection can darken black fish.
  4. No on-screen pond settings panel.

- 2026-09-25 07:54 IST, cycle 27: fish turn - ryukin veil contrast in Pond Next.
  - Hard critique: the ryukin's veil base looked white-hot against the floor, while its peach tips disappeared over pale stones. Added pond-only root/tip colour and reduced backlight plus light-net strength on the veil; the solo fish keeps its previous defaults. Checked ryukin solo on the debug stage and Pond Next at 390x844 and 1280x800. The veil reads as a warmer, more continuous sheet, though pale stones still show through it and a caustic can flatten its edge. No shader errors.
  - Security A: local shader uniforms and material parameters only; no network, persistence, telemetry, secrets, file I/O, new input sink, or JS bridge. Main/live unchanged. The software rasterizer does not measure actual phone GPU FPS.
  - Push state: c26 d1fddeb and this c27 pass are local only. The signed-in browser lease was acquired but the old push helper ignored the lease ID; it was fixed outside the repo, no browser edit occurred, and parent asked for retry next cycle rather than hammering it.
- Still worse, in order:
  1. Real-phone GPU frame rate is unknown.
  2. Ryukin veil still too translucent on pale stones; tight-turn tip brushes remain possible.
  3. Canopy tree is subtle at phone size, settings panel absent in the pond.

- 2026-09-25 06:54 IST, cycle 26: fluid turn - a shared reflected canopy shape.
  - Hard critique: the pond reads as luminous pebbles and caustic web first; the blossom reflection was pink stains with no branch silhouette. Added a softened fork/trunk and broad leaf masses in a shared shader function, sampled by both bare water and the over-fish pass. Solo water and integrated Pond Next rendered. The branch remains subtle in the integrated composition, intentionally behind the fish, not a black hair-like line.
  - Phone 390x844 and desktop 1280x800 render checks passed, but the ryukin base is still bright against caustics and at some angles its veil dissolves into pale stones. The branch is still too weak to read as a tree at phone size. No shader errors. llvmpipe movie GPU timings are software rendering, not real-device FPS.
  - Security A: shader-only procedural arithmetic and shared include, no new endpoints, persistence, secrets, script bridges, third-party loads, or input sinks. Main and live untouched.
- Still worse, in order:
  1. Real-GPU frame rate unmeasured (needs phone hardware).
  2. Veil base stacks with backlight/caustics and tips can brush on tight turns.
  3. Canopy branches still too subtle in Pond Next at phone size; improve without making them look like scratches.
  4. No on-screen settings panel in the pond.

- 2026-09-25 05:52 IST, cycle 25: fish turn - warm veil tips in the pond.
  - The ryukin veil read milky white over the pale floor (overnight worse-list #2). Fin shader has a new `veil_far` colour (the tone the pale veil fades to at its tips); the pond sets it to warm peach, the solo fish lab keeps white. With the lighter light net on veils (03:17) the veil now reads as a peach-tinted sheet over the stones on desktop and phone.
- Still worse, in order:
  1. Real-GPU frame rate unmeasured (needs one look on a phone).
  2. Veil base still bright where fresnel and the backlight stack; tips can brush on tight turns.
  3. Canopy reflection is pink stains with no tree structure.
  4. No on-screen settings panel in the pond.

- OVERNIGHT (Sep 25, from 00:35 IST) - Pond Next, the one deep piece for the 7 AM delivery (parent relay of user directive 00:34: serious, QA-verified, live-ready; report by 06:45).
  - Done: `-- --lab=pond` (labs/pond_lab.gd, extends fish_lab.gd). Water canvas as 3D background (BG_CANVAS, layer -1, linear tonemap so the water keeps its colour), solo-tested ryukin + demekin from overhead, wander/separation/soft-wall steering with banking and fin bend from turn rate, surface kisses with rings, tap = food pellet that sinks, nearest fish eats it (ring + rise). Surface pass (water_lab/surface.gdshader) drawn over the fish: glints, blossom/sky reflection, faint water veil, so fish sit under the water. Soft fish shadows on the floor (body + veil), which also block the light net. Ryukin patch colour white-peach in the pond.
  - 00:45-00:59: food verified with scripted taps (`--autotap=1`: pellets land, nearest fish swims over and eats, ring + rise). Desktop framing (landscape keeps the height, camera higher). "Web Next" export preset (feature tag kin_next, root.gd starts the pond; `sh build.sh "Web Next"` -> godot/export_next/, gitignored, CSP added). Browser QA in headless Chromium (swiftshader) at 390x844 and 1280x800: loads, console clean (3 engine info lines), 0 external requests, tap feeds. Ripple sim moved to the GPU (labs/water_lab/ripple_sim.gdshader, ping-pong RGBA16F SubViewports, drops as uniforms): water script time 6.0 ms -> 0.04 ms per frame natively (wasm would be ~3x the CPU figure). `--gpu=0` keeps the CPU path. `--perf=1` prints script timings.
  - 01:15: GPU sim now does two wave steps per pass (5x5 stencil, one SubViewport draw), so ripples travel at the old CPU speed. CURRENT_TASK/HANDOFF have the pond run and build commands.
  - 01:17: the light net now slides over the fish (fish shaders sample the water's caustic target in screen space, only on up-facing surfaces; off by default so the solo fish lab is unchanged; `--caus=0` turns it off in the pond). A/B render: visible on the demekin's back, soft on the ryukin.
  - 01:25: blossom reflection over the fish lightened (the black veil no longer greys under the canopy). Rebuilt Web Next and re-ran browser QA at 390x844 and 1280x800: loads, console clean (3 engine info lines), 0 external requests, tap drops food with a ring; the two-step GPU sim and fish caustics compile under WebGL2.
  - 01:59: milestone pushed to godot-prototype through the web editor (14 files, fa0281d..cc4a293); remote tree matches local. New-file helper: /home/sandbox/push_webeditor_new.sh.
  - 02:47: tap = soft pellet plop (was a dark crater). Fish spacing rebuilt after renders showed the veils crossing: each fish is a nose-to-veil-tip line, the steering keeps 1.5 between lines and a hard floor of 0.75 (veils ~0.3 each side), targets are picked for room, the fish with the other ahead yields; at feeding the fish nearer its pellet has right of way, the other goes for a different pellet, veils may brush (0.5) but not cross. Headless QA (`--gapqa=1 --qaw=390 --qah=844`, 3 min sim): closest gap 0.73 phone / 0.73 desktop (was 0.11), both pellets eaten in 3-7 s (was 16-52 s).
  - 03:15: desktop pond uses ~34k sim cells (about 5.5 px per cell instead of 7), so on wide screens the light net and rings are finer and the stones sit in better scale with the fish. Phone unchanged.
  - 03:56: quality fallback for slow devices (`--adapt=0` to disable; off while writing movies): after 4 s, each 3 s window under 45 fps steps down once - light net redrawn every other frame, then 3D fish at 75% resolution; never steps back up. Verified it triggers under xvfb (7.5 fps) with no script errors. Security scan of the overnight diff: no network calls, no JS bridge, no file or shell access, no secrets; export CSP default-src 'none', connect-src 'self'; the only URLs in the export are engine doc strings.
  - 05:17: final Web Next build (index.wasm 38.0 MB, index.pck 206 KB, CSP added) and browser QA (headless Chromium, swiftshader) at 390x844 and 1280x800: loads, console clean (3 engine info lines), 0 external requests, 5 requests total, tap drops a pellet with a soft ring. build.sh now drops a .gdignore in the export folder so the editor does not import its pngs.
  - Next: fish veil washes white on the lower-left canopy; real-GPU frame time can't be measured here (swiftshader ~1-2 fps is CPU raster), so keep GPU cost low: check caustic grid density on desktop; then final QA renders, push source via web editor, report.

- 2026-09-24 23:57 IST, cycle 24: fluid turn - fold sheets, depth slope, stone bug.
  - Bug fixed from c22: the per-pixel stone-drift lookup let neighbouring cells disagree, so some pebbles were sliced along cell edges. Each stone now decides from its own 5x5-cell block (one hash per neighbour, still cheap).
  - Caustics: soft knee on the ray-grid intensity (normal light unchanged, cusps compress), and flipped triangles inside folds are kept at 30%. On desktop the big flat pale sheets from fresh drop rings are dimmer and warmer but still visible.
  - Depth slope (`--slope=0..1`): shallow bottom-left, deep top-right; absorption and refraction follow it and the light net spreads thinner in deep water.
  - Canopy reflection is softer (lower-frequency blossom, wider gaps). Tried thin dark branches: they read as hairs on the lens, dropped.
  - Fresnel and the sky tint are capped at steep slopes.
- Still worse than Clearwater / real water, in order:
  1. Desktop fold sheets: fresh drop rings still paint flat pale patches on the coarse desktop grid; needs a denser caustic grid on desktop or a filtered target.
  2. The canopy is still pink stains with no tree structure.
  3. The depth slope is subtle at phone size.
  4. No on-screen settings panel; export frame cost not measured.

- 2026-09-24 22:53 IST, cycle 23: fish turn - body section and side fins. Tested solo (model_test.sh sheets, before = c21 kin-mt3, after = kin-mt4).
  - Ryukin body: laterally compressed (narrower), tapered snout, and the upper section narrows into a dorsal ridge, so it reads as a tall teardrop head-on and slimmer from the top instead of an egg.
  - Side fins: pectorals, pelvics and the anal pair are now real fans (longer, twice as wide, 10-12 subdivisions) with rounded scalloped edges that cup and hang; they show in both silhouettes on both fish.
- Still worse, per model:
  1. Veils still single sheets, no darker layering where lobes overlap.
  2. No fish defocus (only the grid blurs).
  3. Demekin eye sockets read as black tyres from the front on desktop; need body-coloured, softer rims.
  4. Ryukin head-on is better but still round at the belly; the hump still reads mainly from the side.
  5. Settings panel style and style modes still open.

- 2026-09-24 21:58 IST, cycle 22: fluid turn - floor, canopy, crisper net.
  - Sand: warm, with large drift patches and fine grain; absorption retuned (less red loss, lighter aqua tint) so the floor no longer reads grey-olive.
  - Pebbles: sparser, gathered in drifts with bare sand between (`--density=0..1`, default 0.55), mineral speckle and a small wet highlight toward the sun; skipped stones cast no contact shadow.
  - Canopy reflection: blossom clusters with bright sky showing through the gaps instead of one flat pink wash.
  - Caustics: tighter soften taps (`--crisp=0..1`) bring back line sharpness lost in c20; no zipper at phone size.
  - Frame cost: the stone-drift lookup is once per pixel (a per-cell version made the desktop frame render too slow to finish).
- Still worse than Clearwater / real water, in order:
  1. With --crisp=1, strong new drop rings fold into bright white blobs (seen on desktop early frames); needs an energy clamp on fold cusps.
  2. The canopy reads as faint pink stains, not a readable tree; needs soft blur and a darker branch structure.
  3. Desktop sand still flattens to khaki between lines; no depth slope across the pool.
  4. No on-screen settings panel; web frame cost still not measured on the export.

- 2026-09-24 20:52 IST, cycle 21: fish turn - veil pleats, rim-only fresnel, velvet demekin, bigger eyes. Tested solo (debug stage + model_test.sh contact sheets, before = c19 sheets).
  - Veils: vertex fold along the fin rays (pleats), the far side of each fold shades darker; fresnel is limited to a thin rim band so fins glow at the edge instead of washing out the whole sheet (Alpha Fresnel / Rim Glow sliders drive it).
  - Demekin body: matte velvet with a blue-violet grazing sheen instead of glossy black; copper iris now shows.
  - Eyes: bigger on both (ryukin radius 0.056), readable at phone size on the debug stage.
- Still worse, per model:
  1. Veils are still single sheets: no darker layering where lobes overlap; ryukin pleats read only up close.
  2. No fish defocus (only the grid blurs).
  3. Ryukin head-on is still egg-shaped; the hump reads from the side only.
  4. Pectoral/pelvic fins are still slivers.
  5. Settings panel style and style modes (pixel/low-poly/wireframe) still open.

- 2026-09-24 19:57 IST, cycle 20: fluid turn - zipper hunt, surface reflection, bloom.
  - Zipper: diagnosed with isolation renders (--wind=0 removes it, turning off reflection/bloom/glints does not), so it came from ray folds in the swell caustics, not the ripple sim. Fixes kept: cubic B-spline sampling of the sim heights (smooth slopes), 1.5-cell gradients, lower caustic focus (0.92) so fewer rays fold, wider 4-tap soften. Tried and dropped: an HDR caustics target (kept fold spikes -> speckle) and a full-res target (hatching at folds). 2D MSAA is not supported in GLES3.
  - Surface reflection: reflected-ray lookup of a warm sky with a blossom-pink canopy along one side, so a pink wash with a wobbling edge lies over the left of the pool (`--refl=0..1`).
  - Bloom: a ring of wide taps on the caustics adds a soft warm glow on the brightest lines (`--bloom=0..1`).
- Still worse than Clearwater / real water, in order:
  1. The caustic net is softer than c17: zipper gone, but the lines lost some crispness. A proper fix is a filtered (mipmapped) caustics target like Clearwater's.
  2. The canopy reflection reads as a flat wash; it needs leaf gaps and brighter sky between them.
  3. Sand is still flat grey-olive between the lines, with no depth changes.
  4. Pebbles have no speckle or wet highlights.
  5. No on-screen settings panel; web frame cost not measured (CPU sim ~20k cells + 3 x ~36k-vertex caustic grid per frame).

- 2026-09-24 18:52 IST, cycle 19: first fixes driven by the solo model tests.
  - Veils: fin mesh outline is now shaped in geometry, not only by alpha: rounded lobe ends, uneven scallops between rays, a deep centre fork on each caudal fin, and the sheet hangs more toward its tip with a slight edge wave. The tail reads as two forked, drooping lobes in side and top silhouettes (was two hard wedges). Dorsal has a ragged, hanging trailing edge.
  - Eyes: socket rim of body tissue, gold (ryukin) / copper (demekin) iris disc, big black pupil, clear flattened glossy lens dome on top; faces out and slightly forward.
  - Ryukin shoulder: head sits lower and the back rises behind the eyes into the hump.
  - Model-test framing shows the whole fish including veil tips (c18 sheets cropped the tail, so before/after is not pixel-comparable).
- Still worse, per model:
  1. Veils are still one sheet each: no folds along the rays and no darker overlapping layers where lobes cross.
  2. Ryukin head-on is still a smooth egg; hump reads from the side only. Eyes read at 2x crop but are small at phone size.
  3. Demekin body is glossy black, not velvet; copper iris barely shows.
  4. Pectoral/pelvic fins are still slivers; fresnel-as-edge-glow and fish defocus still open.
  5. Settings panel styling and style modes still open.

- 2026-09-24 18:30 IST, cycle 18: solo model tests (Naksh 6:25 PM: Hakozaki "tests every model before using it, separately"; reference post x.com/m_hakozaki/status/2101485567087452339 shows one moon jellyfish on a bare debug grid, orbit camera, live sliders Blur Intensity / Blur Min / Alpha Intensity / Alpha Min / Alpha Fresnel).
  - Debug stage: `-- --lab=fish --stage=debug [--kind=ryukin|demekin]`. One fish, dark debug grid floor, slow low orbit, live dark knob panel: Model, Alpha Intensity, Alpha Min, Alpha Fresnel (fins), Rim Glow (body + fins), Blur Intensity, Blur Min. The Compatibility renderer has no depth of field, so blur is a stand-in: grid lines soften with distance from the focus plane, never below Blur Min. Landscape keeps the vertical view.
  - Model test mode: `--kind=` alone, `--light=studio|back|top|flat`, `--anim=` (0 freezes the rig), `--sil=1` flat silhouette, `--turn=deg`. godot/tools/model_test.sh <kind> <out.png> renders an 8-view contact sheet (side, front, top, 3/4, backlit, side and top silhouettes, flat light).
- What the model tests show (worse-list, per model):
  1. Silhouettes: both tails are hard triangular wedges and the dorsal is a rectangular blade; real veils have scalloped, drooping, uneven edges. Pectoral/pelvic fins are thin curved slivers.
  2. Ryukin front view: body is a smooth egg with flat dot eyes; no shoulder hump, no socketed eye.
  3. Demekin: telescope eyes read, but the orange ring still looks stuck on; black body needs velvet falloff, not gloss.
  4. Fins at high Alpha Fresnel go chalk-white; fresnel should add edge glow, not flatten the whole sheet.
  5. Blur is only on the grid; the fish themselves never defocus.

- 2026-09-24 18:10 IST, cycle 17: real floor caustics (Naksh 6:03 PM: "Can use fluid resources i gave or anything that makes this better feasibly").
  - Studied Clearwater's caustics pass (MIT): a grid of sun rays is refracted through the surface and drawn where it lands on the floor, additively; each triangle's brightness is its original area over its landed area, so bunched rays glow. One draw per colour channel with its own refraction strength gives the rainbow fringes.
  - Our version in Godot Compatibility: a half-resolution SubViewport redrawn each frame with a ray-grid ArrayMesh (~1.6 px cells, overscanned at the edges), vertex shader refracts each vertex using the shared surface gradient (sim + swell, in water_common.gdshaderinc), fragment uses dFdx/dFdy area ratio, blend_add, 3 channels. The surface shader looks the caustics up where each view ray meets the floor, with a 4-tap soften.
  - Result: a continuous net of bright lines instead of shards; ripple rings throw focused rings of light. Warmer look (sun-tinted caustics, warmer sand, gentler absorption, `--warm=0..1`). Pebbles get contact shadows and the pale outline ring is gone.
- Still worse than Clearwater / real water, in order:
  1. Some caustic lines show a sawtooth "zipper" edge (half-res target plus bilinear sim gradients); needs a finer target or smoothed gradients.
  2. The surface itself is almost invisible: no sky or rim reflection, no bloom or glare (Clearwater has lens glare + bloom).
  3. Sand reads grey-olive between caustics; floor needs more KIN colour and some depth variation (Clearwater uses a pebble texture with height).
  4. Pebbles are flat-coloured discs; they want speckle and wet highlights.
  5. No on-screen settings panel; web frame cost of the per-frame ray grid (3 x ~33k verts on phone) not yet measured.

- 2026-09-24 17:55 IST, cycle 16: fluid lab v1 (water on its own, no fish).
  - Heightfield ripple sim on the CPU (~20k square cells, long axis follows the viewport, two steps per frame, damped), random drops plus tap/drag drops, uploaded each frame as a float texture.
  - Shader: analytic ambient swell (9 travelling waves) plus the sim; floor refraction split per colour channel (dispersion); caustics as the inverse area change of the refracted ray bundle, det(I + k*Hessian), per channel (Clearwater idea, our own code); Beer-Lambert style absorption so the water reads aqua; sun glints with shininess eased by local normal variation (a cheap LEAN-like anti-shimmer); soft sky sheen; highlight shoulder so caustics do not clip.
  - Floor options: scattered rounded pebbles on sand (default), pool tile, sand ripples. World scale per pixel is the same on phone and desktop.
  - Tried and dropped: a voronoi mosaic floor (read as stained glass) and a Laplacian-only caustic (blotchy glare, no web).
- Still worse than Clearwater / real water, in order:
  1. Ambient caustic web is broken into short shards; real caustics form a continuous net of thin bright lines. Needs a caustic pass computed at the floor (ray-march or a caustic texture in a SubViewport) instead of the per-pixel surface Hessian.
  2. Colour is cold grey-teal; KIN wants warmer, brighter water with a pastel floor.
  3. Pebbles have a pale outline ring and no contact shadows; they look pasted on.
  4. No bloom and no surface reflection of a sky or rim; the surface itself is nearly invisible where there are no caustics.
  5. Tile floor is untested at phone size; no settings panel yet (launch args only); frame cost on web not measured.

- 2026-09-24 16:50 IST, cycle 15: fish lab v2.
  - Butterfly double tail: two broad forked fans that stand near-vertical at the root and splay outward (58 deg), cupped across their width, with a centre fork and rounded lobe tips. From above it now reads as two lobes, not one fan.
  - Demekin telescope eyes are smooth domes of body tissue with the eye on the outer face (the cylinder "headphones" are gone).
  - Gill plate crease behind the eye and a small mouth on both fish.
  - Showcase settings panel (Hakozaki-style, collapsed by default behind a Settings button): camera Orbit/Top/Side, fish Both/Ryukin/Demekin, background Lilac/Paper/Night/Mint, field of view, tail length, fin opacity, brightness, saturation, contrast. All also settable from launch args.
  - Viewport wireframe was tried for a wireframe style mode: it does nothing in the Compatibility renderer, so that control was removed; style modes need their own shader path.
- Still worse than the reference / real fancy goldfish, in order:
  1. The fish are small in the frame and the head reads cartoonish: eyes are flat black dots with a ring; real goldfish eyes sit in a socket with a glossy lens and a gold iris.
  2. Veils are still flat-ish sheets with even transparency; real veils fold along rays and pile up in darker overlapping layers.
  3. Body silhouette is a clean egg; the ryukin needs a sharper shoulder hump and a tapering belly line, and a lateral line/scale shimmer.
  4. Demekin iris ring sits on the dome like a sticker.
  5. Settings panel uses default grey dropdowns; needs KIN styling. Style modes (pixel, low-poly, wireframe) not built.

- 2026-09-24 15:50 IST, cycle 14: fish lab v1 (workstream split).
  - New 3D fish lab (Compatibility renderer): procedural lofted body from nose to caudal peduncle with egg-shaped, superelliptic sections, a high back behind the head (ryukin hump) and a narrow peduncle; soft-sheen body shader (faint scale lattice only in the sheen, peach/red patches on the ryukin, velvet black with a cool rim light on the demekin); double tail as four drooping sheets, tall dorsal, paired pectoral/pelvic/anal fins; thin double-sided fin shader (rays, edges fading to clear, back-light, faint prismatic edge glint); one spine wave drives body and fins, with fins lagging and rippling like cloth. Eyes with iris rings; demekin telescope eyes on stalks. Cameras: 3/4 orbit, top, side.
  - Workspace reset twice this afternoon and uncommitted work was lost once; the push tool now lives in the repo (godot/tools/mkpush.py) and work is committed as soon as it renders.
- Still worse than the reference / real fancy goldfish, in order:
  1. Top view: the double tail reads as one flat fan; his ryukin tail is two big overlapping lobes that fold and drape.
  2. Demekin telescope eyes look mechanical (cylinder + ring); they should be smooth domes growing out of the head.
  3. Body lacks the gill plate, mouth and a head-to-body transition; the ryukin reads as a smooth egg.
  4. Fins are flat sheets; real veils curl at the edges and fold along rays.
  5. No showcase settings panel yet.

- 2026-09-24 14:00 IST, cycle 13: black veil.
  - Cause of the desktop grey smear: the demekin veil was semi-transparent over most of its area, and on desktop (fish ~2x bigger) the tail trailed past the glass where the rim fade thinned it further. Fixes: veil is now near-opaque ink through its body with a faint blue sheen, softness only in the ragged last stretch and on noise-feathered side edges (a first opaque try showed a hard wedge outline; feathering removed it). Wall-avoidance margins now scale with fish size, and the fish also steers inward when its veil tip nears the glass.
  - Checked desktop 1280x800 render frames (crops of the demekin over ~10 s) and the web frames on phone and desktop: veil reads black and full, no grey smear.
  - Web QA: phone boot 4.5 s, desktop 4.5 s, 10 same-origin requests, 0 external, 0 CSP errors; toggle + reload OK. Pack 140 KB.
- Still worse than reference, in order:
  1. Demekin ruffle is subtle at phone size.
  2. His petals sit in clear depth layers with a few big soft ones in front; ours are more evenly spread.
  3. A faint straight line still shows along the demekin veil's root edge at some angles.
  4. Boot splash flashes lilac before the pond.

- 2026-09-24 13:00 IST, cycle 12: fish gap, sakura, caustics.
  - Fish separation now measures the closest pair across both whole bodies, including two points down each veil, and keeps a visible gap (half-widths + margin). A 1.2 s look-ahead makes a fish sidestep when their paths would cross, and the one behind slows to give way. Tap targets are offset per fish so both no longer aim at the same pixel. 14 phone render frames over 20 s: no touches (c11 build touched in 2 of the same 14 frames).
  - Sakura: 44 base (was 24), 12-21 px base size (was 9-15), 62% whole flowers (was 30%). Foreground blurred petals are single petals at 0.36 alpha; the big foreground flowers were washing the black fish grey.
  - Caustics after Clearwater (MIT) / Evan Wallace: a soft travelling-wave web on the bowl floor, brightness from refracted-area ratio via screen derivatives, per-channel refraction for faint colour edges, plus rings from the touch ripple sim. Kept pale (tuned down twice) so it reads as light, not a pool.
  - Phone bowl framing: tried fitting the whole bowl in 390px; it read small and cramped and the fish crossed the rim. Reverted to the macro crop, which matches the reference (no rim in his frame). Dropping this from the worse-list.
  - Web QA: phone boot 4.4 s, desktop 2.2 s, 10 same-origin requests, 0 external, 0 CSP errors; toggle + reload OK. Pack 139 KB.
- Still worse than reference, in order:
  1. Desktop: a deep demekin's veil fades to a large grey smear; his black veil stays inky.
  2. Demekin ruffle is subtle at phone size.
  3. His petals sit in clear depth layers with a few big soft ones in front; ours are more evenly spread.
  4. Boot splash flashes lilac before the pond.

- 2026-09-24 11:54 IST, cycle 11: demekin outline, depth, sizing.
  - Demekin body edge is softly ruffled (two-octave noise on the outline from the shoulder back), closer to the reference's velvet silhouette.
  - Depth tint cut (max 0.18 water mix, was 0.4) so a deep ryukin stays readable.
  - Desktop fish scale capped (radius factor 1.6, was 2.6): the fish were so big on desktop that two of them could not fit above the card; now they have room.
  - Separation nudge can no longer push a fish out through the glass or under the card (nudge skipped when it would land near the wall). A hard pull-back was tried and reverted: the sudden jumps tore the fins into shards.
  - Web QA: phone boot 5.1 s, desktop 4.4 s, 10 same-origin requests, 0 external, 0 CSP errors; toggle + reload OK.
- Still worse than reference, in order:
  1. The two fish still touch and slightly overlap when both head for the same spot (seen in web frames right after the chip click).
  2. Phone: the bowl is cut off at the sides.
  3. His sakura are bigger, denser and more layered.
  4. Demekin ruffle is subtle at phone size.

- 2026-09-24 10:50 IST, cycle 10: fish spacing and ryukin shape.
  - Separation now checks head, mid-body and rear body on both fish (3x3 pairs), with a radius from body widths plus a share of length and a firmer positional push. At desktop scale the fish no longer slide over each other's backs (checked across 300 render frames and the web frames).
  - Ryukin slimmer with a longer veil (len 108, w 55, tail 215), closer to the reference frame.
  - Web QA: phone boot 4.3 s, desktop 4.1 s, 10 same-origin requests, 0 external, 0 CSP errors; toggle + reload OK.
- Still worse than reference, in order:
  1. Demekin outline is smooth; his is visibly ruffled.
  2. When the ryukin swims deep it fades and blurs a lot; his fish stay crisp.
  3. Phone: the bowl is cut off at the sides.
  4. Sakura in his bowl are bigger, denser and more layered.

- 2026-09-24 09:55 IST, cycle 9: veils.
  - Demekin veil: the hard dark wedge is gone. Trailing edge is now ragged in soft lobes (higher-frequency noise, deeper cut), side edges fade, and the veil stays dark and near-opaque like the reference's black veil.
  - Both veils: each strand also ripples on its own phase, so the veil flutters in layers instead of moving as one flat sheet.
  - Checked against a fresh frame of the reference video (3 s): his demekin is solid black with a ruffled outline; ours now matches the tone.
  - Web QA (fresh workspace, new /tmp/qa.py): phone boot 4.7 s, desktop 2.3 s, 10 same-origin requests, 0 external, 0 CSP errors; toggle + reload OK. Pack is 115 KB (fresh clone; no untracked local files included).
- Still worse than reference, in order:
  1. On desktop the two fish can overlap and draw through each other now that they are bigger (B3).
  2. His ryukin is slimmer with a longer white veil; ours reads rounder and shorter.
  3. Demekin outline is smooth; his is visibly ruffled.
  4. Phone: the bowl is cut off at the sides.

- 2026-09-24 08:49 IST, cycle 8: framing.
  - While the naming card is up, its top edge (plus a margin that scales with the bowl) acts as a soft wall and new swim targets are picked above it, so both fish stay in view on phone instead of hiding under the card.
  - Landscape frames the bowl closer (radius x1.12): the rim runs just past the top and bottom edges and the fish scale up with it, nearer the reference's macro shot.
  - Web QA: phone boot 6.7 s, desktop 6.2 s, 14 same-origin requests, 0 external, 0 CSP errors; toggle + reload OK.
- Still worse than reference, in order:
  1. On the web export at desktop size, the demekin veil still shows a hard-edged dark wedge near the root on some turns.
  2. Veils are one sheet; his flutter in layers.
  3. Demekin lumps are subtle; his has visible velvet texture and a bigger dorsal.
  4. Phone: the bowl is cut off at both sides (radius 1.3x half-width); the reference shows more of the rim.

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

- 2026-09-25 15:56 IST, cycle 35 (fish): body caustic cap, local only.
  - Fish body shader gains a default-neutral `caus_cap=8`; Pond Next sets 0.55, analogous to the veil cap. Solo ryukin remains on its default.
  - Solo debug ryukin at 390x844 and integrated Pond Next at 390x844 and 1280x800 rendered without shader errors. Side-by-side with c34: bright patch on peach body is still plainly present. This caps raw caustic spikes but does not solve body glare; specular or reflected light needs separate diagnosis.
  - Worse-list: (1) peach body white patch and floor caustic knots still compete with the fish; (2) canopy still reads as haze, not a clear tree; (3) actual veil mesh collisions on tight turns unmeasured; (4) real-phone GPU frame cost unmeasured.
  - Security grade A- for this local diff: shader cap and fixed in-scene parameter only; `git diff --check` clean; no new network, input, storage, telemetry, or secret handling. Runtime/export and browser security not retested this cycle.
  - Branch sync parked due exhausted cloud-browser budget and parent direction; main and live unchanged.

- 2026-09-25 20:02 IST, cycle 39 (fish), local candidate committed after inspection.
  - Demekin tail: broadens the double-lobe mesh (spread 1.0 -> 1.2), lowers splay (58 -> 42 degrees), increases mesh subdivisions (26x28 -> 30x34) and inky shader alpha (1.5 -> 1.85); scallop was dialed back to 0.16 after the first version made sharp spikes.
  - Integration: original fish scale restored after an enlarged trial clipped on phone; demekin spawns 0.24 pond units inward and the horizontal steering margin is 1.0 instead of 0.7. This is a soft wall, not a formal no-clip proof.
  - Solo debug at 390x844 and Pond Next at 390x844 and 1280x800 ran without shader errors. Four phone frames across 0-2.3 s show the fan remains inside the frame. Its outline remains more smooth leaf than Hakozaki's dense black ruffle; not a match yet. No claim about all turns or mesh intersections.
  - Worse-list: (1) demekin ruffled fabric silhouette and sharp upper tip; (2) ryukin residual pale stripe; (3) busy pebble/caustic floor and faint tree; (4) actual fin intersections and real-device GPU timing unmeasured.
  - Security grade A- for this local diff: procedural mesh, shader alpha, and steering constants only. No network/storage/input surface or third-party assets added; runtime logs and diff checked. Browser/export security not retested this cycle. Main/live unchanged; branch sync parked under parent browser limit.

- 2026-09-25 20:59 IST, cycle 40 (fluid): modest surface/floor hierarchy pass.
  - Default pebble density lowered 0.55 -> 0.36; floor light-net diffuse 0.18 -> 0.13, highlight cap 1.0 -> 0.7 and multiplier 0.04 -> 0.035, bloom 0.08 -> 0.055. Surface glint layer was left unchanged. These settings affect the water lab and Pond Next, not the existing bowl or live /godot/.
  - Inspected solo water at 390x844, Pond Next 390x844 and 1280x800, and four phone motion samples through 2.6 s; no shader errors. Before/after phone image shows calmer sand and some more open pockets, but pebbles still compete for attention and the reflected canopy remains indistinct. Grade: modest, not a reference match.
  - Worse-list stays: demekin upper fan tip and ruffle; residual ryukin pale stripe; busy floor and faint tree; fin intersections and real-phone GPU timing unmeasured.
  - Security grade A- for this local shader/default pass: no network, storage, user input, external assets or secrets; diff check clean. Browser/export security not retested here. Branch sync and /next/ deployment will wait until after midnight browser reset and the approved signed-in web route; /godot/ stays untouched.

- 2026-09-25 21:59 IST, cycle 41 (fish): tested and reverted.
  - Demekin scallop 0.16 -> 0.12 and fork 0.26 -> 0.12 in a candidate. Solo 390x844 and Pond Next 390x844/1280x800 rendered without shader errors. Before/after at phone size: upper tip slightly less pointy but fan read even more like a smooth leaf, not a dense ruffle. Reverted both values; no shipping visual change.
  - Worse-list unchanged: demekin fan needs a structural ruffled silhouette with soft rounded tips, not just less scallop; ryukin pale stripe; floor/tree hierarchy; fin-mesh collisions and real-device GPU cost.
  - Security grade A for resulting source (no code change); work records only. No browser or branch sync until reset; /godot/ unchanged.

- 2026-09-25 22:59 IST, cycle 42 (fluid): bare sand test rejected.
  - Set default floor to sand for solo water and Pond Next and rendered 390x844/1280x800. The pebble layer was indeed a distraction, but without it the caustic grid dominates every inch and the scene looks shallow, with a dull beige-green floor. Reverted floor default to pebble; the existing `--floor=sand` setting still permits it as an option.
  - Worse-list: demekin fan tip/ruffle, ryukin pale stripe, floor/light net versus surface separation, fin intersections and real-device GPU cost. Need a structural light-net/surface treatment, not an empty floor.
  - Security grade A for resulting source (no code change); records only. Browser/branch/deploy still pending local midnight budget reset; live /godot/ untouched.

- 2026-09-26 01:00 IST, cycle 43 (fish): rejected edge-shape candidate.
  - Tested a rounder lobe outline and five scallop cycles on the caudal sheet at solo 390x844 and Pond Next 390x844/1280x800; all ran without shader errors. Phone before/after showed teeth and detached-looking points, worse than the retained c39 leaf. Reverted code. The candidate also used a numerical seed threshold that would have affected ryukin, so it was unsuitable even if visually acceptable.
  - Worse-list unchanged: soft dense demekin ruffle; ryukin pale stripe; floor/surface hierarchy; actual fin intersections and real-device GPU cost.
  - Security grade A for resulting source, no code change. Browser session still blocked on the shared GitHub sign-in, and I did not initiate one; /godot/ remains untouched.

- 2026-09-26 02:01 IST, cycle 44 (fluid): local-only floor-net softening after /next/ ship.
  - Widened four floor-caustic offsets 2.5x and lowered bloom activation from 2.0 to 1.6. Solo water 390x844, Pond Next 390x844 and 1280x800, and a phone before/after show a softer floor grid with pebbles retained. No shader errors. Grade: modest, not a canopy or surface-plane solution.
  - Security grade A-: shader math only, no new network, storage, input, telemetry or assets; `git diff --check` clean. Real-device frame cost still unknown.
  - The prior snapshot shipped to https://aeiouvcode.github.io/kin-living-pond/next/ via guarded manual workflow; this c44 commit is local until a later sync. Live /godot/ untouched.

- 2026-09-26 03:01 IST, cycle 45 (fish): pond-only color test rejected.
  - Base 0.84/0.64/0.62 -> 0.84/0.58/0.56 and patch 1/0.66/0.56 -> 0.98/0.59/0.49 tested at solo ryukin 390x844 and Pond Next phone/desktop. Solo remained identical by design; pond before/after showed little improvement to the residual stripe and a flatter pink blush. Reverted the candidate.
  - Worse-list unchanged: demekin ruffle, ryukin pale stripe, floor/surface hierarchy, actual fin intersections and real-device GPU cost. Next fish experiment should isolate patch mask versus normal/backlight at the stripe location, not recolor everything.
  - Security grade A for no resulting code change; records only. The initial /next/ deployment remains live, and /godot/ unchanged.

- 2026-09-26 04:02 IST, cycle 46 (fluid): rejected canopy-edge candidate.
  - Mask edge 0.83/0.10 -> 0.64/0.05 with lower-frequency leaves was rendered in solo water at 390x844 and Pond Next 390x844/1280x800. The image lost branch presence and became a flat wash on the left; no shader errors. Reverted the candidate. The reflected tree needs an intentional branch/blossom shape that survives phone size, not a narrower edge gate.
  - Worse-list unchanged: demekin ruffle; ryukin stripe; floor/light-net versus surface hierarchy and canopy form; actual fin intersections and real-device GPU timing.
  - Security grade A for no resulting source change; records only. First /next/ deploy still live and /godot/ untouched.

- 2026-09-26 05:04 IST, cycle 47 (fish): rejected head patch-mask test.
  - Hard critique: the ryukin's transverse pale stripe across the shoulder still looks painted on at phone size. Reduced the body shader's head-mask contribution 0.8 -> 0.25; fixed-frame A/B renders at solo debug 390x844 and Pond Next 390x844 / 1280x800 showed the stripe unchanged, apart from a tiny blush shift. All three runs had no shader error (only the expected V-Sync driver warning). Reverted. The stripe may arise from overlapping fin geometry or lighting, so a mask-only change is not justified.
  - Worse-list unchanged: dense soft demekin ruffle; ryukin stripe; floor/surface hierarchy and canopy form; actual fin-mesh intersections and real-device GPU timing. No source/feature change after rejection.
  - Security grade A: only work records committed; no new network, secrets, telemetry, input sink, or export asset. Existing live /next/ is the earlier build; /godot/ remains untouched.

- 2026-09-26 06:03 IST, cycle 48 (fluid): rejected reflected-blossom cluster test.
  - Hard critique: left-side canopy still fails to read as a tree, and the floor caustic grid competes with the fish. Replaced broad edge mask with three soft flower clusters around the existing forks, leaving branch geometry intact. Solo water at 390x844 showed too much pink fog over the pebbles, while Pond Next at 390x844/1280x800 showed almost no stronger tree structure. Inspected actual pixels; no shader errors. Reverted to avoid fog without payoff.
  - Worse-list remains demekin ruffled fabric, ryukin stripe, floor/surface light hierarchy, canopy silhouette, fin-mesh crossings and real-device GPU timing. Next fluid study should isolate the over-fish surface layer and lower floor-grid dominance, not add more blossom mass.
  - Security A: no source change after rollback; records only, clean diff. No new network, persistence, secrets, telemetry, inputs, or export. Live /next/ still the prior ship and /godot/ untouched.

- 2026-09-26 07:05 IST, cycle 49 (fish): diagnosed, not changed, ryukin shoulder stripe.
  - Hard critique: a straight pale transverse band remains visible over the ryukin's shoulder in the phone pond. Controlled fixed-frame A/B: body-only rig (removed fins/eyes) still has the band in solo debug 390x844 and Pond Next 390x844/1280x800; disabling fish backlight and emission still has it; disabling over-fish water surface still has it. Constant unshaded body loses the stripe, so the body lighting/geometry normals are implicated, rather than a fin overlap, head patch-mask or surface reflection. The constant test also exposes white fins from separate materials and is NOT a shippable styling option. All diagnostic code reverted; renders checked visually, no shader errors.
  - Worse-list: demekin ruffled fabric; ryukin shoulder band now narrowed to lit body/normal behavior; busy floor versus faint surface/canopy; actual fin-mesh crossings and real-device GPU timing. Next fish pass should inspect loft normals and test a targeted lighting adjustment, not blanket recoloring.
  - Security grade A: diagnostic code fully reverted, records only. No new network, storage, telemetry, external assets, inputs, or secrets. Live /next/ remains the earlier build; /godot/ untouched.

- 2026-09-26 08:04 IST, cycle 50 (fluid): modest floor-net rhythm improvement.
  - Hard critique: the whole pond still reads as pebbles and a bright caustic lattice before it reads as water. Added a slow spatial field to attenuate the floor caustic/grid glow in broad calm pockets, without touching stone density or the separate over-fish surface pass. Solo water 390x844, Pond Next 390x844/1280x800, fixed-frame A/B and three 390x844 motion frames inspected. Fish remain readable and the caustic web now has wider breathing room. This is modest, not a full surface-plane or tree-silhouette fix. No shader errors.
  - Worse-list: demekin fan ruffle; ryukin lit-body stripe; the water surface still looks faint against the floor and the tree is indistinct; fin-mesh crossing and real-device GPU cost unmeasured. Next fluid pass should strengthen a broad, restrained surface cue without washing out fish.
  - Security grade A-: same-origin shader arithmetic only, `git diff --check` clean, no new assets, network, storage, telemetry, secrets, or input path. Added four noise hashes per floor pixel; real-device FPS remains an unknown. Local branch only; live /next/ predates c44/c50, /godot/ untouched.

- 2026-09-26 09:05 IST, cycle 51 (fish): rejected shader-only stripe probes.
  - Hard critique: ryukin has a transverse pale shoulder band and demekin fan remains leaf-smooth at phone size. Fixed-frame solo debug 390x844 and Pond Next 390x844/1280x800 A/B with ryukin specular set to zero did not remove the band. Pond phone tests separately turned both directional lights off, used constant ryukin albedo, and removed the head-transition brightening. The band persisted in the first and last; with constant albedo it shrank to a pale sliver and the rest of the body became unnaturally flat. A prior fully unshaded constant-body probe removed the band. These tests favor a lit loft normal/diffuse seam but do not prove its exact mechanism. All code probes reverted; no shader errors.
  - Worse-list unchanged: demekin ruffled fan; ryukin shoulder band; floor/surface hierarchy and canopy; actual fin-mesh crossings and real-device GPU timing. Next fish test should inspect normals/ambient term locally rather than globally removing shine.
  - Security A: no retained source code change, records only; no new network, persistence, secrets, telemetry, inputs, assets. Local c44/c50 still not published; /godot/ untouched.

- 2026-09-26 10:04 IST, cycle 52 (fluid): rejected gradient-weighted surface veil.
  - Hard critique: floor caustics and pebbles still dominate; upper water plane remains visually weak. Added up to 0.11 alpha to the over-fish water veil where surface gradient is high. Solo water 390x844 was unchanged by design; Pond Next 390x844/1280x800 fixed-frame A/B had a faint grey wash across pebbles and dimmer fish but did not introduce a readable moving surface plane. Inspected pixels and reverted. No shader errors. Next try should add a bounded ripple highlight or reflection, not an area-wide veil.
  - Worse-list remains demekin fan ruffle; ryukin lit-body shoulder band; floor/surface separation and canopy form; actual fin-mesh crossings and real-device GPU timing.
  - Security A: no retained code change, records only. No new network, storage, telemetry, external assets, secrets, or input paths. Local c44/c50 not live /next/; /godot/ untouched.

- 2026-09-26 11:06 IST, cycle 53 (fish): softened ryukin gill stripe, modest improvement.
  - Hard critique: the pale transverse shoulder bar still looked painted on despite c49/c51 light and patch probes. Removing the gill-crease shader term altogether in a controlled solo 390x844 and Pond Next 390x844/1280x800 A/B erased the sharp line. Retained a softer crease with width 0.012 -> 0.022 and ryukin strength 0.22 -> 0.07; the hard stripe now fades into the body while the gill region remains hinted. Inspected actual solo and Pond Next phone/desktop pixels. The face is plainer and still needs anatomical form, so this is modest rather than a full fish-craft win. No shader errors. Demekin crease intensity remains 0.4, shared width is slightly wider.
  - Worse-list: demekin fan ruffle and sharp tip; ryukin still lacks convincing gill-plate volume; floor/surface hierarchy and canopy; actual fin-mesh crossings and real-device GPU timing. Next fish pass should focus on a rounded dense demekin tail rather than recoloring the ryukin.
  - Security grade A-: same-origin shader constants only, clean diff, no new network, storage, telemetry, secrets, inputs, assets, or export. Local branch only; live /next/ predates c44/c50/c53, /godot/ untouched.

- 2026-09-26 12:08 IST, cycle 54 (fluid): modest sparse-stone pass.
  - Hard critique: at phone size the warm floor still reads as a stone collection before water, and the canopy is a vague pink shadow rather than a readable reflected tree. Tested lowering default pebble density 0.36 -> 0.22, with fixed 50th-frame solo water and Pond Next at 390x844, and a fixed 10th-frame Pond Next A/B at a real 1280x800 project viewport. Both phone and desktop have more open sand, keep color variation and shadows, and give the fish a little more space. Real desktop rendering required a temporary project viewport override because Godot's --resolution did not override the 390x844 movie size; project settings were restored. No shader or runtime errors. Grade modest: the caustic net and indistinct canopy still prevent an identifiable water surface.
  - Worse-list: demekin fan ruffle and sharp tip; ryukin anatomical gill volume; floor caustics still stronger than water surface; reflected tree silhouette; fin-mesh crossings and real-device GPU timing unmeasured. Next fluid pass needs a moving surface cue rather than uniform alpha fog.
  - Security grade A-: changed one local numeric default only, no external assets or new network, telemetry, storage, input paths, secrets, or export behavior. Diff clean. Initial /next/ release is unchanged; /godot/ untouched.

- 2026-09-26 13:06 IST, cycle 55 (fish): denser demekin tail pleats, modest.
  - Hard critique: the demekin tail has body-scale presence but reads as two broad leaves, not fabric-like ruffles; more edge teeth tried in c43 made things worse. Tested a caudal-only pleat field at 42 versus 26 radians across sheet and 0.022 versus 0.016 displacement. Solo debug demekin and integrated Pond Next 390x844, plus a real 1280x800 project viewport, were rendered at the same fixed frame and inspected against unmodified frames. The black fan gained denser soft striations without sharp teeth or new silhouette break, so retained as a modest textural gain. It is not yet the dense, rounded reference fan. Ryukin solo also rendered without errors; final implementation scopes the new parameter to demekin caudal material only, leaving other fins and ryukin at the original values. No shader/runtime errors.
  - Worse-list: demekin double fan still pointed and leaf-shaped, ryukin gill anatomy, water-surface separation and canopy, unmeasured fin intersections and real-device GPU timing. Next fish turn should test caudal layering or a better rounded edge shape, not blanket pleat frequency.
  - Security grade A-: local shader geometry and scoped material flag only; clean diff. No network, persistence, telemetry, user inputs, secrets, external assets, or export changes. Live /next/ still the initial snapshot; /godot/ untouched.

- 2026-09-26 14:05 IST, cycle 56 (fluid): broad-glint experiment rejected.
  - Hard critique: even after c54 sparse stones, the floor caustic mesh and blurred canopy dominate. The over-fish water surface has thin glints, not a plane. Tested widening specular power from 900/120 to 210/70 and lowering its amplitude from 2.0 to 0.65, with fixed-frame A/B in solo water 390x844 and Pond Next 390x844/1280x800. Inspected actual pixels: the few highlights change only slightly and neither phone nor desktop gains a clear plane; solo water is unchanged by design because it uses a separate shader. Reverted shader; no errors. Next test needs a bounded ripple/reflection structure, not a blunt wider glint.
  - Worse-list: demekin leaf-shaped fan, ryukin gill plate volume, floor/surface separation, indistinct reflected tree, unmeasured fin intersections and real-device GPU timing.
  - Security grade A: no retained source change; no new network, telemetry, storage, secrets, input paths, or assets. Records only; initial /next/ release and /godot/ unchanged.

- 2026-09-26 15:06 IST, cycle 57 (fish): round-outline trial rejected.
  - Hard critique: c55 finer demekin striations help texture but its paired fins remain pointed leaves. Tested a caudal-only circular/elliptic cross-section in place of the superellipse outline (0.50 + 0.50 * sqrt(1-vv^2) versus 0.62 + 0.38 * sqrt(1-vv^4)); solo demekin 390x844 and Pond Next phone 390x844 and true desktop 1280x800 fixed-frame images rendered without errors. Pixels show the outer lobes narrowing and a harder triangular contour, worse than the broad c39 fan. Reverted fully. The tip shape needs controlled overlap and a designed edge, not merely a rounder scalar profile.
  - Worse-list unchanged: leaf-like pointed demekin fan; ryukin gill anatomy; weak water plane and canopy; unmeasured fin intersections and real-device GPU timing.
  - Security A: no retained source change, record updates only; no network, persistence, telemetry, inputs, assets, secrets, or exports. Initial /next/ release and /godot/ unchanged.

- 2026-09-26 16:06 IST, cycle 58 (fluid): rejected slope-isoline reflection cue.
  - Hard critique: sparse pebbles give some negative space, but the over-fish surface still lacks dimensional clarity. Built a narrow reflection ridge from the heightfield gradient projected along the light direction, added to the top layer only. At 0.35 it made wide pale floating flakes over stones and across the demekin, not coherent water; multiple 390x844 Pond Next motion frames exposed the moving artifacts. Reduced to 0.09 and checked fixed 390x844 phone and true 1280x800 desktop Pond Next frames: nearly imperceptible and no separate plane. Solo water 390x844 stayed unchanged by design. Reverted all shader edits, no shader errors. Avoid raw slope-isoline thresholds.
  - Worse-list unchanged: demekin leaf-like fan, ryukin gill-plate form, floor versus water plane, indistinct canopy, unmeasured fin-mesh crossings and real-device GPU cost.
  - Security grade A: records only after full rollback; no external network, persistence, telemetry, input paths, secrets, assets, or export changes. Initial /next/ release and /godot/ remain untouched.

- 2026-09-26 17:09 IST, cycle 59 (fish): rejected a flatter caudal fan profile.
  - Hard critique: the black fish's two caudal sheets still converge into long smooth leaf tips with limited cloth weight, and the translucent peach fish competes with the floor. Tested a demekin caudal-only eighth-power superellipse instead of the fourth-power default, preserving its breadth while shortening the side taper. Solo debug stage at 390x844, Pond Next 390x844, and a true 1280x800 viewport were rendered at frame 40 for both baseline and candidate; visually checked full frames and matching crops. The new fan looks slightly squared at the edges, not softly rounded or materially more ruffled; no clear gain. Reverted fish code and viewport override. No shader/runtime errors beyond the expected software-driver V-Sync warning.
  - Worse-list: demekin double fan remains leaf-like, ryukin gill-plate volume weak, floor caustics and indistinct canopy stronger than the water plane, fin-mesh intersections and real-device GPU timing unmeasured. Next fish candidate needs intentional layering or outline control, not another scalar exponent.
  - Security grade A: final diff is record-only. Candidate touched a mesh-shape calculation for demekin caudal sheets; no network, storage, telemetry, input, assets, secrets, or export changes. /next/ and /godot/ not modified.

- 2026-09-26 18:09 IST, cycle 60 (fluid): rejected periodic fish-tail wakes.
  - Hard critique: pond floor and pebble shapes still dominate; the over-fish surface is faint. Tested direct heightfield disturbances behind each fish every 0.75 s at low 0.12 amplitude, reusing the existing GPU impulse queue. Solo water at 390x844, Pond Next 390x844 frames 40/70/100, and Pond Next 1280x800 frame 40 were rendered and inspected. Phone frame-40 differs by under one RGB level on average and desktop frame-40 is identical because the first impulse is not yet in that render; motion frames show no clear readable tail wake. Reverted rather than spend GPU work on an effect with no visual payoff. One movie run exceeded its command timeout while completing a later desktop frame; captured frame 40 and restored the temporary viewport override. No script/shader errors; only expected V-Sync warning.
  - Worse-list unchanged: demekin caudal fabric, ryukin gill anatomy, surface/floor separation and canopy shape; actual mesh intersections and real Android GPU timing remain unmeasured.
  - Security grade A: final source diff reverted, record-only. Candidate touched a bounded local GPU impulse path; no new network, storage, telemetry, secrets, input, assets, or export changes. Live /next/, /godot/, and main untouched.

- 2026-09-26 19:09 IST, cycle 61 (fish): rejected a second demekin caudal layer.
  - Hard critique: black double fan still reads like broad leaves, not soft ruffled fabric. Added one shorter 0.83-length, 0.97-width dark sheet behind each existing 1.05-length caudal lobe, with 25-degree rather than 42-degree splay and offset hinge. Solo debug 390x844 and Pond Next 390x844 / true 1280x800 fixed frame 40 rendered, full pixels inspected against c59 base. Solo developed a second narrow trailing tip, and overhead fan became softer but more blocky, not a rounded scalloped perimeter. Reverted all mesh/material changes. No script/shader errors; temporary viewport restored.
  - Worse-list unchanged: demekin fan silhouette and ryukin gill volume; floor-dominant caustics/indistinct canopy; true fin-mesh crossings and Android GPU timing not measured. Next fish pass needs coherent silhouette geometry, not an added similar sheet.
  - Security grade A: final change is record-only. Candidate had local fin mesh/material values; no network, storage, telemetry, new input, secrets, external assets or export change. Current staging for /godot/ stays at the previously approved c60-era build; /next/ and /godot/ unchanged.

- 2026-09-26 20:04 IST, logic/control pass: `control-kin.mjs` runs deterministic native Godot QA with explicit JSON outcomes. Doctor verifies Godot and four resources; snapshot parses all three gap constants; 90-frame scripted feeding at 390x844 and 1280x800 logged exactly two distinct fish eating and six finite centerline samples at each size (min 0.824/0.844). Wait-settle phone produced six samples, min 0.829. Native screenshot frame 40 passed actual PNG dimension assertions at 390x844 and 1280x800; both images visually inspected. Early test failures are in MISTAKES.md: no X display, ALSA output error, movie `--resolution` ignored, and a 240-frame timeout. These were not silently treated as passes. Remaining gaps: long-run seeded QA, true fin-mesh crossing checks and real-device GPU cost. Security A-: local child process has fixed Godot binary, validated args/output roots and exclusive viewport-override lock restored in finally; no network or secrets. Private File remains unpublished; /godot/ and /next/ unchanged.

- 2026-09-26 21:11 IST, cycle 62 (fluid logic): GPU ripple queue backpressure.
  - Hard critique: although the normal pond looks unchanged, `_drop` appended to an unbounded GPU queue while `_gpu_step` consumed only eight impulses per frame. Under touch spam, stale rings could emerge late and memory rise. Candidate A (reject latest on overflow) would lose the user's newest action; chose candidate B: keep latest 32 impulses, removing oldest when over capacity. Isolated headless test enqueued 100 known impulses and asserted exact retained first/last IDs 68/99, four ordered groups of eight, 32 delivered and empty queue. The first test leaked a Node and was fixed; final `control-kin.mjs ripple-queue` returned exact proof with no error/leak lines. Solo water and Pond Next native screenshot frame 40 at 390x844 and true 1280x800 passed dimensions and actual pixel inspection, no render errors. No claim of device responsiveness or GPU timing.
  - Worse-list unchanged visually: demekin caudal outline, ryukin gill anatomy, floor/surface hierarchy and canopy. Logic follow-up: stress real touch events and check visual latency; fin-mesh intersection and real Android GPU cost remain unknown.
  - Security grade A-: local queue bound and test only, no network, storage, telemetry, secrets, new input route or external assets. Source diff and known failure paths checked. Existing public /next/ and /godot/ untouched, prior staged export unchanged.

- 2026-09-26 22:15 IST, cycle 63 (fish/feeding logic): stale food no longer locks the six-slot cap.
  - Hard critique: phone solo fish still shows the black fish's leaf-like pointed paired fan and a pale ryukin whose gill plate lacks volume. In Pond Next, stones and caustics dominate the water plane. The fish-focused mechanics defect was more direct: off-reach pellets had no timeout and could fill all six slots forever. Rejected clamping every tap because it breaks location fidelity; added a 40-second expiry for uneaten pellets, leaving normal near-fish eating unchanged.
  - Headless actual Pond method fixture proved cap six, 39.95 s retains three old pellets, 40.05 s frees precisely those three nodes, a `_spawn_food` tap adds one new pellet, remaining age cohorts drain. `control-kin.mjs food-lifetime` exact proof passed after fixing brittle boundary/new-pellet test expectations. Both native two-pellet `interact --frames=90` runs at 390x844 / 1280x800 passed two distinct eaters and six finite centerline gaps (min 0.831 / 0.845). Solo fish and Pond Next fixed frame 40 at 390x844 and true 1280x800 rendered and actual pixels inspected, no obvious regression. No claim of browser edge-tap latency or real GPU proof.
  - Failure path: one 45-second shell timeout killed desktop control CLI mid-viewport override, leaving lock and temporary project size. Inspected processes, restored exact HEAD project config, removed orphan lock, reran desktop interaction to completion and verified viewport 390x844. No crash-safe override yet; future control work should isolate this config rather than write it in place.
  - Worse-list: demekin caudal shape; ryukin gill volume; weak over-fish water surface and indistinct reflected tree; fin-mesh clearance and Android frame cost unknown.
  - Security A-: only in-memory per-pellet age, local test/CLI, no network, telemetry, storage, new external assets, secrets or broadened input. No public root, /next/, /godot/ or staged export changed. Source diff checked.

- 2026-09-26 23:15 IST, cycle 64 (fluid QA/control): isolated native viewport config.
  - Hard critique: solo water still has a vague blossom shadow and a busy bright floor; integrated fish look pasted above a floor rather than under a clearly moving water plane. Before more shader changes, the c63 process interruption showed a worse testing failure: a killed control CLI could leave the real project viewport changed and an orphan lock. Rejected signal-only cleanup, which cannot cover SIGKILL. The CLI now starts Godot from a temporary project root with a viewport-specific config and symlinks for an explicit project resource allowlist; canonical repo config is never edited. On normal exit it removes the isolated root.
  - Intentional SIGKILL (exit 137) during 600-frame desktop water capture left only one removable temp folder; SHA-256 of `godot/project.godot` unchanged, no repo lock. Verified no live Godot child before removing the folder. Solo water and Pond Next native fixed frame 40 rendered at 390x844 and true 1280x800, pixel-inspected actual images. A combined 120-second desktop call timed out after Pond frame 40 but before its JSON verdict; a new Pond desktop run returned a successful dimension/engine check. Phone two-pellet interaction passed two distinct eaters, six finite gaps min 0.827; ripple-queue and food-lifetime fixtures passed. No Android/mobile-GPU or full visual surface pass claimed.
  - Worse-list unchanged: demekin tail silhouette, ryukin gill anatomy, weak water-plane separation and indistinct canopy, unmeasured fin intersections/Android frame cost.
  - Security A-: local-only QA process with allowlisted resource symlinks and private /tmp config; no network, secrets, telemetry, storage or gameplay input added. No export/live route changed. Hard kill can leave a temporary folder, but not the tracked config; stale screenshot output is refused. Diff checked.

- 2026-09-27 00:10 IST, cycle 65 (fish anatomy): rejected shallow operculum sphere overlays.
  - Hard critique: ryukin gill reads as a flat/bright shoulder mark; demekin fan still makes pointed leaves. Tested a pair of body-colored, shallow ellipsoid plates behind the ryukin eyes as a structural volume alternative to shader paint. Solo fish 390x844 and Pond Next 390x844 frame 40 rendered without script errors; actual pixels showed orange vertical ovals that looked like additional eyes in solo and hard side slivers integrated. This is worse, not a subtle gill. Reverted geometry before desktop testing; there is no candidate retained or visually significant gain.
  - Worse-list unchanged: demekin caudal outline, ryukin anatomical gill, floor-dominant caustics and weak water surface/canopy. Future gill work needs conformal body mesh or bounded normal shape, checked solo side/top before integration. Fin intersections and Android GPU remain unmeasured.
  - Security A: reverted all gameplay changes; records only. No network, telemetry, storage, inputs, secrets, assets or export changes. Release hold and live routes unchanged.

- 2026-09-27 01:10 IST, cycle 66 (fluid reflection): rejected stronger bough mask.
  - Hard critique: the left canopy remains a vague pink shadow over the pebble floor, and the over-fish surface has no convincing broad moving plane. Tested narrowing trunk/fork mask widths and darkening the bough from 0.48/0.37/0.32 at 0.66 blend to 0.32/0.28/0.27 at 0.85 blend. Solo water and Pond Next frame 40 at 390x844 rendered without shader errors. Actual pixels show a heavy charcoal smudge and a sharp angular scratch through stones, not a tree reflected in water. Reverted before desktop because the phone-first gate failed; no retained shader or visual gain. Next try a bounded broad surface structure with motion, not darker line art.
  - Worse-list unchanged: demekin leaf caudal, ryukin gill volume, floor/plane separation and weak canopy; fin intersections and Android GPU cost unknown. Security A: final diff records only, no network, telemetry, storage, inputs, secrets, assets or export. Public routes unchanged.

- 2026-09-27 02:14 IST, cycle 67 (fish-spacing logic): deterministic correction for exact centerline coincidence.
  - Hard critique: the solo demekin caudal remains a pair of sharp leaves and the ryukin shoulder is flat; fish/fin clearance cannot be proved by the existing short gap samples. Found a specific edge-case: Pond Next hard-gap code did nothing if closest-point distance was <=1e-4, because normalization lacked a direction. Rejected random separation for replay determinism. Extracted `_hard_gap_step`: normal geometric correction unchanged; exact overlap uses opposite lateral normals determined by stable fish indices. Actual method fixture asserts finite opposing moves, 0.9 separation at overlap, zero at/above threshold and geometric move when near. The first copied-formula fixture and brittle float equality were fixed before pass.
  - Native 390x844 two-pellet 90-frame regression passed two distinct eaters, six finite gap samples (min 0.829). Solo fish and Pond Next frame 40 at 390x844 and true 1280x800 rendered, PNG dimensions asserted and actual pixels inspected; no normal-state visual regression. Full animated fin/body crossing and real Android GPU cost remain unmeasured.
  - Worse-list: demekin caudal silhouette, ryukin gill volume, weak surface/floor separation and canopy. Security A-: deterministic local math and fixture only, no network, storage, telemetry, secrets, new inputs/assets or export. No public route altered; source diff checked.

- 2026-09-27 03:14 IST, cycle 68 (fluid input): reject invalid/off-canvas ripple impulses.
  - Hard critique: Pond Next still reads as fish over stones rather than fish under a distinct water plane. A logic edge case compounded the weak effect: while a drag is held, coordinates can leave the viewport, and `_drop` would queue out-of-range impulses into the finite eight-per-frame GPU pipeline. Rejected clamp-to-rim, which would fabricate a ripple at an unintended edge. Early-return for nonfinite or UV outside [0,1] before either CPU or GPU path. Actual method fixture rejects six outside/nonfinite drops with empty pending, then accepts UV zero/center/one in order. Prior 100-drop cap fixture still passes.
  - Solo water and integrated Pond Next fixed frame 40 at 390x844 and true 1280x800 rendered, PNG dimensions asserted, actual pixels inspected; no normal-input visual change or shader error. Browser drag-leave behavior and real-device GPU latency unverified. Worse-list unchanged: demekin caudal, ryukin gill volume, floor/surface hierarchy and canopy; fin crossings/device FPS unmeasured.
  - Security A-: input validation narrowed path, no network, persistence, telemetry, secrets or assets. No export or live route changed. Source diff clean.

- 2026-09-27 04:12 IST, cycle 69 (fish anatomy): rejected nearly invisible conformal gill bump.
  - Hard critique: ryukin still has a pale, flat shoulder/gill, and demekin paired fan still points like leaves. After c65 overlay sphere looked like extra eyes, tried a loft-localized 0.024-unit side displacement around ryukin u=0.24, using a bounded side angle and normals regenerated by SurfaceTool. Solo fish and Pond Next 390x844 fixed frame 40 rendered without errors. Actual pixels gave no clearer operculum; 201 solo and 449 integrated pixels changed >3 RGB levels, narrowly inside head silhouette. Not a meaningful phone visual gain. Reverted before desktop because the phone gate failed; no source retained.
  - Worse-list unchanged: demekin caudal shape, ryukin gill volume, floor-vs-water plane, weak canopy, fin-mesh/Android GPU unknown. Security A: records only after rollback, no network, storage, telemetry, input, secrets, assets or export; live routes untouched.

- 2026-09-27 05:12 IST, cycle 70 (fluid surface): rejected broad moving edge streak.
  - Hard critique: bright floor caustics still win over the faint over-fish surface. Tested a bounded, drifting specular band along the left edge, designed to avoid the fish-heavy center and to differ from c52's uniform veil. Pond Next 390x844 frame 40 rendered without shader errors. Actual phone pixels showed a faint pale patch (~1,330 pixels changed >3 RGB levels), not a coherent second plane or meaningful water/fish separation. Reverted before desktop/solo water since this shader is integrated-only and phone failed. Future surface cue should follow ripple/reflection geometry, not add alpha in an arbitrary screen band.
  - Worse-list unchanged: demekin caudal outline, ryukin gill volume, water-plane hierarchy and reflected tree; fin intersections/Android GPU unknown. Security A: records only after rollback; no network, telemetry, storage, inputs, secrets, assets, export or live route changes.

- 2026-09-27 06:15 IST, cycle 71 (fish geometry QA): classified finite authored geometry versus primitive caps.
  - Hard critique: demekin tail remains a leaf-shaped pair and ryukin gill flat, while fixed overhead frames cannot prove all fish mesh data are valid. A headless fixture builds both real fish and walks all MeshInstance3D buffers: finite vertices/normals, valid indices, triangle count and zero-area faces. First broad count found 256 ryukin / 512 demekin degenerates; per-part inspection localized all to built-in sphere primitive pole caps (128 zero-area faces per lens-like sphere), not the ten authored ArrayMesh body/fin parts. Each species has 8,032 authored triangles with zero degenerates. CLI asserts both species' proof strings and exact primitive count; no broad vacuous green.
  - Solo fish and Pond Next fixed frame 40 rendered at 390x844 and true 1280x800, dimensions asserted and actual pixels inspected, no changes or errors. This does not test animated fin-body/fin-fin crossings, which remain a worse-list item alongside anatomy, surface plane/canopy and Android frame cost. Security A-: QA-only local file/process, no network, storage, telemetry, secrets, inputs, assets, export or public route mutation.

- 2026-09-27 07:15 IST, cycle 72 (fluid queue verification): test actual GPU batch drain.
  - Hard critique: the pond still lacks a distinct water plane; c62 queue QA gave assurance about storage/backpressure but copied the eight-drop drain algorithm instead of testing the renderer's path. Extracted `_take_gpu_drops` and called it from both `_gpu_step` and the headless fixture. The exact 100-drop proof confirms newest 32 IDs 68..99 and four ordered batches of eight, ending empty; ripple-boundary QA also passed. This is tighter assurance, not visual improvement.
  - Solo water and Pond Next fixed frame 40 rendered at 390x844 and true 1280x800, dimensions asserted, actual pixels inspected. Compared to c68 baseline, all four RGB images matched exactly (empty difference bbox), confirming normal-frame equivalence on software renderer. No browser drag latency or Android GPU measurement.
  - Worse-list unchanged: demekin pointed caudal, ryukin gill volume, floor-dominant caustics/indistinct canopy, fin crossing/device FPS unmeasured. Security A-: local deterministic queue method and test, no network, storage, telemetry, secrets, new inputs/assets, export or live route. Source diff checked.

- 2026-09-27 08:15 IST, cycle 73 (fish silhouette): rejected demekin caudal outer-boundary shortening.
  - Hard critique: the black tail in solo still looks like two sharp leaves, and in Pond Next its dark sheets have a pointed, stacked silhouette. Tried a demekin-caudal-only 22% shortening near the outer v-boundaries, preserving root and fan width. Actual phone pixels changed (>3 RGB: 1,400 solo and 2,333 integrated), but the sharp paired leaves remained. Reverted; no visual gain. Rework sheet topology/pose rather than another scalar edge taper.
  - Actual final pixels inspected in solo fish and Pond Next at 390x844 and 1280x800, with successful native runs, asserted PNG dimensions and identical c71 frame-40 RGB images at all four combinations. Candidate passed authored mesh QA but was not retained. These fixed frames do not prove animated fin clearance or Android GPU timing.
  - Worse-list unchanged: demekin caudal, ryukin gill volume, floor/surface hierarchy and canopy, fin crossing/device FPS unmeasured. Security A: records only after rollback, clean source diff; no new network, storage, telemetry, secrets, inputs, assets, export or live-route changes. Publication/sign-in hold unchanged.

- 2026-09-27 09:16 IST, cycle 74 (fluid impulse validation): reject malformed strength and radius.
  - Hard critique: the pond still looks like fish above lit stones, not within a distinct water plane. More importantly, previous bounds gate only guarded UV; nonfinite or zero ripple amplitude/radius could consume GPU queue slots, poison uniform math, or divide the CPU Gaussian by zero. `_drop` now rejects these before either path. Headless actual-method QA checks six invalid coordinates and ten invalid strength/radius pairs do not alter GPU pending, three boundary-valid UVs retain order; with CPU selected, ten malformed pairs leave all 64 cells finite and zero, while one valid center drop writes the expected negative height. Existing 100-drop queue fixture still passes. No claim this fixes the water composition.
  - Native solo water and Pond Next fixed frame 40 at 390x844 and 1280x800 succeeded with asserted PNG dimensions. Actual pixels inspected in all four; RGB compares with c72 are exactly equal. One combined desktop call reached its 120-second shell limit after water succeeded and during Pond; a fresh Pond desktop run succeeded. Browser drag-leave and Android GPU latency not checked.
  - Worse-list: demekin caudal, ryukin gill, floor/surface hierarchy and canopy, animated fin crossings and device frame cost. Security A-: narrowed local numeric input to prevent invalid shader uniforms/CPU state; no network, telemetry, persistence, secrets, assets or new input surfaces. Source diff checked. No export or live route change; publication/sign-in hold unchanged.
