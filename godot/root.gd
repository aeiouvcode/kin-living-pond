extends Node
## KIN root: hosts either the koi pond or the goldfish bowl, with a small
## chip to switch. The choice is saved locally; nothing leaves the device.

const SCENES = {"pond": preload("res://main.gd"), "bowl": preload("res://bowl.gd")}
const PREF_PATH = "user://kin_scene.cfg"

var current = "pond"
var world: Node2D
var chip: Button
var layer: CanvasLayer

func _ready() -> void:
	# Pond Next web preview (branch-only "Web Next" export preset): the
	# integrated fish + water scene is the whole app.
	if OS.has_feature("kin_next"):
		var pn = Node3D.new()
		pn.set_script(load("res://labs/pond_lab.gd"))
		add_child(pn)
		return
	# Workstream labs (branch-only, CLI): --lab=fish shows the fish on their own.
	for a in OS.get_cmdline_user_args():
		if a == "--lab=fish":
			var lab = Node3D.new()
			lab.set_script(load("res://labs/fish_lab.gd"))
			add_child(lab)
			return
		if a == "--lab=pond":
			var pl = Node3D.new()
			pl.set_script(load("res://labs/pond_lab.gd"))
			add_child(pl)
			return
		if a == "--lab=water":
			var wl = Node2D.new()
			wl.set_script(load("res://labs/water_lab/water_lab.gd"))
			add_child(wl)
			return
	var cfg = ConfigFile.new()
	if cfg.load(PREF_PATH) == OK:
		var s = str(cfg.get_value("kin", "scene", "pond"))
		if SCENES.has(s):
			current = s
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scene="):
			var s2 = a.substr(8)
			if SCENES.has(s2):
				current = s2
	_build_chip()
	_load_world()
	get_viewport().size_changed.connect(_place_chip)

func _load_world() -> void:
	if world:
		world.queue_free()
	world = Node2D.new()
	world.name = "World"
	world.set_script(SCENES[current])
	add_child(world)
	move_child(world, 0)
	_style_chip()

func _build_chip() -> void:
	layer = CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	chip = Button.new()
	chip.focus_mode = Control.FOCUS_NONE
	chip.add_theme_font_size_override("font_size", 13)
	chip.custom_minimum_size = Vector2(104, 34)
	chip.pressed.connect(_toggle)
	layer.add_child(chip)
	_place_chip()

func _style_chip() -> void:
	# Label names the place you'd go to, so the action is obvious.
	var to_bowl = current == "pond"
	chip.text = "Glass bowl" if to_bowl else "Koi pond"
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 17
	sb.corner_radius_top_right = 17
	sb.corner_radius_bottom_left = 17
	sb.corner_radius_bottom_right = 17
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.bg_color = Color(1, 1, 1, 0.22) if to_bowl else Color(1, 1, 1, 0.55)
	sb.border_color = Color(1, 1, 1, 0.45)
	sb.set_border_width_all(1)
	for st in ["normal", "hover", "pressed"]:
		chip.add_theme_stylebox_override(st, sb)
	var fc = Color(0.95, 0.97, 0.95) if to_bowl else Color(0.25, 0.24, 0.45)
	for c in ["font_color", "font_hover_color", "font_pressed_color"]:
		chip.add_theme_color_override(c, fc)

func _place_chip() -> void:
	var vs = get_viewport().get_visible_rect().size
	chip.position = Vector2(vs.x - chip.custom_minimum_size.x - 16, 18)

func _toggle() -> void:
	current = "bowl" if current == "pond" else "pond"
	var cfg = ConfigFile.new()
	cfg.set_value("kin", "scene", current)
	cfg.save(PREF_PATH)
	_load_world()
