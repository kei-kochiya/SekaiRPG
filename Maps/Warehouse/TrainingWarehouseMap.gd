extends Node2D

"""
TrainingWarehouseMap: Bản đồ chế độ luyện tập tại kho hàng.

Cho phép 1-2 thành viên tham gia luyện tập với số wave tăng theo số người (5 hoặc 10).
Kẻ địch sinh ngẫu nhiên (có thể là nhân vật trong nhóm hoặc mục tiêu).
Hoàn thành chuyển về BaseMap_PostWarehouse.
"""

const TILE_SIZE = 32
const ASSET_ROOT = "res://Assets/kenney_micro-roguelike/Tiles/"

var max_waves = 5

func _ready():
	AudioManager.play_music("map")
	ScreenFade.fade_in(0.8)
	
	if GameManager.training_participants.size() > 1:
		max_waves = 10
	else:
		max_waves = 5
		
	_build_map()
	_spawn_player()
	
	# Check Completion
	if GameManager.warehouse_wave > max_waves:
		_complete_training()
		return
	
	_build_mission_hud()
	_spawn_enemy_wave()

func _spawn_player():
	var player = OverworldPlayer.new()
	player.name = "OverworldPlayer"
	# Start near the door of the big training warehouse
	if GameManager.last_player_position == Vector2.ZERO:
		player.position = Vector2(15 * TILE_SIZE, 18 * TILE_SIZE)
	else:
		player.position = GameManager.last_player_position
	add_child(player)

func _spawn_enemy_wave():
	# Random position inside the room (Internal range: x[5, 25], y[5, 15])
	var rx = randi_range(7, 23)
	var ry = randi_range(7, 13)
	_create_enemy_zone(Vector2(rx * TILE_SIZE, ry * TILE_SIZE))

func _complete_training():
	for p in GameManager.training_participants:
		if p == "Ichika": GameManager.training_ichika_done = true
		if p == "Kanade": GameManager.training_kanade_done = true
	
	GameManager.is_training_mode = false
	DialogueManager.play_dialogue([{
		"text": "Luyện tập hoàn tất. Bạn cảm thấy cơ thể linh hoạt hơn.",
		"type": "narrator"
	}], func():
		_return_to_base()
	)

func _return_to_base():
	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state("res://Maps/Base/BaseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Maps/Base/BaseMap.tscn")

func _create_enemy_zone(pos: Vector2):
	var root = Node2D.new()
	root.position = pos
	root.add_to_group("objectives")
	
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/Person/c_down.png")
	sprite.scale = Vector2(4, 4)
	sprite.position = Vector2(0, -12)
	root.add_child(sprite)
	
	var zone = InteractableZone.new()
	zone.prompt_text = "Nhấn ENTER để bắt đầu lượt tập (Wave " + str(GameManager.warehouse_wave) + ")"
	var zcol = CollisionShape2D.new()
	var zsha = CircleShape2D.new()
	zsha.radius = 40
	zcol.shape = zsha
	zone.add_child(zcol)
	root.add_child(zone)
	
	zone.interacted.connect(func():
		var player = get_node("OverworldPlayer")
		GameManager.store_map_state("res://Maps/Warehouse/TrainingWarehouseMap.tscn", player.global_position)
		GameManager.trigger_battle()
	)
	add_child(root)

func _build_map():
	# Floor
	_fill_floor(2, 2, 30, 22)
	
	# Big Training Room
	_draw_room_walls(5, 5, 25, 15)
	
	# Door
	_remove_wall_at(Vector2(15, 15))
	_place_tile("door_1.png", Vector2(15, 15), false)
	
	# Decor
	for i in range(10):
		var rx = randi_range(2, 28)
		var ry = randi_range(16, 21)
		_place_tile("tree.png", Vector2(rx, ry), true)

	# Some internal decor
	_place_tile("sword.png", Vector2(7, 7), false)
	_place_tile("bow.png", Vector2(23, 7), false)
	_place_tile("chest.png", Vector2(15, 7), false)

func _fill_floor(x1, y1, x2, y2):
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			_place_tile("floor.png", Vector2(x, y), false)

func _draw_room_walls(x1, y1, x2, y2):
	for x in range(x1, x2 + 1):
		_place_tile("horizontal_wall.png", Vector2(x, y1), true)
		_place_tile("horizontal_wall.png", Vector2(x, y2), true)
	for y in range(y1, y2 + 1):
		_place_tile("left_vertical_wall.png", Vector2(x1, y), true)
		_place_tile("right_vertical_wall.png", Vector2(x2, y), true)
	_place_tile("top_left_wall.png", Vector2(x1, y1), true)
	_place_tile("top_right_wall.png", Vector2(x2, y1), true)
	_place_tile("bottom_left_wall.png", Vector2(x1, y2), true)
	_place_tile("bottom_right_wall.png", Vector2(x2, y2), true)

func _place_tile(file: String, grid_pos: Vector2, has_collision: bool):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load(ASSET_ROOT + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = tile_pos
	add_child(sprite)
	if has_collision:
		var body = StaticBody2D.new()
		body.position = tile_pos
		body.name = "Body_" + str(grid_pos.x) + "_" + str(grid_pos.y)
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		col.shape = shape
		body.add_child(col)
		add_child(body)

func _remove_wall_at(grid_pos: Vector2):
	var target_pos = grid_pos * TILE_SIZE
	for child in get_children():
		if child is Node2D:
			if child.position.distance_to(target_pos) < 1.0:
				child.queue_free()
	_place_tile("floor.png", grid_pos, false)

func _build_mission_hud():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	var panel = PanelContainer.new()
	panel.position = Vector2(20, 20)
	canvas.add_child(panel)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.6)
	sb.border_width_left = 4
	sb.border_color = Color(0.2, 0.8, 0.2)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 16)
	label.text = "LUYỆN TẬP: " + ", ".join(GameManager.training_participants) + "\nTiến độ: Wave " + str(GameManager.warehouse_wave) + " / " + str(max_waves)
	panel.add_child(label)
