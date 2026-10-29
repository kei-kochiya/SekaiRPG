extends CanvasLayer

"""
Tóm tắt: ScreenFade là Node Autoload quản lý hiệu ứng làm tối/sáng màn hình (Fade In/Out).

Chức năng chính:
- Hiển thị một lớp phủ `ColorRect` màu đen trên cùng của hệ thống UI (Layer 200).
- Cung cấp API `fade_in` và `fade_out` nhận tham số `duration` để tùy chỉnh tốc độ chuyển cảnh.
- Cho phép `await` chờ hiệu ứng hoàn tất; `busy` cho biết đang có fade chạy.
- Fade mới sẽ hủy fade đang chạy (không để hai tween tranh nhau `modulate:a`).
"""

# True trong lúc đang fade out/in
var busy: bool = false

var _rect: ColorRect
var _tw: Tween

# Phát khi fade cuối cùng kết thúc; mọi coroutine đang await (kể cả của fade đã bị thay thế) đều được đánh thức
signal _settled

# ── Khởi Tạo ───────────────────────────────────────────────────────────────

# Khởi tạo lớp phủ màu đen ở lớp cao nhất (Layer 200).
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 200
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)

# ── Hiệu Ứng ───────────────────────────────────────────────────────────────

func fade_out(duration: float = 0.5) -> void:
	"""
	Làm tối màn hình dần dần bằng cách tăng độ đục (alpha) của lớp phủ.

	Args:
		duration (float): Thời gian diễn ra hiệu ứng (giây).
	Returns: Không có
	"""
	await _fade_to(1.0, duration)

func fade_in(duration: float = 0.5) -> void:
	"""
	Làm sáng màn hình dần dần bằng cách giảm độ đục (alpha) của lớp phủ.

	Args:
		duration (float): Thời gian diễn ra hiệu ứng (giây).
	Returns: Không có
	"""
	_rect.modulate.a = 1.0
	await _fade_to(0.0, duration)

func _fade_to(alpha: float, duration: float) -> void:
	if _tw and _tw.is_valid():
		_tw.kill()
	busy = true
	_tw = create_tween()
	_tw.tween_property(_rect, "modulate:a", alpha, duration)
	_tw.finished.connect(_on_fade_finished)
	await _settled

func _on_fade_finished() -> void:
	busy = false
	_settled.emit()
