extends Node2D

const TILE_SIZE = 32

func _ready():
	AudioManager.play_music("battle")
	
	MapUtils.add_backdrop(self, Color(0.05, 0.05, 0.05))
	
	_build_highway()
	
	MapUtils.add_fixed_camera(self)
	
	var lighting = CanvasModulate.new()
	lighting.color = Color(0.5, 0.5, 0.6)
	add_child(lighting)
	
	await ScreenFade.fade_in(1.0)
	_run_logic()

func _build_highway():
	# Vẽ đường cao tốc
	MapUtils.fill_floor(self, 0, 8, 29, 13)
	
	# Spawn Xe (ghép 2 nửa sprite xe đỏ từ bộ Roads)
	MapUtils.place_road_asset(self, "Red_Car_Facing_Left_1.png", Vector2(15, 11))
	MapUtils.place_road_asset(self, "Red_Car_Facing_Left_2.png", Vector2(16, 11))
	
	# Spawn NPCs
	MapUtils.create_dummy_char(self, "Mizuki", Vector2(14, 11), Color(0.8, 0.5, 0.8))
	MapUtils.create_dummy_char(self, "Mafuyu", Vector2(15, 10), Color(0.4, 0.3, 0.5))
	MapUtils.create_dummy_char(self, "Thủ Tướng", Vector2(15, 12), Color(0.2, 0.2, 0.2))
	MapUtils.create_dummy_char(self, "Ena", Vector2(20, 11), Color(0.7, 0.3, 0.1))

func _run_logic():
	if GameManager.get_flag("pm_boss_defeated"):
		# Đã thắng boss: chỉ phát hậu cảnh khi đã thắng thật sự (không phát sau khi thua)
		if not GameManager.get_flag("finale_done"):
			DialogueManager.play_dialogue(DialogueLoader.get_lines("pm_boss_aftermath"), func():
				# Transition to BaseMap for celebration
				await GameManager.change_map(MapPaths.BASE, 1.0)
			)
	elif not GameManager.get_flag("pm_car_scene_done"):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("pm_car_ride"), func():
			GameManager.set_flag("pm_car_scene_done", true)
			_start_boss_battle()
		)
	else:
		# Đã thua trận trước đó (pm_boss_defeated vẫn false): đánh lại cho tới khi thắng
		DialogueManager.play_dialogue([{
			"text": "Thủ Tướng vẫn chưa gục ngã. Cả đội gượng dậy, chuẩn bị tái đấu!",
			"type": "narrator"
		}], func():
			_start_boss_battle()
		)

func _start_boss_battle():
	GameManager.start_scripted_battle("pm_boss", MapPaths.HIGHWAY, Vector2.ZERO, 1.0)
