# Current task

Rebuild KIN in Godot 4.5 (Compatibility / WebGL2) as a top-down koi pond, and only replace the live direct-WebGL build (KIN VII on `main`) if the Godot web export clears phone QA, performance, security and the distance-to-reference audit.

## Acceptance criteria
- A1 Instant-alive opening: fish swimming on first frame, naming card does not blur the pond.
- A2 Darker, readable water with pebble bed, depth absorption and shore stones.
- A3 Cheap shallow-water heightfield (GPU ping-pong) driven by touch and by fish near the surface; refraction, caustics, restrained foam.
- A4 Individual koi: variety, size, pace, boldness, sociability, preferred depth; states wander/school/rest/gulp/food/touch/startle.
- A5 Calm affection loop: feeding and nuzzles raise per-fish bond; pond harmony opens lotus blooms; daily return streak. Saved locally only.
- A6 390x844 phone frame and 1440x900 desktop frame checked side by side against references.
- A7 Security: no network calls beyond same-origin engine files, no secrets, sanitised name input, strict CSP verified in a browser.
- A8 Web export startup and frame cost measured on the real export, reported honestly.

## Non-goals
- Full 3D fluid simulation.
- Accounts, backend, analytics, ads.
- Replacing `main` before A1-A8 pass.
