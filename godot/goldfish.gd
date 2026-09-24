extends RefCounted
## One fancy goldfish: steering, bond, and a body with spring-chain veil fins.

enum S { WANDER, FOOD, TOUCH, STARTLE, REST }

const N = 16
const TM = 14
const TAIL_ANG = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0]

var name = "Momo"
var kind = 0
var idx = 0
var pos = Vector2.ZERO
var heading = 0.0
var speed = 16.0
var depth = 0.4
var target_depth = 0.4
var length = 120.0
var width = 30.0
var tail_len = 140.0
var spine = PackedVector2Array()
var phase = 0.0
var turn_signal = 0.0
var state = S.WANDER
var state_t = 0.0
var target = Vector2.ZERO
var food_target = null
var startle_from = Vector2.ZERO
var bond = 0.0
var nuzzle_cd = 0.0
var glow = 0.0
var pace = 1.0
var boldness = 0.5
var strands = []
var strands_prev = []
var pects = []
var pects_prev = []
var mesh = {}
var body_node: Node2D
var mat: ShaderMaterial

func setup(p: Vector2, h: float) -> void:
	pos = p
	heading = h
	spine.resize(N)
	var seg = length * 0.8 / float(N - 1)
	var back = Vector2.from_angle(h + PI)
	for i in N:
		spine[i] = p + back * seg * i
	strands.clear()
	strands_prev.clear()
	var tseg = tail_len / float(TM - 1)
	for s in TAIL_ANG.size():
		var a = PackedVector2Array()
		for i in TM:
			a.append(spine[N - 1] + back.rotated(TAIL_ANG[s] * 0.5) * tseg * i)
		strands.append(a)
		strands_prev.append(a.duplicate())
	pects.clear()
	pects_prev.clear()
	for side in 2:
		var c = PackedVector2Array()
		for i in 5:
			c.append(spine[3])
		pects.append(c)
		pects_prev.append(c.duplicate())
	target = p
	phase = randf() * TAU

func bond_level() -> int:
	var l = 0
	for v in [8.0, 22.0, 42.0, 68.0, 100.0]:
		if bond >= v:
			l += 1
	return l

func set_state(s: int, dur: float) -> void:
	state = s
	state_t = dur

func update(dt: float, pond, fishes: Array) -> void:
	state_t -= dt
	nuzzle_cd = maxf(0.0, nuzzle_cd - dt)
	glow = maxf(0.0, glow - dt * 0.7)
	var want_speed = 15.0 * pace
	var turn_rate = 1.1
	var goal = target
	if state != S.STARTLE:
		var pellet = pond.nearest_pellet(pos, 160.0 + 160.0 * boldness + 20.0 * bond_level())
		if pellet != null:
			food_target = pellet
			state = S.FOOD
		elif state == S.FOOD:
			food_target = null
			set_state(S.WANDER, randf_range(3.0, 6.0))
		if state != S.FOOD and pond.hold_active:
			if (bond_level() >= 1 or boldness > 0.6) and pos.distance_to(pond.hold_pos) < 220.0 + 60.0 * bond_level():
				state = S.TOUCH
		elif state == S.TOUCH:
			set_state(S.WANDER, randf_range(2.0, 4.0))
	match state:
		S.WANDER:
			if pos.distance_to(target) < 50.0 or state_t < 0.0:
				target = pond.random_point(0.7)
				if randf() < 0.18:
					set_state(S.REST, randf_range(3.0, 6.0))
				else:
					state_t = randf_range(6.0, 11.0)
			goal = target
			target_depth = 0.35 + 0.25 * sin(phase * 0.05 + idx)
		S.REST:
			goal = pos + Vector2.from_angle(heading) * 40.0
			want_speed = 4.0
			target_depth = 0.6
			if state_t < 0.0:
				set_state(S.WANDER, 0.0)
		S.FOOD:
			if food_target == null or not pond.pellet_alive(food_target):
				food_target = null
				set_state(S.WANDER, 2.0)
			else:
				goal = food_target.pos
				want_speed = 30.0 * pace
				turn_rate = 1.8
				target_depth = 0.1
				var mouth = pos + Vector2.from_angle(heading) * length * 0.05
				if mouth.distance_to(goal) < width * 0.8:
					if pond.eat_pellet(food_target, self):
						bond = minf(100.0, bond + 3.0 + 2.0 * boldness)
						glow = 1.0
					food_target = null
					set_state(S.WANDER, 2.5)
		S.TOUCH:
			var hp: Vector2 = pond.hold_pos
			var ang = pond.time * 0.5 + idx * PI
			goal = hp + Vector2.from_angle(ang) * (40.0 if bond_level() >= 3 else 80.0)
			want_speed = 20.0
			target_depth = 0.1
			var mouth2 = pos + Vector2.from_angle(heading) * length * 0.1
			if mouth2.distance_to(hp) < 44.0 and nuzzle_cd <= 0.0:
				nuzzle_cd = 5.0
				bond = minf(100.0, bond + 1.5)
				glow = 1.0
				pond.add_ripple(mouth2, -0.18, 1.6)
				pond.on_nuzzle(self)
		S.STARTLE:
			var away = (pos - startle_from).normalized()
			if away == Vector2.ZERO:
				away = Vector2.from_angle(heading)
			goal = pos + away * 200.0
			want_speed = 80.0
			turn_rate = 4.0
			target_depth = 0.75
			if state_t < 0.0:
				set_state(S.WANDER, 2.0)
	var desire = goal - pos
	if desire.length() > 0.001:
		desire = desire.normalized()
	var sd = pond.cpu_sdf(pos)
	var inward = (pond.center - pos).normalized()
	var ew = clampf((sd + 70.0) / 60.0, 0.0, 1.0)
	desire = desire * (1.0 - ew) + inward * ew * 1.6
	if pond.cpu_sdf(pos + Vector2.from_angle(heading) * 60.0) > -30.0:
		desire += inward
	for o in fishes:
		if o == self:
			continue
		# Compare against the other fish's mid-body, not just its head, and add a
		# gentle positional nudge so the two never swim through each other.
		var om: Vector2 = o.spine[N / 2] if o.spine.size() == N else o.pos
		for q in [o.pos, om]:
			var dv: Vector2 = pos - q
			var dd = dv.length()
			var r2 = (length + o.length) * 0.6
			if dd < r2 and dd > 0.01:
				var push = 1.0 - dd / r2
				desire += dv / dd * push * 3.0
				pos += dv / dd * push * push * 30.0 * dt
	var want_h = desire.angle() if desire.length() > 0.01 else heading
	var dh = wrapf(want_h - heading, -PI, PI)
	var mt = turn_rate * dt
	var turn = clampf(dh, -mt, mt)
	heading = wrapf(heading + turn, -PI, PI)
	turn_signal = lerpf(turn_signal, turn / maxf(dt, 0.001), 1.0 - exp(-dt * 3.0))
	var brake = 1.0 - clampf(absf(dh) / PI, 0.0, 1.0) * 0.5
	speed = lerpf(speed, want_speed * brake, 1.0 - exp(-dt * (3.0 if state == S.STARTLE else 0.8)))
	pos += Vector2.from_angle(heading) * speed * dt
	depth = lerpf(depth, target_depth, 1.0 - exp(-dt * 0.5))
	phase += dt * (2.0 + speed * 0.09)
	# Spine follows the head with a bend limit per joint.
	var seg = length * 0.8 / float(N - 1)
	spine[0] = pos
	var prev_dir = Vector2.from_angle(heading)
	for i in range(1, N):
		var v = spine[i - 1] - spine[i]
		var l = v.length()
		if l > 0.0001:
			var d = v / l
			var ang2 = prev_dir.angle_to(d)
			if absf(ang2) > 0.065:
				d = prev_dir.rotated(clampf(ang2, -0.065, 0.065))
			spine[i] = spine[i - 1] - d * seg
			prev_dir = d
	_update_fins(dt)
	if depth < 0.25 and speed > 10.0 and fmod(phase, 0.9) < dt * 3.0:
		pond.add_ripple(spine[3], -0.015, 1.8)

func _update_fins(dt: float) -> void:
	# Root the veil a little inside the body so the body hides the pinch.
	var base = spine[N - 1].lerp(spine[N - 3], 0.7)
	var back = (spine[N - 1] - spine[N - 2]).normalized()
	var side = back.orthogonal()
	var tseg = tail_len / float(TM - 1)
	var spread = (0.68 if kind == 0 else 0.66) + 0.2 * (1.0 - clampf(speed / 40.0, 0.0, 1.0))
	var beat = sin(phase) * 0.35
	var k = clampf(dt * 60.0, 0.2, 1.0)
	for s in strands.size():
		var pts: PackedVector2Array = strands[s]
		var prv: PackedVector2Array = strands_prev[s]
		var ta: float = TAIL_ANG[s]
		pts[0] = base + side * ta * width * 0.5
		var dir0 = back.rotated(ta * spread + beat)
		# Pin the first segment to the fan direction so the veil root stays open.
		pts[1] = pts[0] + dir0 * tseg
		prv[1] = pts[1]
		for i in range(2, TM):
			var f = float(i) / float(TM - 1)
			var cur = pts[i]
			var vel = (cur - prv[i]) * 0.86
			prv[i] = cur
			# Each strand also ripples on its own phase so the veil flutters in layers.
			var dir = dir0.rotated(sin(phase * 0.8 - f * 3.2) * 0.22 * f + sin(phase * 1.7 + float(s) * 1.3 - f * 4.0) * 0.1 * f)
			var tgt = pts[i - 1] + dir * tseg
			cur += vel + (tgt - cur) * (0.32 * (1.0 - f) + 0.06) * k
			pts[i] = cur
		for i in range(1, TM):
			var d = pts[i] - pts[i - 1]
			var l = d.length()
			if l > 0.0001:
				var nd = d / l
				if i >= 2:
					# Cap bending per joint so the veil curls instead of folding.
					var pd = (pts[i - 1] - pts[i - 2]).normalized()
					var ang = pd.angle_to(nd)
					nd = pd.rotated(clampf(ang, -0.32, 0.32))
				pts[i] = pts[i - 1] + nd * tseg
		strands[s] = pts
		strands_prev[s] = prv
	# Keep the veil a single sheet: relax each strand toward the midpoint of its
	# neighbours so strands never cross and fold into shards on sharp turns.
	var S = strands.size()
	for _it in 1:
		for s in range(1, S - 1):
			var a: PackedVector2Array = strands[s - 1]
			var c: PackedVector2Array = strands[s + 1]
			var m: PackedVector2Array = strands[s]
			for i in range(2, TM):
				m[i] = m[i].lerp((a[i] + c[i]) * 0.5, 0.25)
			strands[s] = m
	# Keep the strands in order across the veil at every joint. If two swap
	# sides the membrane between them flips over and draws as a dark shard.
	for i in range(1, TM):
		var m = Vector2.ZERO
		var mp = Vector2.ZERO
		for s in S:
			m += strands[s][i]
			mp += strands[s][i - 1]
		m /= float(S)
		mp /= float(S)
		var lat = (m - mp).normalized().orthogonal()
		# Minimum gap grows toward the tip so the veil can never collapse into
		# a single dark whip on a hard turn; the push is re-centred afterwards
		# so the veil does not drift to one side.
		var minsep = width * (0.05 if kind == 1 else 0.035) * (1.0 + float(i) * 0.35)
		var prev_p = -INF
		var shift = PackedFloat32Array()
		shift.resize(S)
		for s in S:
			var pj = (strands[s][i] - m).dot(lat)
			if pj < prev_p + minsep:
				shift[s] = prev_p + minsep - pj
				pj = prev_p + minsep
			prev_p = pj
		var avg = 0.0
		for s in S:
			avg += shift[s]
		avg /= float(S)
		for s in S:
			var st: PackedVector2Array = strands[s]
			st[i] += lat * (shift[s] - avg)
			strands[s] = st
	var fwd = Vector2.from_angle(heading)
	for sd in 2:
		var sgn = -1.0 if sd == 0 else 1.0
		var pts2: PackedVector2Array = pects[sd]
		var prv2: PackedVector2Array = pects_prev[sd]
		var t2 = (spine[3] - spine[4]).normalized()
		pts2[0] = spine[3] + t2.orthogonal() * sgn * width * 0.42
		var pd = (t2.orthogonal() * sgn * 0.8 - t2).normalized().rotated(sgn * sin(phase * 1.3) * 0.35)
		var pseg = length * (0.09 if kind == 1 else 0.07)
		for i in range(1, 5):
			var cur2 = pts2[i]
			var vel2 = (cur2 - prv2[i]) * 0.85
			prv2[i] = cur2
			cur2 += vel2 + (pts2[i - 1] + pd * pseg - cur2) * 0.25 * k
			var d2 = cur2 - pts2[i - 1]
			pts2[i] = pts2[i - 1] + d2.normalized() * pseg
		pects[sd] = pts2
		pects_prev[sd] = prv2

func _w(u: float) -> float:
	# Seen from above. Ryukin: egg body, narrow snout, deep round middle.
	# Demekin: blunt wide head (the eyes sit on it), long velvety taper.
	var s = sin(PI * clampf(u * 0.92 + 0.04, 0.0, 1.0))
	if kind == 1:
		var head1 = pow(clampf(u / 0.1, 0.0, 1.0), 0.4)
		var lump = 1.0 + 0.045 * sin(u * 21.0) * smoothstep(0.1, 0.3, u) * (1.0 - smoothstep(0.6, 0.8, u))
		return width * 0.5 * pow(s, 0.45) * (0.7 + 0.3 * head1) * (1.0 - 0.62 * smoothstep(0.45, 1.0, u)) * lump
	var head = pow(clampf(u / 0.18, 0.0, 1.0), 0.5)
	return width * 0.5 * pow(s, 0.6) * (0.62 + 0.38 * head) * (1.0 - 0.45 * smoothstep(0.55, 1.0, u))

func build_mesh() -> void:
	var pts = PackedVector2Array()
	var uvs = PackedVector2Array()
	var cols = PackedColorArray()
	var ia = PackedInt32Array()
	var sc = 1.0 + 0.08 * (1.0 - depth)
	var c0 = spine[0]
	var sp = PackedVector2Array()
	var tn = PackedVector2Array()
	sp.resize(N)
	tn.resize(N)
	for i in N:
		var t: Vector2
		if i == 0:
			t = (spine[0] - spine[1]).normalized()
		elif i == N - 1:
			t = (spine[N - 2] - spine[N - 1]).normalized()
		else:
			t = (spine[i - 1] - spine[i + 1]).normalized()
		var u = float(i) / float(N - 1)
		sp[i] = c0 + (spine[i] - c0) * sc + t.orthogonal() * sin(phase - u * 3.0) * width * 0.05 * u
		tn[i] = t
	var fin = Color(0.5, 0.62, 0, 1)
	# Tail veil: membranes between neighbouring spring strands.
	var S = strands.size()
	var base = pts.size()
	for s in S:
		var st: PackedVector2Array = strands[s]
		for i in TM:
			pts.append(c0 + (st[i] - c0) * sc)
			uvs.append(Vector2(float(i) / float(TM - 1), float(s) / float(S - 1)))
			cols.append(fin)
	for s in S - 1:
		for i in TM - 1:
			var a = base + s * TM + i
			var b = a + TM
			ia.append_array([a, a + 1, b, b, a + 1, b + 1])
	# Pectoral fins.
	for sd in 2:
		var pc: PackedVector2Array = pects[sd]
		var pb = pts.size()
		for i in 5:
			var dd = (pc[mini(i + 1, 4)] - pc[maxi(i - 1, 0)]).normalized().orthogonal()
			var hw = width * (0.25 if kind == 1 else 0.17) * sin(PI * (0.15 + 0.85 * float(i) / 4.0))
			pts.append(c0 + (pc[i] - c0) * sc + dd * hw)
			pts.append(c0 + (pc[i] - c0) * sc - dd * hw)
			uvs.append(Vector2(float(i) / 4.0, 0.0))
			uvs.append(Vector2(float(i) / 4.0, 1.0))
			cols.append(Color(0.5, 0.3, 0, 1))
			cols.append(Color(0.5, 0.3, 0, 1))
		for i in 4:
			var a2 = pb + i * 2
			ia.append_array([a2, a2 + 2, a2 + 1, a2 + 1, a2 + 2, a2 + 3])
	# Body.
	var body = Color(0, 0, 0, 1)
	base = pts.size()
	for i in N:
		var u2 = float(i) / float(N - 1)
		var n = tn[i].orthogonal()
		var w = _w(u2) * sc
		pts.append(sp[i] + n * w)
		pts.append(sp[i])
		pts.append(sp[i] - n * w)
		uvs.append(Vector2(u2, 0.0))
		uvs.append(Vector2(u2, 0.5))
		uvs.append(Vector2(u2, 1.0))
		for _j in 3:
			cols.append(body)
	# Rounded snout: a half-ellipse cap so the head never ends in a flat cut.
	var n0 = tn[0].orthogonal()
	var w0 = _w(0.0) * sc
	var reach = w0 * (0.75 if kind == 1 else 0.9)
	var ci = pts.size()
	for k in range(1, 8):
		var a5 = PI * float(k) / 8.0
		pts.append(sp[0] + n0 * w0 * cos(a5) + tn[0] * reach * sin(a5))
		uvs.append(Vector2(0.0, 0.5 - 0.5 * cos(a5)))
		cols.append(body)
	var ring = [base] + range(ci, ci + 7) + [base + 2]
	for k in ring.size() - 1:
		ia.append_array([base + 1, ring[k], ring[k + 1]])
	for i in N - 1:
		for j in 2:
			var a3 = base + i * 3 + j
			ia.append_array([a3, a3 + 3, a3 + 1, a3 + 1, a3 + 3, a3 + 4])
	# Dorsal fin: a translucent sail over the back that flutters.
	base = pts.size()
	for i in range(3, 13):
		var u3 = float(i - 3) / 9.0
		var n3 = tn[i].orthogonal()
		var fl = sin(phase * 1.2 - u3 * 3.0) * width * 0.12 * u3
		var hw3 = width * (0.11 if kind == 1 else 0.07) * sin(PI * u3) + 0.6
		pts.append(sp[i] + n3 * (hw3 + fl))
		pts.append(sp[i] - n3 * (hw3 - fl))
		uvs.append(Vector2(u3, 0.0))
		uvs.append(Vector2(u3, 1.0))
		cols.append(Color(0.5, 0.45, 0, 1))
		cols.append(Color(0.5, 0.45, 0, 1))
	for i in 9:
		var a4 = base + i * 2
		ia.append_array([a4, a4 + 2, a4 + 1, a4 + 1, a4 + 2, a4 + 3])
	# Demekin: telescope eyes bulge out past the head.
	for sd in [-1.0, 1.0]:
		if true:
			var ei = 2 if kind == 1 else 3
			var ec = sp[ei] + tn[ei].orthogonal() * sd * width * (0.36 if kind == 1 else 0.27) * sc - tn[2] * width * (0.02 if kind == 1 else -0.02)
			var er = width * (0.15 if kind == 1 else 0.1) * sc
			var eb = pts.size()
			var t1 = tn[2]
			var o1 = t1.orthogonal()
			for q in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
				pts.append(ec + t1 * q.x * er + o1 * q.y * er)
				uvs.append((q + Vector2.ONE) * 0.5)
				cols.append(Color(1, 0, 0, 1))
			ia.append_array([eb, eb + 1, eb + 2, eb, eb + 2, eb + 3])
	mesh = {"pts": pts, "uvs": uvs, "cols": cols, "idx": ia}
