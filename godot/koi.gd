extends RefCounted
## One koi: personality, steering, bond and a procedural body mesh.

enum S { WANDER, SCHOOL, FOOD, TOUCH, STARTLE, REST, GULP }

const N = 14

var name = "Koi"
var variety = "kohaku"
var idx = 0
var pos = Vector2.ZERO
var heading = 0.0
var speed = 30.0
var depth = 0.4
var target_depth = 0.4
var length = 120.0
var width = 16.0
var spine = PackedVector2Array()
var phase = 0.0
var fin_phase = 0.0
var turn_signal = 0.0
var state = S.WANDER
var state_t = 0.0
var target = Vector2.ZERO
var buddy: RefCounted = null
var food_target = null
var startle_from = Vector2.ZERO
var bond = 0.0
var nuzzle_cd = 0.0
var glow = 0.0
var wake_acc = 0.0

# Personality
var pace = 1.0
var boldness = 0.5
var social = 0.5
var laziness = 0.3
var pref_depth = 0.45
var home = Vector2.ZERO

var mesh = {}
var body_node: Node2D
var shadow_node: Node2D
var mat: ShaderMaterial

func setup(p: Vector2, h: float) -> void:
	pos = p
	heading = h
	spine.resize(N)
	var seg = length * 0.74 / float(N - 1)
	var back = Vector2.from_angle(h + PI)
	for i in N:
		spine[i] = p + back * seg * i
	target = p
	phase = randf() * TAU
	fin_phase = randf() * TAU

func bond_level() -> int:
	var t = [8.0, 22.0, 42.0, 68.0, 100.0]
	var l = 0
	for v in t:
		if bond >= v:
			l += 1
	return l

func set_state(s: int, dur: float) -> void:
	state = s
	state_t = dur

func update(dt: float, pond, fishes: Array) -> void:
	state_t -= dt
	nuzzle_cd = maxf(0.0, nuzzle_cd - dt)
	glow = maxf(0.0, glow - dt * 0.8)
	var vis: Vector2 = pond.vis
	var want_speed = 26.0 * pace
	var turn_rate = 1.5
	var goal = target

	# Food and touch override the idle states.
	if state != S.STARTLE:
		var pellet = pond.nearest_pellet(pos, 90.0 + 140.0 * boldness + 12.0 * bond_level())
		if pellet != null:
			food_target = pellet
			state = S.FOOD
		elif state == S.FOOD:
			food_target = null
			set_state(S.WANDER, randf_range(3.0, 7.0))
		if state != S.FOOD and pond.hold_active:
			var lvl = bond_level()
			var reach = 110.0 + 70.0 * lvl + 90.0 * boldness
			if (lvl >= 1 or boldness > 0.7) and pos.distance_to(pond.hold_pos) < reach:
				state = S.TOUCH
		elif state == S.TOUCH:
			set_state(S.WANDER, randf_range(2.0, 5.0))

	match state:
		S.WANDER:
			if pos.distance_to(target) < 40.0 or state_t < 0.0:
				_pick_wander(pond)
				var r = randf()
				if r < laziness * 0.35:
					set_state(S.REST, randf_range(4.0, 9.0))
				elif r < laziness * 0.35 + social * 0.25 and fishes.size() > 1:
					buddy = fishes[randi() % fishes.size()]
					if buddy != self:
						set_state(S.SCHOOL, randf_range(5.0, 12.0))
				elif r > 0.93:
					set_state(S.GULP, 4.0)
				else:
					state_t = randf_range(5.0, 10.0)
			goal = target
			target_depth = pref_depth
		S.SCHOOL:
			if buddy == null or state_t < 0.0:
				set_state(S.WANDER, 0.0)
			else:
				var bd = Vector2.from_angle(buddy.heading)
				goal = buddy.pos - bd * buddy.length * 0.9 + bd.orthogonal() * (22.0 if idx % 2 == 0 else -22.0)
				want_speed = clampf(buddy.speed * 1.1, 18.0, 48.0)
				target_depth = clampf(buddy.depth + 0.08, 0.1, 0.9)
		S.REST:
			goal = pos + Vector2.from_angle(heading) * 30.0
			want_speed = 7.0
			target_depth = 0.85
			if state_t < 0.0:
				set_state(S.WANDER, 0.0)
		S.GULP:
			goal = target
			target_depth = 0.0
			want_speed = 20.0
			if depth < 0.06:
				pond.add_ripple(pos + Vector2.from_angle(heading) * length * 0.1, -0.35, 2.0)
				set_state(S.WANDER, 0.0)
			elif state_t < 0.0:
				set_state(S.WANDER, 0.0)
		S.FOOD:
			if food_target == null or not pond.pellet_alive(food_target):
				food_target = null
				set_state(S.WANDER, 2.0)
			else:
				goal = food_target.pos
				want_speed = 46.0 * pace
				turn_rate = 2.6
				var dist = pos.distance_to(goal)
				target_depth = clampf(dist / 260.0, 0.0, pref_depth)
				var mouth = pos + Vector2.from_angle(heading) * 6.0
				if mouth.distance_to(goal) < 12.0 + width * 0.4 and depth < 0.18:
					if pond.eat_pellet(food_target, self):
						bond = minf(100.0, bond + 3.0 + 2.0 * boldness)
						glow = 1.0
					food_target = null
					set_state(S.WANDER, 2.0)
		S.TOUCH:
			var hp: Vector2 = pond.hold_pos
			var lvl2 = bond_level()
			var orbit = 26.0 + 10.0 * float(idx % 3)
			var ang = pond.time * (0.6 + 0.1 * idx) + idx * 1.7
			goal = hp + Vector2.from_angle(ang) * (orbit if lvl2 >= 3 else 50.0)
			want_speed = 30.0
			target_depth = 0.12
			var mouth2 = pos + Vector2.from_angle(heading) * length * 0.08
			if mouth2.distance_to(hp) < 34.0 and nuzzle_cd <= 0.0:
				nuzzle_cd = 5.0
				bond = minf(100.0, bond + 1.5)
				glow = 1.0
				pond.add_ripple(mouth2, -0.18, 1.5)
				pond.on_nuzzle(self)
		S.STARTLE:
			var away = (pos - startle_from).normalized()
			if away == Vector2.ZERO:
				away = Vector2.from_angle(heading)
			goal = pos + away * 200.0
			want_speed = 120.0 * (0.8 + 0.4 * (1.0 - boldness))
			turn_rate = 5.5
			target_depth = 0.8
			if state_t < 0.0:
				set_state(S.WANDER, 2.0)

	# Steering: goal, bank avoidance, separation.
	var desire = (goal - pos)
	if desire.length() > 0.001:
		desire = desire.normalized()
	var sdf: float = pond.cpu_sdf(pos)
	var inward = pond.inward(pos)
	var edge_w = clampf((sdf + 0.085) / 0.06, 0.0, 1.0)
	desire = (desire * (1.0 - edge_w) + inward * edge_w * 1.6)
	var fwd = pos + Vector2.from_angle(heading) * 40.0
	if pond.cpu_sdf(fwd) > -0.04:
		desire += inward * 1.2
	for o in fishes:
		if o == self:
			continue
		var d: Vector2 = pos - o.pos
		var dd = d.length()
		var r2 = (length + o.length) * 0.55
		if dd < r2 and absf(depth - o.depth) < 0.3 and dd > 0.01:
			desire += d / dd * (1.0 - dd / r2) * 2.6
	for pad in pond.pads:
		pass
	var want_h = desire.angle() if desire.length() > 0.01 else heading
	var dh = wrapf(want_h - heading, -PI, PI)
	var max_turn = turn_rate * dt * (0.6 + 0.4 * pace)
	var turn = clampf(dh, -max_turn, max_turn)
	heading = wrapf(heading + turn, -PI, PI)
	turn_signal = lerpf(turn_signal, turn / maxf(dt, 0.001), 1.0 - exp(-dt * 4.0))
	# Slow down in sharp turns, like a real koi braking with its pectorals.
	var brake = 1.0 - clampf(absf(dh) / PI, 0.0, 1.0) * 0.5
	speed = lerpf(speed, want_speed * brake, 1.0 - exp(-dt * (3.0 if state == S.STARTLE else 0.9)))
	pos += Vector2.from_angle(heading) * speed * dt
	depth = lerpf(depth, target_depth, 1.0 - exp(-dt * (1.4 if state == S.STARTLE else 0.45)))

	phase += dt * (2.2 + speed * 0.075)
	fin_phase += dt * (1.6 + absf(turn_signal) * 5.0 + (3.0 if state == S.REST else 0.0))

	# Chain spine: the body follows the head.
	var seg = length * 0.74 / float(N - 1)
	spine[0] = pos
	var prev_dir = Vector2.from_angle(heading)
	for i in range(1, N):
		var v = spine[i - 1] - spine[i]
		var l = v.length()
		if l > 0.0001:
			var d = v / l
			# Limit the bend per joint so the body never folds.
			var ang = prev_dir.angle_to(d)
			var lim = 0.22
			if absf(ang) > lim:
				d = prev_dir.rotated(clampf(ang, -lim, lim))
			spine[i] = spine[i - 1] - d * seg
			prev_dir = d

	# Wakes: fish near the surface push water.
	if depth < 0.3:
		wake_acc += dt
		if wake_acc > 0.08:
			wake_acc = 0.0
			var s = -0.02 * (1.0 - depth / 0.3) * clampf(speed / 40.0, 0.2, 2.5)
			pond.add_ripple(spine[3], s, 1.6)

func _w(u: float) -> float:
	var head = pow(clampf(u / 0.2, 0.0, 1.0), 0.38)
	var taper = 1.0 - 0.8 * smoothstep(0.3, 1.0, u)
	return width * head * taper

func build_mesh() -> void:
	var sc = 1.0 + 0.1 * (1.0 - depth)
	var pts = PackedVector2Array()
	var uvs = PackedVector2Array()
	var cols = PackedColorArray()
	var idx_arr = PackedInt32Array()
	var sp = PackedVector2Array()
	var tn = PackedVector2Array()
	sp.resize(N)
	tn.resize(N)
	var amp = width * (0.25 + clampf(speed / 60.0, 0.0, 1.0) * 0.3)
	var c0 = spine[0]
	for i in N:
		var t: Vector2
		if i == 0:
			t = (spine[0] - spine[1]).normalized()
		elif i == N - 1:
			t = (spine[N - 2] - spine[N - 1]).normalized()
		else:
			t = (spine[i - 1] - spine[i + 1]).normalized()
		var u = float(i) / float(N - 1)
		var n = t.orthogonal()
		var lat = amp * pow(u, 1.7) * sin(phase - u * 5.5)
		sp[i] = c0 + (spine[i] - c0) * sc + n * lat
		tn[i] = t
	var W = width * sc

	var body = Color(0, 0, 0, 1)
	# Pectoral and pelvic fins (under the body).
	for side in [-1.0, 1.0]:
		_fin(pts, uvs, cols, idx_arr, sp[3], tn[3], side, W * 0.8, 0.95 + 0.35 * sin(fin_phase) * side * 0.0 + 0.3 * sin(fin_phase), W * 1.9, W * 0.62, 0.5)
		_fin(pts, uvs, cols, idx_arr, sp[7], tn[7], side, W * 0.5, 1.15 + 0.2 * sin(fin_phase + 1.3), W * 0.8, W * 0.28, 0.45)
	# Tail.
	var pe = sp[N - 1]
	var te = tn[N - 1]
	var swing = sin(phase - 6.3) * 0.45
	var M = 7
	var base = pts.size()
	var Lt = length * 0.34 * sc
	for k in M:
		var r = float(k) / float(M - 1)
		var dir = (-te).rotated(swing * r)
		var nn = dir.orthogonal()
		var hw = lerpf(W * 0.14, W * 1.2, pow(r, 0.7))
		var cen = pe + dir * (r * Lt)
		var notch = pe + dir * (r * Lt * (1.0 - 0.38 * pow(r, 2.5)))
		pts.append(cen + nn * hw)
		pts.append(notch)
		pts.append(cen - nn * hw)
		uvs.append(Vector2(r, 0.0))
		uvs.append(Vector2(r, 0.5))
		uvs.append(Vector2(r, 1.0))
		for _j in 3:
			cols.append(Color(1, 0.8, 0, 1))
	for k in M - 1:
		for j in 2:
			var a = base + k * 3 + j
			idx_arr.append_array([a, a + 3, a + 1, a + 1, a + 3, a + 4])
	# Body strip with a centre column so the round shading interpolates cleanly.
	base = pts.size()
	for i in N:
		var u = float(i) / float(N - 1)
		var n = tn[i].orthogonal()
		var w = _w(u) * sc
		pts.append(sp[i] + n * w)
		pts.append(sp[i])
		pts.append(sp[i] - n * w)
		uvs.append(Vector2(u, 0.0))
		uvs.append(Vector2(u, 0.5))
		uvs.append(Vector2(u, 1.0))
		for _j in 3:
			cols.append(body)
	# Round the nose with a small fan.
	var nose = sp[0] + tn[0] * W * 0.26
	pts.append(nose)
	uvs.append(Vector2(0.0, 0.5))
	cols.append(body)
	var ni = pts.size() - 1
	idx_arr.append_array([base, ni, base + 1, base + 1, ni, base + 2])
	for i in N - 1:
		for j in 2:
			var a = base + i * 3 + j
			idx_arr.append_array([a, a + 3, a + 1, a + 1, a + 3, a + 4])
	# Dorsal fin: a thin translucent ridge over the back.
	base = pts.size()
	var d0 = 4
	var d1 = 10
	for i in range(d0, d1 + 1):
		var u2 = float(i - d0) / float(d1 - d0)
		var n2 = tn[i].orthogonal()
		var hw2 = W * 0.13 * sin(PI * u2) + 0.5
		var fl = sin(phase * 1.3 - u2 * 3.0) * W * 0.08 * u2
		pts.append(sp[i] + n2 * (hw2 + fl))
		pts.append(sp[i] - n2 * (hw2 - fl))
		uvs.append(Vector2(u2, 0.0))
		uvs.append(Vector2(u2, 1.0))
		cols.append(Color(1, 0.45, 0, 1))
		cols.append(Color(1, 0.45, 0, 1))
	for i in d1 - d0:
		var a = base + i * 2
		idx_arr.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
	mesh = {"pts": pts, "uvs": uvs, "cols": cols, "idx": idx_arr}

func _fin(pts: PackedVector2Array, uvs: PackedVector2Array, cols: PackedColorArray, idx_arr: PackedInt32Array, at: Vector2, t: Vector2, side: float, off: float, sweep: float, flen: float, fw: float, op: float) -> void:
	var n = t.orthogonal() * side
	var root = at + n * off
	var dir = (n * cos(sweep) - t * sin(sweep)).normalized()
	var perp = dir.orthogonal()
	var base = pts.size()
	var R = 5
	for k in R:
		var r = float(k) / float(R - 1)
		var hw = fw * pow(sin(PI * (0.25 + 0.75 * r)), 0.6) + fw * 0.15 * (1.0 - r)
		var c = root + dir * (r * flen) - t * (r * r * flen * 0.15)
		pts.append(c + perp * hw)
		pts.append(c - perp * hw)
		uvs.append(Vector2(r, 0.0))
		uvs.append(Vector2(r, 1.0))
		cols.append(Color(1, op, 0, 1))
		cols.append(Color(1, op, 0, 1))
	for k in R - 1:
		var a = base + k * 2
		idx_arr.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])

func _pick_wander(pond) -> void:
	var vis: Vector2 = pond.vis
	for _i in 8:
		var cand = home + Vector2(randf_range(-0.35, 0.35) * vis.x, randf_range(-0.3, 0.3) * vis.y)
		if randf() < 0.4:
			cand = Vector2(randf_range(0.12, 0.88) * vis.x, randf_range(0.12, 0.88) * vis.y)
		if pond.cpu_sdf(cand) < -0.07:
			target = cand
			return
	target = vis * 0.5
