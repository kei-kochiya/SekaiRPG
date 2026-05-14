extends CanvasLayer

"""
MobileControls: Cung cấp điều khiển cảm ứng cho nền tảng di động.

Bao gồm:
- Joystick ảo ở góc dưới bên trái để di chuyển.
- Nút Menu ở góc trên bên trái.
- Nút Tương tác (Interact) hiện lên khi ở gần NPC/Cửa.

Chỉ hiển thị trên các nền tảng di động hoặc khi có hỗ trợ cảm ứng.
"""

# ── Cấu hình ────────────────────────────────────────────────────────────────
const JOYSTICK_RADIUS = 80.0
const HANDLE_RADIUS = 40.0
const INTERACT_BUTTON_SIZE = Vector2(100, 100)
const MENU_BUTTON_SIZE = Vector2(80, 80)

# ── Biến thành phần ─────────────────────────────────────────────────────────
var _is_mobile: bool = false
var _root: Control
var _joystick_base: Control
var _joystick_handle: ColorRect
var _btn_menu: TextureButton
var _btn_interact: TextureButton

var _is_dragging_joystick: bool = false
var _current_dir: Vector2 = Vector2.ZERO

func _ready():
	_check_platform()
	
	if not _is_mobile:
		visible = false
		return
	
	layer = 120
	_setup_ui()

func _process(_delta):
	if not _is_mobile: return
	
	# Ẩn controls khi đang hội thoại hoặc menu tạm dừng đang mở
	var should_hide = GameManager.is_in_dialogue or get_tree().paused
	if should_hide and _root.visible:
		_root.visible = false
		_reset_joystick() # Đảm bảo không bị kẹt nút di chuyển
	elif not should_hide and not _root.visible:
		_root.visible = true

func _check_platform():
	var os = OS.get_name()
	# Cho phép test trên PC nếu có touch hoặc debug
	_is_mobile = (os == "Android" or os == "iOS" or DisplayServer.is_touchscreen_available())
	
	# Debug: uncomment line below to test on PC
	# _is_mobile = true 

func _setup_ui():
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	
	# 1. Joystick Ảo
	_joystick_base = Control.new()
	_joystick_base.custom_minimum_size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	_joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_joystick_base.set_begin(Vector2(100, -250)) # Position relative to bottom-left
	_root.add_child(_joystick_base)
	
	var base_circle = ColorRect.new()
	base_circle.size = Vector2(JOYSTICK_RADIUS * 2, JOYSTICK_RADIUS * 2)
	base_circle.position = -base_circle.size / 2
	base_circle.color = Color(1, 1, 1, 0.15)
	# Bo tròn giả lập (nếu có texture thì tốt hơn, nhưng dùng ColorRect cho gọn)
	_joystick_base.add_child(base_circle)
	
	_joystick_handle = ColorRect.new()
	_joystick_handle.size = Vector2(HANDLE_RADIUS * 2, HANDLE_RADIUS * 2)
	_joystick_handle.position = -_joystick_handle.size / 2
	_joystick_handle.color = Color(1, 1, 1, 0.4)
	_joystick_base.add_child(_joystick_handle)
	
	# 2. Nút Menu
	_btn_menu = TextureButton.new()
	var menu_tex = load("res://Assets/kenney_ui-pack-adventure/Vector/button_grey_lines.svg")
	if menu_tex: _btn_menu.texture_normal = menu_tex
	_btn_menu.custom_minimum_size = MENU_BUTTON_SIZE
	_btn_menu.ignore_texture_size = true
	_btn_menu.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_btn_menu.position = Vector2(20, 20)
	_btn_menu.pressed.connect(_on_menu_pressed)
	_root.add_child(_btn_menu)
	
	# 3. Nút Tương tác
	_btn_interact = TextureButton.new()
	var interact_tex = load("res://Assets/kenney_ui-pack-adventure/Vector/button_grey_square.svg")
	if interact_tex: _btn_interact.texture_normal = interact_tex
	_btn_interact.custom_minimum_size = INTERACT_BUTTON_SIZE
	_btn_interact.ignore_texture_size = true
	_btn_interact.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	
	# Đặt ở góc dưới phải
	_btn_interact.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_btn_interact.set_begin(Vector2(-180, -180)) 
	
	_btn_interact.visible = false
	_btn_interact.pressed.connect(_on_interact_pressed)
	
	var icon = Label.new()
	icon.text = "ENTER"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	icon.add_theme_font_size_override("font_size", 16)
	_btn_interact.add_child(icon)
	
	_root.add_child(_btn_interact)

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

func _update_joystick(touch_pos: Vector2):
	var diff = touch_pos - _joystick_base.global_position
	if diff.length() > JOYSTICK_RADIUS:
		diff = diff.normalized() * JOYSTICK_RADIUS
	
	_joystick_handle.position = diff - _joystick_handle.size / 2
	
	var dir = diff / JOYSTICK_RADIUS
	_apply_movement_input(dir)

func _reset_joystick():
	_joystick_handle.position = -_joystick_handle.size / 2
	_apply_movement_input(Vector2.ZERO)

func _apply_movement_input(dir: Vector2):
	# Deadzone
	var threshold = 0.2
	
	# Release old actions
	if _current_dir.x > threshold: Input.action_release("ui_right")
	if _current_dir.x < -threshold: Input.action_release("ui_left")
	if _current_dir.y > threshold: Input.action_release("ui_down")
	if _current_dir.y < -threshold: Input.action_release("ui_up")
	
	_current_dir = dir
	
	# Press new actions
	if dir.x > threshold: Input.action_press("ui_right")
	if dir.x < -threshold: Input.action_press("ui_left")
	if dir.y > threshold: Input.action_press("ui_down")
	if dir.y < -threshold: Input.action_press("ui_up")

func _on_menu_pressed():
	if not GameManager.is_in_dialogue:
		PauseMenu.toggle()

func _on_interact_pressed():
	# Trigger ui_accept
	Input.action_press("ui_accept")
	await get_tree().create_timer(0.1).timeout
	Input.action_release("ui_accept")

func set_interact_visible(is_visible: bool):
	if not _is_mobile: return
	if _btn_interact:
		_btn_interact.visible = is_visible
