extends PanelContainer
class_name EntityDetailPanel

"""
EntityDetailPanel: Bảng hiển thị thông tin chi tiết chỉ số và kỹ năng của thực thể.
Được tách ra từ BattleHUD để giảm độ phức tạp của code giao diện chính.
"""

func _init():
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = 100; offset_right = -100
	offset_top = 50; offset_bottom = -50
	
	var dsb = StyleBoxFlat.new()
	dsb.bg_color = Color(0, 0, 0, 0.85)
	dsb.border_width_left = 4
	dsb.border_color = Color(0.4, 0.7, 1.0)
	add_theme_stylebox_override("panel", dsb)

func show_entities(p_team: Array, e_team: Array):
	"""
	Hiển thị bảng chi tiết cho hai đội.
	"""
	# Xóa nội dung cũ
	for child in get_children():
		child.queue_free()
	
	var scroll = ScrollContainer.new()
	add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(vbox)
	
	# Nút đóng
	var close = Button.new()
	close.text = "[ ĐÓNG ]"
	close.pressed.connect(func(): visible = false)
	vbox.add_child(close)
	
	# Danh sách phe ta
	var lbl_p = Label.new()
	lbl_p.text = "=== PHE TA ==="
	lbl_p.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	vbox.add_child(lbl_p)
	
	for e in p_team:
		_add_entity_info(vbox, e)
		
	# Danh sách kẻ địch
	var lbl_e = Label.new()
	lbl_e.text = "=== KẺ ĐỊCH ==="
	lbl_e.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	vbox.add_child(lbl_e)
	
	for e in e_team:
		_add_entity_info(vbox, e)
		
	visible = true

func _add_entity_info(parent: Control, e: Entity):
	"""
	Hàm nội bộ để dựng UI thông tin cho một thực thể đơn lẻ.
	"""
	var box = VBoxContainer.new()
	parent.add_child(box)
	
	var name_lbl = Label.new()
	name_lbl.text = "%s (Lv.%d) - HP: %d/%d" % [e.entity_name, e.level, e.current_hp, e.max_hp]
	name_lbl.add_theme_font_size_override("font_size", 18)
	box.add_child(name_lbl)
	
	var stats_lbl = Label.new()
	stats_lbl.text = "ATK: %d | DEF: %d | SPD: %d | HỆ: %s" % [e.atk, e.defense, e.spd, e.type]
	stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	box.add_child(stats_lbl)
	
	var skill_box = VBoxContainer.new()
	skill_box.add_theme_constant_override("separation", 2)
	box.add_child(skill_box)
	
	for s in e.skills:
		var s_lbl = Label.new()
		var cd = e.cooldowns.get(s["method"], 0)
		var cd_text = " (Hồi chiêu: %d lượt)" % cd if cd > 0 else " [Sẵn sàng]"
		s_lbl.text = " - %s: %s %s" % [s["name"], s.get("details", ""), cd_text]
		s_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		skill_box.add_child(s_lbl)
