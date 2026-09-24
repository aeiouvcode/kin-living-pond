extends Node2D
## KIN: two goldfish in a glass bowl. Local-first; nothing leaves the device.

const FishScript = preload("res://goldfish.gd")
const FishDraw = preload("res://fish_draw.gd")
const SAVE_PATH = "user://kin_bowl.json"
const MAX_IMP = 24

var vis = Vector2(390, 844)
var center = Vector2(195, 422)
var radius = 200.0
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
var impulses = []

var under_vp: SubViewport
var small_vp: SubViewport
var small_rect: TextureRect
var bg_rect: ColorRect
var bg_mat: ShaderMaterial
var fish_layer: Node2D
var comp_rect: ColorRect
var comp_mat: ShaderMaterial
var petal_mat: ShaderMaterial
var deep_petals: Node2D
var top_petals: Node2D
var surface: Node2D

var fishes = []
var pellets = []
var petals = []

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

var tag_fish = null
var tag_t = 0.0
var ui: CanvasLayer
var name_label: Label
var sub_label: Label
var toast: Label
var toast_t = 0.0
var toast_queue = []
var card: PanelContainer
var name_edit: LineEdit

var pond_name = ""
var streak = 1
var visits = 1
var blossoms = 0
var dirty = false
var save_t = 0.0
var _save_fish = []

class Pellet:
	var pos = Vector2.ZERO
	var vel = Vector2.ZERO
	var life = 16.0
	var alive = true

class PetalDraw extends Node2D:
	var pond
	var deep = false
	func _draw() -> void:
		pond.draw_petals(self, deep)

class SurfaceDraw extends Node2D:
	var pond
	func _draw() -> void:
		pond.draw_surface(self)

func _ready() -> void:
	randomize()
	_measure()
	_build_sim()
	_build_under()
	_build_composite()
	_load()
	_build_fish()
	_seed_petals()
	_build_ui()
	get_viewport().size_changed.connect(_on_resize)
	for _i in 120:
		for f in fishes:
			f.update(1.0 / 30.0, self, fishes)
	impulses.clear()
	_greet()

func _measure() -> void:
	vis = get_viewport().get_visible_rect().size
	center = vis * 0.5
	# Landscape: frame the bowl closer, like the reference's macro shot; the
	# rim runs just past the top and bottom edges.
	radius = minf(vis.x, vis.y) * 0.5 * (1.12 if vis.x > vis.y * 1.2 else 1.0)
	if vis.y > vis.x * 1.3:
		radius = vis.x * 0.5 * 1.3
	grid = Vector2i(maxi(16, int(vis.x / 4.4)), maxi(16, int(vis.y / 4.4)))

func _fish_scale() -> float:
	return clampf(radius / 218.0, 0.9, 2.6) * 1.4

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
	m.shader = preload("res://shaders/sim_bowl.gdshader")
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
	for m in [mat_a, mat_b]:
		m.set_shader_parameter("grid", Vector2(grid))

func _render_scale() -> float:
	var win = Vector2(DisplayServer.window_get_size())
	return clampf(win.x / maxf(vis.x, 1.0) * 0.8, 1.0, 2.0)

func _build_under() -> void:
	under_vp = SubViewport.new()
	under_vp.disable_3d = true
	under_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(under_vp)
	bg_rect = ColorRect.new()
	bg_mat = ShaderMaterial.new()
	bg_mat.shader = preload("res://shaders/bowl_bg.gdshader")
	bg_rect.material = bg_mat
	under_vp.add_child(bg_rect)
	petal_mat = ShaderMaterial.new()
	petal_mat.shader = preload("res://shaders/petal.gdshader")
	deep_petals = PetalDraw.new()
	deep_petals.pond = self
	deep_petals.deep = true
	deep_petals.material = petal_mat
	under_vp.add_child(deep_petals)
	fish_layer = Node2D.new()
	under_vp.add_child(fish_layer)
	small_vp = SubViewport.new()
	small_vp.disable_3d = true
	small_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(small_vp)
	small_rect = TextureRect.new()
	small_rect.texture = under_vp.get_texture()
	small_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	small_rect.stretch_mode = TextureRect.STRETCH_SCALE
	small_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	small_vp.add_child(small_rect)
	_size_under()

func _size_under() -> void:
	var s = _render_scale()
	under_vp.size = Vector2i(int(vis.x * s), int(vis.y * s))
	under_vp.size_2d_override = Vector2i(int(vis.x), int(vis.y))
	under_vp.size_2d_override_stretch = true
	small_vp.size = Vector2i(maxi(8, int(vis.x / 8.0)), maxi(8, int(vis.y / 8.0)))
	small_rect.size = Vector2(small_vp.size)
	bg_rect.size = vis
	bg_mat.set_shader_parameter("res", vis)
	bg_mat.set_shader_parameter("center", center)
	bg_mat.set_shader_parameter("radius", radius)

func _build_composite() -> void:
	comp_rect = ColorRect.new()
	comp_mat = ShaderMaterial.new()
	comp_mat.shader = preload("res://shaders/bowl_comp.gdshader")
	comp_rect.material = comp_mat
	comp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(comp_rect)
	comp_mat.set_shader_parameter("under", under_vp.get_texture())
	comp_mat.set_shader_parameter("small", small_vp.get_texture())
	top_petals = PetalDraw.new()
	top_petals.pond = self
	top_petals.material = petal_mat
	add_child(top_petals)
	surface = SurfaceDraw.new()
	surface.pond = self
	add_child(surface)
	_comp_params()

func _comp_params() -> void:
	comp_rect.size = vis
	comp_mat.set_shader_parameter("grid", Vector2(grid))
	comp_mat.set_shader_parameter("res", vis)
	comp_mat.set_shader_parameter("center", center)
	comp_mat.set_shader_parameter("radius", radius)

func _on_resize() -> void:
	var old = grid
	_measure()
	if old != grid:
		for v in [sim_a, sim_b]:
			v.size = grid
		rect_a.size = Vector2(grid)
		rect_b.size = Vector2(grid)
		for m in [mat_a, mat_b]:
			m.set_shader_parameter("grid", Vector2(grid))
		reset_frames = 3
	_size_under()
	_comp_params()
	for f in fishes:
		if cpu_sdf(f.pos) > -40.0:
			f.setup(center + Vector2(randf_range(-40, 40), randf_range(-60, 60)), randf() * TAU)
	_layout_ui()

# ---------- Bowl geometry ----------

func swim_radius() -> float:
	return minf(radius * 0.86, minf(vis.x, vis.y) * 0.5 * 0.95 if vis.y <= vis.x * 1.6 else radius * 0.86)

func cpu_sdf(p: Vector2) -> float:
	var d = p - center
	var ry = minf(radius * 0.9, vis.y * 0.42)
	var rx = minf(radius * 0.9, vis.x * 0.34)
	var q = Vector2(d.x / rx, d.y / ry)
	var sd = (q.length() - 1.0) * minf(rx, ry)
	# While the naming card is up, treat its top edge as a soft wall so the
	# fish stay in view above it instead of hiding under the card.
	if card != null:
		sd = maxf(sd, p.y - (card.position.y - 36.0 - radius * 0.12))
	return sd

func random_point(frac: float) -> Vector2:
	var ry = minf(radius * 0.9, vis.y * 0.42)
	var rx = minf(radius * 0.9, vis.x * 0.34)
	var pt = center
	for _t in 8:
		var a = randf() * TAU
		var r = sqrt(randf()) * frac
		pt = center + Vector2(cos(a) * rx, sin(a) * ry) * r
		if card == null or pt.y < card.position.y - 60.0:
			break
	return pt

# ---------- Fish ----------

func _build_fish() -> void:
	var defs = [
		{"name": "Momo", "kind": 0, "len": 104.0, "w": 62.0, "tail": 185.0, "bold": 0.45},
		{"name": "Kuro", "kind": 1, "len": 124.0, "w": 44.0, "tail": 160.0, "bold": 0.75},
	]
	var s = _fish_scale()
	for i in defs.size():
		var dfn: Dictionary = defs[i]
		var f = FishScript.new()
		f.idx = i
		f.kind = dfn.kind
		f.name = dfn.name
		f.length = dfn.len * s
		f.width = dfn.w * s
		f.tail_len = dfn.tail * s
		f.pace = randf_range(0.9, 1.1)
		f.boldness = dfn.bold
		if i < _save_fish.size():
			var sv: Dictionary = _save_fish[i]
			f.bond = clampf(float(sv.get("bond", 0.0)), 0.0, 100.0)
			var nm = _clean_name(str(sv.get("name", f.name)), 14)
			if nm != "":
				f.name = nm
		f.setup(random_point(0.5), randf() * TAU)
		f.mat = ShaderMaterial.new()
		f.mat.shader = preload("res://shaders/fish2.gdshader")
		f.mat.set_shader_parameter("kind", float(f.kind))
		f.mat.set_shader_parameter("seed", randf() * 10.0)
		var body = FishDraw.new()
		body.fish = f
		body.material = f.mat
		fish_layer.add_child(body)
		f.body_node = body
		fishes.append(f)

# ---------- Petals ----------

func _petal_target() -> int:
	return 24 + 4 * blossoms

func _new_petal(anywhere: bool) -> Dictionary:
	var d = randf()
	var near = randf() < 0.14
	var p = random_point(1.15) if anywhere else center + Vector2.from_angle(randf() * TAU) * radius * 1.1
	return {"pos": p, "depth": -0.4 if near else d * d, "rot": randf() * TAU, "spin": randf_range(-0.25, 0.25),
		"size": randf_range(9.0, 15.0) * _fish_scale() * 0.62 * (1.35 if randf() < 0.3 else 1.0) * (2.4 if near else 1.0),
		"flower": 1.0 if randf() < 0.3 else 0.0, "vel": Vector2(randf_range(-3, 3), randf_range(-3, 3))}

func _seed_petals() -> void:
	petals.clear()
	for i in _petal_target():
		petals.append(_new_petal(true))

func _update_petals(dt: float) -> void:
	while petals.size() < _petal_target():
		petals.append(_new_petal(false))
	for pt in petals:
		var v: Vector2 = pt.vel
		v += Vector2(sin(time * 0.13 + pt.rot), cos(time * 0.11 + pt.rot * 1.3)) * 1.2 * dt
		for f in fishes:
			var dv: Vector2 = pt.pos - f.pos
			var dd = dv.length()
			var rr = f.length * 0.9
			if dd < rr and dd > 0.1 and absf(pt.depth - f.depth) < 0.45:
				v += dv / dd * (1.0 - dd / rr) * f.speed * 0.9 * dt * 6.0
		if touch_down:
			var dt2: Vector2 = pt.pos - touch_pos
			var d2 = dt2.length()
			if d2 < 70.0 and d2 > 0.1 and pt.depth < 0.4:
				v += dt2 / d2 * (1.0 - d2 / 70.0) * 120.0 * dt
		v *= pow(0.6, dt)
		pt.vel = v
		pt.pos += v * dt
		pt.rot += pt.spin * dt + v.length() * 0.004
		var sdf = cpu_sdf(pt.pos)
		if sdf > 30.0:
			pt.vel += (center - pt.pos).normalized() * 8.0 * dt

func draw_petals(ci: CanvasItem, deep: bool) -> void:
	var pts = PackedVector2Array()
	var uvs = PackedVector2Array()
	var cols = PackedColorArray()
	var ia = PackedInt32Array()
	for pt in petals:
		var d: float = pt.depth
		if deep != (d > 0.35):
			continue
		var blur = clampf(absf(d - 0.12) * 1.3, 0.0, 1.0)
		var sz: float = pt.size * (1.0 - 0.3 * d) * (1.0 + blur * 0.35)
		var alpha = (0.95 - 0.45 * d) if d >= 0.0 else 0.7
		var r = Vector2.from_angle(pt.rot) * sz
		var o = r.orthogonal()
		var c: Vector2 = pt.pos
		var b = pts.size()
		pts.append_array([c - r - o, c + r - o, c + r + o, c - r + o])
		uvs.append_array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
		var col = Color(blur, alpha, pt.flower, 1.0)
		cols.append_array([col, col, col, col])
		ia.append_array([b, b + 1, b + 2, b, b + 2, b + 3])
	if ia.size() > 0:
		RenderingServer.canvas_item_add_triangle_array(ci.get_canvas_item(), ia, pts, cols, uvs)

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

# ---------- Food and bond ----------

func nearest_pellet(p: Vector2, r: float):
	var best = null
	var bd = r
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
	add_ripple(pl.pos, -0.25, 1.8)
	dirty = true
	_check_blossoms()
	return true

func _drop_food(p: Vector2) -> void:
	for i in 4:
		var pl = Pellet.new()
		pl.pos = p + Vector2(randf_range(-12, 12), randf_range(-12, 12))
		pl.vel = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		pellets.append(pl)

func harmony() -> float:
	var s = 0.0
	for f in fishes:
		s += f.bond
	return s

func _check_blossoms() -> void:
	var want = mini(8, int(harmony() / 20.0))
	if want > blossoms:
		blossoms = want
		dirty = true
		_toast("More blossoms drift in")

func on_nuzzle(f) -> void:
	dirty = true
	if f.bond_level() >= 3 and randf() < 0.35:
		_toast(f.name + " trusts you")
	_check_blossoms()

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
			for f in fishes:
				var d = f.pos.distance_to(event.position)
				if d < 150.0 and f.state == FishScript.S.WANDER:
					if f.bond_level() >= 2:
						f.target = event.position
					else:
						f.target = f.pos + (f.pos - event.position).normalized() * 120.0
		else:
			touch_down = false
			if hold_active:
				hold_active = false
			elif time - touch_t0 < 0.3 and touch_moved < 14.0:
				_tap(event.position)
	elif event is InputEventScreenDrag:
		if event.index != 0:
			return
		var d: Vector2 = event.position - touch_pos
		touch_moved += d.length()
		touch_pos = event.position
		if hold_active:
			hold_pos = touch_pos
		add_ripple(touch_pos, -0.07 * clampf(d.length() / 8.0, 0.2, 1.6), 1.7)
		if d.length() > 24.0:
			for f in fishes:
				if f.pos.distance_to(touch_pos) < 110.0 and f.bond_level() < 2:
					f.startle_from = touch_pos
					f.set_state(FishScript.S.STARTLE, 0.8)

func _tap(p: Vector2) -> void:
	if time - last_tap_t < 0.32 and p.distance_to(last_tap_pos) < 50.0:
		last_tap_t = -10.0
		add_ripple(p, -0.8, 2.6)
		for f in fishes:
			if f.pos.distance_to(p) < 240.0:
				f.startle_from = p
				f.set_state(FishScript.S.STARTLE, 1.2)
		return
	last_tap_t = time
	last_tap_pos = p
	var hit = null
	for f in fishes:
		if p.distance_to(f.spine[3]) < f.width * 0.9:
			hit = f
	if hit != null:
		tag_fish = hit
		tag_t = 3.2
		add_ripple(p, -0.12, 1.5)
		return
	add_ripple(p, -0.4, 2.0)
	if food_cd <= 0.0 and cpu_sdf(p) < 0.0:
		_drop_food(p)
		food_cd = 0.6

# ---------- Frame ----------

func _process(dt: float) -> void:
	dt = minf(dt, 0.05)
	time += dt
	food_cd -= dt
	if touch_down and not hold_active and time - touch_t0 > 0.45 and touch_moved < 16.0:
		hold_active = true
		hold_pos = touch_pos
	if hold_active and fmod(time, 0.6) < dt:
		add_ripple(hold_pos, -0.05, 1.4)
	for f in fishes:
		f.update(dt, self, fishes)
	for pl in pellets:
		if not pl.alive:
			continue
		pl.life -= dt
		pl.pos += pl.vel * dt
		pl.vel *= 0.97
		if pl.life <= 0.0:
			pl.alive = false
	pellets = pellets.filter(func(x): return x.alive)
	_update_petals(dt)
	var sorted = fishes.duplicate()
	sorted.sort_custom(func(a, b): return a.depth > b.depth)
	for i in sorted.size():
		var f = sorted[i]
		f.build_mesh()
		f.body_node.z_index = i
		f.mat.set_shader_parameter("depth", f.depth)
		f.mat.set_shader_parameter("glow", f.glow)
		f.mat.set_shader_parameter("bowl", Vector4(center.x / vis.x, center.y / vis.y, radius / vis.x, vis.x / vis.y))
		f.body_node.queue_redraw()
	bg_mat.set_shader_parameter("time", time)
	bg_mat.set_shader_parameter("warmth", clampf(harmony() / 150.0, 0.0, 1.0))
	comp_mat.set_shader_parameter("time", time)
	_step_sim()
	deep_petals.queue_redraw()
	top_petals.queue_redraw()
	surface.queue_redraw()
	tag_t -= dt
	_ui_tick(dt)
	save_t += dt
	if dirty and save_t > 4.0:
		_save()

func draw_surface(ci: CanvasItem) -> void:
	for pl in pellets:
		var a = clampf(pl.life / 2.0, 0.0, 1.0)
		ci.draw_circle(pl.pos, 5.0, Color(1.0, 0.85, 0.6, 0.18 * a))
		ci.draw_circle(pl.pos, 2.6, Color(0.93, 0.55, 0.35, a))
		ci.draw_circle(pl.pos + Vector2(-0.8, -0.8), 1.0, Color(1, 0.95, 0.85, 0.9 * a))
	if hold_active:
		var pulse = 0.5 + 0.5 * sin(time * 3.0)
		ci.draw_arc(hold_pos, 20.0 + 4.0 * pulse, 0.0, TAU, 40, Color(1, 1, 1, 0.5), 1.5, true)
	if tag_fish != null and tag_t > 0.0:
		var f = tag_fish
		var a2: float = clampf(tag_t, 0.0, 1.0)
		var at: Vector2 = f.spine[3] + Vector2(0, -f.width - 30.0)
		at.x = clampf(at.x, 70.0, vis.x - 70.0)
		at.y = clampf(at.y, 50.0, vis.y - 40.0)
		var font = ThemeDB.fallback_font
		var txt: String = f.name
		var tw: float = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		var w = maxf(tw, 64.0) + 26.0
		var box = Rect2(at - Vector2(w * 0.5, 22.0), Vector2(w, 42.0))
		ci.draw_rect(box, Color(1.0, 0.98, 1.0, 0.82 * a2))
		ci.draw_string(font, Vector2(box.position.x, box.position.y + 18.0), txt, HORIZONTAL_ALIGNMENT_CENTER, w, 15, Color(0.25, 0.24, 0.42, a2))
		var lvl: int = f.bond_level()
		for k in 5:
			var hc = box.position + Vector2(w * 0.5 - 24.0 + 12.0 * k, 30.0)
			_heart(ci, hc, 4.2, Color(0.93, 0.45, 0.58, a2) if k < lvl else Color(0.6, 0.6, 0.75, 0.45 * a2))

func _heart(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_circle(c + Vector2(-s * 0.5, -s * 0.2), s * 0.55, col)
	ci.draw_circle(c + Vector2(s * 0.5, -s * 0.2), s * 0.55, col)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.02, 0.0), c + Vector2(s * 1.02, 0.0), c + Vector2(0, s * 1.05)]), col)

# ---------- UI ----------

const INK = Color(0.26, 0.25, 0.44)

func _label(sz: int, col: Color) -> Label:
	var l = Label.new()
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 10
	add_child(ui)
	name_label = _label(17, INK)
	ui.add_child(name_label)
	sub_label = _label(12, Color(0.4, 0.4, 0.6, 0.9))
	ui.add_child(sub_label)
	toast = _label(14, INK)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.modulate.a = 0.0
	ui.add_child(toast)
	if pond_name == "":
		_build_card()
	_layout_ui()
	_refresh_labels()

func _build_card() -> void:
	card = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.98, 1.0, 0.82)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 18
	sb.shadow_color = Color(0.3, 0.3, 0.6, 0.18)
	sb.shadow_size = 16
	card.add_theme_stylebox_override("panel", sb)
	var vb = VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)
	var eyebrow = _label(11, Color(0.86, 0.42, 0.56))
	eyebrow.text = "A SMALL BEGINNING"
	vb.add_child(eyebrow)
	var title = _label(22, INK)
	title.text = "Name your bowl"
	vb.add_child(title)
	var body = _label(13, Color(0.42, 0.41, 0.58))
	body.text = "Two goldfish live here. Feed them,\nand they will learn to trust you."
	vb.add_child(body)
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	vb.add_child(hb)
	name_edit = LineEdit.new()
	name_edit.text = "Spring Glass"
	name_edit.max_length = 24
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.custom_minimum_size = Vector2(0, 44)
	name_edit.add_theme_font_size_override("font_size", 16)
	name_edit.add_theme_color_override("font_color", INK)
	var le = StyleBoxFlat.new()
	le.bg_color = Color(0.93, 0.93, 1.0, 0.9)
	le.set_corner_radius_all(10)
	le.content_margin_left = 12
	name_edit.add_theme_stylebox_override("normal", le)
	name_edit.add_theme_stylebox_override("focus", le)
	name_edit.text_submitted.connect(func(_t): _begin())
	hb.add_child(name_edit)
	var btn = Button.new()
	btn.text = "Begin"
	btn.custom_minimum_size = Vector2(88, 44)
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.4, 0.38, 0.7)
	bs.set_corner_radius_all(10)
	for st in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(st, bs)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 15)
	btn.pressed.connect(_begin)
	hb.add_child(btn)
	ui.add_child(card)

func _begin() -> void:
	var nm = _clean_name(name_edit.text, 24)
	pond_name = nm if nm != "" else "Spring Glass"
	card.queue_free()
	card = null
	dirty = true
	_save()
	_refresh_labels()
	_toast("Tap the water to feed")
	_toast("Touch gently. Swipe and they scatter")
	_toast("Hold still. The brave one comes close")

func _layout_ui() -> void:
	if name_label == null:
		return
	var big = vis.x > 700.0
	name_label.add_theme_font_size_override("font_size", 24 if big else 17)
	sub_label.add_theme_font_size_override("font_size", 15 if big else 12)
	toast.add_theme_font_size_override("font_size", 18 if big else 14)
	name_label.position = Vector2(20, 14)
	sub_label.position = Vector2(20, 14 + (31 if big else 23))
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
	if blossoms > 0:
		parts.append("%d blossoms" % blossoms)
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
	blossoms = clampi(int(data.get("blossoms", 0)), 0, 8)
	var fl = data.get("fish", [])
	if typeof(fl) == TYPE_ARRAY:
		for e in fl.slice(0, 2):
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
	var data = {"v": 1, "pond": pond_name, "last_day": _today(), "streak": streak, "visits": visits, "blossoms": blossoms, "fish": fl}
	var fa = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if fa != null:
		fa.store_string(JSON.stringify(data))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if pond_name != "":
			_save()
