extends CharacterBody2D
class_name OverworldPlayer

const SPEED = 250.0

# Character color — set this after creating the player to change identity
var character_color: Color = Color(0.29, 0.62, 0.62) # Default: Ichika blue

var _marker: Polygon2D
var _last_dir: Vector2 = Vector2.ZERO

func _ready():
	collision_layer = 1
	collision_mask = 3
	
	# Polygon2D for the arrow/dot
	_marker = Polygon2D.new()
	_marker.color = character_color
	add_child(_marker)
	
	# Start as dot
	_draw_dot()
	
	# Physics hitbox
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

func _physics_process(_delta):
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

# Draw a simple circle approximation (8-sided polygon) as the idle dot
func _draw_dot():
	var points = PackedVector2Array()
	var r = 7.0
	var sides = 8
	for i in range(sides):
		var angle = (TAU / sides) * i
		points.append(Vector2(cos(angle) * r, sin(angle) * r))
	_marker.polygon = points
	_marker.color = character_color

# Draw a triangle arrow pointing in the given direction
func _draw_arrow(dir: Vector2):
	var norm = dir.normalized()
	var perp = Vector2(-norm.y, norm.x)
	var tip = norm * 12.0
	var base_left = -norm * 5.0 + perp * 7.0
	var base_right = -norm * 5.0 - perp * 7.0
	_marker.polygon = PackedVector2Array([tip, base_left, base_right])
	_marker.color = character_color
