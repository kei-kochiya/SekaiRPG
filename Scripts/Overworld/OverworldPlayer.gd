extends CharacterBody2D
class_name OverworldPlayer

"""
Tóm tắt: OverworldPlayer điều khiển nhân vật người chơi trong thế giới khám phá (Overworld).

Chức năng chính:
- Hiển thị SpriteSheet nhân vật phong cách RPG Maker (3x4 khung hình, 4 hướng).
- Xử lý hoạt ảnh bước đi (walk animation) và đứng yên (idle) mượt mà theo hướng di chuyển.
- Tự động chuyển đổi ngoại hình theo nhân vật đang điều khiển (Ichika, Mizuki, Ena, v.v.).
- Xử lý hệ thống di chuyển đa hướng (8 hướng) bằng cả bàn phím (WASD/Mũi tên) và tay cầm/joystick.
- Tự động tìm kiếm và xoay mũi tên hướng dẫn (Objective Arrow) về phía mục tiêu nhiệm vụ gần nhất.
- Khóa di chuyển khi đang trong trạng thái hội thoại.
"""

# ── Cấu Hình & Biến ────────────────────────────────────────────────────────

const SPEED = 250.0
const ANIM_FRAME_TIME = 0.16
const SPRITE_ROOT = "res://Assets/Sprites/"

# Màu sắc đại diện cho nhân vật (Tự động map sang Sprite tương ứng)
var character_color: Color = Color(0.29, 0.62, 0.62):
	set(c):
		character_color = c
		_update_character_from_color(c)

var character_name: String = "Ichika":
	set(val):
		character_name = val
		_update_sprite_texture()

var _sprite: Sprite2D
var _objective_arrow: Sprite2D

var _facing: String = "down" # "down", "left", "right", "up"
var _anim_frame: int = 1     # 0: left step, 1: idle, 2: right step
var _step_idx: int = 1       # Index in [0, 1, 2, 1]
var _anim_timer: float = 0.0

# ── Khởi Tạo ───────────────────────────────────────────────────────────────

func _ready():
	"""
	Khởi tạo các thành phần cốt lõi của người chơi.
	"""
	collision_layer = 1
	collision_mask = 3
	z_index = 5
	
	# Kiểm tra cờ kịch bản để đặt nhân vật chính xác
	if GameManager.get_flag("mizuki_control_phase"):
		character_name = "Mizuki"
	elif GameManager.get_flag("ena_control_phase"):
		character_name = "Ena"
	else:
		_update_character_from_color(character_color)
		
	# Sprite 3x4 RPG Maker
	_sprite = Sprite2D.new()
	_sprite.position = Vector2(0, -16)
	add_child(_sprite)
	_update_sprite_texture()
	
	# Mũi tên chỉ mục tiêu
	_objective_arrow = Sprite2D.new()
	var arrow_tex = load("res://Assets/kenney_ui-pack-adventure/Vector/minimap_arrow_c.svg")
	if arrow_tex != null:
		_objective_arrow.texture = arrow_tex
		
	_objective_arrow.modulate = Color(1.0, 0.9, 0.2, 0.9)
	_objective_arrow.scale = Vector2(0.4, 0.4)
	add_child(_objective_arrow)
	
	# Hitbox vật lý
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

# ── Cập Nhật Sprite & Hoạt Ảnh ─────────────────────────────────────────────

func _update_sprite_texture():
	if not _sprite:
		return
	var path = SPRITE_ROOT + character_name.to_lower() + ".svg"
	if ResourceLoader.exists(path):
		_sprite.texture = load(path)
		_sprite.hframes = 3
		_sprite.vframes = 4
		_update_sprite_frame()
	else:
		# Fallback nếu chưa có sprite cụ thể
		var fallback_path = SPRITE_ROOT + "ichika.svg"
		if ResourceLoader.exists(fallback_path):
			_sprite.texture = load(fallback_path)
			_sprite.hframes = 3
			_sprite.vframes = 4
			_update_sprite_frame()

func _update_sprite_frame():
	if not _sprite:
		return
	var row = 0
	match _facing:
		"down": row = 0
		"left": row = 1
		"right": row = 2
		"up": row = 3
	_sprite.frame = row * 3 + _anim_frame

func _update_character_from_color(c: Color):
	var color_map = {
		"Mafuyu": Color(0.4, 0.3, 0.5),
		"Ena": Color(0.72, 0.38, 0.16),
		"Kanade": Color(0.8, 0.8, 0.9),
		"Mizuki": Color(0.85, 0.65, 0.8),
		"Ichika": Color(0.29, 0.62, 0.62),
		"Honami": Color(0.5, 0.35, 0.25)
	}
	var best_name = "Ichika"
	var min_dist = 100.0
	for name_key in color_map:
		var target_c: Color = color_map[name_key]
		var dist = abs(c.r - target_c.r) + abs(c.g - target_c.g) + abs(c.b - target_c.b)
		if dist < min_dist:
			min_dist = dist
			best_name = name_key
	character_name = best_name

# ── Logic Khung Hình ───────────────────────────────────────────────────────

func _process(_delta):
	_update_objective_arrow()

func _update_objective_arrow():
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

# ── Logic Vật Lý & Di Chuyển ───────────────────────────────────────────────

func _physics_process(delta):
	"""
	Xử lý di chuyển vật lý và hoạt ảnh bước đi 4 hướng của nhân vật.
	"""
	if GameManager.is_in_dialogue:
		velocity = Vector2.ZERO
		move_and_slide()
		_step_idx = 1
		_anim_frame = 1
		_anim_timer = 0.0
		_update_sprite_frame()
		return
		
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Hỗ trợ phím WASD
	if input_dir == Vector2.ZERO:
		if Input.is_key_pressed(KEY_W): input_dir.y -= 1
		if Input.is_key_pressed(KEY_S): input_dir.y += 1
		if Input.is_key_pressed(KEY_A): input_dir.x -= 1
		if Input.is_key_pressed(KEY_D): input_dir.x += 1
		input_dir = input_dir.normalized()
		
	velocity = input_dir * SPEED
	move_and_slide()
	
	# Xử lý hướng nhìn và bước đi
	if input_dir != Vector2.ZERO:
		if abs(input_dir.x) > abs(input_dir.y):
			_facing = "left" if input_dir.x < 0 else "right"
		else:
			_facing = "up" if input_dir.y < 0 else "down"
			
		_anim_timer += delta
		if _anim_timer >= ANIM_FRAME_TIME:
			_anim_timer = 0.0
			_step_idx = (_step_idx + 1) % 4
			var steps = [0, 1, 2, 1]
			_anim_frame = steps[_step_idx]
	else:
		_step_idx = 1
		_anim_frame = 1
		_anim_timer = 0.0
		
	_update_sprite_frame()

# ── Legacy Stubs ───────────────────────────────────────────────────────────

func _draw_dot():
	_anim_frame = 1
	_update_sprite_frame()

func _draw_arrow(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		_facing = "left" if dir.x < 0 else "right"
	else:
		_facing = "up" if dir.y < 0 else "down"
	_update_sprite_frame()
