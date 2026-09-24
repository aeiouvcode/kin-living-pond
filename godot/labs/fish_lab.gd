extends Node3D
## KIN fish lab: the fish on their own, no water, so anatomy and fins can be
## judged in isolation (Hakozaki-style: fish and fluid as separate crafts,
## integrated later). Settings come from user args (--kind=ryukin|demekin|both,
## --cam=top|34|side, --fov=, --tail=, --fin=, --orbit=) and later an on-screen panel.

const BodyShader = preload("res://labs/fish_body.gdshader")
const FinShader = preload("res://labs/fish_fin.gdshader")

var settings = {"kind": "both", "cam": "34", "fov": 34.0, "tail": 1.0, "fin": 0.8, "orbit": 1.0}
var cam: Camera3D
var fish = []
var t = 0.0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv = a.substr(2).split("=", true, 1)
			if settings.has(kv[0]):
				settings[kv[0]] = float(kv[1]) if typeof(settings[kv[0]]) == TYPE_FLOAT else kv[1]
	_env()
	var kinds = ["ryukin", "demekin"] if settings.kind == "both" else [settings.kind]
	for i in kinds.size():
		var f = _build_fish(kinds[i])
		var off = (i - (kinds.size() - 1) * 0.5) * 1.6
		f.position = Vector3(0, -off * 0.7, 0) if settings.cam == "side" else Vector3(0, 0, off)
		add_child(f)
		fish.append(f)
	cam = Camera3D.new()
	cam.fov = settings.fov
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	add_child(cam)
	_place_cam()

func _env() -> void:
	var we = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.6, 0.62, 0.86)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.78, 0.8, 0.95)
	e.ambient_light_energy = 0.4
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	add_child(we)
	var key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-62, 35, 0)
	key.light_energy = 0.95
	key.light_color = Color(1.0, 0.97, 0.93)
	add_child(key)
	var rim = DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 200, 0)
	rim.light_energy = 0.55
	rim.light_color = Color(0.75, 0.82, 1.0)
	add_child(rim)

# ---------- Anatomy ----------
# Fancy goldfish: short, deep, egg-shaped body with a high back behind the
# head, a blunt head, narrow caudal peduncle. x: nose (+) to tail (-); y up; z side.

func _profile(u: float, kind: String) -> Vector3:
	# (top, bottom, half-width) at body fraction u (0 nose, 1 tail root)
	var hump = 0.36 if kind == "ryukin" else 0.26
	var top = 0.02 + hump * pow(sin(PI * clampf(u * 1.05, 0.0, 1.0)), 0.5) * (1.0 - 0.4 * u)
	top += (0.1 if kind == "ryukin" else 0.03) * exp(-pow((u - 0.33) / 0.16, 2.0))
	var bot = -(0.02 + 0.27 * pow(sin(PI * clampf(u * 1.02, 0.0, 1.0)), 0.55) * (1.0 - 0.3 * u))
	if kind == "demekin":
		bot *= 1.1
	var hw = 0.02 + 0.23 * pow(sin(PI * clampf(u * 1.03, 0.0, 1.0)), 0.5) * (1.0 - 0.5 * u)
	var pin = smoothstep(0.78, 1.0, u)
	top = lerpf(top, 0.05, pin)
	bot = lerpf(bot, -0.04, pin)
	hw = lerpf(hw, 0.025, pin)
	return Vector3(top, bot, hw)

func _body_mesh(kind: String) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var R = 40
	var C = 28
	for i in R + 1:
		var u = float(i) / R
		var p = _profile(u, kind)
		var x = 0.35 - u
		for j in C + 1:
			var a = float(j) / C * TAU
			var s = sin(a)
			var c = cos(a)
			# superellipse-ish section: fuller shoulders than an ellipse
			var cy = (p.x + p.y) * 0.5
			var ry = (p.x - p.y) * 0.5
			var y = cy + ry * signf(c) * pow(absf(c), 0.85)
			var z = p.z * signf(s) * pow(absf(s), 0.8)
			st.set_uv(Vector2(u, float(j) / C))
			st.add_vertex(Vector3(x, y, z))
	for i in R:
		for j in C:
			var a0 = i * (C + 1) + j
			var b0 = a0 + C + 1
			st.add_index(a0); st.add_index(b0); st.add_index(a0 + 1)
			st.add_index(a0 + 1); st.add_index(b0); st.add_index(b0 + 1)
	st.generate_normals()
	return st.commit()

func _fin_mesh(len: float, w0: float, w1: float, nu: int, nv: int, spread: float, droop: float, axis_up: bool) -> ArrayMesh:
	# A fin sheet from root (u=0) to tip (u=1) along -x, spanning y (axis_up)
	# or z, fanning from w0 to w1.
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in nu + 1:
		var u = float(i) / nu
		var w = lerpf(w0, w1, pow(u, 0.7))
		for j in nv + 1:
			var v = float(j) / nv
			var s = (v - 0.5) * w
			var x = -u * len
			var p: Vector3
			if axis_up:
				p = Vector3(x, s + u * spread, 0.0)
			else:
				p = Vector3(x, -u * u * droop, s + u * spread)
			st.set_uv(Vector2(u, v))
			st.set_normal(Vector3(0, 0, 1) if axis_up else Vector3(0, 1, 0))
			st.add_vertex(p)
	for i in nu:
		for j in nv:
			var a0 = i * (nv + 1) + j
			var b0 = a0 + nv + 1
			st.add_index(a0); st.add_index(b0); st.add_index(a0 + 1)
			st.add_index(a0 + 1); st.add_index(b0); st.add_index(b0 + 1)
	return st.commit()

func _fin_mat(kind: String, root_x: float, ph: float, axis: Vector3, op: float) -> ShaderMaterial:
	var m = ShaderMaterial.new()
	m.shader = FinShader
	m.set_shader_parameter("kind", 0.0 if kind == "ryukin" else 1.0)
	m.set_shader_parameter("root_x", root_x)
	m.set_shader_parameter("phase", ph)
	m.set_shader_parameter("wave_axis", axis)
	m.set_shader_parameter("opacity", op * settings.fin)
	return m

func _add_fin(parent: Node3D, mesh: ArrayMesh, mat: ShaderMaterial, pos: Vector3, rot_deg: Vector3) -> void:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)

func _build_fish(kind: String) -> Node3D:
	var root = Node3D.new()
	var body = MeshInstance3D.new()
	body.mesh = _body_mesh(kind)
	var bm = ShaderMaterial.new()
	bm.shader = BodyShader
	bm.set_shader_parameter("kind", 0.0 if kind == "ryukin" else 1.0)
	body.material_override = bm
	root.add_child(body)
	var tl = settings.tail * (1.25 if kind == "ryukin" else 1.05)
	# Double tail: two lobes, each an upper and lower sheet that fan out
	# sideways and droop, like a butterfly seen from above.
	var tail_x = -0.62
	for side in [-1.0, 1.0]:
		for tier in [0, 1]:
			var m = _fin_mesh(tl * (1.0 if tier == 0 else 0.85), 0.08, 0.95, 22, 12, side * (0.45 + 0.15 * tier), 0.22 + 0.2 * tier, false)
			_add_fin(root, m, _fin_mat(kind, tail_x, side * 1.3 + tier * 0.9, Vector3(0, 1, 0), 0.85), Vector3(tail_x + 0.03, -0.01 - 0.03 * tier, side * 0.012), Vector3(side * (12.0 + 10.0 * tier), 0, 0))
	# Tall dorsal fin on the hump.
	var dm = _fin_mesh(0.45 * settings.tail, 0.26, 0.2, 10, 6, 0.12, 0.0, true)
	_add_fin(root, dm, _fin_mat(kind, -0.05, 0.4, Vector3(0, 0, 1), 0.8), Vector3(0.02, 0.36 if kind == "ryukin" else 0.26, 0), Vector3(0, 0, -28))
	# Paired pectorals and pelvics, anal pair.
	for side in [-1.0, 1.0]:
		var pm = _fin_mesh(0.22, 0.06, 0.14, 8, 5, side * 0.1, 0.05, false)
		_add_fin(root, pm, _fin_mat(kind, 0.12, side * 2.0, Vector3(0, 1, 0), 0.7), Vector3(0.14, -0.1, side * 0.16), Vector3(0, side * 30.0, 0))
		var vm = _fin_mesh(0.26, 0.05, 0.16, 8, 5, side * 0.08, 0.12, false)
		_add_fin(root, vm, _fin_mat(kind, -0.08, side * 2.6, Vector3(0, 1, 0), 0.7), Vector3(-0.06, -0.24, side * 0.08), Vector3(side * 25.0, side * 15.0, 0))
		var am = _fin_mesh(0.3 * settings.tail, 0.05, 0.18, 8, 5, side * 0.06, 0.15, false)
		_add_fin(root, am, _fin_mat(kind, -0.4, side * 3.1, Vector3(0, 1, 0), 0.7), Vector3(-0.4, -0.18, side * 0.04), Vector3(side * 30.0, 0, 0))
	# Eyes: glossy domes; the demekin's telescope eyes sit on short stalks.
	for side in [-1.0, 1.0]:
		var eye = MeshInstance3D.new()
		var sm = SphereMesh.new()
		var er = 0.042 if kind == "ryukin" else 0.08
		sm.radius = er
		sm.height = er * 2.0
		eye.mesh = sm
		var em = StandardMaterial3D.new()
		em.albedo_color = Color(0.02, 0.02, 0.04)
		em.roughness = 0.05
		em.metallic_specular = 0.9
		em.rim_enabled = true
		em.rim = 0.4
		eye.material_override = em
		var ez = 0.12 if kind == "ryukin" else 0.2
		eye.position = Vector3(0.24, 0.07, side * ez)
		root.add_child(eye)
		var iris = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = er * 0.62
		tm.outer_radius = er * 0.98
		iris.mesh = tm
		var im = StandardMaterial3D.new()
		im.albedo_color = Color(0.85, 0.72, 0.45) if kind == "ryukin" else Color(0.85, 0.42, 0.15)
		im.roughness = 0.3
		iris.material_override = im
		iris.position = eye.position + Vector3(0, 0, side * er * 0.55)
		iris.rotation_degrees = Vector3(90, 0, 0)
		root.add_child(iris)
		if kind == "demekin":
			var stalk = MeshInstance3D.new()
			var cm = CylinderMesh.new()
			cm.top_radius = 0.06
			cm.bottom_radius = 0.075
			cm.height = 0.1
			stalk.mesh = cm
			stalk.material_override = bm
			stalk.position = Vector3(0.24, 0.07, side * 0.14)
			stalk.rotation_degrees = Vector3(90, 0, 0)
			root.add_child(stalk)
	return root

func _place_cam() -> void:
	var target = Vector3(-0.35, 0, 0)
	match settings.cam:
		"top":
			cam.position = target + Vector3(0, 4.6, 0.001)
		"side":
			cam.position = target + Vector3(0.6, 0.15, 4.6)
		_:
			cam.position = target + Vector3(2.4, 2.7, 3.2)
	cam.look_at(target, Vector3.UP)

func _process(dt: float) -> void:
	t += dt
	for f in fish:
		var b = 0.35 * sin(t * 0.4 + f.position.z)
		for c in f.get_children():
			if c is MeshInstance3D and c.material_override is ShaderMaterial:
				c.material_override.set_shader_parameter("time_s", t)
				c.material_override.set_shader_parameter("bend", b * 0.3)
	if settings.orbit > 0.0 and settings.cam == "34":
		var target = Vector3(-0.35, 0, 0)
		var a = t * 0.15 * settings.orbit
		cam.position = target + Vector3(cos(a) * 4.0, 2.7, sin(a) * 4.0)
		cam.look_at(target, Vector3.UP)
