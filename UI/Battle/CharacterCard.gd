extends PanelContainer
class_name CharacterCard

"""
CharacterCard: thẻ trạng thái của một nhân vật hoặc kẻ địch trong trận.

- Hiển thị chân dung, tên, cấp, hệ nguyên tố, thanh máu, thanh Break (kẻ địch) và các hiệu ứng trạng thái.
- Tự cập nhật qua signal của Entity; `set_active()` đánh dấu thực thể đang tới lượt.
"""

const CARD_WIDTH = 264
const PORTRAIT_SIZE = 48

var entity: Entity
var is_player: bool = false

var hp_bar: ProgressBar
var break_bar: ProgressBar
var hp_label: Label
var level_label: Label
var status_row: HFlowContainer

func setup(e: Entity, player: bool):
	entity = e
	is_player = player
	_build_ui()
	_connect_signals()
	_refresh_all()

# ── Xây dựng ───────────────────────────────────────────────────────────────

func _faction_color() -> Color:
	return UITheme.PLAYER if is_player else UITheme.ENEMY

func _build_ui():
	custom_minimum_size = Vector2(CARD_WIDTH, 0)
	add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, _faction_color(), UITheme.SP_3))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SP_2)
	add_child(vbox)

	vbox.add_child(_create_header())

	hp_bar = ProgressBar.new()
	UITheme.style_bar(hp_bar, UITheme.SUCCESS, 16)
	hp_label = UITheme.make_label("", UITheme.FS_CAPTION, UITheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	hp_label.add_theme_font_override("font", UITheme.font_display_medium())
	hp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.add_theme_color_override("font_outline_color", UITheme.INK_900)
	hp_label.add_theme_constant_override("outline_size", 3)
	hp_bar.add_child(hp_label)
	vbox.add_child(hp_bar)

	if not is_player:
		break_bar = ProgressBar.new()
		UITheme.style_bar(break_bar, UITheme.BREAK, 6)
		vbox.add_child(break_bar)

	status_row = HFlowContainer.new() # nhiều hiệu ứng cùng lúc thì xuống dòng thay vì làm thẻ rộng ra
	status_row.add_theme_constant_override("h_separation", UITheme.SP_1)
	status_row.add_theme_constant_override("v_separation", UITheme.SP_1)
	vbox.add_child(status_row)

func _create_header() -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", UITheme.SP_3)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UITheme.box(UITheme.INK_900, UITheme.INK_600, UITheme.RADIUS_SM, 0, 0))
	frame.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var p_path := entity.get_portrait_path()
	if ResourceLoader.exists(p_path):
		portrait.texture = load(p_path)
	frame.add_child(portrait)
	h.add_child(frame)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	h.add_child(info)

	var name_label := UITheme.make_label(entity.entity_name, UITheme.FS_LABEL, UITheme.TEXT)
	name_label.add_theme_font_override("font", UITheme.font_display_bold())
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(name_label)

	var meta := HBoxContainer.new()
	meta.add_theme_constant_override("separation", UITheme.SP_2)
	info.add_child(meta)
	level_label = UITheme.make_label("", UITheme.FS_CAPTION, UITheme.TEXT_MUTED)
	meta.add_child(level_label)
	if entity.type != "None":
		meta.add_child(UITheme.chip(entity.type, UITheme.element_color(entity.type)))
	return h

# ── Trạng thái lượt ────────────────────────────────────────────────────────

func set_active(active: bool):
	var border := UITheme.ACCENT if active else UITheme.INK_600
	var sb := UITheme.panel(UITheme.INK_700 if active else UITheme.INK_800, border, _faction_color(), UITheme.SP_3)
	if active:
		sb.border_width_left = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_blend = false
		sb.border_color = UITheme.ACCENT
	add_theme_stylebox_override("panel", sb)

# ── Signal ─────────────────────────────────────────────────────────────────

func _connect_signals():
	entity.hp_changed.connect(_on_hp_changed)
	entity.died.connect(_on_died)
	entity.status_changed.connect(_on_status_changed)
	entity.damage_received_detailed.connect(_on_damage_received_detailed)
	entity.level_changed.connect(_on_level_changed)
	if break_bar:
		entity.break_gauge_changed.connect(_on_break_gauge_changed)

func _refresh_all():
	_on_level_changed(entity.level)
	_on_hp_changed(entity.current_hp, entity.max_hp)
	_on_status_changed(entity.active_statuses)
	if break_bar:
		_on_break_gauge_changed(entity.break_gauge, entity.max_break_gauge)
	if entity.current_hp <= 0:
		_on_died()

func _on_level_changed(lv: int):
	level_label.text = "Lv.%d" % lv

func _on_break_gauge_changed(cur: int, max_v: int):
	if not break_bar:
		return
	break_bar.max_value = max_v
	create_tween().tween_property(break_bar, "value", float(cur), 0.25)

func _on_hp_changed(cur: int, m_hp: int):
	hp_bar.max_value = m_hp
	create_tween().tween_property(hp_bar, "value", cur, 0.3).set_trans(Tween.TRANS_CUBIC)
	hp_label.text = "%d / %d" % [cur, m_hp]
	var ratio := float(cur) / maxf(1.0, float(m_hp))
	var fill_color := UITheme.SUCCESS if ratio > 0.5 else (UITheme.WARNING if ratio > 0.25 else UITheme.DANGER_TEXT)
	hp_bar.add_theme_stylebox_override("fill", UITheme.box(fill_color, Color.TRANSPARENT, UITheme.RADIUS_SM, 0, 0))

func _on_died():
	modulate = Color(0.55, 0.55, 0.55, 0.65)

func _on_status_changed(statuses: Array):
	for c in status_row.get_children():
		c.queue_free()

	var counts := {}
	for s in statuses:
		var type_name: String = s.get("type", "Unknown")
		counts[type_name] = counts.get(type_name, 0) + 1

	for type_name in counts:
		var info: Dictionary = UITheme.STATUS_INFO.get(type_name, {"label": type_name, "color": UITheme.TEXT_MUTED})
		var text: String = info["label"] if counts[type_name] == 1 else "%s x%d" % [info["label"], counts[type_name]]
		status_row.add_child(UITheme.chip(text, info["color"], UITheme.FS_CAPTION, UITheme.status_icon(type_name)))
	status_row.visible = not counts.is_empty()

func _on_damage_received_detailed(amt: int, type: String, is_crit: bool, is_break: bool):
	var spawn_pos := global_position + Vector2(size.x / 2, 0)
	var overlay := get_tree().get_first_node_in_group("ui_overlay")
	FloatingText.spawn(overlay if overlay else get_tree().root, amt, type, spawn_pos, is_crit, is_break)
