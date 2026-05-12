extends Node2D

"""
WarehouseMap: Bản đồ nhiệm vụ kho hàng (Story Mode).

Ichika và Kanade tiêu diệt 5 wave kẻ địch tuần tự.
Sửa là cấp độ tăng dần (Lv3 →3 →6 →... →15).
Hoàn thành chuyển về BaseMap_PostWarehouse.
"""

const TILE_SIZE = 32
const ASSET_ROOT = "res://Assets/kenney_micro-roguelike/Tiles/"

func _ready():
	AudioManager.play_music("map")
	ScreenFade.fade_in(0.8)
	
	_build_map()
	_spawn_player()
	
	# Trường hợp kết thúc: Đã qua wave 5, hiện hội thoại rồi chuyển về Safehouse mới.
	if GameManager.warehouse_wave > 5:
		AudioManager.play_music("after_warehouse")
		DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_clear"), func():
			_return_to_base_with_fade()
		)
		return
	
	# Hội thoại mở đầu theo từng wave quan trọng (wave 1, 3, 5)
	if GameManager.warehouse_wave == 1 and GameManager.enemies_defeated == 0:
		var intro = DialogueLoader.get_lines("warehouse_wave1_intro")
		var start = DialogueLoader.get_lines("warehouse_wave1_start")
		DialogueManager.play_dialogue(intro + start)
	elif GameManager.warehouse_wave == 3 and (GameManager.enemies_defeated % 5 == 0):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_wave3_start"))
	elif GameManager.warehouse_wave == 5 and (GameManager.enemies_defeated % 5 == 0):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_wave5_start"))
	
	_build_mission_hud()
	_spawn_current_wave()

func _return_to_base_with_fade():
	await ScreenFade.fade_out(1.5)
	GameManager.store_map_state("res://Scenes/BaseMap_PostWarehouse.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Scenes/BaseMap_PostWarehouse.tscn")

func _spawn_player():
	var p = OverworldPlayer.new()
	p.name = "OverworldPlayer"
	if GameManager.last_player_position == Vector2.ZERO:
		p.position = Vector2(10 * TILE_SIZE, 18 * TILE_SIZE)
	else:
		p.position = GameManager.last_player_position
	add_child(p)

func _spawn_current_wave():
	var x_coord = (GameManager.warehouse_wave * 10)
	_create_enemy_zone(Vector2(x_coord * TILE_SIZE, 10 * TILE_SIZE))

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
	zone.prompt_text = "Nhấn ENTER để bắt đầu Wave " + str(GameManager.warehouse_wave)
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40
	col.shape = shape
	zone.add_child(col)
	root.add_child(zone)
	
	zone.interacted.connect(func():
		var player = get_node("OverworldPlayer")
		GameManager.store_map_state("res://Scenes/WarehouseMap.tscn", player.global_position)
		GameManager.trigger_battle()
	)
	add_child(root)

# ── Map Construction ───────────────────────────────────────────────────────

func _build_map():
	_fill_floor(2, 2, 60, 22)
	
	_draw_room_walls(5, 5, 15, 15)  # Room 1
	_draw_room_walls(15, 5, 25, 15) # Room 2
	_draw_room_walls(25, 5, 35, 15) # Room 3
	_draw_room_walls(35, 5, 45, 15) # Room 4
	_draw_room_walls(45, 5, 55, 15) # Room 5
	
	# Zig-zag connections
	_remove_wall_at(Vector2(15, 7))  # 1 -> 2 (Top)
	_remove_wall_at(Vector2(25, 10)) # 2 -> 3 (Mid)
	_remove_wall_at(Vector2(35, 13)) # 3 -> 4 (Bot)
	_remove_wall_at(Vector2(45, 7))  # 4 -> 5 (Top)
	
	_remove_wall_at(Vector2(10, 15)) # Entrance
	_place_tile("door_1.png", Vector2(10, 15), false)
	
	# Decor
	var tree_spots = [
		Vector2(4, 18), Vector2(16, 18), Vector2(8, 20),
		Vector2(2, 4), Vector2(30, 20), Vector2(58, 10)
	]
	for spot in tree_spots:
		_place_tile("tree.png", spot, true)
		
	# Richer Decor
	_place_tile("sword.png", Vector2(7, 7), false)
	_place_tile("axe.png", Vector2(13, 7), false)
	_place_tile("spear.png", Vector2(17, 13), false)
	_place_tile("bow.png", Vector2(23, 13), false)
	_place_tile("arrow.png", Vector2(23, 14), false)
	_place_tile("chest.png", Vector2(30, 7), false)
	_place_tile("axe.png", Vector2(37, 7), false)
	_place_tile("spear.png", Vector2(43, 7), false)
	_place_tile("chest.png", Vector2(50, 13), false)
	_place_tile("sword.png", Vector2(53, 7), false)

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
	sb.border_color = Color(1.0, 0.9, 0.2)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 16)
	label.text = "MỤC TIÊU: Dọn dẹp kho hàng\nTiến độ: Wave " + str(GameManager.warehouse_wave) + " / 5"
	panel.add_child(label)
