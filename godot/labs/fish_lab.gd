extends Node3D
## KIN fish lab: the fish on their own, no water, so anatomy and fins can be
## judged in isolation (Hakozaki-style: fish and fluid as separate crafts,
## integrated later). Settings come from user args (--kind=ryukin|demekin|both,
## --cam=top|34|side, --fov=, --tail=, --fin=, --orbit=) and later an on-screen panel.

const BodyShader = preload("res://labs/fish_body.gdshader")
const FinShader = preload("res://labs/fish_fin.gdshader")

var settings = {"kind": "both", "cam": "34", "fov": 34.0, "tail": 1.0, "fin": 0.8, "orbit": 1.0, "panel": 0.0, "bright": 1.0, "sat": 1.0, "contrast": 1.0, "bg": "lilac", "light": "studio", "anim": 1.0, "sil": 0.0, "turn": -1.0, "stage": "plain", "a_int": 0.8, "a_min": 0.0, "a_fres": 0.0, "rim": 1.0, "blur": 0.4, "blur_min": 0.05}
const BGS = {"lilac": Color(0.6, 0.62, 0.86), "paper": Color(0.93, 0.91, 0.87), "night": Color(0.07, 0.08, 0.14), "mint": Color(0.7, 0.86, 0.82)}
var env: Environment
var ui_panel: PanelContainer
var cam: Camera3D
var fish = []
var grid_mat: ShaderMaterial
var key: DirectionalLight3D
var rim: DirectionalLight3D
# Model test (Naksh, Sep 24 6:25 PM: Hakozaki "tests every model before using it,
# separately"): --kind=ryukin|demekin alone, --light=studio|back|top|flat,
# --anim=0..2 (0 freezes the rig), --sil=1 flat silhouette, --turn=deg fixed
# yaw (or -1 for a slow turntable). tools/model_test.sh renders a contact sheet.
var t = 0.0

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv = a.substr(2).split("=", true, 1)
			if settings.has(kv[0]):
				settings[kv[0]] = float(kv[1]) if typeof(settings[kv[0]]) == TYPE_FLOAT else kv[1]
	_env()
	if settings.stage == "debug":
		settings.fin = settings.a_int
		settings.panel = 1.0
		if settings.kind == "both":
			settings.kind = "ryukin"
		_debug_stage()
	_build_ui()
	_spawn()
	cam = Camera3D.new()
	cam.fov = settings.fov
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	var vsz = get_viewport().get_visible_rect().size
	if settings.stage == "debug" and vsz.x > vsz.y:
		cam.keep_aspect = Camera3D.KEEP_HEIGHT # landscape: keep the vertical view
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
	_apply_sil()
	_apply_knobs()

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
	key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-62, 35, 0)
	key.light_energy = 0.95
	key.light_color = Color(1.0, 0.97, 0.93)
	add_child(key)
	rim = DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20, 200, 0)
	rim.light_energy = 0.55
	rim.light_color = Color(0.75, 0.82, 1.0)
	add_child(rim)
	_light_preset()

# ---------- Anatomy ----------
# Fancy goldfish: short, deep, egg-shaped body with a high back behind the
# head, a blunt head, narrow caudal peduncle. x: nose (+) to tail (-); y up; z side.

func _profile(u: float, kind: String) -> Vector3:
	# (top, bottom, half-width) at body fraction u (0 nose, 1 tail root)
	var hump = 0.36 if kind == "ryukin" else 0.26
	var top = 0.02 + hump * pow(sin(PI * clampf(u * 1.05, 0.0, 1.0)), 0.5) * (1.0 - 0.4 * u)
	top += (0.1 if kind == "ryukin" else 0.03) * exp(-pow((u - 0.33) / 0.16, 2.0))
	if kind == "ryukin":
		# ryukin shoulder: head stays low, then the back rises steeply behind
		# the eyes into a peaked hump and slopes long toward the tail
		top -= 0.04 * smoothstep(0.22, 0.0, u)
		top += 0.05 * smoothstep(0.08, 0.32, u) * (1.0 - smoothstep(0.34, 0.85, u))
	var bot = -(0.02 + 0.27 * pow(sin(PI * clampf(u * 1.02, 0.0, 1.0)), 0.55) * (1.0 - 0.3 * u))
	if kind == "demekin":
		bot *= 1.1
	var hw = 0.02 + 0.23 * pow(sin(PI * clampf(u * 1.03, 0.0, 1.0)), 0.5) * (1.0 - 0.5 * u)
	if kind == "ryukin":
		# deep, narrow body (laterally compressed) with a tapered snout
		hw *= 0.86 - 0.18 * smoothstep(0.22, 0.0, u)
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
			if kind == "ryukin":
				# dorsal ridge: the upper section narrows into the hump, so the
				# fish reads as a tall teardrop head-on, not an egg
				z *= lerpf(1.0, 0.58, pow(maxf(c, 0.0), 1.4) * smoothstep(0.05, 0.3, u))
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

func _fin_mesh(len: float, w0: float, w1: float, nu: int, nv: int, spread: float, droop: float, axis_up: bool, cup: float = 0.0, scallop: float = 0.0, fork: float = 0.0, hang: float = 0.0, seed: float = 0.0) -> ArrayMesh:
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
			# outline: rounded lobe ends, uneven scallops between rays, a
			# centre fork; the sheet hangs (hang) more toward its tip
			var vv = 2.0 * v - 1.0
			var lv = 1.0
			if scallop > 0.0:
				lv = 0.62 + 0.38 * sqrt(maxf(0.0, 1.0 - vv * vv * vv * vv))
				lv *= 1.0 - scallop * (0.5 - 0.5 * cos(v * TAU * 3.5 + seed)) * (0.6 + 0.4 * sin(v * 17.0 + seed * 3.0))
				lv *= 1.0 - fork * exp(-pow((v - 0.5) / 0.1, 2.0))
			var x = -u * len * lv
			var p: Vector3
			var curl = cup * u * (v - 0.5) * (v - 0.5) * 4.0 * w
			if axis_up:
				p = Vector3(x, s + u * spread - hang * pow(u * lv, 2.0) * len, curl + hang * 0.25 * sin(v * 9.0 + seed) * u * u * len)
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
		var m = _fin_mesh(tl, 0.1, 1.0, 26, 28, 0.0, 0.0, true, 0.22, 0.22, 0.28, 0.28, 1.7 + side)
		var fm = _fin_mat(kind, tail_x, side * 1.3, Vector3(0, 0, 1), 0.85)
		fm.set_shader_parameter("fork", 0.0) # the fork now lives in the mesh outline
		_add_fin(root, m, fm, Vector3(tail_x + 0.03, -0.02, side * 0.015), Vector3(side * 58.0, side * 16.0, 0))
	# Tall dorsal fin on the hump.
	var dm = _fin_mesh(0.45 * settings.tail, 0.3, 0.24, 12, 14, 0.12, 0.0, true, 0.0, 0.16, 0.0, 0.35, 4.2)
	_add_fin(root, dm, _fin_mat(kind, -0.05, 0.4, Vector3(0, 0, 1), 0.8), Vector3(0.02, 0.36 if kind == "ryukin" else 0.26, 0), Vector3(0, 0, -28))
	# Paired pectorals and pelvics, anal pair: real fan fins with rounded,
	# scalloped edges that cup and hang, not slivers.
	for side in [-1.0, 1.0]:
		var pm = _fin_mesh(0.3, 0.07, 0.24, 10, 10, side * 0.1, 0.07, false, 0.25, 0.12, 0.0, 0.0, 2.0 + side)
		_add_fin(root, pm, _fin_mat(kind, 0.12, side * 2.0, Vector3(0, 1, 0), 0.72), Vector3(0.14, -0.1, side * 0.15), Vector3(side * 12.0, side * 38.0, 0))
		var vm = _fin_mesh(0.34, 0.06, 0.24, 10, 10, side * 0.08, 0.14, false, 0.25, 0.14, 0.0, 0.0, 3.1 + side)
		_add_fin(root, vm, _fin_mat(kind, -0.08, side * 2.6, Vector3(0, 1, 0), 0.72), Vector3(-0.06, -0.24, side * 0.07), Vector3(side * 32.0, side * 18.0, 0))
		var am = _fin_mesh(0.42 * settings.tail, 0.06, 0.3, 12, 12, side * 0.06, 0.2, false, 0.22, 0.18, 0.0, 0.0, 4.7 + side)
		_add_fin(root, am, _fin_mat(kind, -0.4, side * 3.1, Vector3(0, 1, 0), 0.72), Vector3(-0.4, -0.18, side * 0.04), Vector3(side * 34.0, 0, 0))
	# Eyes: socket rim of body tissue, gold iris disc with a black pupil, and
	# a clear glossy lens dome on top (real goldfish eyes are lens + iris).
	for side in [-1.0, 1.0]:
		var er = 0.056 if kind == "ryukin" else 0.074
		var ez = 0.114 if kind == "ryukin" else 0.2
		var ep = Vector3(0.235, 0.06, side * ez)
		var out = Vector3(0.25, 0.05, side).normalized() # eye faces out and slightly forward
		var basis = Basis.looking_at(-out, Vector3.UP) # -Z of this basis points outward
		var socket = MeshInstance3D.new()
		var tm = TorusMesh.new()
		tm.inner_radius = er * 0.92
		tm.outer_radius = er * 1.32
		socket.mesh = tm
		var sk = StandardMaterial3D.new()
		sk.albedo_color = Color(0.93, 0.8, 0.76) if kind == "ryukin" else Color(0.03, 0.03, 0.045)
		sk.roughness = 0.5
		socket.material_override = sk
		socket.transform = Transform3D(basis * Basis(Vector3.RIGHT, PI * 0.5), ep - out * er * 0.1)
		root.add_child(socket)
		var iris = MeshInstance3D.new()
		var cy = CylinderMesh.new()
		cy.top_radius = er * 0.95
		cy.bottom_radius = er * 0.95
		cy.height = er * 0.08
		iris.mesh = cy
		var im = StandardMaterial3D.new()
		im.albedo_color = Color(0.88, 0.7, 0.36) if kind == "ryukin" else Color(0.72, 0.36, 0.12)
		im.metallic = 0.6
		im.roughness = 0.35
		iris.material_override = im
		iris.transform = Transform3D(basis * Basis(Vector3.RIGHT, PI * 0.5), ep + out * er * 0.05)
		root.add_child(iris)
		var pupil = MeshInstance3D.new()
		var pc = CylinderMesh.new()
		pc.top_radius = er * 0.64
		pc.bottom_radius = er * 0.64
		pc.height = er * 0.1
		pupil.mesh = pc
		var pm2 = StandardMaterial3D.new()
		pm2.albedo_color = Color(0.01, 0.01, 0.02)
		pm2.roughness = 0.2
		pupil.material_override = pm2
		pupil.transform = Transform3D(basis * Basis(Vector3.RIGHT, PI * 0.5), ep + out * er * 0.1)
		root.add_child(pupil)
		var lens = MeshInstance3D.new()
		var sm = SphereMesh.new()
		sm.radius = er
		sm.height = er * 2.0
		lens.mesh = sm
		var lm = StandardMaterial3D.new()
		lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lm.albedo_color = Color(0.9, 0.95, 1.0, 0.12)
		lm.roughness = 0.03
		lm.metallic_specular = 1.0
		lm.rim_enabled = true
		lm.rim = 0.6
		lens.material_override = lm
		lens.position = ep
		lens.scale = Vector3(1, 1, 1) - out.abs() * 0.45 # flattened dome
		root.add_child(lens)
		var eye = lens
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

func _debug_stage() -> void:
	# Hakozaki-style dev scene: one model, bare grid, orbit camera, live knobs.
	env.background_color = Color(0.16, 0.17, 0.2)
	var pm = PlaneMesh.new()
	pm.size = Vector2(40, 40)
	var floor_mi = MeshInstance3D.new()
	floor_mi.mesh = pm
	floor_mi.position = Vector3(0, -0.9, 0)
	grid_mat = ShaderMaterial.new()
	grid_mat.shader = load("res://labs/debug_grid.gdshader")
	floor_mi.material_override = grid_mat
	add_child(floor_mi)
	_apply_knobs()

func _apply_knobs() -> void:
	if grid_mat:
		grid_mat.set_shader_parameter("blur_intensity", settings.blur)
		grid_mat.set_shader_parameter("blur_min", settings.blur_min)
	for f in fish:
		for c in f.find_children("*", "MeshInstance3D", true, false):
			var m = c.material_override
			if m is ShaderMaterial:
				m.set_shader_parameter("rim_glow", settings.rim)
				if m.shader == FinShader:
					m.set_shader_parameter("opacity", settings.a_int)
					m.set_shader_parameter("alpha_min", settings.a_min)
					m.set_shader_parameter("alpha_fresnel", settings.a_fres)

func _light_preset() -> void:
	match settings.light:
		"back":
			key.rotation_degrees = Vector3(-25, 200, 0)
			key.light_energy = 1.2
			rim.rotation_degrees = Vector3(-60, 20, 0)
			rim.light_energy = 0.25
		"top":
			key.rotation_degrees = Vector3(-88, 0, 0)
			key.light_energy = 1.05
			rim.light_energy = 0.2
		"flat":
			key.light_energy = 0.0
			rim.light_energy = 0.0
			env.ambient_light_energy = 1.2
		_:
			pass

func _apply_sil() -> void:
	if settings.sil <= 0.0:
		return
	env.background_color = Color(0.96, 0.95, 0.92)
	var m = StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.08, 0.08, 0.12)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	for f in fish:
		for c in f.find_children("*", "MeshInstance3D", true, false):
			c.material_override = m

func _place_cam() -> void:
	var target = Vector3(-0.35, 0, 0)
	var k = 1.0 if settings.kind == "both" else 0.9 # solo model test: whole fish incl. veil tips
	if settings.kind != "both":
		target = Vector3(-0.75, 0, 0)
	match settings.cam:
		"top":
			cam.position = target + Vector3(0, 4.6 * k, 0.001)
		"side":
			cam.position = target + Vector3(0.6, 0.15, 4.6 * k)
		_:
			cam.position = target + Vector3(2.4, 2.7, 3.2) * k
	cam.look_at(target, Vector3.UP)

func _process(dt: float) -> void:
	t += dt * settings.anim
	for f in fish:
		if settings.turn >= 0.0:
			f.rotation_degrees.y = settings.turn
		elif settings.kind != "both" and settings.stage != "debug":
			f.rotation.y += dt * 0.35
	for f in fish:
		var b = 0.35 * sin(t * 0.4 + f.position.z)
		for c in f.get_children():
			if c is MeshInstance3D and c.material_override is ShaderMaterial:
				c.material_override.set_shader_parameter("time_s", t)
				c.material_override.set_shader_parameter("bend", b * 0.3)
	if settings.orbit > 0.0 and settings.cam == "34" and (settings.kind == "both" or settings.stage == "debug"):
		var target = Vector3(-0.35, 0, 0)
		var a = t * 0.15 * settings.orbit
		if settings.stage == "debug":
			# low orbit, fish sits in the upper half above the knob panel
			var land = cam.keep_aspect == Camera3D.KEEP_HEIGHT
			var rr = 4.4 if land else 3.0
			cam.position = target + Vector3(cos(a) * rr, 1.0, sin(a) * rr)
			cam.look_at(target + Vector3(0, -0.2 if land else -0.75, 0), Vector3.UP)
		else:
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
	if settings.stage == "debug":
		ui_panel.position = Vector2(12, get_viewport().get_visible_rect().size.y - 330)
		_opt(vb, "Model", ["ryukin", "demekin"], ["Ryukin", "Demekin"], "kind", func(): _spawn())
		_slider(vb, "Alpha Intensity", "a_int", 0.0, 1.0, func(): _apply_knobs())
		_slider(vb, "Alpha Min", "a_min", 0.0, 1.0, func(): _apply_knobs())
		_slider(vb, "Alpha Fresnel", "a_fres", 0.0, 1.5, func(): _apply_knobs())
		_slider(vb, "Rim Glow", "rim", 0.0, 3.0, func(): _apply_knobs())
		_slider(vb, "Blur Intensity", "blur", 0.0, 1.5, func(): _apply_knobs())
		_slider(vb, "Blur Min", "blur_min", 0.0, 0.5, func(): _apply_knobs())
		for c in vb.get_children():
			c.add_theme_font_size_override("font_size", 12)
			c.add_theme_color_override("font_color", Color(0.9, 0.92, 0.96))
		var sb2 = StyleBoxFlat.new()
		sb2.bg_color = Color(0.08, 0.09, 0.11, 0.78)
		sb2.set_corner_radius_all(10)
		sb2.set_content_margin_all(10)
		ui_panel.add_theme_stylebox_override("panel", sb2)
		return
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
