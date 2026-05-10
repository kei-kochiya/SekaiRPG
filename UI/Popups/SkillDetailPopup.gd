extends PanelContainer
class_name SkillDetailPopup

"""
SkillDetailPopup: Cửa sổ hiển thị thông tin chuyên sâu của một kỹ năng.
Bao gồm mô tả, tỉ lệ sát thương và các hiệu ứng đi kèm. 
Tách ra từ CommandMenu để giữ code điều khiển gọn gàng.
"""

var _content_vbox: VBoxContainer

func _init():
	visible = false
	top_level = true
	set_anchors_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	custom_minimum_size = Vector2(400, 250)
	
	var sb = StyleBoxTexture.new()
	sb.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/panel_border_brown.svg")
	sb.texture_margin_left = 32; sb.texture_margin_right = 32
	sb.texture_margin_top = 32; sb.texture_margin_bottom = 32
	sb.set_content_margin_all(24)
	add_theme_stylebox_override("panel", sb)
	
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.04, 0.03, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.show_behind_parent = true
	add_child(bg)
	
	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 15)
	add_child(_content_vbox)

func display_skill(skill: Dictionary):
	"""
	Cập nhật nội dung và hiển thị bảng chi tiết kỹ năng.
	"""
	for c in _content_vbox.get_children():
		c.queue_free()
	
	# Header (Tiêu đề + Nút đóng)
	var header = HBoxContainer.new()
	_content_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "CHI TIẾT KỸ NĂNG"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)
	
	var close_btn = Button.new()
	close_btn.icon = load("res://Assets/kenney_ui-pack-adventure/Vector/checkbox_brown_cross.svg")
	close_btn.flat = true
	close_btn.pressed.connect(func(): visible = false)
	header.add_child(close_btn)
	
	# Nội dung tên chiêu
	var name_lbl = Label.new()
	name_lbl.text = skill["name"]
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	name_lbl.add_theme_font_size_override("font_size", 22)
	_content_vbox.add_child(name_lbl)
	
	# Nội dung mô tả chi tiết (scaling, effects)
	var details = Label.new()
	details.text = skill.get("details", "Không có thông tin chi tiết.")
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_font_size_override("font_size", 16)
	_content_vbox.add_child(details)
	
	visible = true
