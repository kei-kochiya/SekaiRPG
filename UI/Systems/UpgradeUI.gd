extends CanvasLayer

"""
UpgradeUI: Giao diện nâng cấp chỉ số nhân vật bằng điểm SP.

Cho phép người chơi lựa chọn nhân vật trong đội và sử dụng Skill Points (SP) 
để tăng vĩnh viễn các chỉ số như HP, ATK, DEF và SPD.
"""

signal closed

const THEME_COLOR = Color(0.2, 0.6, 0.8)
const BG_COLOR = Color(0.05, 0.05, 0.08, 0.9)

var characters: Array[Entity] = []
var selected_index: int = 0

var char_list: VBoxContainer
var stat_vbox: VBoxContainer
var sp_label: Label
var char_name_label: Label

func _ready():
	"""
	Khởi tạo cấu trúc UI ban đầu.
	"""
	_build_ui()
	visible = false

func show_ui(chars: Array[Entity]):
	"""
	Hiển thị giao diện nâng cấp với danh sách nhân vật hiện có.

	Args:
		chars (Array[Entity]): Danh sách các nhân vật có thể nâng cấp.
	"""
	characters = chars
	selected_index = 0
	visible = true
	GameManager.start_dialogue() # Khóa di chuyển người chơi khi đang nâng cấp
	_refresh_all()

func _build_ui():
	"""
	Xây dựng cây node giao diện động cho bảng nâng cấp.
	"""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 400)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var sb = StyleBoxTexture.new()
	sb.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/panel_border_brown.svg")
	sb.texture_margin_left = 32; sb.texture_margin_right = 32
	sb.texture_margin_top = 32; sb.texture_margin_bottom = 32
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", sb)
	
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.08, 0.05, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.show_behind_parent = true
	panel.add_child(bg)
	
	add_child(panel)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 20)
	panel.add_child(main_hbox)
	
	# -- Cột trái: Danh sách nhân vật --
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(150, 0)
	main_hbox.add_child(left_vbox)
	
	var list_title = Label.new()
	list_title.text = "NHÂN VẬT"
	list_title.add_theme_color_override("font_color", THEME_COLOR)
	left_vbox.add_child(list_title)
	
	char_list = VBoxContainer.new()
	char_list.name = "CharList"
	left_vbox.add_child(char_list)
	
	# -- Cột phải: Chỉ số & Nút nâng cấp --
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_vbox)
	
	char_name_label = Label.new()
	char_name_label.name = "CharNameLabel"
	char_name_label.text = "NAME"
	char_name_label.add_theme_font_size_override("font_size", 24)
	right_vbox.add_child(char_name_label)
	
	sp_label = Label.new()
	sp_label.name = "SPLabel"
	sp_label.text = "Điểm kỹ năng (SP): 0"
	sp_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	right_vbox.add_child(sp_label)
	
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color(0.3, 0.3, 0.3)
	right_vbox.add_child(sep)
	
	stat_vbox = VBoxContainer.new()
	stat_vbox.name = "StatVBox"
	stat_vbox.add_theme_constant_override("separation", 10)
	right_vbox.add_child(stat_vbox)
	
	# Nút đóng
	var close_btn = Button.new()
	close_btn.text = " ĐÓNG "
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.pressed.connect(func():
		visible = false
		GameManager.end_dialogue()
		closed.emit()
	)
	right_vbox.add_child(Control.new())
	right_vbox.add_child(close_btn)

func _refresh_all():
	"""
	Cập nhật lại danh sách nhân vật và các chỉ số hiển thị của nhân vật đang chọn.
	"""
	# Làm mới danh sách nhân vật bên trái
	for c in char_list.get_children(): c.queue_free()
	for i in range(characters.size()):
		var btn = Button.new()
		btn.text = characters[i].entity_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var ns = StyleBoxTexture.new()
		ns.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg")
		ns.texture_margin_left = 10; ns.texture_margin_right = 10
		ns.texture_margin_top = 10; ns.texture_margin_bottom = 14
		btn.add_theme_stylebox_override("normal", ns)
		
		btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
		btn.pressed.connect(func():
			selected_index = i
			_refresh_all()
		)
		char_list.add_child(btn)
	
	var entity = characters[selected_index]
	char_name_label.text = entity.entity_name.to_upper() + " - Lv." + str(entity.level)
	sp_label.text = "Điểm kỹ năng (SP): " + str(entity.skill_points)
	
	# Làm mới khu vực chỉ số bên phải
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
		stat_vbox.add_child(row)
		
		var name_lbl = Label.new()
		name_lbl.text = labels[stat]
		name_lbl.custom_minimum_size = Vector2(120, 0)
		row.add_child(name_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = str(entity.get(stat))
		val_lbl.custom_minimum_size = Vector2(60, 0)
		row.add_child(val_lbl)
		
		# Nút nâng cấp
		var btn_container = HBoxContainer.new()
		btn_container.add_theme_constant_override("separation", 4)
		row.add_child(btn_container)
		
		# Hàm tạo nút helper
		var create_up_btn = func(label: String, count: int):
			var b = Button.new()
			b.text = label
			var bns = StyleBoxTexture.new()
			bns.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg")
			bns.texture_margin_left = 6; bns.texture_margin_right = 6
			bns.texture_margin_top = 6; bns.texture_margin_bottom = 10
			b.add_theme_stylebox_override("normal", bns)
			b.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
			b.add_theme_font_size_override("font_size", 11)
			b.pressed.connect(func():
				if count == 1:
					if UpgradeManager.upgrade_stat(entity, stat): _refresh_all()
				else:
					if UpgradeManager.bulk_upgrade(entity, stat, count) > 0: _refresh_all()
			)
			return b
			
		btn_container.add_child(create_up_btn.call("+1", 1))
		btn_container.add_child(create_up_btn.call("+10", 10))
		btn_container.add_child(create_up_btn.call("+25", 25))
		btn_container.add_child(create_up_btn.call("MAX", 999))
		
		var inc_lbl = Label.new()
		inc_lbl.text = "(+%d)" % UpgradeManager.UPGRADE_AMOUNTS[stat]
		inc_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		inc_lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(inc_lbl)
