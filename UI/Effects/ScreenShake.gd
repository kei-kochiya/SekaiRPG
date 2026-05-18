extends Node
class_name ScreenShake

"""
Tóm tắt: ScreenShake cung cấp hiệu ứng rung màn hình và dừng hình (Hitstop) cho các pha hành động.

Chức năng chính:
- Xử lý dịch chuyển (offset) ngẫu nhiên Node cha (thường là Camera hoặc khung hình chính) để tạo cảm giác rung lắc.
- Cung cấp API `shake` để tùy chỉnh cường độ (intensity) và thời lượng (duration) của rung chấn.
- Cung cấp API `hitstop` để làm chậm thời gian cục bộ (Engine.time_scale) nhằm tạo độ nặng cho đòn đánh.
"""

# ── Biến Cấu Hình ──────────────────────────────────────────────────────────


var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

# ── Khởi Tạo & Vòng Lặp ────────────────────────────────────────────────────

# Tắt quá trình xử lý rung mặc định
func _ready():
	set_process(false)

# ── API Kích Hoạt ──────────────────────────────────────────────────────────

func shake(intensity: float = 5.0, duration: float = 0.2):
	"""
	Kích hoạt hiệu ứng rung màn hình.
	
	Args:
		intensity (float): Độ mạnh của cú rung (pixels).
		duration (float): Thời gian rung (giây).
	Returns: Không có
	"""
	shake_intensity = intensity
	shake_timer = duration
	set_process(true)

func hitstop(duration: float = 0.1):
	"""
	Hiệu ứng dừng hình chớp nhoáng (giảm time_scale) để tạo cảm giác lực va chạm mạnh.
	
	Args:
		duration (float): Thời gian dừng (giây thực tế).
	Returns: Không có
	"""
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

# ── Xử Lý Frame ────────────────────────────────────────────────────────────

# Xử lý dịch chuyển vị trí ngẫu nhiên của Node cha
func _process(delta):
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
