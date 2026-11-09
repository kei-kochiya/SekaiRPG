extends CanvasLayer

"""
Tóm tắt: DialogueManager là trình điều phối luồng logic (Controller) của hệ thống hội thoại.

Chức năng chính:
- Lưu trữ danh sách các câu thoại hiện tại và theo dõi tiến trình đọc (index).
- Tiếp nhận dữ liệu cấu hình để hiển thị Menu lựa chọn (Choices).
- Bắt và xử lý các sự kiện đầu vào (Click chuột, Touch màn hình, phím Enter/Space) để sang câu tiếp theo.
- Gọi hàm callback khi chuỗi hội thoại kết thúc; `ask`/`play_async` cho phép `await` kết quả lựa chọn/hội thoại.
- Hoạt động độc lập với logic vẽ UI (được đảm nhiệm bởi DialogueUI).
"""

# ── Trạng Thái & Biến ──────────────────────────────────────────────────────


var current_dialogue: Array = []
var index: int   = 0
var active: bool = false
var _in_choice: bool = false
var _callback: Callable

# Phát sau mỗi chuỗi hội thoại kết thúc (sau callback). Dùng cho logic muốn chạy "khi người chơi vừa nói chuyện xong".
signal dialogue_finished

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
	if active or _in_choice or lines.is_empty():
		# Callback vẫn chạy để luồng cốt truyện không kẹt. Mảng rỗng là chủ ý (chỉ chạy callback; khóa thiếu đã được DialogueLoader.get_lines
		# báo); còn bị chặn vì đang có hội thoại/lựa chọn khác thì phải báo, trước đây mất thoại như vậy rất khó dò
		if not lines.is_empty():
			GameLogger.warn("Dialogue", "play_dialogue bị bỏ qua: đang có hội thoại/lựa chọn khác")
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

# Đóng sạch hội thoại/lựa chọn đang mở mà KHÔNG chạy callback (thoát về menu giữa chừng, nạp game...): khỏi để hộp thoại mồ côi
# đè lên màn hình kế tiếp rồi chạy callback của cảnh cũ.
func reset() -> void:
	active = false
	_in_choice = false
	_callback = Callable()
	_choice_waiter = null # coroutine đang chờ lựa chọn/hội thoại bị bỏ rơi hẳn, không bị đánh thức nhầm bởi phiên sau
	current_dialogue = []
	index = 0
	visible = false
	if _ui:
		_ui.clear()
	GameManager.end_dialogue()

# Người chờ dùng một lần: mỗi lời gọi ask/play_async await trên đối tượng riêng thay vì một tín hiệu dùng chung. Nếu reset() xảy ra
# (thoát về menu giữa chừng) thì người chờ không bao giờ được báo, thay vì bị đánh thức bởi lựa chọn đầu tiên của phiên kế tiếp
# rồi chạy tiếp mã của một cảnh đã đóng.
class Waiter extends RefCounted:
	signal done(value: int)

var _choice_waiter: Waiter

# Phát một đoạn hội thoại và chờ tới khi xong (dùng với await). Mảng rỗng (vd. khóa hội thoại thiếu) thì trả về ngay.
func play_async(lines: Array) -> void:
	if lines.is_empty():
		return
	var waiter := Waiter.new()
	var state := {"done": false}
	play_dialogue(lines, func():
		state["done"] = true
		waiter.done.emit(0)
	)
	if not state["done"]: # play_dialogue có thể đã gọi callback ngay (đang có hội thoại khác): khi đó không chờ
		await waiter.done

# Hiện danh sách lựa chọn rồi chờ người chơi chọn: trả về chỉ số được chọn (dùng với await)
func ask(options: Array) -> int:
	var waiter := Waiter.new()
	_choice_waiter = waiter
	show_choice(options)
	return await waiter.done

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
	var waiter := _choice_waiter # lấy ra trước khi báo: người chờ có thể gọi ask() mới ngay trong lần chạy tiếp
	_choice_waiter = null
	if waiter:
		waiter.done.emit(idx)

# Kết thúc và đóng giao diện hội thoại
func _finish():
	active = false
	visible = false
	_ui.clear()
	GameManager.end_dialogue()
	if _callback.is_valid(): _callback.call()
	dialogue_finished.emit()
