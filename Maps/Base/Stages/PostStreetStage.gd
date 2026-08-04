extends BaseMapStage
class_name PostStreetStage

var _cutscene_active = false

func get_npc_positions() -> Dictionary:
	return {
		"Ena": Vector2(17 * map.TILE_SIZE, 11 * map.TILE_SIZE),
		"Kanade": Vector2(23 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mizuki": Vector2(19 * map.TILE_SIZE, 12 * map.TILE_SIZE),
		"Mafuyu": Vector2(24 * map.TILE_SIZE, 11 * map.TILE_SIZE),
	}

func on_stage_start():
	var player = map.get_node_or_null("OverworldPlayer")
	if player:
		player.character_color = map.NPC_COLORS["Ichika"]
		player.queue_redraw()
		
	var lighting = CanvasModulate.new()
	map.add_child(lighting)
	lighting.color = Color(0.9, 0.9, 1.0)
	
	if GameManager.get_flag("post_street_trained_once"):
		_cutscene_active = true
		_play_honami_invasion()

func handle_npc_interaction(npc_name: String):
	if _cutscene_active: return
	
	if npc_name == "Mafuyu":
		DialogueManager.play_dialogue([{"text": "Cô cần gì? Muốn tập luyện thêm à?", "type": "dialogue", "name": "Mafuyu", "color": Color("#665588")}], func():
			_show_training_menu()
		)
	elif npc_name == "Kanade":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_kanade_post"), func():
			var p_list: Array[Entity] = [
				GameManager.get_party_member("Ichika"),
				GameManager.get_party_member("Kanade"),
				GameManager.get_party_member("Mafuyu"),
				GameManager.get_party_member("Ena"),
				GameManager.get_party_member("Mizuki")
			]
			UpgradeUI.show_ui(p_list)
		)
	elif npc_name == "Ena":
		DialogueManager.play_dialogue([{"text": "Chị còn đau lưng lắm, đừng rủ chị tập luyện.", "type": "dialogue", "name": "Ena", "color": Color("#b86028")}])
	elif npc_name == "Mizuki":
		DialogueManager.play_dialogue([{"text": "Mới đi dạo có chút xíu mà mệt muốn đứt hơi. Tội nghiệp Mafuyu phải cõng tôi về.", "type": "dialogue", "name": "Mizuki", "color": Color("#d8a4cc")}])

func _show_training_menu():
	var opts: Array = ["Ichika (5 Waves)", "Kanade (5 Waves)", "Ena (5 Waves)", "Mizuki (5 Waves)", "Mafuyu (5 Waves)", "Để sau."]
	var mapping = ["Ichika", "Kanade", "Ena", "Mizuki", "Mafuyu"]
	
	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	if opts[idx] == "Để sau.": return
	
	GameManager.set_flag("post_street_trained_once", true)
	
	GameManager.is_training_mode = true
	GameManager.warehouse_wave = 1
	GameManager.training_participants = [mapping[idx]]
	
	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state("res://Maps/Warehouse/TrainingWarehouseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Maps/Warehouse/TrainingWarehouseMap.tscn")

func _play_honami_invasion():
	# Phát âm thanh báo động
	AudioManager.play_sound("res://Assets/Audio/SFX/alert.wav") # Giả định có âm thanh này hoặc sẽ bỏ qua nếu không có
	
	# Spawn Honami ở cửa chính
	MapUtils.create_dummy_char(map, "Honami", Vector2(24, 21), Color(0.5, 0.35, 0.25))
	
	DialogueManager.play_dialogue(DialogueLoader.get_lines("base_honami_invasion"), func():
		GameManager.set_flag("honami_house_unlocked", true)
		GameManager.set_flag("post_street_trained_once", false) # Reset flag for safety
		
		# Đưa người chơi sang nhà Honami
		await ScreenFade.fade_out(1.5)
		GameManager.last_player_position = Vector2.ZERO
		get_tree().change_scene_to_file("res://Maps/HonamiHouse/HonamiHouseMap.tscn")
	)

func get_quest_text() -> String:
	return "MỤC TIÊU: Nói chuyện với Mafuyu để luyện tập (Unlock: Mafuyu, Mizuki)."
