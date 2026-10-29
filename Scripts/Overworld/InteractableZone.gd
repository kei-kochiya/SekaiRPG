extends Area2D
class_name InteractableZone

"""
Tóm tắt: InteractableZone quản lý các vùng tương tác sự kiện trên bản đồ.

Chức năng chính:
- Tạo một vùng phát hiện va chạm (Area2D) chuyên biệt để nhận diện OverworldPlayer.
- Tự động hiển thị nhãn gợi ý (Prompt) "Press ENTER" khi người chơi nằm trong vùng an toàn.
- Lắng nghe sự kiện phím (InputEvent) và phát tín hiệu `interacted` khi người chơi bấm nút tương tác.
- Tích hợp với hệ thống MobileControls để hiển thị phím bấm tương tác ảo trên điện thoại.
"""

# ── Biến Thành Phần ────────────────────────────────────────────────────────


signal interacted

var prompt_label: Label
var is_player_inside: bool = false

# Khoảng cách từ gốc vùng tới đáy nhãn gợi ý (đủ cao để không che sprite và tên NPC)
const PROMPT_GAP = 56

# Đổi text sau khi vùng đã tạo (vd. TreasureChest: "Mở rương" -> "Rương trống") thì nhãn cập nhật theo
@export var prompt_text: String = "Press ENTER":
	set(value):
		prompt_text = value
		_refresh_prompt()

# ── Khởi Tạo ───────────────────────────────────────────────────────────────

func _ready():
	"""
	Khởi tạo cấu hình cho vùng tương tác và nhãn gợi ý hiển thị.
	
	Thiết lập Collision Layer để không cản trở và Collision Mask để phát hiện 
	người chơi (Layer 1). Nhãn gợi ý dùng UITheme (chip nền tối, viền hổ phách).
	"""
	collision_layer = 0
	collision_mask = 1 
	z_index = 10
	
	prompt_label = Label.new()
	prompt_label.visible = false
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.style_label(prompt_label, UITheme.FS_BODY, UITheme.TEXT)
	prompt_label.add_theme_stylebox_override("normal", UITheme.box(UITheme.INK_800, UITheme.ACCENT, UITheme.RADIUS_SM, UITheme.SP_3, UITheme.SP_1))
	add_child(prompt_label)
	_refresh_prompt()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

# Cập nhật nội dung nhãn, co theo chữ và canh giữa phía trên vùng
func _refresh_prompt():
	if prompt_label == null:
		return
	prompt_label.text = prompt_text
	prompt_label.reset_size()
	prompt_label.position = Vector2(-prompt_label.size.x / 2.0, -PROMPT_GAP - prompt_label.size.y)

# ── Xử Lý Va Chạm ──────────────────────────────────────────────────────────

func _on_body_entered(body):
	"""
	Xử lý khi người chơi bước vào vùng tương tác.

	Args:
		body (Node2D): Đối tượng vừa bước vào vùng.
	"""
	if body.name == "OverworldPlayer":
		is_player_inside = true
		prompt_label.visible = true
		if has_node("/root/MobileControls"):
			get_node("/root/MobileControls").set_interact_visible(true)

func _on_body_exited(body):
	"""
	Xử lý khi người chơi bước ra khỏi vùng tương tác.

	Args:
		body (Node2D): Đối tượng vừa bước ra khỏi vùng.
	"""
	if body.name == "OverworldPlayer":
		is_player_inside = false
		prompt_label.visible = false
		if has_node("/root/MobileControls"):
			get_node("/root/MobileControls").set_interact_visible(false)

# ── Xử Lý Tương Tác ────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	"""
	Xử lý hành động nhấn phím tương tác từ người chơi.

	Đảm bảo tương tác chỉ xảy ra khi người chơi đang ở trong vùng và không 
	đang trong trạng thái hội thoại. Sử dụng set_input_as_handled để ngăn 
	chặn sự kiện phím lan truyền sang các đối tượng khác.

	Args:
		event (InputEvent): Sự kiện đầu vào từ bàn phím.
	"""
	if is_player_inside and event.is_action_pressed("ui_accept"):
		if not GameManager.is_in_dialogue:
			get_viewport().set_input_as_handled()
			interacted.emit()

func _process(_delta):
	"""
	Cập nhật trạng thái hiển thị của nhãn gợi ý theo thời gian thực.
	"""
	if GameManager.is_in_dialogue:
		prompt_label.visible = false
		if has_node("/root/MobileControls"):
			get_node("/root/MobileControls").set_interact_visible(false)
	elif is_player_inside:
		prompt_label.visible = true
		if has_node("/root/MobileControls"):
			get_node("/root/MobileControls").set_interact_visible(true)
