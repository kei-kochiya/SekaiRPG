extends CanvasLayer

"""
PauseMenu: Hệ thống Menu tạm dừng của trò chơi.

Cung cấp các chức năng: Tiếp tục, Lưu game, Xem hướng dẫn và Thoát ra Menu chính.
Menu này hoạt động độc lập với trạng thái Pause của game để người chơi vẫn có thể tương tác UI.
"""

# ── Biến tham chiếu ────────────────────────────────────────────────────────
var _root: Control
var _panel: PanelContainer
var _guide_panel: PanelContainer
var _options_panel: PanelContainer

func _ready():
	"""
	Khởi tạo cấu hình ban đầu cho Menu tạm dừng.
	"""
	process_mode = Node.PROCESS_MODE_ALWAYS # Cho phép hoạt động ngay cả khi game bị pause
	layer = 110
	visible = false
	_build_ui()

func _build_ui():
	"""
	Xây dựng cây node giao diện cho Menu tạm dừng.
	"""
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	
	# Hiệu ứng làm mờ nền
	var dim = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	_root.add_child(dim)
	
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -150
	_panel.offset_right = 150
	_panel.offset_top = -100
	_panel.offset_bottom = 100
	
	var sb = StyleBoxTexture.new()
	sb.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/panel_brown.svg")
	sb.texture_margin_left = 12; sb.texture_margin_right = 12
	sb.texture_margin_top = 12; sb.texture_margin_bottom = 12
	sb.set_content_margin_all(20)
	_panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(_panel)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "TẠM DỪNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	vbox.add_child(_create_button("Tiếp tục", _on_resume))
	vbox.add_child(_create_button("Lưu Game", _on_save))
	vbox.add_child(_create_button("Hướng dẫn", _on_guide))
	vbox.add_child(_create_button("Tùy chọn", _on_options))
	vbox.add_child(_create_button("Thoát ra Menu", _on_quit))

	# --- Bảng Hướng dẫn (Guide Panel) ---
	_guide_panel = PanelContainer.new()
	_guide_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_guide_panel.offset_left = 50
	_guide_panel.offset_right = -50
	_guide_panel.offset_top = 50
	_guide_panel.offset_bottom = -50
	_guide_panel.visible = false
	
	var gsb = StyleBoxFlat.new()
	gsb.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	gsb.border_width_left = 4
	gsb.border_color = Color(0.4, 1.0, 0.7)
	_guide_panel.add_theme_stylebox_override("panel", gsb)
	_root.add_child(_guide_panel)

	# --- Bảng Tùy chọn (Options Panel) ---
	_options_panel = PanelContainer.new()
	_options_panel.set_anchors_preset(Control.PRESET_CENTER)
	_options_panel.offset_left = -200; _options_panel.offset_right = 200
	_options_panel.offset_top = -150; _options_panel.offset_bottom = 150
	_options_panel.visible = false
	
	var osb = StyleBoxTexture.new()
	osb.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/panel_grey.svg")
	osb.texture_margin_left = 12; osb.texture_margin_right = 12
	osb.texture_margin_top = 12; osb.texture_margin_bottom = 12
	osb.set_content_margin_all(20)
	_options_panel.add_theme_stylebox_override("panel", osb)
	_root.add_child(_options_panel)

func _on_guide():
	"""
	Xử lý khi mở bảng hướng dẫn nâng cao.
	"""
	if _guide_panel.visible:
		_guide_panel.visible = false
		return
		
	# Xóa nội dung cũ để xây dựng lại (tránh trùng lặp)
	for child in _guide_panel.get_children():
		child.queue_free()
		
	var scroll = ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	_guide_panel.add_child(scroll)
	
	var margin = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	scroll.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 15)
	margin.add_child(vbox)
	
	var close = Button.new()
	close.text = "[ ĐÓNG HƯỚNG DẪN ]"
	close.pressed.connect(func(): _guide_panel.visible = false)
	vbox.add_child(close)
	
	var title = Label.new()
	title.text = "CẨM NANG CHIẾN ĐẤU NÂNG CAO"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = """
1. CÔNG THỨC TÍNH SÁT THƯƠNG:
   Sát thương = (ATK - DEF) * (1 - RES/100) * Hệ số hệ
   - ATK: Tấn công của bạn.
   - DEF: Phòng thủ của kẻ địch (giảm trực tiếp sát thương).
   - RES: Kháng (giảm theo % sát thương sau khi trừ DEF).
   * Sát thương tối thiểu luôn bằng 5% ATK của người đánh.

2. HỆ THỐNG HỆ (TYPE CHART):
   - Cool > Happy
   - Happy > Cute
   - Cute > Cool
   - Mysterious <> Pure
   * Hệ khắc chế gây 125% sát thương. Hệ bị khắc gây 80%.

3. THỨ TỰ LƯỢT (ACTION GAUGE):
   - Tốc độ (SPD) càng cao, bạn càng xuất hiện nhiều lần trong thanh hành động bên trái.
   - Sử dụng các kỹ năng Stun hoặc giảm tốc kẻ địch để chiếm ưu thế lượt đánh.

4. NÂNG CẤP CHỈ SỐ:
   - Nói chuyện với Kanade tại căn cứ để dùng Điểm Kỹ Năng (SP) nâng cấp vĩnh viễn các chỉ số cho cả đội.
"""
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(text)
	
	_guide_panel.visible = true

func _on_options():
	"""
	Xử lý khi mở bảng tùy chọn cài đặt.
	"""
	if _options_panel.visible:
		_options_panel.visible = false
		return
		
	for child in _options_panel.get_children():
		child.queue_free()
		
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	_options_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "TÙY CHỌN HỆ THỐNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)
	
	# --- Fast Battle Option ---
	var hb_fast = HBoxContainer.new()
	vbox.add_child(hb_fast)
	
	var lbl_fast = Label.new()
	lbl_fast.text = "Chiến đấu nhanh (Fast Battle)"
	lbl_fast.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	lbl_fast.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb_fast.add_child(lbl_fast)
	
	var check = CheckButton.new()
	check.button_pressed = (GameManager.battle_speed < 1.0)
	check.toggled.connect(func(pressed):
		GameManager.battle_speed = 0.6 if pressed else 1.2
	)
	hb_fast.add_child(check)
	
	# --- Volume Option ---
	var v_vol = VBoxContainer.new()
	vbox.add_child(v_vol)
	
	var lbl_vol = Label.new()
	lbl_vol.text = "Âm lượng tổng: " + str(int(GameManager.master_volume * 100)) + "%"
	lbl_vol.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	v_vol.add_child(lbl_vol)
	
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = GameManager.master_volume
	slider.value_changed.connect(func(val):
		GameManager.master_volume = val
		lbl_vol.text = "Âm lượng tổng: " + str(int(val * 100)) + "%"
	)
	v_vol.add_child(slider)
	
	# --- Close Button ---
	var close = _create_button("Đóng", func(): _options_panel.visible = false)
	vbox.add_child(close)
	
	_options_panel.visible = true

func _create_button(txt: String, callback: Callable) -> Button:
	"""
	Hàm tiện ích tạo các nút Menu với phong cách thống nhất.
	"""
	var btn = Button.new()
	btn.text = txt
	btn.add_theme_font_size_override("font_size", 18)
	
	var normal = StyleBoxTexture.new()
	normal.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg")
	normal.texture_margin_left = 8; normal.texture_margin_right = 8
	normal.texture_margin_top = 8; normal.texture_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", normal)
	
	var hover = StyleBoxTexture.new()
	hover.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_grey.svg")
	hover.texture_margin_left = 8; hover.texture_margin_right = 8
	hover.texture_margin_top = 8; hover.texture_margin_bottom = 12
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("focus", hover)
	
	btn.add_theme_color_override("font_color", Color(0.15, 0.08, 0.05))
	btn.add_theme_color_override("font_hover_color", Color(0, 0, 0))
	btn.add_theme_color_override("font_focus_color", Color(0, 0, 0))
	
	btn.pressed.connect(callback)
	return btn

func _input(event):
	"""
	Lắng nghe phím ESC (ui_cancel) để bật/tắt Menu.
	"""
	if event.is_action_pressed("ui_cancel"):
		# Cho phép mở Menu khi không đang đối thoại
		if not GameManager.is_in_dialogue:
			toggle()

func toggle():
	"""
	Chuyển đổi trạng thái hiển thị của Menu và trạng thái Pause của Game.
	"""
	visible = !visible
	get_tree().paused = visible
	if visible:
		# Tự động focus nút đầu tiên để hỗ trợ điều khiển bằng phím
		_panel.get_child(0).get_child(1).grab_focus() 

func _on_resume():
	toggle()

func _on_save():
	"""
	Lưu lại vị trí hiện tại của người chơi và các cờ sự kiện.
	"""
	var player = get_tree().current_scene.find_child("OverworldPlayer", true, false)
	if player:
		GameManager.last_player_position = player.global_position
	
	GameManager.save_game()
	_on_resume()

func _on_quit():
	"""
	Thoát game và quay về Start Menu.
	"""
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Menus/Start/StartMenu.tscn")
