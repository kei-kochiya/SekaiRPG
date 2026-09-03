extends CanvasLayer

"""
Tóm tắt: PauseMenu là hệ thống Menu tạm dừng toàn cục của trò chơi.

Chức năng chính:
- Cung cấp giao diện tạm dừng game, hỗ trợ hoạt động bất chấp `get_tree().paused = true`.
- Quản lý các chức năng: Tiếp tục, Lưu/Tải nhanh, Xem Cẩm nang chiến đấu (Guide), Cài đặt hệ thống.
- Cung cấp bảng Options chuyên sâu để tinh chỉnh Âm lượng, Tốc độ trận đấu, và bật/tắt tính năng Bỏ qua trận đấu (Skip Battle).
- Hỗ trợ cơ chế nhập mật khẩu (Secret Code) để mở khóa các tùy chọn ẩn.
"""

# ── Biến Tham Chiếu ────────────────────────────────────────────────────────

var _root: Control
var _panel: PanelContainer
var _guide_panel: PanelContainer
var _options_panel: PanelContainer
var _pw_dialog: PanelContainer

# ── Khởi Tạo ───────────────────────────────────────────────────────────────

# Khởi tạo Menu tạm dừng
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 130
	visible = false
	_build_ui()

# ── Xây Dựng Cấu Trúc UI ───────────────────────────────────────────────────

# Xây dựng cây node giao diện
func _build_ui():
	var ui_nodes = PauseMenuBuilder.build_base_ui(self)
	_root = ui_nodes["root"]
	_panel = ui_nodes["panel"]
	_guide_panel = ui_nodes["guide_panel"]
	_options_panel = ui_nodes["options_panel"]
	var vbox = ui_nodes["vbox"]
	
	vbox.add_child(PauseMenuBuilder.create_button("Tiếp tục", _on_resume))
	vbox.add_child(PauseMenuBuilder.create_button("Lưu nhanh (Quick Save)", _on_quick_save))
	vbox.add_child(PauseMenuBuilder.create_button("Quản lý Lưu / Tải (Save & Load)", _on_open_save_load_menu))
	vbox.add_child(PauseMenuBuilder.create_button("Hướng dẫn", _on_guide))
	vbox.add_child(PauseMenuBuilder.create_button("Tùy chọn", _on_options))
	vbox.add_child(PauseMenuBuilder.create_button("Thoát ra Menu", _on_quit))

# ── Xử Lý Bảng Hướng Dẫn ───────────────────────────────────────────────────

# Xử lý hiển thị bảng hướng dẫn
func _on_guide():
	if _guide_panel.visible:
		_guide_panel.visible = false
		return
		
	PauseMenuBuilder.build_guide_panel(_guide_panel)

# ── Xử Lý Bảng Tùy Chọn ────────────────────────────────────────────────────

func show_options(from_main_menu: bool = false):
	visible = true
	_root.visible = true
	_panel.visible = false
	_guide_panel.visible = false
	_options_panel.visible = true
	_build_options_vbox(from_main_menu)

func _on_options():
	if _options_panel.visible:
		_options_panel.visible = false
		return
	_build_options_vbox(false)

func _build_options_vbox(from_main_menu: bool):
	for child in _options_panel.get_children():
		child.queue_free()
		
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	_options_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "TÙY CHỌN HỆ THỐNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_font_override("font", load(PauseMenuBuilder.FONT_PATH))
	vbox.add_child(title)
	
	var hb_fast = HBoxContainer.new()
	vbox.add_child(hb_fast)
	
	var lbl_fast = Label.new()
	lbl_fast.text = "Chiến đấu nhanh (Fast Battle)"
	lbl_fast.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	lbl_fast.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_fast.add_theme_font_override("font", load(PauseMenuBuilder.FONT_PATH))
	hb_fast.add_child(lbl_fast)
	
	var check = CheckButton.new()
	check.button_pressed = (GameManager.battle_speed < 1.0)
	check.toggled.connect(func(pressed):
		GameManager.battle_speed = 0.6 if pressed else 1.2
	)
	hb_fast.add_child(check)
	
	var v_vol = VBoxContainer.new()
	vbox.add_child(v_vol)
	
	var lbl_vol = Label.new()
	lbl_vol.text = "Âm lượng tổng: " + str(int(GameManager.master_volume * 100)) + "%"
	lbl_vol.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	lbl_vol.add_theme_font_override("font", load(PauseMenuBuilder.FONT_PATH))
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
	
	var hb_skip = HBoxContainer.new()
	vbox.add_child(hb_skip)
	
	var lbl_skip = Label.new()
	lbl_skip.text = "Bỏ qua trận đánh (Skip Battle)"
	lbl_skip.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	lbl_skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_skip.add_theme_font_override("font", load(PauseMenuBuilder.FONT_PATH))
	hb_skip.add_child(lbl_skip)
	
	var btn_skip = CheckButton.new()
	btn_skip.button_pressed = GameManager.skip_battle_enabled
	btn_skip.toggled.connect(func(pressed):
		if pressed and not GameManager.skip_battle_unlocked:
			btn_skip.button_pressed = false
			_show_password_dialog(btn_skip)
		else:
			GameManager.skip_battle_enabled = pressed
	)
	hb_skip.add_child(btn_skip)
	
	var close = PauseMenuBuilder.create_button("Đóng", func():
		_options_panel.visible = false
		if from_main_menu:
			visible = false
			_root.visible = false
	)
	vbox.add_child(close)
	
	_options_panel.visible = true

# ── Tiện Ích Khác ──────────────────────────────────────────────────────────

# Hiển thị hộp thoại nhập mật khẩu
func _show_password_dialog(target_check: CheckButton):
	if _pw_dialog: _pw_dialog.queue_free()
	
	_pw_dialog = PanelContainer.new()
	_pw_dialog.custom_minimum_size = Vector2(300, 150)
	_pw_dialog.set_anchors_preset(Control.PRESET_CENTER)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.8, 0.6, 0.2)
	_pw_dialog.add_theme_stylebox_override("panel", sb)
	_root.add_child(_pw_dialog)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	_pw_dialog.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = "NHẬP MẬT MÃ"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl)
	
	var edit = LineEdit.new()
	edit.secret = true
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.placeholder_text = "****"
	vbox.add_child(edit)
	edit.grab_focus()
	
	var hb = HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hb)
	
	var btn_ok = Button.new()
	btn_ok.text = "XÁC NHẬN"
	hb.add_child(btn_ok)
	
	var btn_cancel = Button.new()
	btn_cancel.text = "HỦY"
	hb.add_child(btn_cancel)
	
	var on_confirm = func():
		if edit.text == "27101108":
			GameManager.skip_battle_unlocked = true
			GameManager.skip_battle_enabled = true
			target_check.button_pressed = true
			_pw_dialog.queue_free()
			print("[Options] Skip Battle unlocked!")
		else:
			edit.text = ""
			lbl.text = "SAI MẬT MÃ! THỬ LẠI"
			lbl.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	
	btn_ok.pressed.connect(on_confirm)
	edit.text_submitted.connect(func(_t): on_confirm.call())
	btn_cancel.pressed.connect(func(): _pw_dialog.queue_free())


# ── Điều Khiển ─────────────────────────────────────────────────────────────

# Lắng nghe phím ESC để bật/tắt Menu
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# Failsafe: Nếu cờ báo đang hội thoại nhưng UI không hiển thị, tự động reset
		if GameManager.is_in_dialogue and not DialogueManager.visible:
			GameManager.end_dialogue()
			
		if not GameManager.is_in_dialogue:
			toggle()

func toggle():
	"""
	Chuyển đổi trạng thái hiển thị của Menu và trạng thái Pause của Game.
	
	Args: Không có
	Returns: Không có
	"""
	visible = !visible
	get_tree().paused = visible
	if visible:
		_panel.get_child(0).get_child(1).grab_focus() 

func _on_resume():
	toggle()

func _on_quick_save():
	"""
	Lưu nhanh vào quicksave.json.
	"""
	var player = get_tree().current_scene.find_child("OverworldPlayer", true, false)
	if player:
		GameManager.last_player_position = player.global_position
	
	GameManager.quick_save()
	_on_resume()

func _on_open_save_load_menu():
	"""
	Mở menu quản lý Save & Load dạng Overlay.
	"""
	var save_load_scene = preload("res://UI/Menus/SaveLoad/SaveLoadMenu.tscn").instantiate()
	_root.add_child(save_load_scene)

func _on_quit():
	"""
	Thoát game và quay về Start Menu.
	
	Args: Không có
	Returns: Không có
	"""
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/Menus/Start/StartMenu.tscn")

