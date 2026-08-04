extends BaseMapStage
class_name HonamiHouseUnlockedStage

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
	
	if not GameManager.get_flag("honami_unlocked_intro_done"):
		_cutscene_active = true
		if player:
			player.position = Vector2(24 * map.TILE_SIZE, 20 * map.TILE_SIZE)
		
		DialogueManager.play_dialogue([
			{"text": "Cô về rồi à. Có vẻ ả bác sĩ đó không làm khó dễ gì cô nhỉ.", "type": "dialogue", "name": "Mafuyu", "color": Color("#665588")},
			{"text": "Dạ vâng! Chị ấy tốt bụng lắm, còn chỉ cho em mấy chiêu phòng thân nữa!", "type": "dialogue", "name": "Ichika", "color": Color("#4a9e9e")},
			{"text": "Cô ta... tốt bụng? Chắc là chỉ đối với những người ngây ngô như cô thôi.", "type": "dialogue", "name": "Mafuyu", "color": Color("#665588")},
			{"text": "Thôi bỏ đi. Từ giờ cô được phép tự do đi lại giữa hai bên.", "type": "dialogue", "name": "Mafuyu", "color": Color("#665588")}
		], func():
			GameManager.set_flag("honami_unlocked_intro_done", true)
			_cutscene_active = false
			map._refresh_quest_label()
		)

func handle_npc_interaction(npc_name: String):
	if _cutscene_active: return
	
	if npc_name == "Mafuyu":
		if not GameManager.get_flag("pm_arc_started"):
			DialogueManager.play_dialogue([{"text": "Cô tìm được thông tin gì rồi?", "type": "dialogue", "name": "Mafuyu", "color": Color("#665588")}], func():
				_show_mafuyu_menu()
			)
		else:
			DialogueManager.play_dialogue([{"text": "Đừng để ả lôi kéo cô quá đà.", "type": "dialogue", "name": "Mafuyu", "color": Color("#665588")}], func():
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
		DialogueManager.play_dialogue([{"text": "Bác sĩ gì mà tay vịn cứng như thép... Đau điếng cả người.", "type": "dialogue", "name": "Ena", "color": Color("#b86028")}])
	elif npc_name == "Mizuki":
		DialogueManager.play_dialogue([{"text": "Bà bác sĩ đó cũng bảnh đấy chứ, ha ha!", "type": "dialogue", "name": "Mizuki", "color": Color("#d8a4cc")}])

func _show_mafuyu_menu():
	DialogueManager.show_choice(["[Báo cáo Intel]", "[Tập luyện]", "[Hủy]"])
	var idx: int = await DialogueManager.choice_made
	if idx == 0:
		_start_finale_arc()
	elif idx == 1:
		_show_training_menu()

func _start_finale_arc():
	GameManager.set_flag("pm_arc_started", true)
	DialogueManager.play_dialogue(DialogueLoader.get_lines("pm_plot_reveal"), func():
		await ScreenFade.fade_out(1.0)
		GameManager.store_map_state("res://Maps/CityOperations/CityOperationsMap.tscn", Vector2.ZERO)
		get_tree().change_scene_to_file("res://Maps/CityOperations/CityOperationsMap.tscn")
	)

func _show_training_menu():
	var opts: Array = ["Ichika (5 Waves)", "Kanade (5 Waves)", "Ena (5 Waves)", "Mizuki (5 Waves)", "Mafuyu (5 Waves)", "Để sau."]
	var mapping = ["Ichika", "Kanade", "Ena", "Mizuki", "Mafuyu"]
	
	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	if opts[idx] == "Để sau.": return
	
	GameManager.is_training_mode = true
	GameManager.warehouse_wave = 1
	GameManager.training_participants = [mapping[idx]]
	
	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state("res://Maps/Warehouse/TrainingWarehouseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Maps/Warehouse/TrainingWarehouseMap.tscn")

func get_quest_text() -> String:
	return "MỤC TIÊU: Bạn đã được phép đi lại tự do. Luyện tập qua lại giữa Nightcord và nhà Honami."
