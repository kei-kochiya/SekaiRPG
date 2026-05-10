extends PanelContainer
class_name CharacterCard

"""
CharacterCard: Hiển thị thẻ trạng thái của nhân vật hoặc kẻ địch trong trận đấu.

Lớp này quản lý việc hiển thị thông tin trực quan cho một thực thể, bao gồm:
- Ảnh chân dung và Tên (màu sắc phân biệt Ta/Địch).
- Cấp độ và Thanh HP (tự động cập nhật bằng Tween).
- Danh sách hiệu ứng trạng thái (Status Dots).
- Chỉ số hồi chiêu kỹ năng (Cooldown Icons).
Hệ thống sử dụng cơ chế Signal-driven để tự động cập nhật UI khi dữ liệu 
của Entity thay đổi.
"""

const COLORS = {
	"player": Color(0.29, 0.62, 0.62),
	"enemy": Color(0.72, 0.38, 0.16),
	"hp_fill": Color(0.2, 0.8, 0.2),
	"bg": Color(0.12, 0.12, 0.12, 0.9)
}

var entity: Entity
var is_player: bool = false

# Các thành phần giao diện
var hp_bar: ProgressBar
var hp_label: Label
var name_label: Label
var level_label: Label
var status_row: HBoxContainer
var cooldown_icons: Dictionary = {}

func setup(e: Entity, player: bool):
	"""
	Khởi tạo và cấu hình dữ liệu cho thẻ thực thể.

	Args:
		e (Entity): Thực thể mục tiêu cần hiển thị.
		player (bool): Xác định phe của thực thể (Ta/Địch).
	"""
	entity = e
	is_player = player
	_build_ui()
	_connect_signals()
	_refresh_all()

func _build_ui():
	"""Xây dựng cấu trúc cây Node và áp dụng phong cách hình ảnh (Kenney Style)."""
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
	
	vbox.add_child(_create_header())
	
	hp_bar = _create_hp_bar()
	vbox.add_child(hp_bar)
	
	var footer = HBoxContainer.new()
	vbox.add_child(footer)
	
	status_row = HBoxContainer.new()
	footer.add_child(status_row)
	
	if not entity.skills.is_empty():
		var cd_row = _create_cooldown_row()
		vbox.add_child(cd_row)

func _create_header() -> HBoxContainer:
	"""Khởi tạo phần đầu thẻ với chân dung, tên và cấp độ."""
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
	"""Khởi tạo thanh máu với giao diện tùy chỉnh."""
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
	"""Khởi tạo hàng biểu tượng theo dõi thời gian hồi kỹ năng."""
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
	"""Kết nối các tín hiệu của thực thể để đảm bảo UI cập nhật tự động."""
	entity.hp_changed.connect(_on_hp_changed)
	entity.died.connect(_on_died)
	entity.cooldown_updated.connect(_on_cooldown_updated)
	entity.status_changed.connect(_on_status_changed)
	entity.damage_received.connect(_on_damage_received)
	entity.level_changed.connect(_on_level_changed)

func _refresh_all():
	"""Làm mới toàn bộ dữ liệu hiển thị trên thẻ theo trạng thái hiện tại."""
	_on_level_changed(entity.level)
	_on_hp_changed(entity.current_hp, entity.max_hp)
	_on_status_changed(entity.active_statuses)
	if entity.current_hp <= 0: _on_died()

func _on_level_changed(lv: int):
	"""Cập nhật nhãn cấp độ."""
	level_label.text = "Lv.%d" % lv

func _on_hp_changed(cur: int, m_hp: int):
	"""Cập nhật giá trị thanh máu với hiệu ứng chuyển động mượt mà."""
	hp_bar.max_value = m_hp
	var tw = create_tween()
	tw.tween_property(hp_bar, "value", cur, 0.3).set_trans(Tween.TRANS_CUBIC)
	hp_label.text = "%d / %d" % [cur, m_hp]

func _on_died():
	"""Xử lý hiệu ứng thị giác khi thực thể bị hạ gục."""
	modulate = Color(0.5, 0.5, 0.5, 0.7)

func _on_cooldown_updated(skill: String, turns: int):
	"""Cập nhật thông số hồi chiêu trên từng biểu tượng kỹ năng tương ứng."""
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
	"""Cập nhật danh sách các điểm chỉ báo hiệu ứng trạng thái hiện có."""
	for c in status_row.get_children(): c.queue_free()
	for s in statuses:
		var dot = ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.color = Color(0.8, 0.2, 0.2) if s["type"] == "Bleed" else Color(0.2, 0.8, 0.2)
		status_row.add_child(dot)

func _on_damage_received(amt: int, type: String):
	"""Kích hoạt hiệu ứng chữ nổi (Floating Text) khi thực thể chịu tác động."""
	var spawn_pos = global_position + Vector2(size.x / 2, 0)
	var overlay = get_tree().get_first_node_in_group("ui_overlay")
	FloatingText.spawn(overlay if overlay else get_tree().root, amt, type, spawn_pos)
