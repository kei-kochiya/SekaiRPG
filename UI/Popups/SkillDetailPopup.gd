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
	sb.texture = load("res://Assets/UI/panel_angular_brown.svg")
	sb.texture_margin_left = 20; sb.texture_margin_right = 20
	sb.texture_margin_top = 20; sb.texture_margin_bottom = 20
	sb.content_margin_left = 24; sb.content_margin_right = 24
	sb.content_margin_top = 20; sb.content_margin_bottom = 20
	add_theme_stylebox_override("panel", sb)
	
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
	
	var close_btn = _create_close_button()
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

func display_entity_skills(entity: Entity):
	"""
	Hiển thị toàn bộ danh sách kỹ năng của một thực thể.
	"""
	for c in _content_vbox.get_children():
		c.queue_free()
	
	var header = HBoxContainer.new()
	_content_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "THÔNG TIN KỸ NĂNG: " + entity.entity_name.to_upper()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 18)
	header.add_child(title)
	
	var close_btn = _create_close_button()
	header.add_child(close_btn)
	
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_vbox.add_child(scroll)
	
	var list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 20)
	scroll.add_child(list)
	
	for skill in entity.skills:
		var item = VBoxContainer.new()
		list.add_child(item)
		
		var name_lbl = Label.new()
		name_lbl.text = "✦ " + skill["name"]
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		name_lbl.add_theme_font_size_override("font_size", 18)
		item.add_child(name_lbl)
		
		var details = Label.new()
		details.text = skill.get("details", "Không có thông tin chi tiết.")
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_theme_font_size_override("font_size", 14)
		item.add_child(details)
	
	visible = true

func _create_close_button() -> Button:
	var close_btn = Button.new()
	close_btn.text = " ✕ "
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.88))
	var cb_sb = StyleBoxTexture.new()
	cb_sb.texture = load("res://Assets/UI/btn_angular_red.svg")
	cb_sb.texture_margin_left = 6
	cb_sb.texture_margin_right = 6
	cb_sb.texture_margin_top = 4
	cb_sb.texture_margin_bottom = 6
	close_btn.add_theme_stylebox_override("normal", cb_sb)
	close_btn.add_theme_stylebox_override("hover", cb_sb)
	close_btn.pressed.connect(func(): visible = false)
	return close_btn
