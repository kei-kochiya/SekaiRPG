extends CanvasLayer

"""
Tóm tắt: ScreenFade là Node Autoload quản lý hiệu ứng làm tối/sáng màn hình (Fade In/Out).

Chức năng chính:
- Hiển thị một lớp phủ `ColorRect` màu đen trên cùng của hệ thống UI (Layer 200).
- Cung cấp API `fade_in` và `fade_out` nhận tham số `duration` để tùy chỉnh tốc độ chuyển cảnh.
- Trả về tín hiệu `await tw.finished` cho phép các đoạn code gọi nó có thể tạm dừng (yield) chờ hiệu ứng hoàn tất.
"""

var _rect: ColorRect

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
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 1.0, duration)
	await tw.finished

func fade_in(duration: float = 0.5) -> void:
	"""
	Làm sáng màn hình dần dần bằng cách giảm độ đục (alpha) của lớp phủ.
	
	Args:
		duration (float): Thời gian diễn ra hiệu ứng (giây).
	Returns: Không có
	"""
	_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 0.0, duration)
	await tw.finished
