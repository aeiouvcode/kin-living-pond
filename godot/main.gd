extends Node2D
## KIN: a living koi pond. Local-first; nothing leaves the device.

const KoiScript = preload("res://koi.gd")
const FishDraw = preload("res://fish_draw.gd")
const SAVE_PATH = "user://kin_save.json"
const MAX_IMP = 24
const NAMES = ["Mochi", "Hana", "Kinako", "Sora", "Yuzu", "Ume", "Tora", "Kiku", "Nami"]

var vis = Vector2(390, 844)
var aspect = 0.462
var grid = Vector2i(90, 195)
var time = 0.0

var sim_a: SubViewport
var sim_b: SubViewport
var mat_a: ShaderMaterial
var mat_b: ShaderMaterial
var rect_a: ColorRect
var rect_b: ColorRect
var parity = 0
var reset_frames = 3
var impulses: Array[Vector4] = []

var under_vp: SubViewport
var floor_rect: ColorRect
var floor_mat: ShaderMaterial
var shadow_layer: Node2D
var fish_layer: Node2D
var comp_rect: ColorRect
var comp_mat: ShaderMaterial
var surface: Node2D
var shadow_mat: ShaderMaterial

var fishes: Array = []
var pellets: Array = []
var pads: Array = []
var petals: Array = []

# Touch state
var touch_down = false
var touch_start = Vector2.ZERO
var touch_pos = Vector2.ZERO
var touch_t0 = 0.0
var touch_moved = 0.0
var last_tap_t = -10.0
var last_tap_pos = Vector2.ZERO
var hold_active = false
var hold_pos = Vector2.ZERO
var food_cd = 0.0

# Tags and UI
var tag_fish = null
var tag_t = 0.0
var ui: CanvasLayer
var name_label: Label
var sub_label: Label
var toast: Label
var toast_t = 0.0
var toast_queue: Array = []
var card: PanelContainer
var name_edit: LineEdit
var card_body: Label

# Save data
var pond_name = ""
var streak = 1
var visits = 1
var lotus = 0
var dirty = false
var save_t = 0.0

class Pellet:
	var pos = Vector2.ZERO
	var vel = Vector2.ZERO
	var life = 14.0
	var alive = true

class SurfaceDraw extends Node2D:
	var pond
	func _draw() -> void:
		pond.draw_surface(self)

class PadShadowDraw extends Node2D:
	var pond
	func _draw() -> void:
		pond.draw_pad_shadows(self)

func _ready() -> void:
	randomize()
	_measure()
	_build_sim()
	_build_under()
	_build_composite()
	_build_pads()
	_load()
	_build_fish()
	_build_ui()
	get_viewport().size_changed.connect(_on_resize)
	# Instant-alive: let the fish settle into motion before the first frame.
	for _i in 90:
		for f in fishes:
			f.update(1.0 / 30.0, self, fishes)
	impulses.clear()
	_greet()

func _measure() -> void:
	vis = get_viewport().get_visible_rect().size
	aspect = vis.x / vis.y
	var cell = 4.4
	grid = Vector2i(maxi(16, int(vis.x / cell)), maxi(16, int(vis.y / cell)))

func _mk_sim_vp() -> Array:
	var vp = SubViewport.new()
	vp.size = grid
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	add_child(vp)
	var r = ColorRect.new()
	r.size = Vector2(grid)
	var m = ShaderMaterial.new()
	m.shader = preload("res://shaders/sim.gdshader")
	r.material = m
	vp.add_child(r)
	return [vp, r, m]

func _build_sim() -> void:
	var a = _mk_sim_vp()
	var b = _mk_sim_vp()
	sim_a = a[0]; rect_a = a[1]; mat_a = a[2]
	sim_b = b[0]; rect_b = b[1]; mat_b = b[2]
	mat_a.set_shader_parameter("prev", sim_b.get_texture())
	mat_b.set_shader_parameter("prev", sim_a.get_texture())
	_sim_params()

func _sim_params() -> void:
	for m in [mat_a, mat_b]:
		m.set_shader_parameter("grid", Vector2(grid))
		m.set_shader_parameter("aspect", aspect)

func _render_scale() -> float:
	var win = Vector2(DisplayServer.window_get_size())
	var s = win.x / maxf(vis.x, 1.0)
	return clampf(s * 0.8, 1.0, 2.0)

func _build_under() -> void:
	under_vp = SubViewport.new()
	under_vp.disable_3d = true
	under_vp.transparent_bg = false
	under_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(under_vp)
	floor_rect = ColorRect.new()
	floor_mat = ShaderMaterial.new()
	floor_mat.shader = preload("res://shaders/floor.gdshader")
	floor_rect.material = floor_mat
	under_vp.add_child(floor_rect)
	shadow_layer = Node2D.new()
	under_vp.add_child(shadow_layer)
	var ps = PadShadowDraw.new()
	ps.pond = self
	shadow_layer.add_child(ps)
	fish_layer = Node2D.new()
	under_vp.add_child(fish_layer)
	shadow_mat = ShaderMaterial.new()
	shadow_mat.shader = preload("res://shaders/shadow.gdshader")
	_size_under()

func _size_under() -> void:
	var s = _render_scale()
	under_vp.size = Vector2i(int(vis.x * s), int(vis.y * s))
	under_vp.size_2d_override = Vector2i(int(vis.x), int(vis.y))
	under_vp.size_2d_override_stretch = true
	floor_rect.size = vis
	floor_mat.set_shader_parameter("aspect", aspect)

func _build_composite() -> void:
	comp_rect = ColorRect.new()
	comp_mat = ShaderMaterial.new()
	comp_mat.shader = preload("res://shaders/composite.gdshader")
	comp_rect.material = comp_mat
	comp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(comp_rect)
	comp_mat.set_shader_parameter("under", under_vp.get_texture())
	surface = SurfaceDraw.new()
	surface.pond = self
	add_child(surface)
	_comp_params()

func _comp_params() -> void:
	comp_rect.size = vis
	comp_mat.set_shader_parameter("grid", Vector2(grid))
	comp_mat.set_shader_parameter("aspect", aspect)
	comp_mat.set_shader_parameter("px_h", 1.0 / vis.y)

func _on_resize() -> void:
	var old = grid
	_measure()
	if old != grid:
		sim_a.size = grid
		sim_b.size = grid
		rect_a.size = Vector2(grid)
		rect_b.size = Vector2(grid)
		reset_frames = 3
	_sim_params()
	_size_under()
	_comp_params()
	_build_pads()
	for f in fishes:
		if cpu_sdf(f.pos) > -0.05:
			f.setup(vis * 0.5 + Vector2(randf_range(-40, 40), randf_range(-80, 80)), randf() * TAU)
	_layout_ui()

# ---------- Pond geometry on the CPU (mirrors the shader without noise) ----------

func _pp(p: Vector2) -> Vector2:
	return (p / vis - Vector2(0.5, 0.5)) * Vector2(aspect, 1.0)

func cpu_sdf(p: Vector2) -> float:
	var q = _pp(p)
	var b = Vector2(aspect * 0.5 - 0.018, 0.5 - 0.06)
	var r = minf(0.12, b.x * 0.6)
	var d = Vector2(absf(q.x), absf(q.y)) - b + Vector2(r, r)
	return Vector2(maxf(d.x, 0.0), maxf(d.y, 0.0)).length() + minf(maxf(d.x, d.y), 0.0) - r + 0.022

func inward(p: Vector2) -> Vector2:
	var e = 2.0
	var g = Vector2(cpu_sdf(p + Vector2(e, 0)) - cpu_sdf(p - Vector2(e, 0)), cpu_sdf(p + Vector2(0, e)) - cpu_sdf(p - Vector2(0, e)))
	if g.length() < 1e-6:
		return (vis * 0.5 - p).normalized()
	return -g.normalized()

# ---------- Fish ----------

func _variety(i: int) -> Dictionary:
	var cream = Color(0.95, 0.92, 0.86)
	var red = Color(0.84, 0.19, 0.07)
	var ink = Color(0.05, 0.05, 0.06)
	var list = [
		{"v": "kohaku", "base": cream, "patch": red, "pa": 0.5, "ink": 0.0, "met": 0.0, "fin": 0.0, "tancho": 0.0},
		{"v": "tancho", "base": cream, "patch": red, "pa": 0.0, "ink": 0.0, "met": 0.1, "fin": 0.0, "tancho": 1.0},
		{"v": "chagoi", "base": Color(0.58, 0.42, 0.26), "patch": Color(0.5, 0.35, 0.2), "pa": 0.0, "ink": 0.0, "met": 0.35, "fin": 1.0, "tancho": 0.0},
		{"v": "sanke", "base": cream, "patch": red, "pa": 0.45, "ink": 0.2, "met": 0.0, "fin": 0.0, "tancho": 0.0},
		{"v": "yamabuki", "base": Color(0.98, 0.8, 0.36), "patch": Color(0.98, 0.8, 0.36), "pa": 0.0, "ink": 0.0, "met": 0.85, "fin": 1.0, "tancho": 0.0},
		{"v": "showa", "base": cream, "patch": red, "pa": 0.34, "ink": 0.45, "met": 0.0, "fin": 0.2, "tancho": 0.0},
		{"v": "benigoi", "base": Color(0.9, 0.33, 0.11), "patch": Color(0.9, 0.33, 0.11), "pa": 0.0, "ink": 0.0, "met": 0.1, "fin": 1.0, "tancho": 0.0},
		{"v": "asagi", "base": Color(0.56, 0.63, 0.69), "patch": Color(0.86, 0.42, 0.2), "pa": 0.22, "ink": 0.0, "met": 0.15, "fin": 0.6, "tancho": 0.0},
		{"v": "ogon", "base": Color(0.93, 0.86, 0.72), "patch": Color(0.93, 0.86, 0.72), "pa": 0.0, "ink": 0.0, "met": 1.0, "fin": 0.0, "tancho": 0.0},
	]
	return list[i % list.size()]

func _build_fish() -> void:
	var saved: Array = _save_fish
	for i in NAMES.size():
		var f = KoiScript.new()
		f.idx = i
		f.name = NAMES[i]
		var v = _variety(i)
		f.variety = v.v
		f.length = randf_range(114.0, 154.0) * clampf(vis.x / 390.0, 0.95, 2.1)
		if v.v == "chagoi":
			f.length *= 1.12
		f.width = f.length * randf_range(0.13, 0.148)
		f.pace = randf_range(0.8, 1.2)
		f.boldness = randf_range(0.2, 0.75)
		f.social = randf_range(0.2, 0.8)
		f.laziness = randf_range(0.1, 0.6)
		f.pref_depth = randf_range(0.25, 0.7)
		if v.v == "chagoi":
			f.boldness = 0.95
			f.social = 0.8
		elif v.v == "tancho":
			f.boldness = 0.15
		f.home = Vector2(randf_range(0.25, 0.75) * vis.x, randf_range(0.2, 0.8) * vis.y)
		if i < saved.size():
			var s: Dictionary = saved[i]
			f.bond = clampf(float(s.get("bond", 0.0)), 0.0, 100.0)
			var nm = _clean_name(str(s.get("name", f.name)), 14)
			if nm != "":
				f.name = nm
		var start = Vector2(randf_range(0.2, 0.8) * vis.x, randf_range(0.18, 0.82) * vis.y)
		f.setup(start, randf() * TAU)
		f.depth = f.pref_depth
		f.mat = ShaderMaterial.new()
		f.mat.shader = preload("res://shaders/koi.gdshader")
		f.mat.set_shader_parameter("seed", randf() * 10.0 + i)
		f.mat.set_shader_parameter("base_col", v.base)
		f.mat.set_shader_parameter("patch_col", v.patch)
		f.mat.set_shader_parameter("patch_amt", v.pa)
		f.mat.set_shader_parameter("ink_amt", v.ink)
		f.mat.set_shader_parameter("metallic", v.met)
		f.mat.set_shader_parameter("fin_tint", v.fin)
		f.mat.set_shader_parameter("tancho", v.tancho)
		var body = FishDraw.new()
		body.fish = f
		body.material = f.mat
		fish_layer.add_child(body)
		var sh = FishDraw.new()
		sh.fish = f
		sh.mode = 1
		sh.material = shadow_mat
		shadow_layer.add_child(sh)
		f.body_node = body
		f.shadow_node = sh
		fishes.append(f)

# ---------- Water ----------

func add_ripple(p: Vector2, strength: float, radius_cells: float) -> void:
	if impulses.size() >= MAX_IMP:
		return
	var c = p / vis * Vector2(grid)
	impulses.append(Vector4(c.x, c.y, radius_cells, strength))

func _step_sim() -> void:
	var m = mat_a if parity == 0 else mat_b
	var vp = sim_a if parity == 0 else sim_b
	var arr: Array[Vector4] = []
	for i in MAX_IMP:
		arr.append(impulses[i] if i < impulses.size() else Vector4.ZERO)
	m.set_shader_parameter("imp", arr)
	m.set_shader_parameter("imp_count", impulses.size())
	m.set_shader_parameter("reset", reset_frames > 0)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	comp_mat.set_shader_parameter("sim", vp.get_texture())
	impulses.clear()
	parity = 1 - parity
	if reset_frames > 0:
		reset_frames -= 1

# ---------- Food ----------

func nearest_pellet(p: Vector2, radius: float):
	var best = null
	var bd = radius
	for pl in pellets:
		if not pl.alive:
			continue
		var d: float = p.distance_to(pl.pos)
		if d < bd:
			bd = d
			best = pl
	return best

func pellet_alive(pl) -> bool:
	return pl.alive

func eat_pellet(pl, f) -> bool:
	if not pl.alive:
		return false
	pl.alive = false
	add_ripple(pl.pos, -0.3, 1.8)
	dirty = true
	_check_lotus()
	return true

func _drop_food(p: Vector2) -> void:
	for i in 3:
		var pl = Pellet.new()
		pl.pos = p + Vector2(randf_range(-14, 14), randf_range(-14, 14))
		pl.vel = Vector2(randf_range(-4, 4), randf_range(-4, 4))
		pellets.append(pl)

# ---------- Progression ----------

func harmony() -> float:
	var s = 0.0
	for f in fishes:
		s += f.bond
	return s

func _check_lotus() -> void:
	var want = mini(pads.size(), int(harmony() / 45.0))
	if want > lotus:
		lotus = want
		dirty = true
		_toast("A lotus opened")

func on_nuzzle(f) -> void:
	dirty = true
	if f.bond_level() >= 3 and randf() < 0.3:
		_toast(f.name + " trusts you")
	_check_lotus()

# ---------- Input ----------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.index != 0:
			return
		if event.pressed:
			touch_down = true
			touch_start = event.position
			touch_pos = event.position
			touch_t0 = time
			touch_moved = 0.0
			add_ripple(event.position, -0.12, 1.6)
		else:
			touch_down = false
			var dur = time - touch_t0
			if hold_active:
				hold_active = false
			elif dur < 0.3 and touch_moved < 14.0:
				_tap(event.position)
	elif event is InputEventScreenDrag:
		if event.index != 0:
			return
		var d: Vector2 = event.position - touch_pos
		touch_moved += d.length()
		touch_pos = event.position
		if hold_active:
			hold_pos = touch_pos
		var sp = clampf(d.length() / 8.0, 0.2, 1.6)
		add_ripple(touch_pos, -0.07 * sp, 1.7)
		if d.length() > 22.0:
			for f in fishes:
				if f.pos.distance_to(touch_pos) < 90.0 and f.bond_level() < 2:
					f.startle_from = touch_pos
					f.set_state(KoiScript.S.STARTLE, 0.8)

func _tap(p: Vector2) -> void:
	if time - last_tap_t < 0.32 and p.distance_to(last_tap_pos) < 50.0:
		last_tap_t = -10.0
		add_ripple(p, -0.9, 2.6)
		for f in fishes:
			if f.pos.distance_to(p) < 220.0:
				f.startle_from = p
				f.set_state(KoiScript.S.STARTLE, 1.1 + randf() * 0.5)
		return
	last_tap_t = time
	last_tap_pos = p
	var hit = _fish_at(p)
	if hit != null:
		tag_fish = hit
		tag_t = 3.2
		add_ripple(p, -0.15, 1.5)
		return
	add_ripple(p, -0.45, 2.0)
	if food_cd <= 0.0 and cpu_sdf(p) < -0.01:
		_drop_food(p)
		food_cd = 0.6

func _fish_at(p: Vector2):
	var best = null
	var bd = 9999.0
	for f in fishes:
		var c: Vector2 = f.spine[4]
		var d: float = p.distance_to(c)
		if d < f.length * 0.45 and d < bd:
			bd = d
			best = f
	return best

# ---------- Frame ----------

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	time += dt
	food_cd -= dt
	if touch_down and not hold_active and time - touch_t0 > 0.45 and touch_moved < 16.0:
		hold_active = true
		hold_pos = touch_pos
	if hold_active and fmod(time, 0.5) < dt:
		add_ripple(hold_pos, -0.05, 1.4)
	for f in fishes:
		f.update(dt, self, fishes)
	for pl in pellets:
		if not pl.alive:
			continue
		pl.life -= dt
		pl.pos += pl.vel * dt + Vector2(sin(time * 0.7 + pl.pos.y * 0.02), cos(time * 0.5 + pl.pos.x * 0.02)) * 2.0 * dt
		pl.vel *= 0.98
		if pl.life <= 0.0:
			pl.alive = false
	pellets = pellets.filter(func(x): return x.alive)
	_update_petals(dt)
	# Draw order by depth; deeper fish first.
	var sorted = fishes.duplicate()
	sorted.sort_custom(func(a, b): return a.depth > b.depth)
	for i in sorted.size():
		var f = sorted[i]
		f.build_mesh()
		f.body_node.z_index = i
		f.mat.set_shader_parameter("depth", f.depth)
		f.mat.set_shader_parameter("heading", f.heading)
		f.mat.set_shader_parameter("glow", f.glow)
		var off: Vector2 = Vector2(0.55, 0.83) * (5.0 + 24.0 * (1.0 - f.depth))
		f.shadow_node.position = off
		f.shadow_node.modulate.a = 0.42 + 0.36 * f.depth
		f.body_node.queue_redraw()
		f.shadow_node.queue_redraw()
	floor_mat.set_shader_parameter("time", time)
	comp_mat.set_shader_parameter("time", time)
	_step_sim()
	surface.queue_redraw()
	shadow_layer.get_child(0).queue_redraw()
	tag_t -= dt
	_ui_tick(dt)
	save_t += dt
	if dirty and save_t > 4.0:
		_save()

# ---------- Surface: lily pads, lotus, food, petals, tags ----------

func _build_pads() -> void:
	pads.clear()
	var s = clampf(vis.x / 390.0, 0.9, 1.6)
	var spots = [Vector2(0.14, 0.2), Vector2(0.86, 0.33), Vector2(0.1, 0.62), Vector2(0.82, 0.8), Vector2(0.3, 0.88), Vector2(0.74, 0.14)]
	var rs = [34.0, 28.0, 38.0, 31.0, 24.0, 22.0]
	for i in spots.size():
		pads.append({"pos": spots[i] * vis, "r": rs[i] * s, "rot": randf() * TAU, "notch": randf() * TAU, "ph": randf() * TAU})

func _pad_poly(c: Vector2, r: float, notch: float) -> PackedVector2Array:
	var poly = PackedVector2Array()
	poly.append(c)
	var n = 40
	for k in n + 1:
		var a = notch + 0.2 + (TAU - 0.4) * float(k) / float(n)
		var rr = r * (1.0 + 0.03 * sin(a * 5.0 + notch))
		poly.append(c + Vector2.from_angle(a) * rr)
	return poly

func draw_pad_shadows(ci: CanvasItem) -> void:
	for p in pads:
		var c: Vector2 = p.pos + Vector2(0.55, 0.83) * 20.0
		for k in 3:
			ci.draw_colored_polygon(_pad_poly(c, p.r * (1.08 + 0.1 * k), p.notch + p.rot * 0.0), Color(0, 0.01, 0.015, 0.16))

func draw_surface(ci: CanvasItem) -> void:
	for i in pads.size():
		var p: Dictionary = pads[i]
		var bob: Vector2 = Vector2(sin(time * 0.3 + p.ph), cos(time * 0.23 + p.ph)) * 1.5
		var c: Vector2 = p.pos + bob
		var notch: float = p.notch + sin(time * 0.1 + p.ph) * 0.08
		var r: float = p.r
		_draw_pad(ci, c, r, notch)
		if i < lotus:
			_draw_lotus(ci, c + Vector2.from_angle(notch + PI) * r * 0.25, r * 0.55)
	for pl in pellets:
		var a: float = clampf(pl.life / 2.0, 0.0, 1.0)
		ci.draw_circle(pl.pos + Vector2(1.2, 1.8), 3.2, Color(0, 0, 0, 0.25 * a))
		ci.draw_circle(pl.pos, 3.0, Color(0.55, 0.33, 0.16, a))
		ci.draw_circle(pl.pos + Vector2(-0.9, -0.9), 1.1, Color(0.95, 0.8, 0.6, 0.8 * a))
	for pt in petals:
		var col = Color(0.97, 0.8, 0.84, 0.9)
		var d: Vector2 = Vector2.from_angle(pt.rot)
		var poly = PackedVector2Array([pt.pos + d * 5.0, pt.pos + d.orthogonal() * 2.6, pt.pos - d * 4.0, pt.pos - d.orthogonal() * 2.6])
		ci.draw_colored_polygon(poly, col)
	if hold_active:
		var pulse = 0.5 + 0.5 * sin(time * 3.0)
		ci.draw_arc(hold_pos, 18.0 + 4.0 * pulse, 0.0, TAU, 40, Color(1, 0.96, 0.88, 0.35), 1.5, true)
	if tag_fish != null and tag_t > 0.0:
		var f = tag_fish
		var a2: float = clampf(tag_t, 0.0, 1.0)
		var at: Vector2 = f.spine[4] + Vector2(0, -f.width * 2.6 - 16.0)
		at.x = clampf(at.x, 70.0, vis.x - 70.0)
		at.y = clampf(at.y, 40.0, vis.y - 40.0)
		var font = ThemeDB.fallback_font
		var txt: String = f.name
		var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		var w = maxf(tw, 5.0 * 12.0) + 24.0
		var box = Rect2(at - Vector2(w * 0.5, 22.0), Vector2(w, 40.0))
		ci.draw_rect(box, Color(0.96, 0.93, 0.86, 0.9 * a2))
		ci.draw_string(font, Vector2(box.position.x, box.position.y + 17.0), txt, HORIZONTAL_ALIGNMENT_CENTER, w, 14, Color(0.1, 0.15, 0.15, a2))
		var lvl: int = f.bond_level()
		for k in 5:
			var hc = box.position + Vector2(w * 0.5 - 24.0 + 12.0 * k, 29.0)
			_heart(ci, hc, 4.2, Color(0.8, 0.27, 0.2, a2) if k < lvl else Color(0.5, 0.5, 0.48, 0.45 * a2))

func _draw_pad(ci: CanvasItem, c: Vector2, r: float, notch: float) -> void:
	var poly = _pad_poly(c, r, notch)
	var cols = PackedColorArray()
	var ld = Vector2(-0.55, -0.83)
	for k in poly.size():
		if k == 0:
			cols.append(Color(0.36, 0.5, 0.2))
		else:
			var dirv = (poly[k] - c).normalized()
			var lit = dirv.dot(ld)
			cols.append(Color(0.12, 0.25, 0.1).lerp(Color(0.24, 0.4, 0.16), 0.5 + 0.5 * lit))
	ci.draw_polygon(poly, cols)
	for k in 11:
		var a = notch + 0.3 + (TAU - 0.6) * float(k) / 10.0
		var e = c + Vector2.from_angle(a) * r * 0.9
		ci.draw_line(c, e, Color(0.42, 0.56, 0.26, 0.35), 1.0, true)
	# Upturned rim: lit on the light side, shaded on the far side.
	ci.draw_arc(c, r * 0.97, notch + 0.2, notch + TAU - 0.2, 48, Color(0.1, 0.2, 0.08, 0.6), 1.6, true)
	var la = ld.angle()
	ci.draw_arc(c, r * 0.95, la - 1.1, la + 1.1, 24, Color(0.62, 0.74, 0.42, 0.55), 1.3, true)
	# Waxy sheen.
	ci.draw_circle(c + ld * r * 0.35, r * 0.28, Color(0.8, 0.9, 0.7, 0.07))
	ci.draw_circle(c + ld * r * 0.4, r * 0.14, Color(0.9, 0.95, 0.8, 0.08))

func _heart(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-s * 0.5, -s * 0.2), s * 0.55, col)
	ci.draw_circle(c + Vector2(s * 0.5, -s * 0.2), s * 0.55, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.02, 0.0), c + Vector2(s * 1.02, 0.0), c + Vector2(0, s * 1.05)]), col)

func _draw_lotus(ci: CanvasItem, c: Vector2, r: float) -> void:
	for layer in 2:
		var n = 8
		var rr = r * (1.0 - 0.3 * layer)
		for k in n:
			var a = TAU * float(k) / float(n) + layer * 0.4 + sin(time * 0.2) * 0.03
			var d = Vector2.from_angle(a)
			var tip = c + d * rr
			var poly = PackedVector2Array([c + d.orthogonal() * rr * 0.22, tip, c - d.orthogonal() * rr * 0.22])
			var col = Color(0.96, 0.78, 0.82) if layer == 0 else Color(0.99, 0.9, 0.9)
			ci.draw_colored_polygon(poly, col)
			ci.draw_line(c, tip, Color(0.85, 0.5, 0.6, 0.6), 1.0, true)
	ci.draw_circle(c, r * 0.18, Color(0.95, 0.8, 0.3))

func _update_petals(dt: float) -> void:
	if petals.size() < 5 and randf() < dt * 0.08:
		petals.append({"pos": Vector2(randf() * vis.x, -6.0), "rot": randf() * TAU, "v": Vector2(randf_range(-4, 4), randf_range(5, 10))})
	for pt in petals:
		pt.pos += pt.v * dt
		pt.rot += dt * 0.2
	petals = petals.filter(func(x): return x.pos.y < vis.y + 10.0)

# ---------- UI ----------

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.84))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	ui.add_child(name_label)
	sub_label = Label.new()
	sub_label.add_theme_font_size_override("font_size", 12)
	sub_label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.78, 0.9))
	sub_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	sub_label.add_theme_constant_override("shadow_offset_y", 1)
	ui.add_child(sub_label)
	toast = Label.new()
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 14)
	toast.add_theme_color_override("font_color", Color(0.97, 0.94, 0.86))
	toast.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	toast.add_theme_constant_override("shadow_offset_y", 1)
	toast.modulate.a = 0.0
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(toast)
	if pond_name == "":
		_build_card()
	_layout_ui()
	_refresh_labels()

func _build_card() -> void:
	card = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.96, 0.94, 0.88, 0.94)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 18
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 12
	card.add_theme_stylebox_override("panel", sb)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)
	var eyebrow = Label.new()
	eyebrow.text = "A SMALL BEGINNING"
	eyebrow.add_theme_font_size_override("font_size", 11)
	eyebrow.add_theme_color_override("font_color", Color(0.72, 0.28, 0.18))
	vb.add_child(eyebrow)
	var title = Label.new()
	title.text = "Name your pond"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.1, 0.17, 0.17))
	vb.add_child(title)
	var body = Label.new()
	body.text = "Nine koi live here. Feed them,\nand they will learn to trust you."
	card_body = body
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color(0.3, 0.36, 0.35))
	vb.add_child(body)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	name_edit = LineEdit.new()
	name_edit.text = "Still Water"
	name_edit.max_length = 24
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.custom_minimum_size = Vector2(0, 44)
	name_edit.add_theme_font_size_override("font_size", 16)
	name_edit.add_theme_color_override("font_color", Color(0.1, 0.17, 0.17))
	var le = StyleBoxFlat.new()
	le.bg_color = Color(1, 1, 1, 0.6)
	le.set_corner_radius_all(8)
	le.content_margin_left = 10
	le.border_width_bottom = 2
	le.border_color = Color(0.1, 0.2, 0.2, 0.4)
	name_edit.add_theme_stylebox_override("normal", le)
	name_edit.add_theme_stylebox_override("focus", le)
	name_edit.text_submitted.connect(func(_t): _begin())
	hb.add_child(name_edit)
	var btn = Button.new()
	btn.text = "Begin"
	btn.custom_minimum_size = Vector2(88, 44)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.1, 0.2, 0.2)
	bs.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", bs)
	btn.add_theme_stylebox_override("hover", bs)
	btn.add_theme_stylebox_override("pressed", bs)
	btn.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(_begin)
	hb.add_child(btn)
	ui.add_child(card)

func _begin() -> void:
	var nm = _clean_name(name_edit.text, 24)
	pond_name = nm if nm != "" else "Still Water"
	card.queue_free()
	card = null
	dirty = true
	_save()
	_refresh_labels()
	_toast("Tap the water to feed")
	_toast("Drag a finger to stir it")
	_toast("Hold still. The brave ones come close")

func _layout_ui() -> void:
	if name_label == null:
		return
	var safe = DisplayServer.get_display_safe_area()
	var top = 14.0
	var big = vis.x > 700.0
	name_label.add_theme_font_size_override("font_size", 24 if big else 17)
	sub_label.add_theme_font_size_override("font_size", 15 if big else 12)
	toast.add_theme_font_size_override("font_size", 18 if big else 14)
	name_label.position = Vector2(20, top)
	sub_label.position = Vector2(20, top + (31 if big else 23))
	toast.size = Vector2(vis.x - 40, 24)
	toast.position = Vector2(20, vis.y - 44)
	if card != null:
		var w = minf(vis.x - 32.0, 380.0)
		card.custom_minimum_size = Vector2(w, 0)
		card.size = Vector2(w, 0)
		card.reset_size()
		var h = card.get_combined_minimum_size().y
		card.size = Vector2(w, h)
		card.position = Vector2((vis.x - w) * 0.5, vis.y - h - 22.0)

func _refresh_labels() -> void:
	name_label.text = pond_name if pond_name != "" else "KIN"
	var parts = []
	parts.append("day %d" % streak if streak > 1 else "first day")
	if lotus > 0:
		parts.append("%d lotus" % lotus)
	sub_label.text = "  ·  ".join(parts)

func _toast(t: String) -> void:
	toast_queue.append(t)

func _ui_tick(dt: float) -> void:
	if toast_t > 0.0:
		toast_t -= dt
		toast.modulate.a = clampf(minf(toast_t, 3.6 - toast_t) * 2.0, 0.0, 1.0)
	elif toast_queue.size() > 0 and card == null:
		toast.text = toast_queue.pop_front()
		toast_t = 3.6
	else:
		toast.modulate.a = 0.0
	if dirty:
		_refresh_labels()

func _greet() -> void:
	if pond_name == "":
		return
	var best = fishes[0]
	for f in fishes:
		if f.bond > best.bond:
			best = f
	if best.bond >= 8.0:
		_toast(best.name + " swam up to say hello")
	else:
		_toast("Welcome back to " + pond_name)

# ---------- Persistence (local only) ----------

var _save_fish: Array = []

func _clean_name(s: String, max_len: int) -> String:
	var out = ""
	for ch in s:
		var c = ch.unicode_at(0)
		if c >= 32 and c != 127 and not (c >= 0x200B and c <= 0x200F) and not (c >= 0x202A and c <= 0x202E):
			out += ch
	return out.strip_edges().substr(0, max_len)

func _today() -> int:
	var bias = int(Time.get_time_zone_from_system().get("bias", 0))
	return int(floor((Time.get_unix_time_from_system() + bias * 60.0) / 86400.0))

func _load() -> void:
	var today = _today()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null or f.get_length() > 16384:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	pond_name = _clean_name(str(data.get("pond", "")), 24)
	var last = int(data.get("last_day", today))
	streak = clampi(int(data.get("streak", 1)), 1, 100000)
	visits = clampi(int(data.get("visits", 1)), 1, 1000000)
	lotus = clampi(int(data.get("lotus", 0)), 0, 6)
	var fl = data.get("fish", [])
	if typeof(fl) == TYPE_ARRAY:
		for e in fl.slice(0, NAMES.size()):
			if typeof(e) == TYPE_DICTIONARY:
				_save_fish.append(e)
	if today == last + 1:
		streak += 1
	elif today > last + 1:
		streak = 1
	if today != last:
		visits += 1
		for e in _save_fish:
			e["bond"] = clampf(float(e.get("bond", 0.0)) + 2.0, 0.0, 100.0)
	dirty = true

func _save() -> void:
	save_t = 0.0
	dirty = false
	if pond_name == "":
		return
	var fl = []
	for f in fishes:
		fl.append({"name": f.name, "bond": snappedf(f.bond, 0.1)})
	var data = {"v": 1, "pond": pond_name, "last_day": _today(), "streak": streak, "visits": visits, "lotus": lotus, "fish": fl}
	var fa = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if fa != null:
		fa.store_string(JSON.stringify(data))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if pond_name != "":
			_save()
