extends Node2D

const TILE_SIZE = 32

func _ready():
	AudioManager.play_music("battle")
	
	var bg = ColorRect.new()
	bg.size = Vector2(2000, 2000)
	bg.color = Color(0.05, 0.05, 0.05)
	add_child(bg)
	
	_build_highway()
	
	var cam = Camera2D.new()
	cam.position = Vector2(15 * TILE_SIZE, 10 * TILE_SIZE)
	cam.zoom = Vector2(1.5, 1.5)
	add_child(cam)
	
	var lighting = CanvasModulate.new()
	lighting.color = Color(0.5, 0.5, 0.6)
	add_child(lighting)
	
	await ScreenFade.fade_in(1.0)
	_run_logic()

func _build_highway():
	# Vẽ đường cao tốc
	for x in range(0, 30):
		for y in range(8, 14):
			MapUtils.place_tile(self, "floor.png", Vector2(x, y))
	
	# Spawn Xe (dùng sprite giả)
	var car = Sprite2D.new()
	car.texture = load("res://Assets/kenney_micro-roguelike/Tiles/tree_1.png") # Tạm dùng asset gì đó
	car.scale = Vector2(4, 4)
	car.position = Vector2(15 * TILE_SIZE, 11 * TILE_SIZE)
	add_child(car)
	
	# Spawn NPCs
	MapUtils.create_dummy_char(self, "Mizuki", Vector2(14, 11), Color(0.8, 0.5, 0.8))
	MapUtils.create_dummy_char(self, "Mafuyu", Vector2(15, 10), Color(0.4, 0.3, 0.5))
	MapUtils.create_dummy_char(self, "PrimeMinister", Vector2(15, 12), Color(0.2, 0.2, 0.2))
	MapUtils.create_dummy_char(self, "Ena", Vector2(20, 11), Color(0.7, 0.3, 0.1))

func _run_logic():
	if not GameManager.get_flag("pm_car_scene_done"):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("pm_car_ride"), func():
			GameManager.set_flag("pm_car_scene_done", true)
			# Start Boss Battle
			GameManager.is_scripted_battle = true
			GameManager.scripted_battle_id = "pm_boss"
			GameManager.last_player_position = Vector2.ZERO
			GameManager.store_map_state("res://Maps/Highway/HighwayMap.tscn", Vector2.ZERO)
			await ScreenFade.fade_out(1.0)
			GameManager.trigger_battle()
		)
	elif not GameManager.get_flag("finale_done"):
		# Đã thắng boss
		DialogueManager.play_dialogue(DialogueLoader.get_lines("pm_boss_aftermath"), func():
			# Transition to BaseMap for celebration
			await ScreenFade.fade_out(1.0)
			GameManager.store_map_state("res://Maps/Base/BaseMap.tscn", Vector2.ZERO)
			get_tree().change_scene_to_file("res://Maps/Base/BaseMap.tscn")
		)
