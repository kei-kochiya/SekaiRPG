extends CanvasLayer

"""
Tóm tắt: UpgradeUI là hệ thống giao diện cho phép người chơi nâng cấp chỉ số nhân vật.

Chức năng chính:
- Khởi tạo bảng UI động hiển thị danh sách các nhân vật trong đội hình.
- Lấy và hiển thị các chỉ số hiện tại (HP, ATK, DEF, SPD) và Điểm Kỹ Năng (SP) của nhân vật được chọn.
- Xây dựng cụm nút nâng cấp (+1, +10, +25, MAX) kết nối trực tiếp với API của `UpgradeManager`.
- Tự động khóa sự kiện di chuyển của người chơi (thông qua `GameManager.start_dialogue()`) khi đang hiển thị.
"""

# ── Biến Giao Diện & Dữ Liệu ───────────────────────────────────────────────


signal closed

const THEME_COLOR = Color(0.2, 0.6, 0.8)
const BG_COLOR = Color(0.05, 0.05, 0.08, 0.9)

var characters: Array[Entity] = []
var selected_index: int = 0

var char_list: VBoxContainer
var stat_vbox: VBoxContainer
var sp_label: Label
var char_name_label: Label

# ── Vòng Đời & Khởi Tạo UI ──────────────────────────────────────────────────

# Khởi tạo giao diện
func _ready():
	_build_ui()
	visible = false

# ── API Hiển Thị ───────────────────────────────────────────────────────────

func show_ui(chars: Array[Entity]):
	"""
	Hiển thị giao diện nâng cấp với danh sách nhân vật hiện có.
	
	Args:
		chars (Array[Entity]): Danh sách các nhân vật có thể nâng cấp.
	Returns: Không có
	"""
	characters = chars
	selected_index = 0
	visible = true
	GameManager.start_dialogue()
	_refresh_all()

# ── Xây Dựng Cấu Trúc UI ───────────────────────────────────────────────────

# Xây dựng cấu trúc UI động
func _build_ui():
	# Lớp nền tối mờ (Dimmer) toàn màn hình để loại bỏ hoàn toàn hiện tượng xuyên thấu
	var dimmer = ColorRect.new()
	dimmer.name = "ModalDimmer"
	dimmer.color = Color(0.04, 0.03, 0.02, 0.75)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dimmer)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 420)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var sb = StyleBoxTexture.new()
	sb.texture = load("res://Assets/UI/panel_angular_brown.svg")
	sb.texture_margin_left = 24; sb.texture_margin_right = 24
	sb.texture_margin_top = 24; sb.texture_margin_bottom = 24
	sb.content_margin_left = 28; sb.content_margin_right = 28
	sb.content_margin_top = 24; sb.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", sb)
	
	add_child(panel)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 24)
	panel.add_child(main_hbox)
	
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(160, 0)
	main_hbox.add_child(left_vbox)
	
	var list_title = Label.new()
	list_title.text = "NHÂN VẬT"
	list_title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.45))
	list_title.add_theme_font_size_override("font_size", 16)
	left_vbox.add_child(list_title)
	
	char_list = VBoxContainer.new()
	char_list.name = "CharList"
	char_list.add_theme_constant_override("separation", 6)
	left_vbox.add_child(char_list)
	
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_vbox)
	
	char_name_label = Label.new()
	char_name_label.name = "CharNameLabel"
	char_name_label.text = "NAME"
	char_name_label.add_theme_font_size_override("font_size", 22)
	char_name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	right_vbox.add_child(char_name_label)
	
	sp_label = Label.new()
	sp_label.name = "SPLabel"
	sp_label.text = "Điểm kỹ năng (SP): 0"
	sp_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	sp_label.add_theme_font_size_override("font_size", 15)
	right_vbox.add_child(sp_label)
	
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color(0.35, 0.25, 0.18, 0.9)
	right_vbox.add_child(sep)
	
	stat_vbox = VBoxContainer.new()
	stat_vbox.name = "StatVBox"
	stat_vbox.add_theme_constant_override("separation", 10)
	right_vbox.add_child(stat_vbox)
	
	var close_btn = Button.new()
	close_btn.text = " ĐÓNG "
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.custom_minimum_size = Vector2(100, 34)
	
	var r_normal = StyleBoxTexture.new()
	r_normal.texture = load("res://Assets/UI/btn_angular_red.svg")
	r_normal.texture_margin_left = 8; r_normal.texture_margin_right = 8
	r_normal.texture_margin_top = 8; r_normal.texture_margin_bottom = 8
	close_btn.add_theme_stylebox_override("normal", r_normal)
	
	var r_hover = StyleBoxTexture.new()
	r_hover.texture = load("res://Assets/UI/btn_angular_red_hover.svg")
	r_hover.texture_margin_left = 8; r_hover.texture_margin_right = 8
	r_hover.texture_margin_top = 8; r_hover.texture_margin_bottom = 8
	close_btn.add_theme_stylebox_override("hover", r_hover)
	close_btn.add_theme_stylebox_override("pressed", r_hover)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.9))
	close_btn.add_theme_font_size_override("font_size", 13)
	
	close_btn.pressed.connect(func():
		visible = false
		GameManager.end_dialogue()
		closed.emit()
	)
	right_vbox.add_child(Control.new())
	right_vbox.add_child(close_btn)

# ── Tiện Ích Cập Nhật UI ───────────────────────────────────────────────────

func _refresh_all():
	for c in char_list.get_children(): c.queue_free()
	for i in range(characters.size()):
		var btn = Button.new()
		btn.text = " %s " % characters[i].entity_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(150, 34)
		
		var is_selected = (i == selected_index)
		var ns = StyleBoxTexture.new()
		ns.texture = load("res://Assets/UI/btn_angular_amber.svg" if is_selected else "res://Assets/UI/btn_angular_brown.svg")
		ns.texture_margin_left = 8; ns.texture_margin_right = 8
		ns.texture_margin_top = 8; ns.texture_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", ns)
		
		var hs = StyleBoxTexture.new()
		hs.texture = load("res://Assets/UI/btn_angular_amber_hover.svg" if is_selected else "res://Assets/UI/btn_angular_brown_hover.svg")
		hs.texture_margin_left = 8; hs.texture_margin_right = 8
		hs.texture_margin_top = 8; hs.texture_margin_bottom = 8
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("pressed", hs)
		
		btn.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7) if is_selected else Color(0.92, 0.88, 0.82))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.85))
		btn.add_theme_font_size_override("font_size", 14)
		btn.pressed.connect(func():
			selected_index = i
			_refresh_all()
		)
		char_list.add_child(btn)
	
	var entity = characters[selected_index]
	char_name_label.text = entity.entity_name.to_upper() + " - Lv." + str(entity.level)
	sp_label.text = "Điểm kỹ năng (SP): " + str(entity.skill_points)
	
	for c in stat_vbox.get_children(): c.queue_free()
	
	var stats_to_show = ["max_hp", "atk", "defense", "spd"]
	var labels = {
		"max_hp": "Máu (HP)",
		"atk": "Tấn công (ATK)",
		"defense": "Phòng thủ (DEF)",
		"spd": "Tốc độ (SPD)"
	}
	
	for stat in stats_to_show:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		stat_vbox.add_child(row)
		
		var name_lbl = Label.new()
		name_lbl.text = labels[stat]
		name_lbl.custom_minimum_size = Vector2(130, 0)
		name_lbl.add_theme_color_override("font_color", Color(0.85, 0.8, 0.72))
		name_lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(name_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = str(entity.get(stat))
		val_lbl.custom_minimum_size = Vector2(55, 0)
		val_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
		val_lbl.add_theme_font_size_override("font_size", 14)
		row.add_child(val_lbl)
		
		var btn_container = HBoxContainer.new()
		btn_container.add_theme_constant_override("separation", 6)
		row.add_child(btn_container)
		
		var create_up_btn = func(label: String, count: int, is_max: bool = false):
			var b = Button.new()
			b.text = label
			b.custom_minimum_size = Vector2(52 if is_max else 42, 28)
			
			var bns = StyleBoxTexture.new()
			bns.texture = load("res://Assets/UI/btn_angular_amber.svg" if is_max else "res://Assets/UI/btn_angular_brown.svg")
			bns.texture_margin_left = 6; bns.texture_margin_right = 6
			bns.texture_margin_top = 6; bns.texture_margin_bottom = 6
			b.add_theme_stylebox_override("normal", bns)
			
			var bhs = StyleBoxTexture.new()
			bhs.texture = load("res://Assets/UI/btn_angular_amber_hover.svg" if is_max else "res://Assets/UI/btn_angular_brown_hover.svg")
			bhs.texture_margin_left = 6; bhs.texture_margin_right = 6
			bhs.texture_margin_top = 6; bhs.texture_margin_bottom = 6
			b.add_theme_stylebox_override("hover", bhs)
			b.add_theme_stylebox_override("pressed", bhs)
			
			b.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3) if is_max else Color(0.95, 0.9, 0.82))
			b.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.8))
			b.add_theme_font_size_override("font_size", 12)
			b.pressed.connect(func():
				if count == 1:
					if UpgradeManager.upgrade_stat(entity, stat): _refresh_all()
				else:
					if UpgradeManager.bulk_upgrade(entity, stat, count) > 0: _refresh_all()
			)
			return b
			
		btn_container.add_child(create_up_btn.call("+1", 1, false))
		btn_container.add_child(create_up_btn.call("+10", 10, false))
		btn_container.add_child(create_up_btn.call("+25", 25, false))
		btn_container.add_child(create_up_btn.call("MAX", 999, true))
		
		var inc_lbl = Label.new()
		inc_lbl.text = "(+%d)" % UpgradeManager.UPGRADE_AMOUNTS[stat]
		inc_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		inc_lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(inc_lbl)
