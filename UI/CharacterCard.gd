extends PanelContainer
class_name CharacterCard

## Refactored CharacterCard: Displays entity status using a reactive design.
## Separates UI construction from state management.

const COLORS = {
	"player": Color(0.29, 0.62, 0.62),
	"enemy": Color(0.72, 0.38, 0.16),
	"hp_fill": Color(0.2, 0.8, 0.2),
	"bg": Color(0.12, 0.12, 0.12, 0.9)
}

var entity: Entity
var is_player: bool = false

# UI Nodes
var hp_bar: ProgressBar
var hp_label: Label
var name_label: Label
var level_label: Label
var status_row: HBoxContainer
var cooldown_icons: Dictionary = {}

func setup(e: Entity, player: bool):
	entity = e
	is_player = player
	_build_ui()
	_connect_signals()
	_refresh_all()

func _build_ui():
	# Card Panel Style
	var ps = StyleBoxTexture.new()
	ps.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/panel_brown.svg")
	ps.texture_margin_left = 12
	ps.texture_margin_right = 12
	ps.texture_margin_top = 12
	ps.texture_margin_bottom = 12
	ps.set_content_margin_all(12)
	add_theme_stylebox_override("panel", ps)
	custom_minimum_size = Vector2(220, 0)
	
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	# 1. Header (Portrait + Name + Level)
	var header = _create_header()
	vbox.add_child(header)
	
	# 2. HP Bar
	hp_bar = _create_hp_bar()
	vbox.add_child(hp_bar)
	
	# 3. Cooldowns & Status
	var footer = HBoxContainer.new()
	vbox.add_child(footer)
	
	status_row = HBoxContainer.new()
	footer.add_child(status_row)
	
	if not entity.skills.is_empty():
		var cd_row = _create_cooldown_row()
		vbox.add_child(cd_row)

func _create_header() -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	
	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(44, 44)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var p_path = "res://Art/Portraits/%s.png" % entity.entity_name.to_lower()
	if ResourceLoader.exists(p_path): portrait.texture = load(p_path)
	h.add_child(portrait)
	
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)
	
	name_label = Label.new()
	name_label.text = entity.entity_name.to_upper()
	name_label.add_theme_color_override("font_color", COLORS.player if is_player else COLORS.enemy)
	name_label.add_theme_font_size_override("font_size", 14)
	info.add_child(name_label)
	
	level_label = Label.new()
	level_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	level_label.add_theme_font_size_override("font_size", 11)
	info.add_child(level_label)
	
	return h

func _create_hp_bar() -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 16)
	bar.show_percentage = false
	
	var fill = StyleBoxTexture.new()
	fill.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/progress_green.svg")
	fill.texture_margin_left = 6
	fill.texture_margin_right = 6
	bar.add_theme_stylebox_override("fill", fill)
	
	var bg = StyleBoxTexture.new()
	bg.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/progress_transparent.svg")
	bg.texture_margin_left = 6
	bg.texture_margin_right = 6
	bar.add_theme_stylebox_override("background", bg)
	
	hp_label = Label.new()
	hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 10)
	bar.add_child(hp_label)
	
	return bar

func _create_cooldown_row() -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for skill in entity.skills:
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(24, 20)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.15, 0.15, 0.15)
		sb.set_corner_radius_all(2)
		panel.add_theme_stylebox_override("panel", sb)
		
		var l = Label.new()
		l.text = skill["name"].substr(0, 2)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 10)
		panel.add_child(l)
		row.add_child(panel)
		cooldown_icons[skill["method"]] = {"label": l, "panel": panel, "style": sb}
	return row

func _connect_signals():
	entity.hp_changed.connect(_on_hp_changed)
	entity.died.connect(_on_died)
	entity.cooldown_updated.connect(_on_cooldown_updated)
	entity.status_changed.connect(_on_status_changed)
	entity.damage_received.connect(_on_damage_received)
	entity.level_changed.connect(_on_level_changed)

func _refresh_all():
	_on_level_changed(entity.level)
	_on_hp_changed(entity.current_hp, entity.max_hp)
	_on_status_changed(entity.active_statuses)
	if entity.current_hp <= 0: _on_died()

func _on_level_changed(lv: int):
	level_label.text = "Lv.%d" % lv

func _on_hp_changed(cur: int, m_hp: int):
	hp_bar.max_value = m_hp
	var tw = create_tween()
	tw.tween_property(hp_bar, "value", cur, 0.3).set_trans(Tween.TRANS_CUBIC)
	hp_label.text = "%d / %d" % [cur, m_hp]

func _on_died():
	modulate = Color(0.5, 0.5, 0.5, 0.7)

func _on_cooldown_updated(skill: String, turns: int):
	if not cooldown_icons.has(skill): return
	var icon = cooldown_icons[skill]
	if turns > 0:
		icon.label.text = str(turns)
		icon.label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		icon.style.bg_color = Color(0.3, 0.2, 0.1)
	else:
		icon.label.text = "OK"
		icon.label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		icon.style.bg_color = Color(0.15, 0.15, 0.15)

func _on_status_changed(statuses: Array):
	for c in status_row.get_children(): c.queue_free()
	for s in statuses:
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.color = Color(0.8, 0.2, 0.2) if s["type"] == "Bleed" else Color(0.2, 0.8, 0.2)
		status_row.add_child(dot)

func _on_damage_received(amt: int, type: String):
	var spawn_pos = global_position + Vector2(size.x / 2, 0)
	var overlay = get_tree().get_first_node_in_group("ui_overlay")
	FloatingText.spawn(overlay if overlay else get_tree().root, amt, type, spawn_pos)
