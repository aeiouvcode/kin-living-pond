# KIN feature map

This branch has three entry points. The repository root `index.html` is a separate legacy WebGL app; the Godot build lives in `godot/`. The live `/godot/` build remains on main, not this branch's Pond Next work.

## Godot app: `godot/main.tscn` -> `godot/root.gd`

| Feature | How to reach or trigger | Implementation / state |
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

## Branch-only labs and integration preview

| Feature | How to reach or trigger | Implementation / state |
| --- | --- | --- |
| Fish workshop | Run Godot with `-- --lab=fish` | `labs/fish_lab.gd`, `fish_body.gdshader`, `fish_fin.gdshader`; "Settings" opens camera, model, background, FOV, tail, opacity, grade. CLI options include `--kind`, `--cam`, `--fov`, `--tail`, `--fin`, `--bg`. |
| Solo model inspection | `-- --lab=fish --stage=debug --kind=ryukin` (or `demekin`) | Fish workshop debug grid, model and opacity controls; `godot/tools/model_test.sh` makes contact sheets. |
| Water workshop | `-- --lab=water`; tap or drag to make ripples | `labs/water_lab/`; `--floor`, `--depth`, `--chroma`, `--glint`, `--drops`, `--wind`, `--warm`, `--bloom`, `--refl`, `--crisp`, `--density`, `--slope` set the procedural water. Default pebble density is 0.36 (c40); floor caustic contribution is lower, leaving the over-fish surface layer distinct. |
| Pond Next | `-- --lab=pond`, or branch-only `godot/export_next` Web Next build | `labs/pond_lab.gd` places lab fish over the water lab; tap drops food and ripples. Ryukin body base is warmer and pond backlight is lower than the solo fish (c37). The demekin uses a wider, darker fan tail (c39); phone horizontal steering has a wider soft wall. `--caus=0` disables fish caustic emission for diagnosis; `--perf=1`, `--gapqa=1`, `--autotap=1` are QA options. |

## Legacy root web app

`index.html` is a standalone WebGL pond, separate from the Godot routes. Its opening card names the pond and eldest fish; the bottom controls select auto/follow/orbit cameras and show perf; tap feeds and double-tap startles. It uses browser local storage under `kin.pond`. Do not infer that fixes in Godot alter this page or the live site.

## Web surface quality checks

- Godot web export (`godot/build.sh`): title, description, generated PNG favicon, strict CSP and friendly startup failure message are applied during each export; the CSP hashes are recalculated after the HTML edit. Failure details stay in the developer console, not the page. The loading bar disappears on successful engine startup.
- Root legacy `index.html`: backlog item - has a title and opening card, but needs a favicon, meta description, and controlled WebGL failure state. Give it a separate focused pass after the Hakozaki visual gaps; do not claim it passed the new checklist.
- Godot 404: `godot/404.html` is copied into each exported folder by the build script, and links to `/godot/`. A static host may ignore a nested 404 file; host routing must be verified after deployment.
- Verification: inspect metadata, CSP, and the favicon; test failed and successful engine boots at phone and desktop; test a nonexistent path on the actual deployment host. Never display raw stack traces.
