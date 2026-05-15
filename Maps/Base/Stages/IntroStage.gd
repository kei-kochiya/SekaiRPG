extends BaseMapStage

func get_npc_positions() -> Dictionary:
	return {
		"Mafuyu": Vector2(10 * map.TILE_SIZE, 14 * map.TILE_SIZE),
		"Kanade": Vector2(24 * map.TILE_SIZE, 15 * map.TILE_SIZE),
		"Ena":    Vector2(28 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mizuki": Vector2(24 * map.TILE_SIZE, 12 * map.TILE_SIZE),
	}

func on_stage_start():
	if not GameManager.safehouse_intro_done:
		GameManager.safehouse_intro_done = true
		DialogueManager.play_dialogue(DialogueLoader.get_lines("safehouse_intro"), func():
			map._refresh_quest_label()
		)

func handle_npc_interaction(npc_name: String):
	if not GameManager.intro_quest_done:
		_quest_phase_interact(npc_name)
	elif not GameManager.warehouse_mission_accepted:
		_mission_briefing_interact(npc_name)
	else:
		_free_roam_interact(npc_name)

func _quest_phase_interact(npc_name: String):
	var key := "safehouse_meet_" + npc_name.to_lower()
	if npc_name not in GameManager.npcs_greeted:
		GameManager.npcs_greeted.append(npc_name)
		DialogueManager.play_dialogue(DialogueLoader.get_lines(key), func():
			map._refresh_quest_label()
			_check_quest_complete()
		)
	else:
		DialogueManager.play_dialogue(DialogueLoader.get_lines(key + "_repeat"))

func _mission_briefing_interact(npc_name: String):
	if npc_name == "Kanade":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("kanade_mission"), func():
			GameManager.warehouse_mission_accepted = true
			map._refresh_quest_label()
		)
	else:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("npc_hello_" + npc_name.to_lower()))

func _free_roam_interact(npc_name: String):
	DialogueManager.play_dialogue(DialogueLoader.get_lines("npc_hello_" + npc_name.to_lower()))

func _check_quest_complete():
	var quests = ["Mafuyu", "Ena", "Kanade", "Mizuki"]
	for n in quests:
		if n not in GameManager.npcs_greeted: return
	GameManager.intro_quest_done = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines("quest_intro_complete"), func():
		map._refresh_quest_label()
	)

func get_quest_text() -> String:
	if not GameManager.intro_quest_done:
		var remaining: Array = []
		var quests = ["Mafuyu", "Ena", "Kanade", "Mizuki"]
		for n in quests:
			if n not in GameManager.npcs_greeted: remaining.append(n)
		return "MỤC TIÊU: Làm quen với mọi người\nCòn lại: " + ", ".join(remaining)
	elif not GameManager.warehouse_mission_accepted:
		return "MỤC TIÊU: Nói chuyện với Kanade để nhận nhiệm vụ"
	else:
		return "MỤC TIÊU: Rời khỏi nhà để bắt đầu nhiệm vụ\n(Có thể nói chuyện thêm với mọi người)"
