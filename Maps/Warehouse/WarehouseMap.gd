extends Node2D

"""
WarehouseMap: Bản đồ nhiệm vụ kho hàng (Story Mode).

Ichika và Kanade tiêu diệt 5 wave kẻ địch tuần tự.
Sửa là cấp độ tăng dần (Lv3 →3 →6 →... →15).
Hoàn thành chuyển về BaseMap_PostWarehouse.
"""

const TILE_SIZE = MapUtils.TILE_SIZE

func _ready():
	AudioManager.play_music("map")
	
	# Vào wave 1: bỏ số kẻ địch đã hạ từ trận khác (mở màn, luyện tập) để không lẫn vào tiến trình Nhà kho
	if GameManager.warehouse_wave == 1 and GameManager.enemies_defeated > 0:
		GameManager.reset_mission_stats()
	
	_build_map()
	_spawn_player()
	_build_mission_hud()
	
	# Chỉ spawn wave trigger khi chưa hoàn thành tất cả các wave
	if GameManager.warehouse_wave <= 5:
		_spawn_current_wave()
	
	# Chờ màn hình chuyển cảnh sáng hoàn toàn để tránh Dialogue UI (Layer 100) bị che bởi ScreenFade (Layer 200)
	await ScreenFade.fade_in(0.8)
	
	# Trường hợp kết thúc: Đã qua wave 5, hiện hội thoại rồi chuyển về Safehouse mới.
	if GameManager.warehouse_wave > 5:
		AudioManager.play_music("night")
		DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_clear"), func():
			_return_to_base_with_fade()
		)
		return
	
	# Hội thoại mở đầu theo từng wave quan trọng (wave 1, 3, 5)
	if GameManager.warehouse_wave == 1 and GameManager.enemies_defeated == 0:
		var intro = DialogueLoader.get_lines("warehouse_wave1_intro")
		var start = DialogueLoader.get_lines("warehouse_wave1_start")
		DialogueManager.play_dialogue(intro + start)
	elif GameManager.warehouse_wave == 3:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_wave3_start"))
	elif GameManager.warehouse_wave == 5:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_wave5_start"))

func _return_to_base_with_fade():
	await GameManager.change_map(MapPaths.BASE, 1.5)

func _spawn_player():
	MapUtils.spawn_player(self, Vector2(10 * TILE_SIZE, 18 * TILE_SIZE))

func _spawn_current_wave():
	var x_coord = (GameManager.warehouse_wave * 10)
	_create_enemy_zone(Vector2(x_coord * TILE_SIZE, 10 * TILE_SIZE))

func _create_enemy_zone(pos: Vector2):
	var root = Node2D.new()
	root.position = pos
	root.add_to_group("objectives")
	
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/Person/warehouse_worker.svg")
	sprite.scale = Vector2(1, 1)
	sprite.position = Vector2(0, -16)
	root.add_child(sprite)
	
	var zone = MapUtils.circle_zone(40, "Nhấn ENTER để bắt đầu Wave " + str(GameManager.warehouse_wave))
	root.add_child(zone)
	
	zone.interacted.connect(func():
		var player = get_node("OverworldPlayer")
		GameManager.store_map_state(MapPaths.WAREHOUSE, player.global_position)
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
		
	# Rương kho báu trong nhà kho
	MapUtils.place_chest(self, "warehouse_chest_01", Vector2(30, 7), 180, "potion", 2)
	MapUtils.place_chest(self, "warehouse_chest_02", Vector2(52, 7), 250, "energy_drink", 1)
		
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
	MapUtils.fill_floor(self, x1, y1, x2, y2)

func _draw_room_walls(x1, y1, x2, y2):
	MapUtils.draw_room_walls(self, x1, y1, x2, y2)

func _place_tile(file: String, grid_pos: Vector2, has_collision: bool):
	MapUtils.place_tile(self, file, grid_pos, has_collision)

func _remove_wall_at(grid_pos: Vector2):
	MapUtils.remove_wall_at(self, grid_pos)

func _build_mission_hud():
	QuestHUDBuilder.build(self)["label"].text = "MỤC TIÊU: Dọn dẹp kho hàng\nTiến độ: Wave " + str(mini(GameManager.warehouse_wave, 5)) + " / 5"
