extends CanvasLayer

"""
Tóm tắt: DialogueManager là trình điều phối luồng logic (Controller) của hệ thống hội thoại.

Chức năng chính:
- Lưu trữ danh sách các câu thoại hiện tại và theo dõi tiến trình đọc (index).
- Tiếp nhận dữ liệu cấu hình để hiển thị Menu lựa chọn (Choices).
- Bắt và xử lý các sự kiện đầu vào (Click chuột, Touch màn hình, phím Enter/Space) để sang câu tiếp theo.
- Kích hoạt tín hiệu `choice_made` và gọi hàm callback khi chuỗi hội thoại kết thúc.
- Hoạt động độc lập với logic vẽ UI (được đảm nhiệm bởi DialogueUI).
"""

# ── Trạng Thái & Biến ──────────────────────────────────────────────────────


var current_dialogue: Array = []
var index: int   = 0
var active: bool = false
var _in_choice: bool = false
var _callback: Callable

signal choice_made(index: int)

var _ui: DialogueUI

# ── Khởi Tạo ───────────────────────────────────────────────────────────────

# Khởi tạo giao diện UI
func _ready() -> void:
	layer = 100
	visible = false
	
	_ui = DialogueUI.new()
	add_child(_ui)
	_ui.choice_selected.connect(_on_choice_selected)
	_ui.get_node("DialogueLayer/Clicker").pressed.connect(_on_clicker_pressed)

# ── API Công Khai ──────────────────────────────────────────────────────────

func play_dialogue(lines: Array, on_complete: Callable = Callable()) -> void:
	"""
	Khởi chạy chuỗi hội thoại mới và hiển thị ra màn hình.
	
	Args:
		lines (Array): Mảng các dòng thoại (Dictionary) đã được chuẩn hóa.
		on_complete (Callable): Hàm callback chạy sau khi hội thoại kết thúc.
	Returns: Không có
	"""
	if active or lines.is_empty(): 
		if on_complete.is_valid(): on_complete.call()
		return
	
	current_dialogue = lines
	_callback = on_complete
	index = 0
	active = true
	visible = true
	_ui.clear()
	GameManager.start_dialogue()
	_show_current_line()

func show_choice(options: Array):
	"""
	Hiển thị danh sách các tùy chọn cho người chơi chọn lựa.
	
	Args:
		options (Array): Danh sách các lựa chọn dạng chuỗi văn bản.
	Returns: Không có
	"""
	active = false
	_ui.clear()
	visible = true
	_in_choice = true
	GameManager.start_dialogue()
	_ui.display_choices(options)

# ── Điều Phối Luồng ────────────────────────────────────────────────────────

# Xử lý nút bấm trên bàn phím/tay cầm
func _input(event: InputEvent):
	if _in_choice or not active: return
	
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()

# Xử lý chạm/click trên màn hình
func _on_clicker_pressed():
	if _in_choice or not active: return
	_advance_dialogue()

# Chuyển sang dòng thoại tiếp theo
func _advance_dialogue():
	index += 1
	if index < current_dialogue.size():
		_show_current_line()
	else:
		_finish()

# Hiển thị dòng thoại hiện tại
func _show_current_line():
	if index < current_dialogue.size():
		_ui.display_line(current_dialogue[index])

# Xử lý sự kiện khi người chơi chọn một lựa chọn
func _on_choice_selected(idx: int):
	_in_choice = false
	if not active:
		visible = false
		GameManager.end_dialogue()
	choice_made.emit(idx)

# Kết thúc và đóng giao diện hội thoại
func _finish():
	active = false
	visible = false
	_ui.clear()
	GameManager.end_dialogue()
	if _callback.is_valid(): _callback.call()
