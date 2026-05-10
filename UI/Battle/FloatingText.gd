extends Label
class_name FloatingText

"""
FloatingText: Hiển thị các con số (sát thương, hồi máu) bay lên trên màn hình.

Mỗi instance tự động thực hiện hiệu ứng bay lên, mờ dần và tự hủy sau khi kết thúc.
"""

const COLORS = {
	"physical": Color(1.0, 0.3, 0.3),
	"pure":     Color(1.0, 1.0, 1.0),
	"dot":      Color(0.7, 0.3, 0.8),
	"heal":     Color(0.3, 1.0, 0.3),
}

var float_color: Color = Color.RED

func _ready():
	"""
	Khởi tạo hiệu ứng hoạt ảnh bay (Tween) ngay khi node được thêm vào scene.
	"""
	add_theme_color_override("font_color", float_color)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 4)
	add_theme_font_size_override("font_size", 24)
	
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	z_index = 100
	
	# Tạo độ lệch ngẫu nhiên theo phương ngang để tránh các con số đè lên nhau
	position.x += randf_range(-15, 15)
	
	var tween = create_tween()
	tween.set_parallel(true)
	# Bay lên trên 60 pixels với hiệu ứng Cubic giảm dần
	tween.tween_property(self, "position:y", position.y - 60, 1.0) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# Mờ dần sau 0.5 giây
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.5)
	
	tween.set_parallel(false)
	tween.tween_callback(queue_free) # Tự hủy

static func spawn(parent: Node, amount: int, damage_type: String, pos: Vector2):
	"""
	Hàm tĩnh để tạo nhanh một FloatingText tại vị trí chỉ định.

	Args:
		parent (Node): Node cha (thường là UI Overlay).
		amount (int): Giá trị con số hiển thị.
		damage_type (String): Loại sát thương (để xác định màu sắc).
		pos (Vector2): Vị trí bắt đầu trên màn hình.
	"""
	var ft = FloatingText.new()
	var prefix = "+" if damage_type == "heal" else "-"
	ft.text = "%s%d" % [prefix, amount]
	ft.float_color = COLORS.get(damage_type, Color.RED)
	ft.position = pos
	parent.add_child(ft)
