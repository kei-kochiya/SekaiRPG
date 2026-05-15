extends BaseMapStage

func get_npc_positions() -> Dictionary:
	return {
		"Mafuyu": Vector2(10 * map.TILE_SIZE, 14 * map.TILE_SIZE),
		"Ena":    Vector2(35 * map.TILE_SIZE, 15 * map.TILE_SIZE),
		"Mizuki": Vector2(39 * map.TILE_SIZE, 15 * map.TILE_SIZE),
		"Kanade": Vector2(24 * map.TILE_SIZE, 15 * map.TILE_SIZE),
	}

func on_stage_start():
	if not GameManager.harbor_mission_unlocked:
		# Hiệu ứng buổi đêm "Thơ"
		var lighting = CanvasModulate.new()
		map.add_child(lighting)
		lighting.color = Color(0.15, 0.15, 0.35) # Xanh tím Indigo sâu
		
		# Thêm đom đóm
		var fx = EnvironmentEffects.create_fireflies(map)
		
		DialogueManager.play_dialogue(DialogueLoader.get_lines("post_warehouse_rest"), func():
			# Transition to morning
			_do_morning_transition(lighting, fx)
		)

func _do_morning_transition(lighting: CanvasModulate, fx: Node):
	await ScreenFade.fade_out(1.0)
	await map.get_tree().create_timer(1.0).timeout
	
	if fx: fx.queue_free()
	lighting.color = Color(1.0, 1.0, 1.0) # Trời sáng
	GameManager.harbor_mission_unlocked = true
	
	await ScreenFade.fade_in(1.0)
	DialogueManager.play_dialogue(DialogueLoader.get_lines("post_warehouse_morning"), func():
		DialogueManager.play_dialogue(DialogueLoader.get_lines("kanade_upgrade_intro"), func():
			map._refresh_quest_label()
			lighting.queue_free() # Xóa lighting sau khi xong transition
		)
	)

func handle_npc_interaction(npc_name: String):
	if npc_name == "Kanade":
		_show_upgrade_ui()
	elif npc_name == "Mafuyu":
		_handle_training_dialogue()
	elif npc_name == "Ena":
		_handle_harbor_mission()
	else:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("npc_hello_" + npc_name.to_lower()))

func _show_upgrade_ui():
	var p_list: Array[Entity] = [
		GameManager.get_party_member("Ichika"),
		GameManager.get_party_member("Kanade"),
		GameManager.get_party_member("Mafuyu"),
		GameManager.get_party_member("Ena"),
		GameManager.get_party_member("Mizuki")
	]
	UpgradeUI.show_ui(p_list)

func _handle_training_dialogue():
	if not GameManager.talked_to_mafuyu_training:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("mafuyu_training_intro"), func():
			GameManager.talked_to_mafuyu_training = true
			map._refresh_quest_label()
			_show_training_options()
		)
	else:
		_show_training_options()

func _show_training_options():
	var opts: Array = []
	if not GameManager.get_flag("training_ichika_done"): opts.append("Ichika (5 Waves)")
	if not GameManager.get_flag("training_kanade_done"): opts.append("Kanade (5 Waves)")
	opts.append("Để sau.")
	
	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	if opts[idx] == "Để sau.": return
	
	GameManager.is_training_mode = true
	GameManager.warehouse_wave = 1
	GameManager.training_participants = ["Ichika"] if idx == 0 else ["Kanade"]
	
	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state("res://Maps/Warehouse/TrainingWarehouseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Maps/Warehouse/TrainingWarehouseMap.tscn")

func _handle_harbor_mission():
	if not GameManager.accepted_harbor_mission:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_mission_assignment"), func():
			GameManager.accepted_harbor_mission = true
			map._refresh_quest_label()
		)
	else:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("npc_hello_ena"))

func get_quest_text() -> String:
	var tasks: Array = []
	if not GameManager.talked_to_mafuyu_training:
		tasks.append("- Nói chuyện với Mafuyu về chuyện luyện tập.")
	if not GameManager.accepted_harbor_mission:
		tasks.append("- Gặp Ena để nhận nhiệm vụ tiếp theo.")
	
	if tasks.is_empty():
		return "MỤC TIÊU: Rời khỏi nhà để đến bến cảng.\n(Có thể luyện tập thêm tại Mafuyu)"
	else:
		return "MỤC TIÊU:\n" + "\n".join(tasks)
