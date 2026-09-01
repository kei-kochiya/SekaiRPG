extends CanvasLayer

"""
Tóm tắt: MobileControls quản lý hệ thống phím điều khiển cảm ứng cho nền tảng di động.

Chức năng chính:
- Hiển thị Joystick ảo và cụm nút hành động (Interact, Menu) nếu phát hiện thiết bị hỗ trợ Touch.
- Tự động ẩn/hiện giao diện thông minh dựa trên trạng thái game (đang mở Menu, đang hội thoại, trong trận chiến).
- Tiếp nhận thao tác Drag/Touch và quy đổi thành các Input Event tiêu chuẩn (ui_up, ui_down, ui_accept) để tương thích chéo với bộ code PC.
"""

# ── Cấu Hình ───────────────────────────────────────────────────────────────


const JOYSTICK_RADIUS = 80.0
const HANDLE_RADIUS = 40.0
const INTERACT_BUTTON_SIZE = Vector2(100, 100)
const MENU_BUTTON_SIZE = Vector2(80, 80)

# ── Biến Thành Phần ────────────────────────────────────────────────────────
var _is_mobile: bool = false
var _root: Control
var _joystick_base: Control
var _joystick_handle: ColorRect
var _btn_menu: TextureButton
var _btn_interact: TextureButton

var _is_dragging_joystick: bool = false
var _current_dir: Vector2 = Vector2.ZERO

# ── Khởi Tạo & Vòng Lặp ────────────────────────────────────────────────────

# Khởi tạo giao diện phím ảo nếu đang trên Mobile
func _ready():
	_check_platform()
	
	if not _is_mobile:
		visible = false
		return
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	_setup_ui()

# Kiểm tra và ẩn/hiện bộ phím ảo tùy theo ngữ cảnh game
func _process(_delta):
	if not _is_mobile or _root == null: return
	
	var cur_scene = get_tree().current_scene
	var is_menu = (cur_scene != null and cur_scene.name in ["StartMenu", "SandboxMenu", "SaveLoadMenu"])
	
	if is_menu:
		if _root.visible:
			_root.visible = false
			_reset_joystick()
		return
	
	var is_paused = get_tree().paused
	var in_dialogue = GameManager.is_in_dialogue
	var in_battle = (cur_scene != null and cur_scene.name == "BattleRoot")
	
	if (in_dialogue or is_paused) and _root.visible:
		_root.visible = false
		_reset_joystick()
	elif not (in_dialogue or is_paused) and not _root.visible:
		_root.visible = true
	
	if in_battle:
		if _joystick_base.visible: 
			_joystick_base.visible = false
			_reset_joystick()
		if _btn_interact.visible: _btn_interact.visible = false
	else:
		if not _joystick_base.visible: _joystick_base.visible = true

# Xác định thiết bị có hỗ trợ cảm ứng hay không
func _check_platform():
	var os = OS.get_name()
	_is_mobile = (os == "Android" or os == "iOS" or DisplayServer.is_touchscreen_available())

# ── Xây Dựng UI ────────────────────────────────────────────────────────────

# Khởi tạo toàn bộ cấu trúc Node UI
func _setup_ui():
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	
	_build_joystick()
	_build_menu_button()
	_build_interact_button()

func _build_joystick():
	_joystick_base = Control.new()
	_joystick_base.custom_minimum_size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	_joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_joystick_base.set_begin(Vector2(150, -250))
	_root.add_child(_joystick_base)
	
	var base_circle = ColorRect.new()
	base_circle.size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	base_circle.position = -base_circle.size / 2
	base_circle.color = Color(1, 1, 1, 0.15)
	_joystick_base.add_child(base_circle)
	
	_joystick_handle = ColorRect.new()
	_joystick_handle.size = Vector2(HANDLE_RADIUS * 2, HANDLE_RADIUS * 2)
	_joystick_handle.position = -_joystick_handle.size / 2
	_joystick_handle.color = Color(1, 1, 1, 0.4)
	_joystick_base.add_child(_joystick_handle)

func _build_menu_button():
	_btn_menu = TextureButton.new()
	_btn_menu.texture_normal = load("res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg")
	_btn_menu.custom_minimum_size = MENU_BUTTON_SIZE
	_btn_menu.ignore_texture_size = true
	_btn_menu.stretch_mode = TextureButton.STRETCH_SCALE
	
	_btn_menu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_btn_menu.offset_left = -110
	_btn_menu.offset_top = 20
	_btn_menu.offset_right = -20
	_btn_menu.offset_bottom = 20 + MENU_BUTTON_SIZE.y
	
	_btn_menu.pressed.connect(_on_menu_pressed)
	
	var menu_lbl = Label.new()
	menu_lbl.text = "MENU"
	menu_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu_lbl.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
	menu_lbl.add_theme_font_size_override("font_size", 16)
	menu_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_menu.add_child(menu_lbl)
	
	_root.add_child(_btn_menu)

func _build_interact_button():
	_btn_interact = TextureButton.new()
	_btn_interact.texture_normal = load("res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg")
	_btn_interact.custom_minimum_size = INTERACT_BUTTON_SIZE
	_btn_interact.ignore_texture_size = true
	_btn_interact.stretch_mode = TextureButton.STRETCH_SCALE
	
	_btn_interact.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_btn_interact.offset_left = -150
	_btn_interact.offset_top = -150
	_btn_interact.offset_right = -50
	_btn_interact.offset_bottom = -50
	
	_btn_interact.visible = false
	_btn_interact.pressed.connect(_on_interact_pressed)
	
	var icon = Label.new()
	icon.text = "ENTER"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.add_theme_color_override("font_color", Color(0.15, 0.1, 0.05))
	icon.add_theme_font_size_override("font_size", 18)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_interact.add_child(icon)
	
	_root.add_child(_btn_interact)

# ── Xử Lý Joystick ─────────────────────────────────────────────────────────

# Đón sự kiện kéo/chạm để xử lý Joystick
func _input(event):
	if not _is_mobile or not visible: return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			var dist = event.position.distance_to(_joystick_base.global_position)
			if dist < JOYSTICK_RADIUS * 2:
				_is_dragging_joystick = true
				_update_joystick(event.position)
		else:
			if _is_dragging_joystick:
				_is_dragging_joystick = false
				_reset_joystick()
			
	elif event is InputEventScreenDrag and _is_dragging_joystick:
		_update_joystick(event.position)

# Cập nhật vị trí của tâm Joystick và tính góc
func _update_joystick(touch_pos: Vector2):
	var diff = touch_pos - _joystick_base.global_position
	if diff.length() > JOYSTICK_RADIUS:
		diff = diff.normalized() * JOYSTICK_RADIUS
	
	_joystick_handle.position = diff - _joystick_handle.size / 2
	
	var dir = diff / JOYSTICK_RADIUS
	_apply_movement_input(dir)

# Đặt lại Joystick về chính giữa
func _reset_joystick():
	_joystick_handle.position = -_joystick_handle.size / 2
	_apply_movement_input(Vector2.ZERO)

func _apply_movement_input(dir: Vector2):
	"""
	Áp dụng hướng di chuyển ảo vào hệ thống phím tắt Godot (InputMap).
	
	Args:
		dir (Vector2): Vector hướng di chuyển (giá trị -1 đến 1).
	Returns: Không có
	"""
	var threshold = 0.2
	
	if _current_dir.x > threshold: Input.action_release("ui_right")
	if _current_dir.x < -threshold: Input.action_release("ui_left")
	if _current_dir.y > threshold: Input.action_release("ui_down")
	if _current_dir.y < -threshold: Input.action_release("ui_up")
	
	_current_dir = dir
	
	if dir.x > threshold: Input.action_press("ui_right")
	if dir.x < -threshold: Input.action_press("ui_left")
	if dir.y > threshold: Input.action_press("ui_down")
	if dir.y < -threshold: Input.action_press("ui_up")

# ── Xử Lý Nút Bấm ──────────────────────────────────────────────────────────

# Mở trình đơn Pause
func _on_menu_pressed():
	if not GameManager.is_in_dialogue:
		PauseMenu.toggle()

# Giả lập thao tác nhấn phím tương tác
func _on_interact_pressed():
	var ev = InputEventAction.new()
	ev.action = "ui_accept"
	ev.pressed = true
	Input.parse_input_event(ev)
	
	await get_tree().create_timer(0.1, false).timeout
	
	var ev_rel = InputEventAction.new()
	ev_rel.action = "ui_accept"
	ev_rel.pressed = false
	Input.parse_input_event(ev_rel)

# Ẩn/Hiện nút Tương tác (Interact) theo khoảng cách vùng
func set_interact_visible(p_is_visible: bool):
	if not _is_mobile: return
	if _btn_interact:
		_btn_interact.visible = p_is_visible
