extends "res://labs/fish_lab.gd"
## KIN Pond Next: the solo-tested fish (fish_lab) swimming over the solo-tested
## water (water_lab), integrated only after both passed their own tests.
## The water canvas is drawn as the 3D background (Environment BG_CANVAS), the
## fish are real 3D above it, seen from overhead like the RYUKIN reference.
## Tap: a food pellet lands, rings spread, the nearest fish comes to eat.

const FLOOR_DROP = 1.3
const GAP_SOFT = 1.65 # start easing apart before the wide veil lobes can meet
const GAP_HARD = 0.9 # centre-line guard gives the veils room to flutter on turns
const GAP_FEED = 0.72 # feeding still gets a narrow right of way, not a veil collision
const HEAD_L = 0.45 # nose ahead of the fish origin
const TAIL_L = 1.3 # veil tip behind it
const FISH_S = 0.9 # floor sits this far below the fish (for shadow offset)
var water: Node2D
var caus_set := false
var gap_min := 1e9
var agents = []
var food = []
var half := Vector2(2.4, 5.0) # visible half extents at fish depth (x, z)
var depth_y := 0.0
var rng2 := RandomNumberGenerator.new()
var kiss_t := 9.0
var perf_acc := 0.0
var perf_n := 0
var adapt_t := 0.0
var adapt_frames := 0
var adapt_level := 0
var pond_us := 0

func _ready() -> void:
	settings["gapqa"] = 0.0 # QA: print the closest body/veil gap every 2 s
	settings["qaw"] = 0.0 # QA: pretend viewport size for headless steering runs
	settings["qah"] = 0.0
	settings["autotap"] = 0.0 # QA: drop food automatically at t = 2 s
	settings["caus"] = 1.0 # light net on the fish (0 = off)
	settings["adapt"] = 1.0 # lower the costliest passes if a device cannot hold ~45 fps
	settings["perf"] = 0.0 # QA: print average process time
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv = a.substr(2).split("=", true, 1)
			if settings.has(kv[0]):
				settings[kv[0]] = float(kv[1]) if typeof(settings[kv[0]]) == TYPE_FLOAT else kv[1]
	rng2.seed = 11
	water = Node2D.new()
	water.set_meta("embedded", true)
	water.set_script(load("res://labs/water_lab/water_lab.gd"))
	add_child(water)
	_env()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = -1
	if settings.get("tm", 0.0) == 0.0:
		env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		env.adjustment_enabled = false
	env.ambient_light_color = Color(0.85, 0.88, 0.95)
	env.ambient_light_energy = 0.5
	key.rotation_degrees = Vector3(-68, 30, 0)
	key.light_energy = 1.0
	rim.rotation_degrees = Vector3(-35, 210, 0)
	rim.light_energy = 0.45
	cam = Camera3D.new()
	cam.fov = settings.fov
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	add_child(cam)
	_frame()
	get_viewport().size_changed.connect(_frame)
	for k in ["ryukin", "demekin"]:
		var f = _build_fish(k)
		f.scale = Vector3.ONE * FISH_S
		if k == "ryukin":
			for c in f.get_children():
				if c is MeshInstance3D and c.material_override is ShaderMaterial and c.material_override.shader == BodyShader:
					c.material_override.set_shader_parameter("base_col", Color(0.84, 0.64, 0.62))
					c.material_override.set_shader_parameter("backlight_strength", 0.25)
					c.material_override.set_shader_parameter("patch_col", Color(1.0, 0.66, 0.56)) # white-peach sarasa, not orange
		add_child(f)
		fish.append(f)
		var p = Vector3(rng2.randf_range(-0.5, 0.5) * half.x + (0.24 if k == "demekin" else 0.0), depth_y, rng2.randf_range(-0.4, 0.4) * half.y + (0.9 if k == "demekin" else -0.9))
		agents.append({"node": f, "pos": p, "head": rng2.randf_range(0, TAU), "turn": 0.0, "speed": 0.32, "tf": rng2.randf() * 5.0, "target": p, "retarget": 0.0, "rise": 0.0, "kind": k})
	_apply_knobs()

func _frame() -> void:
	var vsz = get_viewport().get_visible_rect().size
	if settings.get("qaw", 0.0) > 0.0:
		vsz = Vector2(settings.qaw, settings.qah)
	var land = vsz.x > vsz.y
	# phone: the width frames the pond; desktop: the height does, from a little
	# higher, so the fish keep a calm size and room to swim
	var d = 7.2 if land else 5.2
	cam.keep_aspect = Camera3D.KEEP_HEIGHT if land else Camera3D.KEEP_WIDTH
	cam.position = Vector3(0, d, 0)
	cam.look_at(Vector3.ZERO, Vector3(0, 0, -1)) # screen up = -z
	var h = d * tan(deg_to_rad(settings.fov * 0.5))
	half = Vector2(h * vsz.x / vsz.y, h) if land else Vector2(h, h * vsz.y / vsz.x)

func _pick_target(a: Dictionary) -> void:
	# a few random spots; keep the one with the most room from the other fish
	# (their bodies and where they are heading), so the two drift apart
	var m = Vector2(half.x - 0.9, half.y - 1.0)
	var best = -1.0
	for k in 6:
		var c = Vector3(rng2.randf_range(-m.x, m.x), depth_y, rng2.randf_range(-m.y, m.y))
		var room = 1e9
		for o in agents:
			if o == a:
				continue
			room = minf(room, minf(Vector2(c.x - o.pos.x, c.z - o.pos.z).length(), Vector2(c.x - o.target.x, c.z - o.target.z).length()))
		room += rng2.randf() * 0.6
		if room > best:
			best = room
			a.target = c
	a.retarget = rng2.randf_range(7.0, 13.0)

func _process(dt: float) -> void:
	var us0 = Time.get_ticks_usec()
	var t0 = t
	t += dt
	_adapt(dt)
	kiss_t -= dt
	if settings.autotap > 0.0 and t0 < 2.0 and t >= 2.0:
		var vsz = get_viewport().get_visible_rect().size
		for q in [Vector2(0.62, 0.42), Vector2(0.4, 0.6)]:
			_spawn_food(vsz * q)
			water.drop_at(q, 0.28, 2.2) # same plop a real tap makes
	if settings.gapqa > 0.0 and agents.size() > 1:
		var cp = _closest_pair(agents[0].pos, _fwd(agents[0]), agents[1].pos, _fwd(agents[1]), 0.0)
		gap_min = minf(gap_min, Vector2(cp[0].x - cp[1].x, cp[0].z - cp[1].z).length())
		if int(t0 / 2.0) != int(t / 2.0):
			print("GAP t=%.0f min=%.3f a=%s b=%s h=%.2f,%.2f half=%s" % [t, gap_min, agents[0].pos, agents[1].pos, agents[0].head, agents[1].head, half])
			gap_min = 1e9
	# food sinks slowly and drifts
	for fd in food:
		fd.node.position.y = maxf(fd.node.position.y - dt * 0.12, depth_y + 0.15)
	for i in agents.size():
		var a = agents[i]
		var p: Vector3 = a.pos
		a.retarget -= dt
		var chasing = false
		var goal: Vector3 = a.target
		var best = 1e9
		for fd in food:
			var dd = p.distance_to(fd.node.position)
			# a pellet the other fish is clearly closer to counts as further
			# away, so the two go for different pellets instead of colliding
			for o in agents:
				if o != a and o.pos.distance_to(fd.node.position) < dd - 0.3:
					dd += 3.0
			if dd < best:
				best = dd
				goal = Vector3(fd.node.position.x, depth_y, fd.node.position.z)
				chasing = true
		if not chasing and (a.retarget <= 0.0 or Vector2(p.x - goal.x, p.z - goal.z).length() < 0.5):
			_pick_target(a)
			goal = a.target
		var fwd = Vector3(cos(a.head), 0, -sin(a.head))
		var yielding = false
		a.yield_cd = a.get("yield_cd", 0.0) - dt
		var want = Vector3(goal.x - p.x, 0, goal.z - p.z)
		want = want.normalized() * minf(want.length(), 2.5 if chasing else 1.5) # the goal pulls, but never louder than the gap rule
		# keep a clear gap from the other fish along the whole body + veil:
		# nearest point between this fish's look-ahead body and the other's
		# head-to-veil-tip line
		# at feeding time the fish closer to its pellet has right of way; the
		# other keeps clear of it
		a.best = best if chasing else 1e9
		for j in agents.size():
			if j == i:
				continue
			var lead = chasing and a.best <= agents[j].get("best", 1e9)
			var soft = GAP_HARD + 0.3 if lead else GAP_SOFT
			var cp = _closest_pair(p, fwd, agents[j].pos, _fwd(agents[j]), 0.6)
			var dv: Vector3 = cp[0] - cp[1]
			dv.y = 0.0
			var dl = dv.length()
			if dl < soft:
				want += dv.normalized() * (soft - dl) * (2.0 if lead else 6.0)
				# the other is in front: this fish yields (slows, heads elsewhere)
				if not lead and (cp[1] - p).dot(fwd) > 0.0:
					yielding = true
					if not chasing and a.retarget > 2.0 and a.get("yield_cd", 0.0) <= 0.0:
						_pick_target(a)
						a.yield_cd = 4.0
		# soft walls
		var m = Vector2(half.x - 1.0, half.y - 0.8)
		if p.x > m.x: want.x -= (p.x - m.x) * 4.0
		if p.x < -m.x: want.x += (-m.x - p.x) * 4.0
		if p.z > m.y: want.z -= (p.z - m.y) * 4.0
		if p.z < -m.y: want.z += (-m.y - p.z) * 4.0
		var desired = atan2(-want.z, want.x)
		if settings.gapqa > 1.0 and chasing and int(t0) != int(t):
			print("CH t=%.0f %s p=(%.2f,%.2f) goal=(%.2f,%.2f) best=%.2f yield=%s want=(%.2f,%.2f)" % [t, a.kind, p.x, p.z, goal.x, goal.z, best, yielding, want.x, want.z])
		var dh = wrapf(desired - a.head, -PI, PI)
		var max_turn = 1.1 if chasing else 0.6
		var turn = clampf(dh * 1.2, -max_turn, max_turn)
		a.turn = lerpf(a.turn, turn, 1.0 - exp(-dt * 2.0))
		a.head += a.turn * dt
		var sp_target = 0.62 if chasing else (0.3 + 0.08 * sin(t * 0.3 + i * 2.0))
		if chasing:
			# ease in on the pellet so the turn circle never orbits it
			sp_target *= clampf(best / 1.2, 0.3, 1.0)
		if absf(dh) > 1.4:
			sp_target *= 0.5 # slow down to turn around
		if yielding:
			sp_target *= 0.55
		a.speed = lerpf(a.speed, sp_target, 1.0 - exp(-dt * 1.5))
		fwd = Vector3(cos(a.head), 0, -sin(a.head))
		p += fwd * a.speed * dt
		# hard gap: if the bodies still get too close, ease this fish sideways
		for j in agents.size():
			if j == i:
				continue
			var cp = _closest_pair(p, fwd, agents[j].pos, _fwd(agents[j]), 0.0)
			var dv: Vector3 = cp[0] - cp[1]
			dv.y = 0.0
			var dl = dv.length()
			var hard = GAP_FEED if (a.best < 1.2 or agents[j].get("best", 1e9) < 1.2) else GAP_HARD
			if dl < hard and dl > 1e-4:
				p += dv / dl * (hard - dl) * 0.5 # both fish do this, so the gap closes fully
		# eat
		for fd in food.duplicate():
			var nose = p + fwd * 0.4
			if Vector2(nose.x - fd.node.position.x, nose.z - fd.node.position.z).length() < 0.3:
				_ripple(fd.node.position, 0.3, 2.2)
				fd.node.queue_free()
				food.erase(fd)
				a.rise = 1.0
				if settings.gapqa > 0.0:
					print("ATE t=%.1f by %s" % [t, a.kind])
		# now and then one fish kisses the surface
		if kiss_t <= 0.0 and i == int(t) % agents.size():
			kiss_t = rng2.randf_range(14.0, 22.0)
			a.rise = 1.0
			_ripple(p + fwd * 0.45, 0.22, 2.0)
		a.rise = maxf(a.rise - dt * 0.5, 0.0)
		p.y = depth_y + 0.06 * sin(t * 0.7 + i * 1.9) + 0.25 * sin(a.rise * PI)
		a.pos = p
		var f: Node3D = a.node
		f.position = p
		f.rotation = Vector3(-a.turn * 0.22, a.head, 0.0) # bank into turns
		a.tf += dt * (0.6 + a.speed * 2.2)
		var bend = clampf(-a.turn * 0.18, -0.16, 0.16)
		for c in f.get_children():
			if c is MeshInstance3D and c.material_override is ShaderMaterial:
				c.material_override.set_shader_parameter("time_s", a.tf)
				c.material_override.set_shader_parameter("bend", bend)
				c.material_override.set_shader_parameter("swim", 0.8 + a.speed * 0.8)
	_shadows()
	if settings.perf > 0.0:
		perf_acc += Performance.get_monitor(Performance.TIME_PROCESS)
		pond_us += Time.get_ticks_usec() - us0
		perf_n += 1
		if perf_n == 60:
			print("PERF process_ms=%.2f pond_ms=%.2f water_ms=%.2f fps=%d" % [perf_acc / perf_n * 1000.0, pond_us / 60000.0, water.proc_us / 60000.0, Engine.get_frames_per_second()])
			pond_us = 0
			water.proc_us = 0
			perf_acc = 0.0
			perf_n = 0

# Quality fallback for slow devices, measured on real frame time (not the
# fixed movie clock): after a short warm-up, if a 3 s window averages under
# 45 fps, step down once per window: 1) light net redrawn every other frame,
# 2) the 3D fish drawn at 75% resolution. Never steps back up (no flicker).
func _adapt(dt: float) -> void:
	if settings.adapt <= 0.0 or adapt_level >= 2 or Engine.get_write_movie_path() != "" or t < 4.0:
		return
	adapt_t += dt
	adapt_frames += 1
	if adapt_t < 3.0:
		return
	var fps = adapt_frames / adapt_t
	adapt_t = 0.0
	adapt_frames = 0
	if fps >= 45.0:
		return
	adapt_level += 1
	if adapt_level == 1:
		water.caus_every = 2
	else:
		get_viewport().scaling_3d_scale = 0.75
	if settings.perf > 0.0:
		print("ADAPT level=%d fps=%.1f" % [adapt_level, fps])

func _fwd(a: Dictionary) -> Vector3:
	return Vector3(cos(a.head), 0, -sin(a.head))

# nearest points between two fish, each a line from nose to veil tip
# (sampled; 7 points each is plenty at this scale)
func _closest_pair(p: Vector3, f: Vector3, q: Vector3, g: Vector3, look: float) -> Array:
	var best = 1e9
	var out = [p, q]
	for u in 7:
		var a = p + f * (HEAD_L + look - (HEAD_L + look + TAIL_L) * u / 6.0)
		for v in 7:
			var b = q + g * (HEAD_L - (HEAD_L + TAIL_L) * v / 6.0)
			var d = Vector2(a.x - b.x, a.z - b.z).length_squared()
			if d < best:
				best = d
				out = [a, b]
	return out

func _shadows() -> void:
	if not caus_set and water and water.caus_vp:
		caus_set = true
		var ct = water.caus_vp.get_texture()
		for f in fish:
			for c in f.find_children("*", "MeshInstance3D", true, false):
				if c.material_override is ShaderMaterial:
					c.material_override.set_shader_parameter("caus_tex", ct)
					c.material_override.set_shader_parameter("caus_amt", (0.9 if c.material_override.shader == BodyShader else 0.25) * settings.caus)
					if c.material_override.shader == BodyShader:
						c.material_override.set_shader_parameter("caus_cap", 0.55)
					if c.material_override.shader != BodyShader:
						c.material_override.set_shader_parameter("veil_far", Color(0.97, 0.77, 0.72)) # veil stays peach against the pale sand
						c.material_override.set_shader_parameter("veil_root", Color(0.94, 0.67, 0.62))
						c.material_override.set_shader_parameter("veil_light", 0.55) # avoid backlight + caustic stacking at the base
						c.material_override.set_shader_parameter("veil_blend", 0.55)
						c.material_override.set_shader_parameter("veil_coverage", 1.0)
						c.material_override.set_shader_parameter("caus_cap", 0.42)
	if not water or not water.mat:
		return
	var vsz = get_viewport().get_visible_rect().size
	var arr = PackedVector4Array()
	for a in agents:
		var p: Vector3 = a.pos
		var fl = p + Vector3(0.55, -FLOOR_DROP - (p.y - depth_y), 0.8) # onto the floor, away from the sun
		var s = cam.unproject_position(fl) / vsz
		var ang = atan2(sin(-a.head), cos(a.head)) # screen: x right, y down (= +z)
		arr.append(Vector4(s.x, s.y, FISH_S / (2.0 * half.x) * 1.15 * (1.0 if cam.keep_aspect == Camera3D.KEEP_WIDTH else 1.0), -a.head))
	water.mat.set_shader_parameter("fish_sh", arr)
	water.mat.set_shader_parameter("sh_amt", 0.85)

func _ripple(wp: Vector3, amt: float, r: float) -> void:
	var vsz = get_viewport().get_visible_rect().size
	water.drop_at(cam.unproject_position(Vector3(wp.x, depth_y, wp.z)) / vsz, amt, r)

func _unhandled_input(e: InputEvent) -> void:
	var pressed = (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventScreenTouch and e.pressed)
	if not pressed:
		return
	_spawn_food(e.position)

func _spawn_food(sp: Vector2) -> void:
	if food.size() >= 6:
		return
	var o = cam.project_ray_origin(sp)
	var dir = cam.project_ray_normal(sp)
	if absf(dir.y) < 0.01:
		return
	var hit = o + dir * ((depth_y + 0.6 - o.y) / dir.y)
	var mi = MeshInstance3D.new()
	var sm = SphereMesh.new()
	sm.radius = 0.045
	sm.height = 0.08
	mi.mesh = sm
	var m = StandardMaterial3D.new()
	m.albedo_color = Color(0.86, 0.52, 0.3)
	m.roughness = 0.6
	mi.material_override = m
	mi.position = hit
	add_child(mi)
	food.append({"node": mi})
