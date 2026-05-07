extends PanelContainer
class_name CharacterCard

## Self-contained status card for one entity: HP bar, cooldown icons, status dots.
## Dark/utilitarian aesthetic. Connects to Entity signals for live updates.

const PLAYER_NAME_COLOR  = Color(0.29, 0.62, 0.62)  # muted teal
const ENEMY_NAME_COLOR   = Color(0.72, 0.38, 0.16)  # rust orange
const HP_FILL_COLOR      = Color(0.55, 0.0, 0.0)    # deep red
const HP_LOW_COLOR       = Color(0.7, 0.15, 0.0)    # orange-red when low
const HP_BG_COLOR        = Color(0.12, 0.12, 0.12)
const PANEL_BG           = Color(0.1, 0.1, 0.1, 0.9)
const BORDER_COLOR       = Color(0.2, 0.2, 0.2)

var entity: Entity
var is_player: bool = false

var hp_bar: ProgressBar
var hp_label: Label
var name_label: Label
var level_label: Label
var cooldown_icons: Dictionary = {}   # skill method name -> {panel, label, style}
var status_row: HBoxContainer

# ---- Setup ----

func setup(e: Entity, player: bool):
	entity = e
	is_player = player
	_build_ui()
	_connect_signals()

func _build_ui():
	# Panel style
	var ps = StyleBoxFlat.new()
	ps.bg_color = PANEL_BG
	ps.border_color = BORDER_COLOR
	ps.set_border_width_all(1)
	ps.set_corner_radius_all(4)
	ps.set_content_margin_all(8)
	add_theme_stylebox_override("panel", ps)
	custom_minimum_size = Vector2(200, 0)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	add_child(vbox)
	
	# -- Header: Portrait + Name + Level --
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	vbox.add_child(header)
	
	# Portrait thumbnail
	var portrait_container = PanelContainer.new()
	portrait_container.custom_minimum_size = Vector2(42, 42)
	var ps_p = StyleBoxFlat.new()
	ps_p.bg_color = Color(0, 0, 0, 0.5)
	ps_p.set_border_width_all(1)
	ps_p.border_color = Color(0.3, 0.3, 0.3)
	portrait_container.add_theme_stylebox_override("panel", ps_p)
	header.add_child(portrait_container)
	
	var portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var p_path = "res://Art/Portraits/%s.png" % entity.entity_name.to_lower()
	if ResourceLoader.exists(p_path):
		portrait.texture = load(p_path)
	portrait_container.add_child(portrait)
	
	var name_vbox = VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.add_theme_constant_override("separation", 0)
	header.add_child(name_vbox)
	
	name_label = Label.new()
	name_label.text = entity.entity_name.to_upper()
	name_label.add_theme_color_override("font_color",
		PLAYER_NAME_COLOR if is_player else ENEMY_NAME_COLOR)
	name_label.add_theme_font_size_override("font_size", 14)
	name_vbox.add_child(name_label)
	
	level_label = Label.new()
	level_label.text = "Lv.%d" % entity.level
	level_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	level_label.add_theme_font_size_override("font_size", 11)
	name_vbox.add_child(level_label)
	
	# -- HP Bar --
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 18)
	hp_bar.show_percentage = false
	hp_bar.max_value = entity.max_hp
	hp_bar.value = entity.current_hp
	
	var fill = StyleBoxFlat.new()
	fill.bg_color = HP_FILL_COLOR
	fill.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("fill", fill)
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = HP_BG_COLOR
	bg.set_corner_radius_all(2)
	hp_bar.add_theme_stylebox_override("background", bg)
	vbox.add_child(hp_bar)
	
	# HP text overlay (child of ProgressBar, fills its rect)
	hp_label = Label.new()
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	hp_bar.add_child(hp_label)
	_refresh_hp_text()
	
	# -- Cooldown icons row (only if entity has skills) --
	if not entity.skills.is_empty():
		var cd_row = HBoxContainer.new()
		cd_row.add_theme_constant_override("separation", 3)
		vbox.add_child(cd_row)
		
		for skill in entity.skills:
			var ip = PanelContainer.new()
			ip.custom_minimum_size = Vector2(24, 20)
			var ist = StyleBoxFlat.new()
			ist.set_corner_radius_all(2)
			ist.set_content_margin_all(2)
			ip.add_theme_stylebox_override("panel", ist)
			
			var il = Label.new()
			
			var initial_cd = entity.cooldowns.get(skill["method"], 0)
			if initial_cd > 0:
				il.text = str(initial_cd)
				il.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
				ist.bg_color = Color(0.25, 0.2, 0.1)
			else:
				il.text = skill["name"].substr(0, 2)
				il.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
				ist.bg_color = Color(0.15, 0.15, 0.15)
				
			il.add_theme_font_size_override("font_size", 10)
			il.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ip.add_child(il)
			cd_row.add_child(ip)
			
			cooldown_icons[skill["method"]] = {"panel": ip, "label": il, "style": ist}
	
	# -- Status icons row --
	status_row = HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 2)
	vbox.add_child(status_row)

func _connect_signals():
	entity.hp_changed.connect(_on_hp_changed)
	entity.died.connect(_on_died)
	entity.cooldown_updated.connect(_on_cooldown_updated)
	entity.status_changed.connect(_on_status_changed)
	entity.damage_received.connect(_on_damage_received)

# ---- Signal handlers ----

func _refresh_hp_text():
	hp_label.text = "%d / %d" % [entity.current_hp, entity.max_hp]

func _on_hp_changed(new_hp: int, max_hp_val: int):
	hp_bar.max_value = max_hp_val
	# Smooth tween instead of instant snap
	var tween = create_tween()
	tween.tween_property(hp_bar, "value", new_hp, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	hp_label.text = "%d / %d" % [new_hp, max_hp_val]

func _on_died():
	modulate = Color(0.4, 0.4, 0.4, 0.6)

func _on_cooldown_updated(skill_name: String, turns_left: int):
	if not cooldown_icons.has(skill_name):
		return
	var icon = cooldown_icons[skill_name]
	if turns_left > 0:
		icon["label"].text = str(turns_left)
		icon["label"].add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		icon["style"].bg_color = Color(0.25, 0.2, 0.1)
	else:
		# Restore to abbreviation
		for s in entity.skills:
			if s["method"] == skill_name:
				icon["label"].text = s["name"].substr(0, 2)
				break
		icon["label"].add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		icon["style"].bg_color = Color(0.15, 0.15, 0.15)

func _on_status_changed(statuses: Array):
	for c in status_row.get_children():
		c.queue_free()
	for status in statuses:
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		match status["type"]:
			"Bleed":  dot.color = Color(0.8, 0.2, 0.2)
			"Poison": dot.color = Color(0.2, 0.8, 0.2)
			"Stun":   dot.color = Color(0.9, 0.8, 0.2)
			_:        dot.color = Color(0.5, 0.5, 0.5)
		status_row.add_child(dot)

func _on_damage_received(amount: int, damage_type: String):
	# Spawn floating text near the top-center of this card
	var spawn_pos = global_position + Vector2(size.x / 2 - 20, -10)
	
	var parent = get_tree().get_first_node_in_group("ui_overlay")
	if not parent:
		parent = get_tree().root
		
	FloatingText.spawn(parent, amount, damage_type, spawn_pos)
