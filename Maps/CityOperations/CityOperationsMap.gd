extends Node2D

func _ready():
	AudioManager.play_music("battle")
	
	MapUtils.add_backdrop(self, Color(0.1, 0.1, 0.1))
	
	MapUtils.add_fixed_camera(self)
	
	await ScreenFade.fade_in(1.0)
	_run_logic()

func _run_logic():
	if not GameManager.get_flag("ops_kanade_done"):
		_setup_scene("Kanade", Color(0.2, 0.2, 0.25))
		_briefing_then_battle("ops_kanade")
	elif not GameManager.get_flag("ops_ena_done"):
		# Khu D: Ena hộ tống đoàn xe chở bom trên cầu gần Vịnh Tokyo (chương 9); lời dẫn phát một lần
		_setup_scene("Ena", Color(0.12, 0.14, 0.24))
		if GameManager.get_flag("ops_ena_intro_done"):
			_start_battle_after_pause("ops_ena")
		else:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("ops_ena_pre"), func():
				GameManager.set_flag("ops_ena_intro_done", true)
				_start_battle("ops_ena")
			)
	elif not GameManager.get_flag("ops_ena_post_done"):
		GameManager.set_flag("ops_ena_post_done", true)
		_setup_scene("Ena", Color(0.12, 0.14, 0.24))
		DialogueManager.play_dialogue(DialogueLoader.get_lines("ops_ena_post"), func():
			# Nạp lại map (có fade) để _setup_scene của khu kế tiếp chạy trên map trống (xem ghi chú ở _setup_scene)
			await GameManager.change_map(MapPaths.CITY_OPS, 1.0)
		)
	elif not GameManager.get_flag("ops_ichika_done"):
		_setup_scene("Ichika", Color(0.15, 0.2, 0.2))
		_briefing_then_battle("ops_ichika")
	elif not GameManager.get_flag("ops_honami_done"):
		_setup_scene("Honami", Color(0.1, 0.15, 0.25))
		_briefing_then_battle("ops_honami")
	else:
		# All done, transition to Highway Map
		await GameManager.change_map(MapPaths.HIGHWAY, 1.0)

func _start_battle_after_pause(battle_key: String):
	await get_tree().create_timer(1.0, false).timeout
	_start_battle(battle_key)

# ops_intro chỉ phát một lần (lần đầu vào map); các trận sau và khi đánh lại sau khi thua thì vào thẳng trận sau một nhịp chờ
func _briefing_then_battle(battle_key: String):
	if GameManager.get_flag("ops_intro_done"):
		_start_battle_after_pause(battle_key)
		return
	DialogueManager.play_dialogue(DialogueLoader.get_lines("ops_intro"), func():
		GameManager.set_flag("ops_intro_done", true)
		_start_battle(battle_key)
	)

# Mỗi trận kết thúc sẽ nạp lại cả map nên _setup_scene luôn chạy trên map trống, không cần dọn node cũ
func _setup_scene(char_name: String, light_color: Color):
	var lighting = CanvasModulate.new()
	lighting.color = light_color
	add_child(lighting)
	
	# Spawn character
	MapUtils.create_dummy_char(self, char_name, Vector2(12, 10), Color(0.8, 0.8, 0.8))
	# Spawn terrorists
	MapUtils.create_dummy_char(self, "Khủng Bố 1", Vector2(18, 9), Color(1, 0, 0))
	MapUtils.create_dummy_char(self, "Khủng Bố 2", Vector2(18, 11), Color(1, 0, 0))

func _start_battle(battle_key: String):
	GameManager.start_scripted_battle(battle_key, MapPaths.CITY_OPS, Vector2.ZERO, 1.0)
