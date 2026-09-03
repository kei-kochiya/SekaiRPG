extends Label
class_name FloatingText

"""
Tóm tắt: FloatingText hiển thị các con số nổi (sát thương, hồi máu, chí mạng, break) bay lên trên màn hình.

Chức năng chính:
- Tự động thực hiện hiệu ứng bay lên, phóng to nảy (pop) và mờ dần (Tween).
- Phân biệt màu sắc trực quan:
  - Chí mạng (Crit): Vàng kim viền đỏ, cỡ chữ lớn kèm nhãn "CRIT!".
  - Phá điểm yếu (Break): Xanh ngọc phát sáng "BREAK!".
  - Hồi máu: Xanh lá cây (+HP).
  - DoT: Tím mờ.
  - Sát thương vật lý/thuộc tính thường: Đỏ / Trắng.
"""

# ── Cấu Hình ───────────────────────────────────────────────────────────────

const COLORS = {
	"physical": Color(1.0, 0.35, 0.35),
	"pure":     Color(1.0, 1.0, 1.0),
	"dot":      Color(0.75, 0.35, 0.9),
	"heal":     Color(0.25, 1.0, 0.4),
	"crit":     Color(1.0, 0.85, 0.2),
	"break":    Color(0.2, 0.95, 1.0),
}

var float_color: Color = Color.RED
var is_crit: bool = false

# ── Xử Lý Hiệu Ứng ─────────────────────────────────────────────────────────

func _ready():
	"""
	Khởi tạo hiệu ứng hoạt ảnh nảy (Scale Bounce) và bay lên (Tween).
	"""
	add_theme_color_override("font_color", float_color)
	var outline_col = Color(0.6, 0.1, 0.1) if is_crit else Color.BLACK
	add_theme_color_override("font_outline_color", outline_col)
	add_theme_constant_override("outline_size", 6 if is_crit else 4)
	add_theme_font_size_override("font_size", 28 if is_crit else 22)
	
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	z_index = 120
	pivot_offset = size / 2.0
	
	# Độ lệch ngẫu nhiên nhẹ tránh đè số
	position.x += randf_range(-16, 16)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Hiệu ứng nảy phóng to (Pop bounce) khi Chí mạng
	if is_crit:
		scale = Vector2(0.5, 0.5)
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.15)
	
	# Bay lên trên với hiệu ứng Cubic giảm dần
	var rise_dist = 70 if is_crit else 50
	tween.tween_property(self, "position:y", position.y - rise_dist, 0.9) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Mờ dần sau 0.4s
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.5)
	
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

# ── Hàm Khởi Tạo Nhanh ─────────────────────────────────────────────────────

static func spawn(parent: Node, amount: int, damage_type: String, pos: Vector2, p_is_crit: bool = false, p_is_break: bool = false):
	"""
	Hàm tĩnh để tạo nhanh FloatingText tại vị trí chỉ định.
	"""
	# Nếu có phá vỡ điểm yếu, tạo thêm nhãn thông báo BREAK phía trên
	if p_is_break:
		var break_lbl = FloatingText.new()
		break_lbl.text = "WEAKNESS BREAK!"
		break_lbl.float_color = COLORS["break"]
		break_lbl.position = pos + Vector2(0, -28)
		parent.add_child(break_lbl)

	var ft = FloatingText.new()
	ft.is_crit = p_is_crit
	
	if damage_type == "heal":
		ft.text = "+%d" % amount
		ft.float_color = COLORS["heal"]
	elif p_is_crit:
		ft.text = "CRIT! -%d" % amount
		ft.float_color = COLORS["crit"]
	else:
		ft.text = "-%d" % amount
		ft.float_color = COLORS.get(damage_type, Color.RED)
		
	ft.position = pos
	parent.add_child(ft)
