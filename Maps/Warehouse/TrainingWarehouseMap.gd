extends Node2D

"""
TrainingWarehouseMap: Bản đồ chế độ luyện tập tại kho hàng.

Cho phép 1-2 thành viên tham gia luyện tập với số wave tăng theo số người (5 hoặc 10).
Kẻ địch sinh ngẫu nhiên (có thể là nhân vật trong nhóm hoặc mục tiêu).
Hoàn thành chuyển về BaseMap_PostWarehouse.
"""

const TILE_SIZE = 32

var max_waves = 5

func _ready():
	AudioManager.play_music("map")
	
	# Vào map luyện tập khi không ở chế độ luyện tập (vd: save cũ) thì không có trận nào để đánh -> về Base
	if not GameManager.is_training_mode:
		_return_to_base()
		return
	
	if GameManager.training_participants.size() > 1:
		max_waves = 10
	else:
		max_waves = 5
		
	_build_map()
	_spawn_player()
	
	# Check Completion (luyện tập dùng training_wave riêng, không đụng warehouse_wave của cốt truyện)
	var training_done: bool = GameManager.training_wave > max_waves
	if not training_done:
		_build_mission_hud()
		_spawn_enemy_wave()
	
	# Chờ màn hình sáng hẳn để Dialogue UI (Layer 100) không bị ScreenFade (Layer 200) che
	await ScreenFade.fade_in(0.8)
	if training_done:
		_complete_training()

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
		var flag: String = "training_%s_done" % p.to_lower() # khớp GameManager.TRAINING_DONE_FLAGS
		if flag in GameManager.TRAINING_DONE_FLAGS:
			GameManager.set_flag(flag, true)
	
	GameManager.end_training()
	# Hồi máu đầy cho party sau khi luyện tập xong
	GameManager.full_heal_party()
	DialogueManager.play_dialogue([{
		"text": "Luyện tập hoàn tất. Bạn cảm thấy cơ thể linh hoạt hơn.",
		"type": "narrator"
	}], func():
		_return_to_base()
	)

func _return_to_base():
	await GameManager.change_map(MapPaths.BASE, 1.0)

func _create_enemy_zone(pos: Vector2):
	var root = Node2D.new()
	root.position = pos
	root.add_to_group("objectives")
	
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/Person/warehouse_worker.svg")
	sprite.scale = Vector2(1, 1)
	sprite.position = Vector2(0, -16)
	root.add_child(sprite)
	
	var zone = InteractableZone.new()
	zone.prompt_text = "Nhấn ENTER để bắt đầu lượt tập (Wave " + str(GameManager.training_wave) + ")"
	var zcol = CollisionShape2D.new()
	var zsha = CircleShape2D.new()
	zsha.radius = 40
	zcol.shape = zsha
	zone.add_child(zcol)
	root.add_child(zone)
	
	zone.interacted.connect(func():
		var player = get_node("OverworldPlayer")
		GameManager.store_map_state(MapPaths.TRAINING, player.global_position)
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
	
	# Decor: cây ngẫu nhiên, chừa lối đi từ chỗ xuất hiện (15,18) tới cửa (15,15) (kèm đệm 1 ô quanh lối đi)
	var trees_placed = 0
	while trees_placed < 10:
		var rx = randi_range(2, 28)
		var ry = randi_range(16, 21)
		if rx >= 14 and rx <= 16 and ry <= 19:
			continue
		_place_tile("tree.png", Vector2(rx, ry), true)
		trees_placed += 1

	# Some internal decor
	_place_tile("sword.png", Vector2(7, 7), false)
	_place_tile("bow.png", Vector2(23, 7), false)
	_place_tile("chest.png", Vector2(15, 7), false)

func _fill_floor(x1, y1, x2, y2):
	MapUtils.fill_floor(self, x1, y1, x2, y2)

func _draw_room_walls(x1, y1, x2, y2):
	MapUtils.draw_room_walls(self, x1, y1, x2, y2)

func _place_tile(file: String, grid_pos: Vector2, has_collision: bool):
	MapUtils.place_tile(self, file, grid_pos, has_collision)

func _remove_wall_at(grid_pos: Vector2):
	MapUtils.remove_wall_at(self, grid_pos)

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
	label.text = "LUYỆN TẬP: " + ", ".join(GameManager.training_participants) + "\nTiến độ: Wave " + str(GameManager.training_wave) + " / " + str(max_waves)
	panel.add_child(label)
