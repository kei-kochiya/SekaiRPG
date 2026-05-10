extends Node
class_name ScreenShake

"""
ScreenShake: Cung cấp hiệu ứng rung màn hình và dừng hình (Hitstop).

Sử dụng để tăng cảm giác va chạm và sự kịch tính trong các pha hành động
hoặc khi nhân vật nhận sát thương mạnh.
"""

var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	"""
	Ban đầu tắt quá trình xử lý rung để tiết kiệm tài nguyên.
	"""
	set_process(false)

func shake(intensity: float = 5.0, duration: float = 0.2):
	"""
	Kích hoạt hiệu ứng rung màn hình.

	Args:
		intensity (float): Độ mạnh của cú rung (pixels).
		duration (float): Thời gian rung (giây).
	"""
	shake_intensity = intensity
	shake_timer = duration
	set_process(true)

func hitstop(duration: float = 0.1):
	"""
	Hiệu ứng dừng hình chớp nhoáng (giảm time_scale) để tạo cảm giác lực va chạm mạnh.

	Args:
		duration (float): Thời gian dừng (giây thực tế).
	"""
	Engine.time_scale = 0.05
	# Sử dụng timer bỏ qua time_scale để đếm thời gian thực
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func _process(delta):
	"""
	Xử lý việc dịch chuyển vị trí ngẫu nhiên của Node cha để tạo hiệu ứng rung.
	"""
	var parent = get_parent()
	if not parent:
		set_process(false)
		return
	
	if shake_timer > 0:
		shake_timer -= delta
		parent.position = original_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		parent.position = original_offset
		set_process(false)
