extends Node2D

const TILE_SIZE = 32

func _ready():
	AudioManager.play_music("map")
	
	# Draw background
	var bg = ColorRect.new()
	bg.size = Vector2(2000, 2000)
	bg.color = Color(0.1, 0.1, 0.1)
	add_child(bg)
	
	_build_house()
	
	# Camera
	var cam = Camera2D.new()
	cam.position = Vector2(15 * TILE_SIZE, 10 * TILE_SIZE)
	cam.zoom = Vector2(1.5, 1.5)
	add_child(cam)
	
	var lighting = CanvasModulate.new()
	lighting.color = Color(0.9, 0.95, 1.0)
	add_child(lighting)
	
	await ScreenFade.fade_in(1.0)
	_run_logic()

func _build_house():
	# Floor and Walls
	for x in range(5, 25):
		for y in range(4, 16):
			MapUtils.place_tile(self, "floor.png", Vector2(x, y))
	
	for x in range(5, 26):
		MapUtils.place_tile(self, "horizontal_wall.png", Vector2(x, 4))
		MapUtils.place_tile(self, "horizontal_wall.png", Vector2(x, 16))
	for y in range(4, 17):
		MapUtils.place_tile(self, "left_vertical_wall.png", Vector2(5, y))
		MapUtils.place_tile(self, "right_vertical_wall.png", Vector2(25, y))
		
	MapUtils.place_tile(self, "top_left_wall.png", Vector2(5, 4))
	MapUtils.place_tile(self, "top_right_wall.png", Vector2(25, 4))
	MapUtils.place_tile(self, "bottom_left_wall.png", Vector2(5, 16))
	MapUtils.place_tile(self, "bottom_right_wall.png", Vector2(25, 16))
	
	# Cửa ra ngoài (về Nightcord) - Dùng Sprite giả hoặc Tile
	var door = Sprite2D.new()
	door.texture = load("res://Assets/kenney_micro-roguelike/Tiles/door_1.png")
	door.scale = Vector2(4, 4)
	door.position = Vector2(15 * TILE_SIZE, 16 * TILE_SIZE)
	add_child(door)
	
	# Tạo InteractableZone cho cửa
	var zone = InteractableZone.new()
	zone.position = Vector2(15 * TILE_SIZE, 15 * TILE_SIZE)
	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(32, 32)
	col.shape = rect
	zone.add_child(col)
	zone.interacted.connect(func():
		DialogueManager.show_choice(["[Trở về Nightcord]", "[Ở lại]"])
		var idx = await DialogueManager.choice_made
		if idx == 0:
			await ScreenFade.fade_out(1.0)
			GameManager.last_player_position = Vector2.ZERO
			get_tree().change_scene_to_file("res://Maps/Base/BaseMap.tscn")
	)
	add_child(zone)
	
	# Giường bệnh, tủ thuốc (Dùng asset tạm)
	_place_indoor_asset("green_bed_facing_right.png", Vector2(8, 7), true, true, PI/2)
	_place_indoor_asset("green_bed_facing_right.png", Vector2(10, 7), true, true, PI/2)
	_place_indoor_asset("kitchen_1.png", Vector2(20, 6), true)
	_place_indoor_asset("kitchen_2.png", Vector2(21, 6), true)
	_place_indoor_asset("kitchen_4.png", Vector2(22, 6), true)
	
	# Spawn NPCs
	var honami_pos = Vector2(15, 8)
	MapUtils.create_dummy_char(self, "Honami", honami_pos, Color(0.5, 0.35, 0.25))
	var honami_zone = InteractableZone.new()
	honami_zone.position = honami_pos * TILE_SIZE
	var honami_col = CollisionShape2D.new()
	var honami_rect = RectangleShape2D.new()
	honami_rect.size = Vector2(32, 32)
	honami_col.shape = honami_rect
	honami_zone.add_child(honami_col)
	honami_zone.interacted.connect(func(): _on_npc_interacted("Honami"))
	add_child(honami_zone)
	
	# Spawn Player
	var player = OverworldPlayer.new()
	player.name = "OverworldPlayer"
	
	if GameManager.last_player_position != Vector2.ZERO:
		player.position = GameManager.last_player_position
	else:
		player.position = Vector2(12 * TILE_SIZE, 8 * TILE_SIZE)
	player.character_color = Color(0.29, 0.62, 0.62)
	add_child(player)

func _place_indoor_asset(file: String, grid_pos: Vector2, _has_collision: bool, flip_h: bool = false, rot: float = 0.0):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/Indoors/" + file)
	sprite.scale = Vector2(-4 if flip_h else 4, 4)
	sprite.position = tile_pos
	sprite.rotation = rot
	add_child(sprite)
	
	if _has_collision:
		var body = StaticBody2D.new()
		body.position = tile_pos
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		col.shape = shape
		body.add_child(col)
		add_child(body)

func _run_logic():
	if not GameManager.get_flag("honami_house_intro_done"):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("honami_house_intro"), func():
			GameManager.set_flag("honami_house_intro_done", true)
		)

func _on_npc_interacted(npc_name: String):
	if npc_name == "Honami":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("honami_training_offer"), func():
			_show_training_menu()
		)

func _show_training_menu():
	var opts: Array = ["Ichika (5 Waves)", "Kanade (5 Waves)", "Ena (5 Waves)", "Mizuki (5 Waves)", "Mafuyu (5 Waves)", "Honami (5 Waves)", "Để sau."]
	var mapping = ["Ichika", "Kanade", "Ena", "Mizuki", "Mafuyu", "Honami"]
	
	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	if opts[idx] == "Để sau.": return
	
	GameManager.is_training_mode = true
	GameManager.warehouse_wave = 1
	GameManager.training_participants = [mapping[idx]]
	
	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state("res://Maps/HonamiHouse/HonamiHouseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Maps/Warehouse/TrainingWarehouseMap.tscn")
