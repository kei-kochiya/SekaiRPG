extends CharacterBody2D
class_name OverworldPlayer

"""
OverworldPlayer: Điều khiển nhân vật người chơi trong thế giới khám phá (Overworld).

Lớp này quản lý việc di chuyển của nhân vật, hiển thị hình đại diện đồ họa 
(Marker động thay đổi theo hướng đi) và mũi tên chỉ hướng mục tiêu (Objective arrow) 
để hướng dẫn người chơi thực hiện nhiệm vụ.
"""

const SPEED = 250.0

# Màu sắc đại diện cho nhân vật (Mặc định: Ichika blue)
var character_color: Color = Color(0.29, 0.62, 0.62)

var _marker: Polygon2D
var _objective_arrow: Sprite2D
var _last_dir: Vector2 = Vector2.ZERO

func _ready():
	"""
	Khởi tạo các thành phần cốt lõi của người chơi.
	
	Thiết lập va chạm, Marker đại diện, mũi tên chỉ đường, Hitbox vật lý 
	và Camera theo chân. Tự động khôi phục vị trí từ GameManager nếu có.
	"""
	collision_layer = 1
	collision_mask = 3
	
	_marker = Polygon2D.new()
	_marker.color = character_color
	add_child(_marker)
	_draw_dot()
	
	_objective_arrow = Sprite2D.new()
	var arrow_tex = load("res://Assets/kenney_ui-pack-adventure/Vector/minimap_arrow_c.svg")
	if arrow_tex != null:
		_objective_arrow.texture = arrow_tex
		
	_objective_arrow.modulate = Color(1.0, 0.9, 0.2, 0.9)
	_objective_arrow.scale = Vector2(0.4, 0.4)
	add_child(_objective_arrow)
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	shape.shape = rect
	add_child(shape)
	
	var camera = Camera2D.new()
	add_child(camera)
	camera.make_current()
	
	if GameManager.last_player_position != Vector2.ZERO:
		global_position = GameManager.last_player_position

func _process(_delta):
	"""
	Cập nhật logic hình ảnh không liên quan đến vật lý (Mũi tên mục tiêu).
	"""
	_update_objective_arrow()

func _update_objective_arrow():
	"""
	Xác định và chỉ hướng tới mục tiêu nhiệm vụ gần nhất.
	
	Quét các Node trong nhóm 'objectives', tính toán khoảng cách và xoay 
	mũi tên hướng về phía đối tượng gần nhất.
	"""
	var objectives = get_tree().get_nodes_in_group("objectives")
	if objectives.is_empty():
		_objective_arrow.visible = false
		return
	
	_objective_arrow.visible = true
	var closest: Node2D = null
	var min_dist = 1e10
	
	for obj in objectives:
		if not obj is Node2D: continue
		var d = global_position.distance_squared_to(obj.global_position)
		if d < min_dist:
			min_dist = d
			closest = obj
			
	if closest == null:
		_objective_arrow.visible = false
		return
	
	var dir = (closest.global_position - global_position).normalized()
	_objective_arrow.rotation = dir.angle()
	_objective_arrow.position = dir * 40.0

func _physics_process(_delta):
	"""
	Xử lý di chuyển vật lý và điều khiển đầu vào từ người chơi.

	Nếu đang trong trạng thái hội thoại, vận tốc sẽ được đặt về 0. 
	Marker của người chơi sẽ tự động chuyển đổi giữa hình tròn (đứng yên) 
	và hình mũi tên (di chuyển) dựa trên vector vận tốc.
	"""
	if GameManager.is_in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		if _last_dir != Vector2.ZERO:
			_last_dir = Vector2.ZERO
			_draw_dot()
		return
		
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * SPEED
	move_and_slide()
	
	if input_dir != Vector2.ZERO:
		if input_dir != _last_dir:
			_last_dir = input_dir
			_draw_arrow(input_dir)
	else:
		if _last_dir != Vector2.ZERO:
			_last_dir = Vector2.ZERO
			_draw_dot()

func _draw_dot():
	"""
	Vẽ hình tròn đơn giản đại diện cho trạng thái đứng yên của người chơi.
	"""
	var points = PackedVector2Array()
	var r = 7.0
	var sides = 8
	for i in range(sides):
		var angle = (TAU / sides) * i
		points.append(Vector2(cos(angle) * r, sin(angle) * r))
	_marker.polygon = points
	_marker.color = character_color

func _draw_arrow(dir: Vector2):
	"""
	Vẽ hình mũi tên đa giác chỉ hướng di chuyển hiện tại.

	Args:
		dir (Vector2): Vector hướng di chuyển của nhân vật.
	"""
	var norm = dir.normalized()
	var perp = Vector2(-norm.y, norm.x)
	var tip = norm * 12.0
	var base_left = -norm * 5.0 + perp * 7.0
	var base_right = -norm * 5.0 - perp * 7.0
	_marker.polygon = PackedVector2Array([tip, base_left, base_right])
	_marker.color = character_color
