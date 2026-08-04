extends Node2D

const TILE_SIZE = 32

func _ready():
	AudioManager.play_music("battle")
	
	var bg = ColorRect.new()
	bg.size = Vector2(2000, 2000)
	bg.color = Color(0.1, 0.1, 0.1)
	add_child(bg)
	
	var cam = Camera2D.new()
	cam.position = Vector2(15 * TILE_SIZE, 10 * TILE_SIZE)
	cam.zoom = Vector2(1.5, 1.5)
	add_child(cam)
	
	await ScreenFade.fade_in(1.0)
	_run_logic()

func _run_logic():
	if not GameManager.get_flag("ops_kanade_done"):
		_setup_scene("Kanade", "Hẻm tối", Color(0.2, 0.2, 0.25))
		DialogueManager.play_dialogue(DialogueLoader.get_lines("defense_agency_ops")["ops_kanade_intro"], func():
			_start_battle("ops_kanade")
		)
	elif not GameManager.get_flag("ops_ichika_done"):
		_setup_scene("Ichika", "Đường phố", Color(0.15, 0.2, 0.2))
		DialogueManager.play_dialogue(DialogueLoader.get_lines("defense_agency_ops")["ops_ichika_intro"], func():
			_start_battle("ops_ichika")
		)
	elif not GameManager.get_flag("ops_honami_done"):
		_setup_scene("Honami", "Bến cảng", Color(0.1, 0.15, 0.25))
		DialogueManager.play_dialogue(DialogueLoader.get_lines("defense_agency_ops")["ops_honami_intro"], func():
			_start_battle("ops_honami")
		)
	else:
		# All done, transition to Highway Map
		await ScreenFade.fade_out(1.0)
		GameManager.store_map_state("res://Maps/Highway/HighwayMap.tscn", Vector2.ZERO)
		get_tree().change_scene_to_file("res://Maps/Highway/HighwayMap.tscn")

func _setup_scene(char_name: String, _location: String, light_color: Color):
	for child in get_children():
		if child.has_meta("is_npc") or child is CanvasModulate or child is StaticBody2D:
			child.queue_free()
			
	var lighting = CanvasModulate.new()
	lighting.color = light_color
	add_child(lighting)
	
	# Spawn character
	MapUtils.create_dummy_char(self, char_name, Vector2(12, 10), Color(0.8, 0.8, 0.8))
	# Spawn terrorists
	MapUtils.create_dummy_char(self, "Terrorist1", Vector2(18, 9), Color(1, 0, 0))
	MapUtils.create_dummy_char(self, "Terrorist2", Vector2(18, 11), Color(1, 0, 0))

func _start_battle(battle_key: String):
	GameManager.is_scripted_battle = true
	GameManager.scripted_battle_id = battle_key
	GameManager.last_player_position = Vector2.ZERO
	GameManager.store_map_state("res://Maps/CityOperations/CityOperationsMap.tscn", Vector2.ZERO)
	
	await ScreenFade.fade_out(1.0)
	get_tree().change_scene_to_file("res://Main.tscn")
