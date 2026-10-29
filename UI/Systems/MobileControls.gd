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
const HANDLE_RADIUS = 36.0
const INTERACT_SIZE = 96
const MENU_SIZE = 64
const EDGE_MARGIN = UITheme.SP_12

# ── Biến Thành Phần ────────────────────────────────────────────────────────
var _is_mobile: bool = false
var _root: Control
var _joystick_base: Control
var _joystick_handle: Panel
var _btn_menu: Button
var _btn_interact: Button

# Index của ngón tay đang giữ joystick (-1: không có), để thả ngón khác không làm joystick reset
var _joystick_touch: int = -1
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

# Chỉ bật phím ảo trên thiết bị di động thật. Không dùng DisplayServer.is_touchscreen_available():
# nhiều máy Windows có màn hình cảm ứng/bút nên sẽ hiện joystick trên PC.
func _check_platform():
	_is_mobile = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")

# ── Xây Dựng UI ────────────────────────────────────────────────────────────

# Khởi tạo toàn bộ cấu trúc Node UI
func _setup_ui():
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_joystick()
	_build_menu_button()
	_build_interact_button()

# Hình tròn (Panel bo góc bằng nửa đường kính) có tâm tại gốc của node cha
func _circle(diameter: float, bg: Color, border: Color) -> Panel:
	var p := Panel.new()
	p.size = Vector2(diameter, diameter)
	p.position = -p.size / 2.0
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", UITheme.box(bg, border, int(diameter * 0.5), 0, 0, 2))
	return p

# Nút bấm tròn theo UITheme; không nhận focus để không cướp focus bàn phím/tay cầm của menu
func _round_button(text: String, diameter: int, kind: UITheme.Kind) -> Button:
	var btn := Button.new()
	btn.text = text
	UITheme.style_button(btn, kind, UITheme.FS_BODY)
	var boxes := UITheme.button_boxes(kind)
	for state in boxes:
		var sb: StyleBoxFlat = boxes[state]
		sb.set_corner_radius_all(int(diameter * 0.5))
		sb.set_content_margin_all(0)
		btn.add_theme_stylebox_override(state, sb)
	btn.custom_minimum_size = Vector2(diameter, diameter)
	btn.focus_mode = Control.FOCUS_NONE
	return btn

func _build_joystick():
	# Node gốc kích thước 0 nằm đúng tâm joystick: global_position chính là tâm
	_joystick_base = Control.new()
	_joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joystick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	var center := Vector2(EDGE_MARGIN + JOYSTICK_RADIUS, -(EDGE_MARGIN + JOYSTICK_RADIUS))
	_joystick_base.offset_left = center.x
	_joystick_base.offset_right = center.x
	_joystick_base.offset_top = center.y
	_joystick_base.offset_bottom = center.y
	_root.add_child(_joystick_base)

	_joystick_base.add_child(_circle(JOYSTICK_RADIUS * 2, Color(UITheme.INK_900, 0.55), UITheme.INK_500))
	_joystick_handle = _circle(HANDLE_RADIUS * 2, Color(UITheme.TEXT, 0.85), UITheme.INK_600)
	_joystick_base.add_child(_joystick_handle)

func _build_menu_button():
	_btn_menu = _round_button("MENU", MENU_SIZE, UITheme.Kind.SECONDARY)
	_btn_menu.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_btn_menu.offset_right = -UITheme.SP_6
	_btn_menu.offset_left = -UITheme.SP_6 - MENU_SIZE
	_btn_menu.offset_top = UITheme.SP_6
	_btn_menu.offset_bottom = UITheme.SP_6 + MENU_SIZE
	_btn_menu.pressed.connect(_on_menu_pressed)
	_root.add_child(_btn_menu)

func _build_interact_button():
	# Tâm nút nằm ngang hàng với tâm joystick; chữ tối trên nền hổ phách (hành động chính duy nhất)
	_btn_interact = _round_button("ENTER", INTERACT_SIZE, UITheme.Kind.PRIMARY)
	_btn_interact.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_btn_interact.offset_right = -EDGE_MARGIN
	_btn_interact.offset_left = -EDGE_MARGIN - INTERACT_SIZE
	_btn_interact.offset_bottom = -(EDGE_MARGIN + JOYSTICK_RADIUS) + INTERACT_SIZE / 2.0
	_btn_interact.offset_top = _btn_interact.offset_bottom - INTERACT_SIZE
	_btn_interact.visible = false
	_btn_interact.pressed.connect(_on_interact_pressed)
	_root.add_child(_btn_interact)

# ── Xử Lý Joystick ─────────────────────────────────────────────────────────

# Đón sự kiện kéo/chạm để xử lý Joystick (chỉ theo dõi đúng ngón tay đã bấm vào joystick)
func _input(event):
	if not _is_mobile or _root == null: return

	if event is InputEventScreenTouch:
		if event.pressed:
			# is_visible_in_tree: joystick ẩn (đang hội thoại/tạm dừng/trong trận) thì không nhận chạm
			var in_zone: bool = event.position.distance_to(_joystick_base.global_position) < JOYSTICK_RADIUS * 2
			if _joystick_touch == -1 and in_zone and _joystick_base.is_visible_in_tree():
				_joystick_touch = event.index
				_update_joystick(event.position)
		elif event.index == _joystick_touch:
			_reset_joystick()

	elif event is InputEventScreenDrag and event.index == _joystick_touch:
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
	_joystick_touch = -1
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
	if not GameManager.is_in_dialogue and not PauseMenu.is_modal_open():
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
