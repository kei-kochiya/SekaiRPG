extends PanelContainer
class_name CommandMenu

## Dynamic button menu for player turn actions.
## Shows action buttons → then target picker → emits command_chosen.

signal command_chosen(action: String, target: Entity)

var current_entity: Entity
var enemy_team: Array
var chosen_action: String = ""

var action_container: VBoxContainer
var target_container: VBoxContainer

func _ready():
	visible = false
	_build_shell()

func _build_shell():
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.08, 0.08, 0.08, 0.95)
	ps.border_color = Color(0.25, 0.25, 0.25)
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(6)
	ps.set_content_margin_all(12)
	add_theme_stylebox_override("panel", ps)
	
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	
	var title = Label.new()
	title.text = "COMMAND"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)
	
	action_container = VBoxContainer.new()
	action_container.add_theme_constant_override("separation", 4)
	root.add_child(action_container)
	
	target_container = VBoxContainer.new()
	target_container.add_theme_constant_override("separation", 4)
	target_container.visible = false
	root.add_child(target_container)

# ---- Public API ----

func show_for(entity: Entity, enemies: Array):
	current_entity = entity
	enemy_team = enemies
	chosen_action = ""
	
	_clear(action_container)
	_clear(target_container)
	action_container.visible = true
	target_container.visible = false
	
	# "Attack" — always available
	action_container.add_child(_make_btn("Attack", "attack", true))
	
	# Skill buttons
	for skill in entity.skills:
		var skill_ready = entity.can_use_skill(skill["method"])
		var cd = entity.cooldowns.get(skill["method"], 0)
		var label = skill["name"]
		if cd >= 99:
			label += " [Used]"
		elif cd > 0:
			label += " (CD: %d)" % cd
		action_container.add_child(_make_btn(label, skill["method"], skill_ready))
	
	visible = true

# ---- Internals ----

func _on_action_picked(action_name: String):
	chosen_action = action_name
	action_container.visible = false
	_show_targets()

func _show_targets():
	_clear(target_container)
	target_container.visible = true
	
	var header = Label.new()
	header.text = "SELECT TARGET"
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_container.add_child(header)
	
	var alive = TargetingManager.get_alive_targets(enemy_team)
	for enemy in alive:
		var label = "%s  HP %d/%d" % [enemy.entity_name, enemy.current_hp, enemy.max_hp]
		var btn = _make_btn(label, "", true)
		btn.pressed.connect(_on_target_picked.bind(enemy))
		target_container.add_child(btn)

func _on_target_picked(target: Entity):
	visible = false
	command_chosen.emit(chosen_action, target)

func _make_btn(label: String, action_name: String, enabled: bool) -> Button:
	var btn = Button.new()
	btn.text = label
	btn.disabled = not enabled
	btn.custom_minimum_size = Vector2(220, 32)
	
	# Normal
	var ns = StyleBoxFlat.new()
	ns.bg_color = Color(0.15, 0.15, 0.15) if enabled else Color(0.08, 0.08, 0.08)
	ns.set_corner_radius_all(3)
	ns.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", ns)
	
	# Hover
	var hs = StyleBoxFlat.new()
	hs.bg_color = Color(0.25, 0.22, 0.15)
	hs.set_corner_radius_all(3)
	hs.set_content_margin_all(4)
	btn.add_theme_stylebox_override("hover", hs)
	
	# Pressed
	var prs = StyleBoxFlat.new()
	prs.bg_color = Color(0.3, 0.25, 0.1)
	prs.set_corner_radius_all(3)
	prs.set_content_margin_all(4)
	btn.add_theme_stylebox_override("pressed", prs)
	
	# Disabled
	var ds = StyleBoxFlat.new()
	ds.bg_color = Color(0.08, 0.08, 0.08)
	ds.set_corner_radius_all(3)
	ds.set_content_margin_all(4)
	btn.add_theme_stylebox_override("disabled", ds)
	
	btn.add_theme_color_override("font_color",
		Color(0.8, 0.75, 0.6) if enabled else Color(0.3, 0.3, 0.3))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.7))
	btn.add_theme_color_override("font_disabled_color", Color(0.3, 0.3, 0.3))
	btn.add_theme_font_size_override("font_size", 13)
	
	# Connect action pick (target buttons connect separately)
	if action_name != "":
		btn.pressed.connect(_on_action_picked.bind(action_name))
	
	return btn

func _clear(container: Container):
	for c in container.get_children():
		c.queue_free()
