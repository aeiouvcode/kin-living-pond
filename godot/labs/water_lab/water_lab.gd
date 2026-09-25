extends Node2D
## KIN water lab: the water on its own, no fish (Hakozaki-style: fish and
## fluid built as separate crafts, integrated later). Techniques studied from
## Clearwater (MIT, https://github.com/Aureliengmz/clearwater) and Evan
## Wallace's WebGL Water: a heightfield ripple sim, refraction of the floor,
## per-channel caustics from surface curvature, and sun glints. No code copied.
## Settings via user args: --floor=pebble|tile|sand --depth= --chroma= --glint=
## --drops= (drops per second) --wind= (ambient wave strength).

var W = 96
var H = 208
const DAMP = 0.985

var settings = {"floor": "pebble", "depth": 1.0, "chroma": 1.0, "glint": 1.0, "drops": 1.2, "wind": 1.0, "warm": 1.0, "bloom": 1.0, "refl": 1.0, "crisp": 1.0, "density": 0.36, "slope": 1.0, "gpu": 1.0}
var cur := PackedFloat32Array()
var prev := PackedFloat32Array()
var img: Image
var tex: Texture2D
var sim_vps = []
var sim_mats = []
var sim_i := 0
var pending = []
var use_gpu := true
var proc_us := 0
var rect: ColorRect
var mat: ShaderMaterial
var caus_mats = []
var surf_mat: ShaderMaterial
var caus_vp: SubViewport
var caus_every := 1 # redraw the light net every Nth frame (pond quality fallback)
var frame_i := 0
var t := 0.0
var drop_acc := 0.0
var rng := RandomNumberGenerator.new()
var dragging := false

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv = a.substr(2).split("=", true, 1)
			if settings.has(kv[0]):
				settings[kv[0]] = float(kv[1]) if typeof(settings[kv[0]]) == TYPE_FLOAT else kv[1]
	rng.seed = 7
	# square sim cells in screen space: ~20k cells, long axis follows the viewport
	var vsz = get_viewport().get_visible_rect().size
	var cells = 20000.0
	# in the pond on a wide screen, keep cells nearer phone size in pixels so
	# rings and the light net stay fine (the fish are framed by height there)
	if has_meta("embedded") and vsz.x > vsz.y:
		cells = clampf(vsz.x * vsz.y / 30.0, 20000.0, 40000.0)
	W = int(round(sqrt(cells * vsz.x / vsz.y)))
	H = int(round(cells / W))
	cur.resize(W * H)
	prev.resize(W * H)
	use_gpu = settings.gpu > 0.0
	if use_gpu:
		_build_sim()
		tex = sim_vps[0].get_texture()
	else:
		img = Image.create_empty(W, H, false, Image.FORMAT_RF)
		tex = ImageTexture.create_from_image(img)
	_build_caustics(vsz)
	var layer = CanvasLayer.new()
	var embedded = has_meta("embedded")
	if embedded:
		layer.layer = -1 # drawn as the 3D background (Environment BG_CANVAS)
	add_child(layer)
	rect = ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mat = ShaderMaterial.new()
	mat.shader = load("res://labs/water_lab/water.gdshader")
	mat.set_shader_parameter("height_tex", tex)
	mat.set_shader_parameter("grid", Vector2(W, H))
	mat.set_shader_parameter("floor_kind", {"pebble": 0, "tile": 1, "sand": 2}.get(settings.floor, 0))
	mat.set_shader_parameter("depth", settings.depth)
	mat.set_shader_parameter("chroma", settings.chroma)
	mat.set_shader_parameter("glint", settings.glint)
	mat.set_shader_parameter("wind", settings.wind)
	mat.set_shader_parameter("warm", settings.warm)
	mat.set_shader_parameter("bloom", settings.bloom)
	mat.set_shader_parameter("refl", settings.refl)
	mat.set_shader_parameter("crisp", settings.crisp)
	mat.set_shader_parameter("density", settings.density)
	mat.set_shader_parameter("slope", settings.slope)
	mat.set_shader_parameter("caus_tex", caus_vp.get_texture())
	rect.material = mat
	layer.add_child(rect)
	if embedded:
		# the surface (glints, reflection) is drawn over the fish instead
		mat.set_shader_parameter("glint", 0.0)
		mat.set_shader_parameter("refl", 0.0)
		var top = CanvasLayer.new()
		top.layer = 1
		add_child(top)
		var sr = ColorRect.new()
		sr.set_anchors_preset(Control.PRESET_FULL_RECT)
		sr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		surf_mat = ShaderMaterial.new()
		surf_mat.shader = load("res://labs/water_lab/surface.gdshader")
		surf_mat.set_shader_parameter("height_tex", tex)
		surf_mat.set_shader_parameter("grid", Vector2(W, H))
		surf_mat.set_shader_parameter("wind", settings.wind)
		surf_mat.set_shader_parameter("glint", settings.glint)
		surf_mat.set_shader_parameter("refl", settings.refl)
		sr.material = surf_mat
		top.add_child(sr)
		for i in 3:
			_drop(Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.2, 0.8)), 0.25, 2.2)
		return
	var tag = Label.new()
	tag.text = "water lab"
	tag.position = Vector2(18, 16)
	tag.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	tag.add_theme_font_size_override("font_size", 13)
	layer.add_child(tag)
	# a few opening drops so the first frame already has rings
	for i in 3:
		_drop(Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.2, 0.8)), 0.35, 2.4)

func _build_sim() -> void:
	# two float targets, ping-pong: each frame one reads the other
	for k in 2:
		var vp = SubViewport.new()
		vp.size = Vector2i(W, H)
		vp.use_hdr_2d = true # RGBA16F: signed heights
		vp.transparent_bg = false
		vp.disable_3d = true
		vp.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		add_child(vp)
		var r = ColorRect.new()
		r.size = Vector2(W, H)
		var m = ShaderMaterial.new()
		m.shader = load("res://labs/water_lab/ripple_sim.gdshader")
		m.set_shader_parameter("grid", Vector2(W, H))
		m.set_shader_parameter("damp", DAMP)
		r.material = m
		vp.add_child(r)
		sim_vps.append(vp)
		sim_mats.append(m)
	sim_mats[0].set_shader_parameter("state", sim_vps[1].get_texture())
	sim_mats[1].set_shader_parameter("state", sim_vps[0].get_texture())
	sim_vps[1].render_target_update_mode = SubViewport.UPDATE_ONCE # start from zero

func _gpu_step() -> void:
	# write the target that holds the older state, reading the newer one
	sim_i = 1 - sim_i
	var m = sim_mats[sim_i]
	var arr = PackedVector4Array()
	for d in pending.slice(0, 8):
		arr.append(d)
	while arr.size() < 8:
		arr.append(Vector4.ZERO)
	m.set_shader_parameter("drops", arr)
	m.set_shader_parameter("n_drops", mini(pending.size(), 8))
	pending = pending.slice(8)
	sim_vps[sim_i].render_target_update_mode = SubViewport.UPDATE_ONCE
	tex = sim_vps[sim_i].get_texture()
	mat.set_shader_parameter("height_tex", tex)
	for cm in caus_mats:
		cm.set_shader_parameter("height_tex", tex)
	if surf_mat:
		surf_mat.set_shader_parameter("height_tex", tex)

func _build_caustics(vsz: Vector2) -> void:
	# half-resolution HDR caustics target (a full-res one showed hatching at the folds), ray grid ~1.5 px, redrawn every frame (additive ray grid)
	caus_vp = SubViewport.new()
	var cs = Vector2i(int(vsz.x * 0.5), int(vsz.y * 0.5))
	caus_vp.size = cs
	caus_vp.transparent_bg = false
	caus_vp.use_hdr_2d = false # HDR kept fold spikes that read as speckle; 8-bit clips them softly
	caus_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	caus_vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	add_child(caus_vp)
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(cs)
	caus_vp.add_child(bg)
	# ray grid, ~1.6 px per cell, overscanned so edges stay lit after refraction
	var gx = int(cs.x / 1.5)
	var gy = int(cs.y / 1.5)
	var over = 0.06
	var verts = PackedVector2Array()
	var idx = PackedInt32Array()
	for j in gy + 1:
		for i in gx + 1:
			verts.append(Vector2((-over + (1.0 + 2.0 * over) * i / gx) * cs.x, (-over + (1.0 + 2.0 * over) * j / gy) * cs.y))
	for j in gy:
		for i in gx:
			var a = j * (gx + 1) + i
			idx.append_array([a, a + 1, a + gx + 1, a + 1, a + gx + 2, a + gx + 1])
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var sh = load("res://labs/water_lab/caustics.gdshader")
	var masks = [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)]
	for c in 3:
		var mi = MeshInstance2D.new()
		mi.mesh = mesh
		var m = ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("height_tex", tex)
		m.set_shader_parameter("grid", Vector2(W, H))
		m.set_shader_parameter("mask", masks[c])
		m.set_shader_parameter("ior_k", 1.0 + (c - 1) * 0.06 * settings.chroma)
		m.set_shader_parameter("vp_size", Vector2(cs))
		m.set_shader_parameter("depth", settings.depth)
		m.set_shader_parameter("wind", settings.wind)
		m.set_shader_parameter("gain", 0.5)
		m.set_shader_parameter("focus", 0.92) # lower focus = fewer ray folds (folds alias into sawtooth)
		mi.material = m
		caus_vp.add_child(mi)
		caus_mats.append(m)

func drop_at(uv: Vector2, amt: float, r: float = 2.6) -> void:
	_drop(uv, amt, r)

func _drop(uv: Vector2, amt: float, r: float = 3.2) -> void:
	if use_gpu:
		pending.append(Vector4(uv.x, uv.y, amt, r))
		return
	var cx = uv.x * W
	var cy = uv.y * H
	var ri = int(ceil(r * 2.0))
	for y in range(max(1, int(cy) - ri), min(H - 1, int(cy) + ri + 1)):
		for x in range(max(1, int(cx) - ri), min(W - 1, int(cx) + ri + 1)):
			var d2 = (x - cx) * (x - cx) + (y - cy) * (y - cy)
			var g = exp(-d2 / (r * r))
			cur[y * W + x] -= amt * g

func _step() -> void:
	var nxt := prev
	for y in range(1, H - 1):
		var row = y * W
		for x in range(1, W - 1):
			var i = row + x
			nxt[i] = ((cur[i - 1] + cur[i + 1] + cur[i - W] + cur[i + W]) * 0.5 - prev[i]) * DAMP
	prev = cur
	cur = nxt

func _process(delta: float) -> void:
	var us0 = Time.get_ticks_usec()
	t += delta
	drop_acc += delta * settings.drops
	while drop_acc >= 1.0:
		drop_acc -= 1.0
		_drop(Vector2(rng.randf_range(0.1, 0.9), rng.randf_range(0.08, 0.92)), rng.randf_range(0.15, 0.35), rng.randf_range(1.6, 2.6))
	if use_gpu:
		_gpu_step()
	else:
		_step()
		_step()
		img.set_data(W, H, false, Image.FORMAT_RF, cur.to_byte_array())
		tex.update(img)
	frame_i += 1
	if caus_every > 1 and caus_vp:
		caus_vp.render_target_update_mode = SubViewport.UPDATE_ONCE if frame_i % caus_every == 0 else SubViewport.UPDATE_DISABLED
	mat.set_shader_parameter("time", t)
	for m in caus_mats:
		m.set_shader_parameter("time", t)
	if surf_mat:
		surf_mat.set_shader_parameter("time", t)
	proc_us += Time.get_ticks_usec() - us0

func _input(e: InputEvent) -> void:
	var vs = get_viewport().get_visible_rect().size
	if e is InputEventScreenTouch or e is InputEventMouseButton:
		dragging = e.pressed
		if e.pressed:
			# in the pond a tap is a pellet plop, not a stone: smaller, softer ring
			if has_meta("embedded"):
				_drop(e.position / vs, 0.28, 2.2)
			else:
				_drop(e.position / vs, 0.6, 3.0)
	elif (e is InputEventScreenDrag or e is InputEventMouseMotion) and dragging:
		_drop(e.position / vs, 0.35, 2.6)
