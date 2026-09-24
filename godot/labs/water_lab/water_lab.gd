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

var settings = {"floor": "pebble", "depth": 1.0, "chroma": 1.0, "glint": 1.0, "drops": 1.2, "wind": 1.0, "warm": 1.0, "bloom": 1.0, "refl": 1.0}
var cur := PackedFloat32Array()
var prev := PackedFloat32Array()
var img: Image
var tex: ImageTexture
var rect: ColorRect
var mat: ShaderMaterial
var caus_mats = []
var caus_vp: SubViewport
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
	W = int(round(sqrt(cells * vsz.x / vsz.y)))
	H = int(round(cells / W))
	cur.resize(W * H)
	prev.resize(W * H)
	img = Image.create_empty(W, H, false, Image.FORMAT_RF)
	tex = ImageTexture.create_from_image(img)
	_build_caustics(vsz)
	var layer = CanvasLayer.new()
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
	mat.set_shader_parameter("caus_tex", caus_vp.get_texture())
	rect.material = mat
	layer.add_child(rect)
	var tag = Label.new()
	tag.text = "water lab"
	tag.position = Vector2(18, 16)
	tag.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	tag.add_theme_font_size_override("font_size", 13)
	layer.add_child(tag)
	# a few opening drops so the first frame already has rings
	for i in 3:
		_drop(Vector2(rng.randf_range(0.2, 0.8), rng.randf_range(0.2, 0.8)), 0.35, 2.4)

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

func _drop(uv: Vector2, amt: float, r: float = 3.2) -> void:
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
	t += delta
	drop_acc += delta * settings.drops
	while drop_acc >= 1.0:
		drop_acc -= 1.0
		_drop(Vector2(rng.randf_range(0.1, 0.9), rng.randf_range(0.08, 0.92)), rng.randf_range(0.15, 0.35), rng.randf_range(1.6, 2.6))
	_step()
	_step()
	img.set_data(W, H, false, Image.FORMAT_RF, cur.to_byte_array())
	tex.update(img)
	mat.set_shader_parameter("time", t)
	for m in caus_mats:
		m.set_shader_parameter("time", t)

func _input(e: InputEvent) -> void:
	var vs = get_viewport().get_visible_rect().size
	if e is InputEventScreenTouch or e is InputEventMouseButton:
		dragging = e.pressed
		if e.pressed:
			_drop(e.position / vs, 0.6, 3.0)
	elif (e is InputEventScreenDrag or e is InputEventMouseMotion) and dragging:
		_drop(e.position / vs, 0.35, 2.6)
