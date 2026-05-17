extends BaseMapStage
class_name PostCafeStreetMissionStage

"""
PostCafeStreetMissionStage: Kịch bản sảnh chính sau sự kiện Quán Cafe.
- Mafuyu giao nhiệm vụ thám thính đường phố cho Ichika và Mizuki.
- Ichika có thể tự do luyện tập (Mafuyu) hoặc nâng chỉ số (Kanade).
- Tiến trình tiếp tục khi Ichika nói chuyện với Mizuki và đi ra cửa chính.
"""

var _cutscene_active: bool = false

func get_npc_positions() -> Dictionary:
	return {
		"Ena": Vector2(21 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Kanade": Vector2(23 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mizuki": Vector2(27 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mafuyu": Vector2(24 * map.TILE_SIZE, 11 * map.TILE_SIZE),
	}

func on_stage_start():
	# Hủy mọi control phase khác, đảm bảo người chơi điều khiển Ichika
	GameManager.set_flag("mizuki_control_phase", false)
	GameManager.set_flag("ena_control_phase", false)
	
	var player = map.get_node_or_null("OverworldPlayer")
	if player:
		player.character_color = map.NPC_COLORS["Ichika"]
		player.queue_redraw()
		
	# Bật ánh sáng dịu nhẹ buổi chiều
	var lighting = CanvasModulate.new()
	map.add_child(lighting)
	lighting.color = Color(0.95, 0.9, 0.85)
	
	# Nếu chưa bắt đầu nhiệm vụ, tự động chạy cutscene giao nhiệm vụ của Mafuyu
	if not GameManager.get_flag("street_mission_started"):
		_cutscene_active = true
		if player:
			player.position = Vector2(24 * map.TILE_SIZE, 15 * map.TILE_SIZE)
		
		# Đợi màn hình fade-in hoàn tất rồi mới thoại
		await map.get_tree().create_timer(0.5).timeout
		DialogueManager.play_dialogue(DialogueLoader.get_lines("lobby_street_mission_start"), func():
			GameManager.set_flag("street_mission_started", true)
			_cutscene_active = false
			map._refresh_quest_label()
		)

func handle_npc_interaction(npc_name: String):
	if _cutscene_active: return
	
	if npc_name == "Kanade":
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
	elif npc_name == "Mafuyu":
		DialogueManager.play_dialogue([{"text": "Hãy chuẩn bị thật kỹ trước khi xuất phát thám thính.", "type": "dialogue", "name": "Mafuyu", "color": Color("#665588")}], func():
			_show_training_menu()
		)
	elif npc_name == "Ena":
		DialogueManager.play_dialogue([{"text": "Hừ... Chị mệt đứt cả hơi sau vụ quán Cafe rồi, hai đứa đi thám thính cẩn thận đấy.", "type": "dialogue", "name": "Ena", "color": Color("#b86028")}])
	elif npc_name == "Mizuki":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("lobby_street_mission_ready_mizuki"), func():
			GameManager.set_flag("street_mission_ready", true)
			map._refresh_quest_label()
		)

func _show_training_menu():
	var opts: Array = ["Ichika (5 Waves)", "Kanade (5 Waves)", "Ena (5 Waves)", "Mizuki (5 Waves)", "Để sau."]
	var mapping = ["Ichika", "Kanade", "Ena", "Mizuki"]
	
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
	if not GameManager.get_flag("street_mission_ready"):
		return "MỤC TIÊU: Nói chuyện với Mizuki để chuẩn bị lên đường thám thính."
	else:
		return "MỤC TIÊU: Rời cửa chính để xuất phát đến Khu Phố Tây."
