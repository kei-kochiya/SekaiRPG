extends BaseMapStage
class_name PostCafeStreetMissionStage

"""
PostCafeStreetMissionStage: Kịch bản sảnh chính sau sự kiện Quán Cafe.
- Mafuyu giao nhiệm vụ thám thính đường phố cho Ichika và Mizuki.
- Ichika có thể tự do luyện tập (Mafuyu) hoặc nâng chỉ số (Kanade).
- Tiến trình tiếp tục khi Ichika nói chuyện với Mizuki và đi ra cửa chính.
"""

# Mafuyu cho luyện tập bốn người này (không ẩn ai đã tập xong)
const TRAINEES := ["Ichika", "Kanade", "Ena", "Mizuki"]

func get_npc_positions() -> Dictionary:
	return {
		"Ena": Vector2(21 * map.TILE_SIZE, 12 * map.TILE_SIZE), # lên một ô để vùng nói chuyện không chồng lên bệ Holo-Sim (20, 15)
		"Kanade": Vector2(23 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mizuki": Vector2(27 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mafuyu": Vector2(25 * map.TILE_SIZE, 12 * map.TILE_SIZE), # lệch khỏi ô cửa phía bắc (24, 10) để không chắn lối vào Khu Nghỉ Ngơi
	}

# Ánh sáng dịu nhẹ buổi chiều; BaseMap áp trước fade_in nên không bị "nháy sáng"
func get_scene_lighting() -> Color:
	return Color(0.95, 0.9, 0.85)

func on_stage_start():
	# Hủy mọi control phase khác, đảm bảo người chơi điều khiển Ichika
	GameManager.set_flag("mizuki_control_phase", false)
	GameManager.set_flag("ena_control_phase", false)
	
	map.set_player("Ichika")
		
	# Nếu chưa bắt đầu nhiệm vụ, tự động chạy cutscene giao nhiệm vụ của Mafuyu
	if not GameManager.get_flag("street_mission_started"):
		_cutscene_active = true
		map.place_player(Vector2(24, 15))
		
		# Đợi màn hình fade-in hoàn tất rồi mới thoại
		await map.get_tree().create_timer(0.5).timeout
		DialogueManager.play_dialogue(DialogueLoader.get_lines("lobby_street_mission_start"), func():
			GameManager.set_flag("street_mission_started", true)
			_cutscene_active = false
			map._refresh_quest_label()
		)

func handle_npc_interaction(npc_name: String):
	if npc_name == "Kanade":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_kanade_post"), func():
			open_upgrade_ui()
		)
	elif npc_name == "Mafuyu":
		DialogueManager.play_dialogue([say("Mafuyu", "Hãy chuẩn bị thật kỹ trước khi xuất phát thám thính.")], func():
			offer_training(TRAINEES)
		)
	elif npc_name == "Ena":
		DialogueManager.play_dialogue([say("Ena", "Hừ... Chị mệt đứt cả hơi sau vụ quán Cafe rồi, hai đứa đi thám thính cẩn thận đấy.")])
	elif npc_name == "Mizuki":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("lobby_street_mission_ready_mizuki"), func():
			GameManager.set_flag("street_mission_ready", true)
			map._refresh_quest_label()
		)

func get_quest_text() -> String:
	if not GameManager.get_flag("street_mission_ready"):
		return "MỤC TIÊU: Nói chuyện với Mizuki để chuẩn bị lên đường thám thính."
	else:
		return "MỤC TIÊU: Rời cửa chính để xuất phát đến Khu Phố Tây."
