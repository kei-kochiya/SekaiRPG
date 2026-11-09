extends BaseMapStage

func get_npc_positions() -> Dictionary:
	var pos = {
		"Mafuyu": Vector2(24 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Ena": Vector2(27 * map.TILE_SIZE, 15 * map.TILE_SIZE),
		"Kanade": Vector2(6 * map.TILE_SIZE, 4 * map.TILE_SIZE),
	}
	
	if GameManager.get_flag("mizuki_control_phase"):
		pos["Ichika"] = Vector2(21 * map.TILE_SIZE, 15 * map.TILE_SIZE)
	else:
		pos["Mizuki"] = Vector2(35 * map.TILE_SIZE, 13 * map.TILE_SIZE)
		
	return pos

func get_bgm_track() -> String:
	return "night"

# Ánh sáng buổi chiều ấm áp (cam vàng); BaseMap áp trước fade_in nên không bị "nháy sáng"
func get_scene_lighting() -> Color:
	return Color(0.8, 0.6, 0.4)

func on_stage_start():
	if GameManager.get_flag("mizuki_vs_mafuyu_done") and not GameManager.get_flag("mizuki_report_done"):
		map.set_player("Mizuki")
		
		DialogueManager.play_dialogue(DialogueLoader.get_lines("base_mizuki_report_p2"), func():
			GameManager.set_flag("mizuki_report_done", true)
			await GameManager.change_map(MapPaths.BASE, 1.5)
		)
		return
	
	if GameManager.story.harbor_wave <= 5:
		if not GameManager.get_flag("harbor_meeting_p1_done"):
			DialogueManager.play_dialogue(DialogueLoader.get_lines("base_meeting_p1"), func():
				GameManager.set_flag("harbor_meeting_p1_done", true)
				map._refresh_quest_label()
			)
	elif GameManager.story.harbor_wave >= 6 and not GameManager.get_flag("harbor_mizuki_snack_done"):
		_play_mizuki_snack_sequence()

func _play_mizuki_snack_sequence():
	DialogueManager.play_dialogue(DialogueLoader.get_lines("base_mizuki_snack_p1"), func():
		# Đánh dấu đã xem để vào lại căn cứ (tải save, đi Holo-Sim...) không phát lại cảnh này
		GameManager.set_flag("harbor_mizuki_snack_done", true)
		GameManager.set_flag("mizuki_control_phase", true)
		map.set_player("Mizuki")
		map.place_player(Vector2(35, 13))
		map._spawn_npcs() 
		map._refresh_quest_label()
	)

func handle_npc_interaction(npc_name: String):
	if GameManager.get_flag("mizuki_control_phase"):
		_handle_mizuki_interactions(npc_name)
	else:
		_handle_normal_interactions(npc_name)

func _handle_mizuki_interactions(npc_name: String):
	if npc_name == "Ichika":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("mizuki_trash_talk_ichika"))
	elif npc_name == "Ena":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("mizuki_trash_talk_ena"))
	elif npc_name == "Mafuyu":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("base_mizuki_report_p1"), func():
			GameManager.start_scripted_battle("mizuki_vs_mafuyu", MapPaths.BASE)
		)

func _handle_normal_interactions(npc_name: String):
	if npc_name == "Mafuyu" and not GameManager.get_flag("mafuyu_honami_talked"):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("mafuyu_honami_info"), func():
			GameManager.set_flag("mafuyu_honami_talked", true)
			GameManager.story.harbor_wave = 6
			await GameManager.change_map(MapPaths.ALLEYWAY, 1.5)
		)
	else:
		DialogueManager.play_dialogue([{"text": "...", "type": "dialogue", "name": npc_name, "color": Color.WHITE}])

func get_quest_text() -> String:
	if GameManager.get_flag("mizuki_control_phase"):
		return "MỤC TIÊU: Báo cáo tình hình cho Mafuyu"
	elif not GameManager.get_flag("mafuyu_honami_talked"):
		return "MỤC TIÊU: Nói chuyện với Mafuyu về Honami"
	else:
		return "MỤC TIÊU: Nghỉ ngơi sau nhiệm vụ"
