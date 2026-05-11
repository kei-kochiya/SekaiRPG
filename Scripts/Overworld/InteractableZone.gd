extends Area2D
class_name InteractableZone

"""
InteractableZone: Vùng tương tác trong thế giới trò chơi (Overworld).

Lớp này quản lý việc phát hiện người chơi khi đi vào vùng kích hoạt, hiển thị
nhãn gợi ý (prompt) và phát tín hiệu khi người chơi thực hiện thao tác tương tác. 
Sử dụng hệ thống Collision Mask để chỉ phản hồi với thực thể người chơi.
"""

signal interacted

var prompt_label: Label
var is_player_inside: bool = false

@export var prompt_text: String = "Press ENTER"

func _ready():
	"""
	Khởi tạo cấu hình cho vùng tương tác và nhãn gợi ý hiển thị.
	
	Thiết lập Collision Layer để không cản trở và Collision Mask để phát hiện 
	người chơi (Layer 1). Tạo nhãn gợi ý sử dụng StyleBox từ bộ Assets Kenney.
	"""
	collision_layer = 0
	collision_mask = 1 
	z_index = 10
	
	prompt_label = Label.new()
	prompt_label.text = prompt_text
	prompt_label.visible = false
	prompt_label.position = Vector2(-60, -50)
	prompt_label.custom_minimum_size = Vector2(120, 40)
	prompt_label.add_theme_font_size_override("font_size", 12)
	prompt_label.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var pb = StyleBoxTexture.new()
	pb.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/banner_modern.svg")
	
	pb.texture_margin_left = 10
	pb.texture_margin_right = 10
	pb.texture_margin_top = 10
	pb.texture_margin_bottom = 10
	prompt_label.add_theme_stylebox_override("normal", pb)
	
	add_child(prompt_label)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	"""
	Xử lý khi người chơi bước vào vùng tương tác.

	Args:
		body (Node2D): Đối tượng vừa bước vào vùng.
	"""
	if body.name == "OverworldPlayer":
		is_player_inside = true
		prompt_label.visible = true

func _on_body_exited(body):
	"""
	Xử lý khi người chơi bước ra khỏi vùng tương tác.

	Args:
		body (Node2D): Đối tượng vừa bước ra khỏi vùng.
	"""
	if body.name == "OverworldPlayer":
		is_player_inside = false
		prompt_label.visible = false

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
	elif is_player_inside:
		prompt_label.visible = true
