extends CanvasLayer

"""
ScreenFade: Trình quản lý hiệu ứng chuyển cảnh (Fade In/Out).

Lớp này cung cấp một lớp phủ màu đen toàn màn hình, được sử dụng để che giấu 
việc chuyển đổi giữa các Scene hoặc bản đồ. Đây là một Autoload (Global Node).
"""

var _rect: ColorRect

func _ready() -> void:
	"""
	Khởi tạo lớp phủ màu đen ở lớp cao nhất (Layer 200).
	"""
	layer = 200
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0 # Bắt đầu ở trạng thái trong suốt
	add_child(_rect)

func fade_out(duration: float = 0.5) -> void:
	"""
	Làm tối màn hình dần dần. Thường dùng trước khi đổi scene.

	Args:
		duration (float): Thời gian diễn ra hiệu ứng (giây).
	"""
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 1.0, duration)
	await tw.finished

func fade_in(duration: float = 0.5) -> void:
	"""
	Làm sáng màn hình dần dần. Thường dùng sau khi scene mới đã nạp xong.

	Args:
		duration (float): Thời gian diễn ra hiệu ứng (giây).
	"""
	_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 0.0, duration)
	await tw.finished
