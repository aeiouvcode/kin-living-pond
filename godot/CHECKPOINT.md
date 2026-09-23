# Checkpoint

- 2026-09-22 First Godot pass (side view, 38 fish) rejected: crowded, flat.
- 2026-09-22 Second pass (18 fish, side view) better but still below KIN VII; source lost in a workspace rebuild.
- 2026-09-23 Rebuilt from scratch as a top-down pond (this branch): shore SDF + stones, pebble floor, GPU heightfield sim, composite with refraction/caustics/foam/specular, 9 procedural koi with chain spines, fins, shadows, lily pads, lotus progression, onboarding card, local save.
- 2026-09-23 First Movie Maker frames at 390x844 render correctly (fish, pads, shore, card).
- 2026-09-23 Audit cycle 1 fixes: onboarding card sized to content, fish scaled up ~1.2x with fuller bodies and bigger pectorals, softer pebble bed, thinner bank, smaller stones, stronger shadows, subtler fin rays and scales.
- 2026-09-23 Audit cycle 2: organic patch edges, warm subsurface edge glow, blunter head, longer tail, softer fins; reflected sky and breeze sparkle on the water; sparser shore stones; shaded lily pads with lit rim and sheen; joint bend limit (no folded bodies); stronger separation, less clumping.
- 2026-09-23 Web export built (build.sh adds a hashed-script CSP). Local headless Chrome: boot 2.7-3.4 s after files are local, zero CSP violations, requests only same-origin + blob, name markup renders as plain text, name + streak persist across reload.
- 2026-09-23 Security scan: 14 commits across all branches, no secret patterns; branch source has no external URLs; engine JS only mentions two doc URLs in error strings.
