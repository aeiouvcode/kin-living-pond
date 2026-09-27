# KIN feature map

This branch has three entry points. The repository root `index.html` is a separate legacy WebGL app; the Godot build lives in `godot/`. The live `/godot/` build remains on main, not this branch's Pond Next work.

Verification legend: **live** = initial public build behavior inspected; **local-tested** = native or local web test only; **unverified** = not yet checked end to end. Source presence alone is not a test.

## Godot app: `godot/main.tscn` -> `godot/root.gd`

| Feature | How to reach or trigger | Implementation / verification status |
| --- | --- | --- |
| Koi pond | Default Godot launch; `-- --scene=pond` selects it explicitly | `main.gd`, `koi.gd`, `fish_draw.gd`, `shaders/`; pond name, fish bond, visits, streak, lotus saved locally in `user://kin_save.json` |
| Glass bowl | Tap the top-right "Glass bowl" chip from the koi pond, or launch `-- --scene=bowl` | `bowl.gd`, `goldfish.gd`, `shaders/bowl_*`; own pond name, fish bond, visits, streak, blossoms in `user://kin_bowl.json` |
| Switch scene | Top-right chip alternates Koi pond / Glass bowl; choice persists across launches | `root.gd`; `user://kin_scene.cfg` |
| First-visit name | Name the pond or bowl in the opening card and continue | `main.gd` / `bowl.gd`; name input is cleaned and length-limited |
| Feed | Single tap on water inside pond/bowl, away from a fish; brief cooldown | `main.gd` / `bowl.gd`; local pellet and fish response |
| Identify fish | Single tap a fish | `main.gd` / `bowl.gd`; transient name tag |
| Startle | Double-tap close together on the water | `main.gd` / `bowl.gd`; temporary fish reaction and ripple |
| Ripple / interaction | Touch and drag water; long touch alters interaction | `main.gd` / `bowl.gd`; movement, ripple, bond behavior |
| Return / bond | Visit on later days, feed and meet the fish | `main.gd` / `bowl.gd`; separate local saves, no account or network |

The original koi/bowl app features above were checked in source and earlier local runs; their current live `/godot/` parity has not been re-audited this cycle.

## Branch-only labs and integration preview

| Feature | How to reach or trigger | Implementation / verification status |
| --- | --- | --- |
| Fish workshop | Run Godot with `-- --lab=fish` | `labs/fish_lab.gd`, `fish_body.gdshader`, `fish_fin.gdshader`; "Settings" opens camera, model, background, FOV, tail, opacity, grade. CLI options include `--kind`, `--cam`, `--fov`, `--tail`, `--fin`, `--bg`. |
| Solo model inspection | `-- --lab=fish --stage=debug --kind=ryukin` (or `demekin`) | Fish workshop debug grid, model and opacity controls; `godot/tools/model_test.sh` makes contact sheets. |
| Water workshop | `-- --lab=water`; tap or drag to make ripples | `labs/water_lab/`; `--floor`, `--depth`, `--chroma`, `--glint`, `--drops`, `--wind`, `--warm`, `--bloom`, `--refl`, `--crisp`, `--density`, `--slope` set the procedural water. Default pebble density is 0.22 (c54 local; 0.36 in the initial /next/ release); floor caustic contribution is lower, leaving the over-fish surface layer distinct. The c44 local candidate samples the floor net more broadly and eases its bloom; it is not in the initial /next/ deploy. |
| Pond Next | `-- --lab=pond`, or branch-only `godot/export_next` Web Next build | `labs/pond_lab.gd` places lab fish over the water lab; tap drops food and ripples. Ryukin body base is warmer and pond backlight is lower than the solo fish (c37). The demekin uses a wider, darker fan tail (c39) and local-only finer caudal pleats (c55); phone horizontal steering has a wider soft wall. `--caus=0` disables fish caustic emission for diagnosis; `--perf=1`, `--gapqa=1`, `--autotap=1` are QA options. **Local-tested** solo/native phone and desktop, and initial `/next/` was visually checked live, but later local changes are not live. Food/eating/surface kisses disturb the water heightfield; periodic swimming-tail wakes were tested c60 and rejected. Five-fish performance and fin-mesh clearance are **unverified**. |

Pond Next does not yet include the original app's local return-care state; this is a **planned**, not verified, feature.

## Legacy root web app

`index.html` is a standalone WebGL pond, separate from the Godot routes. Its opening card names the pond and eldest fish; the bottom controls select auto/follow/orbit cameras and show perf; tap feeds and double-tap startles. It uses browser local storage under `kin.pond`. Do not infer that fixes in Godot alter this page or the live site.

## Web surface quality checks

- Godot web export (`godot/build.sh`): title, description, generated PNG favicon, strict CSP and friendly startup failure message are applied during each export; the CSP hashes are recalculated after the HTML edit. Failure details stay in the developer console, not the page. The loading bar disappears on successful engine startup.
- Root legacy `index.html`: backlog item - has a title and opening card, but needs a favicon, meta description, and controlled WebGL failure state. Give it a separate focused pass after the Hakozaki visual gaps; do not claim it passed the new checklist.
- Godot 404: `godot/404.html` is copied into each exported folder by the build script, and links to `/godot/`. A static host may ignore a nested 404 file; host routing must be verified after deployment.
- Verification: inspect metadata, CSP, and the favicon; test failed and successful engine boots at phone and desktop; test a nonexistent path on the actual deployment host. Never display raw stack traces.

## Pending approved `/godot/` replacement
The owner approved putting the improved 3D fish preview live at `/godot/`; local workflow staging uses the integrated `Web Next` preset (`root.gd` feature `kin_next`). On successful deployment this replaces, not supplements, the old two-scene koi/bowl `/godot/` preview. This is NOT live until a workflow succeeds and browser pixel checks pass; `/next/` and root stay unchanged.

Private File hosting experiment is **unpublished and not playable**: the tested nested `pond/index.pck` URL returned the File viewer HTML, not PCK bytes. This is not a user-facing feature. Run-level browser-minimal, 20-minute escalation, fail-loud test and review rules are recorded in STATE/MISTAKES/PLAN.

Control surface planned: `control-kin.mjs` will drive doctor, snapshot, screenshot, wait-settle and interact with JSON outputs. Until its commands run and assert real outputs, existing local QA claims remain sourced to the earlier Godot/native and browser checks, not retroactively to this CLI. New feature rows will include exact CLI invocation and verification status.

## Local control CLI proof, September 26
| User-facing behavior | CLI drive | Verification status |
| --- | --- | --- |
| Pond starts and source controls exist | `node control-kin.mjs doctor`; `node control-kin.mjs snapshot` | **Verified locally**: required files present and GAP_SOFT/HARD/FEED parsed as 1.65/0.9/0.72. Source check is not a runtime pass. |
| Two fish respond to feeding | `node control-kin.mjs interact --frames=90` and `--width=1280 --height=800 --frames=90` | **Verified locally**: 2 distinct ATE events and 6 finite gap samples at each viewport, min centerline 0.824/0.844. Still not fin-mesh clearance. |
| Pond frame renders | `node control-kin.mjs screenshot --width=390 --height=844 --frames=46 --out=/tmp/kin-phone`; desktop width/height equivalent | **Verified locally**: actual PNG dimensions asserted; inspected frame 40 pixels at both sizes. Native llvmpipe, not device GPU. |
| Unfed fish settle without proxy overlap | `node control-kin.mjs wait-settle --frames=90` | **Verified locally**: 6 finite GAP samples, minimum 0.829. Sampled centerline only. |
| Rapid ripples under many touch events | `node control-kin.mjs ripple-queue` | **Verified locally**: enqueues 100 synthetic drops, retains 32 newest (68..99), drains four ordered batches of eight; water lab and Pond Next native pixels checked phone/desktop. This is queue logic, not touch latency or mobile GPU proof. |
| Uneaten food stops blocking feed taps | `node control-kin.mjs food-lifetime`; `node control-kin.mjs interact --frames=90` | **Verified locally**: three stale pellets expired, queued nodes freed, tap reopened a slot, all remaining eventually expired; two distinct fish still ate on phone and desktop. Full six real edge taps over 40 seconds are not yet an end-to-end browser test. |
| Native QA viewport isolation | `node control-kin.mjs screenshot --lab=water --width=1280 --height=800 --frames=46 --out=/tmp/unique-shot` | **Verified locally**: true-dimension phone/desktop solo water and Pond Next pixels inspected; canonical project config hash unchanged after normal runs and intentional SIGKILL. One interrupted desktop render needed a fresh output path for full QA. Temporary project folders can remain after a hard kill; no repo lock/config edit. |

Midnight September 27 release state: `/godot/` replacement remains pending, not live. The owner reply at 18:13 concerned the improved build then described; current local branch contains later changes and has not been synced to remote. GitHub config-c sign-in and timed prompt remain pending. `/next/` and root are unchanged.
| Fish steer away from exact centerline overlap | `node control-kin.mjs zero-gap`; `node control-kin.mjs interact --frames=90` | **Verified locally**: exact overlap gives finite opposite 0.45-unit moves and 0.9 gap, threshold gives zero correction, near threshold uses geometric direction; normal two-pellet phone QA still has two eaters/six gap samples. This is a centerline proxy, not fin-mesh clearance. |
| Drag ripples outside the water view | `node control-kin.mjs ripple-bounds`; `node control-kin.mjs ripple-queue` | **Verified locally**: six invalid/outside UVs leave pending GPU queue empty; three valid boundary/center UVs enter in order, original 100-drop cap proof still passes. Native solo water and Pond Next phone/desktop pixels inspected, no ordinary-frame change. Browser drag edge and actual GPU latency unverified. |
| Solo fish mesh integrity | `node control-kin.mjs fish-mesh` | **Verified locally**: each species has ten authored body/fin mesh parts, 8,032 authored triangles with zero degenerate faces and finite vertices/normals. Built-in primitive sphere pole caps account for 256 ryukin / 512 demekin zero-area faces; not a fin-mesh collision or Android GPU proof. |
| GPU ripple batch drain | `node control-kin.mjs ripple-queue` | **Verified locally** against the real `_take_gpu_drops` method: 100 synthetic drops retain IDs 68..99, four exact eight-drop batches drain in order; solo water and Pond Next phone/desktop frame-40 pixels exactly match c68 baseline. Browser-visible touch latency not checked. |
| Ripple impulse parameters | `node control-kin.mjs ripple-bounds` | **Verified locally**: GPU queue rejects six bad coordinates and ten bad strength/radius pairs, accepts ordered boundary-valid input; CPU rejects ten bad pairs without grid mutation and applies one valid center drop. Normal water/Pond Next phone/desktop native frame-40 pixels unchanged; touch-on-device latency unmeasured. |
