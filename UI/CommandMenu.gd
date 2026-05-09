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
	var ps = StyleBoxTexture.new()
	ps.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/panel_brown.svg")
	ps.texture_margin_left = 12
	ps.texture_margin_right = 12
	ps.texture_margin_top = 12
	ps.texture_margin_bottom = 12
	ps.set_content_margin_all(16)
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
	
	# Check target type
	var target_type = "enemy" # default
	if action_name != "attack":
		for s in current_entity.skills:
			if s["method"] == action_name:
				target_type = s.get("target", "enemy")
				break
	
	if target_type == "all_allies" or target_type == "all_enemies":
		# AoE skills don't need target selection, just pick first one as dummy (logic handles all)
		visible = false
		command_chosen.emit(chosen_action, current_entity) # Entity logic will use allies/enemies arrays
	elif target_type == "self":
		visible = false
		command_chosen.emit(chosen_action, current_entity)
	else:
		_show_targets(target_type)

func _show_targets(target_type: String = "enemy"):
	_clear(target_container)
	target_container.visible = true
	
	var header = Label.new()
	header.text = "SELECT TARGET"
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_container.add_child(header)
	
	var team = enemy_team if target_type == "enemy" else current_entity.allies
	var alive = AIManager.get_alive_targets(team)
	for member in alive:
		var label = "%s  HP %d/%d" % [member.entity_name, member.current_hp, member.max_hp]
		var btn = _make_btn(label, "", true)
		btn.pressed.connect(_on_target_picked.bind(member))
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
	var ns = StyleBoxTexture.new()
	ns.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg")
	ns.texture_margin_left = 10
	ns.texture_margin_right = 10
	ns.texture_margin_top = 10
	ns.texture_margin_bottom = 14 # 3D effect margin
	ns.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal", ns)
	
	# Hover
	var hs = StyleBoxTexture.new()
	hs.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_grey.svg")
	hs.texture_margin_left = 10
	hs.texture_margin_right = 10
	hs.texture_margin_top = 10
	hs.texture_margin_bottom = 14
	hs.set_content_margin_all(6)
	btn.add_theme_stylebox_override("hover", hs)
	
	# Pressed
	var prs = StyleBoxTexture.new()
	prs.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_red.svg")
	prs.texture_margin_left = 10
	prs.texture_margin_right = 10
	prs.texture_margin_top = 14
	prs.texture_margin_bottom = 10
	prs.set_content_margin_all(6)
	btn.add_theme_stylebox_override("pressed", prs)
	
	# Disabled
	var ds = StyleBoxTexture.new()
	ds.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_grey.svg")
	ds.texture_margin_left = 10
	ds.texture_margin_right = 10
	ds.texture_margin_top = 10
	ds.texture_margin_bottom = 14
	ds.modulate_color = Color(0.5, 0.5, 0.5, 0.6)
	ds.set_content_margin_all(6)
	btn.add_theme_stylebox_override("disabled", ds)
	
	btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	btn.add_theme_color_override("font_hover_color", Color(0.1, 0.1, 0.1))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))
	btn.add_theme_font_size_override("font_size", 14)
	
	# Connect action pick (target buttons connect separately)
	if action_name != "":
		btn.pressed.connect(_on_action_picked.bind(action_name))
	
	return btn

func _clear(container: Container):
	for c in container.get_children():
		c.queue_free()
