extends CanvasLayer

"""
Tóm tắt: PauseMenu là hệ thống Menu tạm dừng toàn cục của trò chơi.

Chức năng chính:
- Cung cấp giao diện tạm dừng game, hỗ trợ hoạt động bất chấp `get_tree().paused = true`.
- Quản lý các chức năng: Tiếp tục, Lưu/Tải nhanh, Xem Cẩm nang chiến đấu (Guide), Cài đặt hệ thống.
- Cung cấp bảng Options chuyên sâu để tinh chỉnh Âm lượng, Tốc độ trận đấu, và bật/tắt tính năng Bỏ qua trận đấu (Skip Battle).
- Hỗ trợ cơ chế nhập mật khẩu (Secret Code) để mở khóa các tùy chọn ẩn.
"""

# Mật mã mở khóa tùy chọn "Bỏ qua trận đánh"
const SKIP_BATTLE_CODE := "27101108"

# Scene không cho mở menu bằng ESC ("Lưu nhanh" sẽ ghi đè quicksave bằng trạng thái mặc định).
# `show_options(true)` từ StartMenu vẫn dùng được vì không đi qua `toggle()`.
const NO_PAUSE_SCENES := ["StartMenu", "SandboxMenu", "SaveLoadMenu"]
# Scene không được lưu game (cùng danh sách với GameManager._can_autosave)
const NO_SAVE_SCENES := ["BattleRoot"]

# ── Biến Tham Chiếu ────────────────────────────────────────────────────────

var _root: Control
var _panel: PanelContainer
var _guide_panel: PanelContainer
var _options_panel: PanelContainer
var _pw_dialog: PanelContainer
var _pw_target: CheckButton
var _save_load_menu: Control

var _btn_resume: Button
var _btn_quick_save: Button
var _btn_save_load: Button
var _btn_guide: Button
var _btn_options: Button

# Bảng Options đang mở từ StartMenu (không có menu tạm dừng phía sau, không pause cây node)
var _options_from_main_menu: bool = false

# Số hộp thoại UI (Shop, Upgrade, chọn Phước Lành...) đang mở. Khi > 0, ESC không mở menu tạm dừng.
var _modal_count: int = 0

func push_modal():
	_modal_count += 1

func pop_modal():
	_modal_count = maxi(0, _modal_count - 1)

func is_modal_open() -> bool:
	return _modal_count > 0

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

	_btn_resume = PauseMenuBuilder.create_button("Tiếp tục", _on_resume, UITheme.Kind.PRIMARY)
	_btn_quick_save = PauseMenuBuilder.create_button("Lưu nhanh", _on_quick_save)
	_btn_save_load = PauseMenuBuilder.create_button("Lưu / Tải game", _on_open_save_load_menu)
	_btn_guide = PauseMenuBuilder.create_button("Hướng dẫn", _on_guide)
	_btn_options = PauseMenuBuilder.create_button("Tùy chọn", _on_options)
	for btn in [_btn_resume, _btn_quick_save, _btn_save_load, _btn_guide, _btn_options]:
		vbox.add_child(btn)
	vbox.add_child(PauseMenuBuilder.create_button("Thoát ra Menu", _on_quit, UITheme.Kind.GHOST))

# Đưa mọi lớp phủ về trạng thái ban đầu (chỉ còn bảng chính), dùng mỗi lần mở/đóng menu
func _reset_views():
	_root.visible = true
	_panel.visible = true
	_guide_panel.visible = false
	_options_panel.visible = false
	_free_pw_dialog()
	if is_instance_valid(_save_load_menu):
		_save_load_menu.queue_free()

# Quay lại bảng chính từ một lớp phủ con (Hướng dẫn / Tùy chọn)
func _show_main_panel(focus: Control):
	_panel.visible = true
	focus.call_deferred("grab_focus")

# Chỉ cho lưu khi đang ở Overworld bình thường (mirror GameManager._can_autosave, trừ cờ hội thoại)
func _can_save() -> bool:
	if GameManager.is_sandbox or GameManager.is_scripted_battle or GameManager.is_training_mode:
		return false
	if HoloSimManager.is_sim_active:
		return false
	var scene := get_tree().current_scene
	if scene == null or scene.name in NO_SAVE_SCENES:
		return false
	return scene.find_child("OverworldPlayer", true, false) != null

func _can_pause() -> bool:
	var scene := get_tree().current_scene
	return scene != null and not (scene.name in NO_PAUSE_SCENES)

# Ẩn nút lưu khi không hợp lệ (trận chiến, Holo-Sim, luyện tập...)
func _refresh_save_buttons():
	var can_save := _can_save()
	_btn_quick_save.visible = can_save
	_btn_save_load.visible = can_save

# ── Xử Lý Bảng Hướng Dẫn ───────────────────────────────────────────────────

# Xử lý hiển thị bảng hướng dẫn
func _on_guide():
	if _guide_panel.visible:
		_close_guide()
		return
	_panel.visible = false
	PauseMenuBuilder.build_guide_panel(_guide_panel, _close_guide)

func _close_guide():
	_guide_panel.visible = false
	_show_main_panel(_btn_guide)

# ── Xử Lý Bảng Tùy Chọn ────────────────────────────────────────────────────

# Không đụng tới trạng thái pause: từ StartMenu chỉ cần vẽ bảng Options lên trên
func show_options(from_main_menu: bool = false):
	_reset_views()
	_panel.visible = false
	visible = true
	_build_options_vbox(from_main_menu)

func _on_options():
	if _options_panel.visible:
		_close_options()
		return
	_panel.visible = false
	_build_options_vbox(false)

func _close_options():
	_options_panel.visible = false
	_free_pw_dialog()
	if _options_from_main_menu:
		visible = false
		get_tree().paused = false
		_reset_views()
	else:
		_show_main_panel(_btn_options)

func _build_options_vbox(from_main_menu: bool):
	_options_from_main_menu = from_main_menu
	for child in _options_panel.get_children():
		_options_panel.remove_child(child)
		child.queue_free()

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SP_4)
	_options_panel.add_child(vbox)

	var title = UITheme.make_label("Tùy chọn", UITheme.FS_TITLE, UITheme.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", UITheme.font_display_bold())
	vbox.add_child(title)

	var check = CheckButton.new()
	check.button_pressed = (GameManager.battle_speed < 1.0)
	check.toggled.connect(func(pressed):
		GameManager.battle_speed = 0.6 if pressed else 1.2
	)
	vbox.add_child(_option_row("Chiến đấu nhanh", check))

	var v_vol = VBoxContainer.new()
	vbox.add_child(v_vol)
	var lbl_vol = UITheme.make_label("Âm lượng tổng: %d%%" % int(GameManager.master_volume * 100), UITheme.FS_LABEL)
	v_vol.add_child(lbl_vol)
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = GameManager.master_volume
	slider.custom_minimum_size.y = UITheme.MIN_TOUCH
	slider.value_changed.connect(func(val):
		GameManager.master_volume = val
		lbl_vol.text = "Âm lượng tổng: %d%%" % int(val * 100)
	)
	v_vol.add_child(slider)

	var btn_skip = CheckButton.new()
	btn_skip.button_pressed = GameManager.skip_battle_enabled
	btn_skip.toggled.connect(func(pressed):
		if pressed and not GameManager.skip_battle_unlocked:
			btn_skip.button_pressed = false
			_show_password_dialog(btn_skip)
		else:
			GameManager.skip_battle_enabled = pressed
	)
	vbox.add_child(_option_row("Bỏ qua trận đánh", btn_skip))

	vbox.add_child(PauseMenuBuilder.create_button("Đóng", _close_options, UITheme.Kind.PRIMARY))

	_options_panel.visible = true
	check.call_deferred("grab_focus")

func _option_row(text: String, control: Control) -> HBoxContainer:
	var row = HBoxContainer.new()
	var lbl = UITheme.make_label(text, UITheme.FS_LABEL)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lbl)
	control.custom_minimum_size.y = UITheme.MIN_TOUCH
	row.add_child(control)
	return row

# ── Tiện Ích Khác ──────────────────────────────────────────────────────────

# Hiển thị hộp thoại nhập mật khẩu
func _show_password_dialog(target_check: CheckButton):
	_free_pw_dialog()
	_pw_target = target_check

	_pw_dialog = PanelContainer.new()
	_pw_dialog.custom_minimum_size = Vector2(340, 0)
	_pw_dialog.set_anchors_preset(Control.PRESET_CENTER)
	_pw_dialog.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pw_dialog.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pw_dialog.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_500, UITheme.ACCENT, UITheme.SP_4))
	_root.add_child(_pw_dialog)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SP_3)
	_pw_dialog.add_child(vbox)

	var lbl = UITheme.make_label("Nhập mật mã", UITheme.FS_HEADING, UITheme.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	vbox.add_child(lbl)

	var edit = LineEdit.new()
	edit.secret = true
	edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	edit.placeholder_text = "****"
	vbox.add_child(edit)
	edit.call_deferred("grab_focus")

	var hb = HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", UITheme.SP_2)
	vbox.add_child(hb)

	var btn_ok = PauseMenuBuilder.create_button("Xác nhận", Callable(), UITheme.Kind.PRIMARY)
	hb.add_child(btn_ok)

	var btn_cancel = PauseMenuBuilder.create_button("Hủy", Callable(), UITheme.Kind.GHOST)
	hb.add_child(btn_cancel)

	var on_confirm = func():
		if edit.text == SKIP_BATTLE_CODE:
			GameManager.skip_battle_unlocked = true
			GameManager.skip_battle_enabled = true
			target_check.button_pressed = true
			_free_pw_dialog()
			print("[Options] Skip Battle unlocked!")
		else:
			edit.text = ""
			lbl.text = "Sai mật mã, thử lại"
			lbl.add_theme_color_override("font_color", UITheme.DANGER_TEXT)

	btn_ok.pressed.connect(on_confirm)
	edit.text_submitted.connect(func(_t): on_confirm.call())
	btn_cancel.pressed.connect(_free_pw_dialog)

# Đóng hộp thoại mật mã và trả focus về công tắc "Bỏ qua trận đánh"
func _free_pw_dialog():
	if is_instance_valid(_pw_dialog):
		_pw_dialog.queue_free()
		if _options_panel.visible and is_instance_valid(_pw_target):
			_pw_target.call_deferred("grab_focus")
	_pw_dialog = null

# ── Điều Khiển ─────────────────────────────────────────────────────────────

# ESC đóng lớp phủ trong cùng trước (nhập mã > Lưu/Tải > Hướng dẫn > Tùy chọn). Trả về true nếu đã đóng một lớp.
func _close_overlay() -> bool:
	if is_instance_valid(_pw_dialog):
		_free_pw_dialog()
	elif is_instance_valid(_save_load_menu):
		_save_load_menu.queue_free()
	elif _guide_panel.visible:
		_close_guide()
	elif _options_panel.visible:
		_close_options()
	else:
		return false
	return true

# Lắng nghe phím ESC để bật/tắt Menu
func _input(event):
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		if not _close_overlay():
			toggle()
		get_viewport().set_input_as_handled()
		return
	if is_modal_open() or not _can_pause():
		return
	# Failsafe: Nếu cờ báo đang hội thoại nhưng UI không hiển thị, tự động reset.
	# Bỏ qua khi có modal: Shop/Upgrade dùng start_dialogue() làm khóa di chuyển (push_modal/pop_modal).
	if GameManager.is_in_dialogue and not DialogueManager.visible and not is_modal_open():
		GameManager.end_dialogue()

	if not GameManager.is_in_dialogue:
		toggle()

func toggle():
	"""
	Chuyển đổi trạng thái hiển thị của Menu và trạng thái Pause của Game.

	Args: Không có
	Returns: Không có
	"""
	if not visible and not _can_pause():
		return
	visible = !visible
	get_tree().paused = visible
	_reset_views()
	if visible:
		_refresh_save_buttons()
		_btn_resume.call_deferred("grab_focus")

func _on_resume():
	toggle()

func _on_quick_save():
	"""
	Lưu nhanh vào quicksave.json.
	"""
	if not _can_save():
		return
	var player = get_tree().current_scene.find_child("OverworldPlayer", true, false)
	if player:
		GameManager.last_player_position = player.global_position

	GameManager.quick_save()
	_on_resume()

func _on_open_save_load_menu():
	"""
	Mở menu quản lý Save & Load dạng Overlay.
	"""
	if not _can_save() or is_instance_valid(_save_load_menu):
		return
	_save_load_menu = preload("res://UI/Menus/SaveLoad/SaveLoadMenu.tscn").instantiate()
	_root.add_child(_save_load_menu)

func _on_quit():
	"""
	Thoát game và quay về Start Menu.

	Args: Không có
	Returns: Không có
	"""
	visible = false
	get_tree().paused = false
	_reset_views()
	get_tree().change_scene_to_file("res://UI/Menus/Start/StartMenu.tscn")

