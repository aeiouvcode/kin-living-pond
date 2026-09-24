extends Node3D
## KIN fish lab: the fish on their own, no water, so anatomy and fins can be
## judged in isolation (Hakozaki-style: fish and fluid as separate crafts,
## integrated later). Settings come from user args (--kind=ryukin|demekin|both,
## --cam=top|34|side, --fov=, --tail=, --fin=, --orbit=) and later an on-screen panel.

const BodyShader = preload("res://labs/fish_body.gdshader")
const FinShader = preload("res://labs/fish_fin.gdshader")

var settings = {"kind": "both", "cam": "34", "fov": 34.0, "tail": 1.0, "fin": 0.8, "orbit": 1.0, "panel": 0.0, "bright": 1.0, "sat": 1.0, "contrast": 1.0, "bg": "lilac"}
const BGS = {"lilac": Color(0.6, 0.62, 0.86), "paper": Color(0.93, 0.91, 0.87), "night": Color(0.07, 0.08, 0.14), "mint": Color(0.7, 0.86, 0.82)}
var env: Environment
var ui_panel: PanelContainer
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
	_build_ui()
	_spawn()
	cam = Camera3D.new()
	cam.fov = settings.fov
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	add_child(cam)
	_place_cam()

func _spawn() -> void:
	for f in fish:
		f.queue_free()
	fish.clear()
	var kinds = ["ryukin", "demekin"] if settings.kind == "both" else [settings.kind]
	for i in kinds.size():
		var f = _build_fish(kinds[i])
		var off = (i - (kinds.size() - 1) * 0.5) * 1.6
		f.position = Vector3(0, -off * 0.7, 0) if settings.cam == "side" else Vector3(0, 0, off)
		add_child(f)
		fish.append(f)

func _env() -> void:
	var we = WorldEnvironment.new()
	var e = Environment.new()
	env = e
	e.background_mode = Environment.BG_COLOR
	e.background_color = BGS.get(settings.bg, BGS.lilac)
	e.adjustment_enabled = true
	_grade()
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

func _fin_mesh(len: float, w0: float, w1: float, nu: int, nv: int, spread: float, droop: float, axis_up: bool, cup: float = 0.0) -> ArrayMesh:
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
			var curl = cup * u * (v - 0.5) * (v - 0.5) * 4.0 * w
			if axis_up:
				p = Vector3(x, s + u * spread, curl)
			else:
				p = Vector3(x, -u * u * droop - curl, s + u * spread)
			st.set_uv(Vector2(u, v))
			st.add_vertex(p)
	for i in nu:
		for j in nv:
			var a0 = i * (nv + 1) + j
			var b0 = a0 + nv + 1
			st.add_index(a0); st.add_index(b0); st.add_index(a0 + 1)
			st.add_index(a0 + 1); st.add_index(b0); st.add_index(b0 + 1)
	st.generate_normals()
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
	# Double tail (butterfly): two caudal fins side by side, each a broad
	# forked fan standing near-vertical at the root and splaying outward, so
	# from above you see two big lobes; each cups and droops at the edges.
	var tail_x = -0.62
	for side in [-1.0, 1.0]:
		var m = _fin_mesh(tl, 0.1, 1.0, 24, 14, 0.0, 0.0, true, 0.22)
		var fm = _fin_mat(kind, tail_x, side * 1.3, Vector3(0, 0, 1), 0.85)
		fm.set_shader_parameter("fork", 0.3)
		_add_fin(root, m, fm, Vector3(tail_x + 0.03, -0.02, side * 0.015), Vector3(side * 58.0, side * 16.0, 0))
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
		var er = 0.042 if kind == "ryukin" else 0.072
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
			# Telescope eye: a smooth dome of body tissue growing out of the head.
			var dome = MeshInstance3D.new()
			var dm2 = SphereMesh.new()
			dm2.radius = 0.1
			dm2.height = 0.2
			dome.mesh = dm2
			dome.material_override = bm
			dome.position = Vector3(0.22, 0.07, side * 0.13)
			dome.scale = Vector3(0.95, 0.85, 1.05)
			root.add_child(dome)
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

# ---------- Showcase settings (Hakozaki-style: many knobs, one rig) ----------

func _grade() -> void:
	env.adjustment_brightness = settings.bright
	env.adjustment_saturation = settings.sat
	env.adjustment_contrast = settings.contrast

func _build_ui() -> void:
	var layer = CanvasLayer.new()
	add_child(layer)
	var toggle = Button.new()
	toggle.text = "Settings"
	toggle.position = Vector2(12, 12)
	layer.add_child(toggle)
	ui_panel = PanelContainer.new()
	ui_panel.position = Vector2(12, 52)
	ui_panel.visible = settings.panel > 0.0
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(1, 1, 1, 0.72)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(12)
	ui_panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(ui_panel)
	toggle.pressed.connect(func(): ui_panel.visible = not ui_panel.visible)
	var vb = VBoxContainer.new()
	vb.custom_minimum_size = Vector2(250, 0)
	ui_panel.add_child(vb)
	_opt(vb, "Camera", ["34", "top", "side"], ["Orbit", "Top", "Side"], "cam", func(): _place_cam())
	_opt(vb, "Fish", ["both", "ryukin", "demekin"], ["Both", "Ryukin", "Demekin"], "kind", func(): _spawn())
	_opt(vb, "Background", ["lilac", "paper", "night", "mint"], ["Lilac", "Paper", "Night", "Mint"], "bg", func(): env.background_color = BGS[settings.bg])
	_slider(vb, "Field of view", "fov", 20.0, 70.0, func(): cam.fov = settings.fov)
	_slider(vb, "Tail length", "tail", 0.6, 1.6, func(): _spawn())
	_slider(vb, "Fin opacity", "fin", 0.2, 1.0, func(): _spawn())
	_slider(vb, "Brightness", "bright", 0.6, 1.4, func(): _grade())
	_slider(vb, "Saturation", "sat", 0.0, 1.6, func(): _grade())
	_slider(vb, "Contrast", "contrast", 0.7, 1.4, func(): _grade())
	# Wireframe/low-poly/pixel style modes come later: Viewport wireframe
	# debug draw does nothing in the Compatibility renderer (checked c15).
	for c in vb.get_children():
		_font(c)

func _font(c: Control) -> void:
	c.add_theme_font_size_override("font_size", 13)
	c.add_theme_color_override("font_color", Color(0.22, 0.2, 0.4))

func _opt(vb: VBoxContainer, label: String, keys: Array, names: Array, key: String, apply: Callable) -> void:
	var l = Label.new()
	l.text = label
	vb.add_child(l)
	var ob = OptionButton.new()
	for i in names.size():
		ob.add_item(names[i], i)
	ob.selected = maxi(0, keys.find(settings[key]))
	ob.item_selected.connect(func(i): settings[key] = keys[i]; apply.call())
	vb.add_child(ob)

func _slider(vb: VBoxContainer, label: String, key: String, lo: float, hi: float, apply: Callable) -> void:
	var l = Label.new()
	l.text = "%s  %.2f" % [label, settings[key]]
	vb.add_child(l)
	var hs = HSlider.new()
	hs.min_value = lo
	hs.max_value = hi
	hs.step = (hi - lo) / 100.0
	hs.value = settings[key]
	hs.value_changed.connect(func(v): settings[key] = v; l.text = "%s  %.2f" % [label, v]; apply.call())
	vb.add_child(hs)
