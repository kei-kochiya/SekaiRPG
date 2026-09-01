extends Control

"""
SaveLoadMenu: Giao diện Lưu & Tải game toàn diện của SekaiRPG.

Chức năng:
- Đồng bộ phong cách Kenney UI (Brown Panel, Adventure Buttons).
- Quản lý danh sách file save trong `user://saves/` với tên file tự do, Quick Save và Auto-Save.
- Hiển thị đầy đủ siêu dữ liệu: Tên Quest hiện tại (QuestRegistry), Tên Map, Ngày giờ lưu.
- Hỗ trợ Lưu file mới, Tải game, Ghi đè, và Xóa file kèm hộp thoại xác nhận.
- Hoạt động linh hoạt cả ở dạng Cảnh độc lập (từ StartMenu) lẫn dạng Lớp phủ (Overlay từ PauseMenu).
"""

const FONT_BODY = "res://Fonts/#9Slide03 AMPLESOFT MEDIUM.ttf"
const FONT_TITLE = "res://Fonts/zhcn.ttf"
const BTN_BROWN_TEX = "res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg"
const BTN_GREY_TEX = "res://Assets/kenney_ui-pack-adventure/Vector/button_grey.svg"
const BTN_RED_TEX = "res://Assets/kenney_ui-pack-adventure/Vector/button_red.svg"
const PANEL_BROWN_TEX = "res://Assets/kenney_ui-pack-adventure/Vector/panel_brown.svg"

var slot_container: VBoxContainer
var new_save_edit: LineEdit
var is_in_game_mode: bool = false
var _confirm_dialog: PanelContainer = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_check_mode()
	_build_ui()
	_refresh_slots()
	ScreenFade.fade_in(0.3)

func _check_mode():
	# Kiểm tra xem có đang ở trong game (Overworld / Map) hay từ StartMenu
	var cur_scene = get_tree().current_scene
	if cur_scene != null and cur_scene.name == "StartMenu" and get_parent() == get_tree().root:
		is_in_game_mode = false
	else:
		is_in_game_mode = true

# ── Xây dựng Giao diện ─────────────────────────────────────────────────────

func _build_ui():
	for c in get_children(): c.queue_free()
	
	# Lớp nền mờ
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var main_panel = PanelContainer.new()
	main_panel.custom_minimum_size = Vector2(650, 520)
	center.add_child(main_panel)
	
	var sb = StyleBoxTexture.new()
	sb.texture = load(PANEL_BROWN_TEX)
	sb.texture_margin_left = 16; sb.texture_margin_right = 16
	sb.texture_margin_top = 16; sb.texture_margin_bottom = 16
	sb.set_content_margin_all(20)
	main_panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	main_panel.add_child(vbox)
	
	# Tiêu đề
	var title = Label.new()
	title.text = "HỆ THỐNG LƯU TRỮ & TẢI GAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_font_override("font", load(FONT_TITLE))
	title.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	vbox.add_child(title)
	
	# Thanh nhập file lưu mới (Chỉ hiện khi đang trong game)
	if is_in_game_mode:
		var new_save_box = HBoxContainer.new()
		new_save_box.add_theme_constant_override("separation", 8)
		vbox.add_child(new_save_box)
		
		new_save_edit = LineEdit.new()
		new_save_edit.placeholder_text = "Nhập tên file lưu mới..."
		new_save_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		new_save_edit.custom_minimum_size = Vector2(0, 36)
		new_save_edit.add_theme_font_override("font", load(FONT_BODY))
		new_save_box.add_child(new_save_edit)
		new_save_edit.text_submitted.connect(func(_t): _on_create_new_save())
		
		var btn_new = _create_styled_button(" + LƯU MỚI ", _on_create_new_save, BTN_BROWN_TEX)
		btn_new.custom_minimum_size = Vector2(130, 36)
		new_save_box.add_child(btn_new)
	
	# Danh sách file save (Scroll Area)
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 320)
	vbox.add_child(scroll)
	
	slot_container = VBoxContainer.new()
	slot_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_container.add_theme_constant_override("separation", 10)
	scroll.add_child(slot_container)
	
	# Nút đóng / quay lại
	var back_btn = _create_styled_button("ĐÓNG", _on_back_pressed, BTN_GREY_TEX)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.custom_minimum_size = Vector2(180, 38)
	vbox.add_child(back_btn)

# ── Cập nhật Danh sách Slots ───────────────────────────────────────────────

func _refresh_slots():
	for c in slot_container.get_children():
		c.queue_free()
		
	var slots = SaveManager.get_all_save_slots()
	
	if slots.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "(Chưa có file lưu nào trong hệ thống)"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3))
		empty_lbl.add_theme_font_override("font", load(FONT_BODY))
		slot_container.add_child(empty_lbl)
		return
		
	for slot_data in slots:
		_create_slot_card(slot_data)

func _create_slot_card(data: Dictionary):
	var card = PanelContainer.new()
	var csb = StyleBoxFlat.new()
	csb.bg_color = Color(0.15, 0.12, 0.1, 0.85)
	csb.set_border_width_all(2)
	csb.border_color = Color(0.6, 0.5, 0.3)
	csb.set_corner_radius_all(6)
	csb.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", csb)
	slot_container.add_child(card)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	card.add_child(main_vbox)
	
	# Hàng 1: Tên file & Thời gian
	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)
	
	var file_name = data.get("file_name", "save.json")
	var is_auto = (file_name == "autosave.json")
	var is_quick = (file_name == "quicksave.json")
	
	var name_lbl = Label.new()
	name_lbl.text = "💾 " + file_name
	if is_auto: name_lbl.text = "⚡ [TỰ ĐỘNG] " + file_name
	elif is_quick: name_lbl.text = "⚡ [LƯU NHANH] " + file_name
	
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4) if (is_auto or is_quick) else Color.WHITE)
	name_lbl.add_theme_font_override("font", load(FONT_BODY))
	header_hbox.add_child(name_lbl)
	
	var time_lbl = Label.new()
	time_lbl.text = "🕒 " + data.get("timestamp", "")
	time_lbl.add_theme_font_size_override("font_size", 12)
	time_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	time_lbl.add_theme_font_override("font", load(FONT_BODY))
	header_hbox.add_child(time_lbl)
	
	# Hàng 2: Badges Nhiệm vụ & Bản đồ
	var info_hbox = HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 15)
	main_vbox.add_child(info_hbox)
	
	var quest_name = data.get("quest_name", "Nhiệm vụ chưa xác định")
	var map_name = data.get("map_name", "Bản đồ chưa xác định")
	
	var quest_lbl = Label.new()
	quest_lbl.text = "📜 Nhiệm vụ: " + quest_name
	quest_lbl.add_theme_font_size_override("font_size", 13)
	quest_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	quest_lbl.add_theme_font_override("font", load(FONT_BODY))
	info_hbox.add_child(quest_lbl)
	
	var map_lbl = Label.new()
	map_lbl.text = "📍 Địa điểm: " + map_name
	map_lbl.add_theme_font_size_override("font_size", 13)
	map_lbl.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	map_lbl.add_theme_font_override("font", load(FONT_BODY))
	info_hbox.add_child(map_lbl)
	
	# Hàng 3: Cụm nút bấm hành động
	var actions_hbox = HBoxContainer.new()
	actions_hbox.alignment = BoxContainer.ALIGNMENT_END
	actions_hbox.add_theme_constant_override("separation", 8)
	main_vbox.add_child(actions_hbox)
	
	var full_path = data.get("path", "")
	
	# Nút Tải
	var btn_load = _create_styled_button("TẢI GAME", func(): _on_load_save(full_path), BTN_BROWN_TEX)
	btn_load.custom_minimum_size = Vector2(100, 30)
	actions_hbox.add_child(btn_load)
	
	# Nút Ghi đè (chỉ khi in-game)
	if is_in_game_mode:
		var btn_overwrite = _create_styled_button("GHI ĐÈ", func(): _confirm_overwrite(full_path), BTN_GREY_TEX)
		btn_overwrite.custom_minimum_size = Vector2(90, 30)
		actions_hbox.add_child(btn_overwrite)
		
	# Nút Xóa
	var btn_del = _create_styled_button("XÓA", func(): _confirm_delete(full_path), BTN_RED_TEX)
	btn_del.custom_minimum_size = Vector2(70, 30)
	actions_hbox.add_child(btn_del)

# ── Xử Lý Hành Động ────────────────────────────────────────────────────────

func _on_create_new_save():
	if not new_save_edit: return
	var fname = new_save_edit.text.strip_edges()
	if fname == "":
		var dt = Time.get_datetime_dict_from_system()
		fname = "save_%02d%02d_%02d%02d" % [dt["day"], dt["month"], dt["hour"], dt["minute"]]
	
	new_save_edit.text = ""
	GameManager.save_game(fname)
	_refresh_slots()

func _on_load_save(path: String):
	print("[SaveLoadMenu] Đang tải game từ: ", path)
	await ScreenFade.fade_out(0.5)
	GameManager.load_game(path)

func _confirm_overwrite(path: String):
	_show_confirmation(
		"XÁC NHẬN GHI ĐÈ",
		"Bạn có chắc chắn muốn ghi đè lên file:\n[" + path.get_file() + "] không?",
		func():
			GameManager.save_game(path)
			_refresh_slots()
	)

func _confirm_delete(path: String):
	_show_confirmation(
		"XÁC NHẬN XÓA FILE",
		"Bạn có chắc chắn muốn xóa vĩnh viễn file:\n[" + path.get_file() + "] không?",
		func():
			SaveManager.delete_save(path)
			_refresh_slots()
	)

func _show_confirmation(title_text: String, msg_text: String, on_confirm: Callable):
	if _confirm_dialog: _confirm_dialog.queue_free()
	
	_confirm_dialog = PanelContainer.new()
	_confirm_dialog.custom_minimum_size = Vector2(380, 180)
	_confirm_dialog.set_anchors_preset(Control.PRESET_CENTER)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.1, 0.08, 0.98)
	sb.set_border_width_all(3)
	sb.border_color = Color(0.9, 0.6, 0.2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(20)
	_confirm_dialog.add_theme_stylebox_override("panel", sb)
	add_child(_confirm_dialog)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	_confirm_dialog.add_child(vbox)
	
	var t_lbl = Label.new()
	t_lbl.text = title_text
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lbl.add_theme_font_size_override("font_size", 18)
	t_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	t_lbl.add_theme_font_override("font", load(FONT_BODY))
	vbox.add_child(t_lbl)
	
	var m_lbl = Label.new()
	m_lbl.text = msg_text
	m_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_lbl.add_theme_font_size_override("font_size", 14)
	m_lbl.add_theme_font_override("font", load(FONT_BODY))
	vbox.add_child(m_lbl)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)
	
	var btn_yes = _create_styled_button("ĐỒNG Ý", func():
		_confirm_dialog.queue_free()
		on_confirm.call()
	, BTN_BROWN_TEX)
	btn_yes.custom_minimum_size = Vector2(100, 34)
	hbox.add_child(btn_yes)
	
	var btn_no = _create_styled_button("HỦY", func():
		_confirm_dialog.queue_free()
	, BTN_GREY_TEX)
	btn_no.custom_minimum_size = Vector2(100, 34)
	hbox.add_child(btn_no)

func _on_back_pressed():
	if get_parent() != get_tree().root:
		queue_free()
		return
	get_tree().change_scene_to_file("res://Menus/Start/StartMenu.tscn")

# ── Helper Nút Bấm Phong Cách Kenney ───────────────────────────────────────

func _create_styled_button(txt: String, callback: Callable, tex_path: String) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.add_theme_font_override("font", load(FONT_BODY))
	btn.add_theme_font_size_override("font_size", 14)
	
	var ns = StyleBoxTexture.new()
	ns.texture = load(tex_path)
	ns.texture_margin_left = 8; ns.texture_margin_right = 8
	ns.texture_margin_top = 8; ns.texture_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", ns)
	
	var hs = StyleBoxTexture.new()
	hs.texture = load(BTN_GREY_TEX)
	hs.texture_margin_left = 8; hs.texture_margin_right = 8
	hs.texture_margin_top = 8; hs.texture_margin_bottom = 12
	btn.add_theme_stylebox_override("hover", hs)
	btn.add_theme_stylebox_override("focus", hs)
	
	btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	btn.add_theme_color_override("font_hover_color", Color.BLACK)
	btn.pressed.connect(callback)
	return btn
