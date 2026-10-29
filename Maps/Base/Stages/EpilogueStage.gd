extends BaseMapStage

"""
EpilogueStage: "Dạ Khúc Mới" - Base sau cái kết. Ichika là người chơi, Honami là NPC duy nhất;
không còn ai trong Nightcord cũ. Luyện tập và nâng cấp thông qua Honami, không giới hạn.
Cửa hàng và máy Holo-Sim (do BaseMap dựng) vẫn dùng được.

Chạy khi: game_completed. Đoạn mở đầu (epilogue_base_intro) phát một lần, đánh dấu bằng epilogue_intro_done.
"""

# Chỉ những người này còn đồng hành với Ichika ở giai đoạn này
const TRAINEES := ["Ichika", "Honami"]

var _cutscene_active: bool = false
var _talked_this_visit: bool = false

func get_npc_positions() -> Dictionary:
	return {
		"Honami": Vector2(25 * map.TILE_SIZE, 14 * map.TILE_SIZE),
	}

# Ấm hơn một chút so với các cảnh trước
func get_scene_lighting() -> Color:
	return Color(1.0, 0.96, 0.9)

func get_bgm_track() -> String:
	return "base"

func on_stage_start():
	GameManager.set_flag("mizuki_control_phase", false)
	GameManager.set_flag("ena_control_phase", false)

	var player = map.get_node_or_null("OverworldPlayer")
	if player:
		player.character_color = map.NPC_COLORS["Ichika"]

	if not GameManager.get_flag("epilogue_intro_done"):
		_cutscene_active = true
		if player:
			player.position = Vector2(24 * map.TILE_SIZE, 18 * map.TILE_SIZE)
		DialogueManager.play_dialogue(DialogueLoader.get_lines("epilogue_base_intro"), func():
			GameManager.set_flag("epilogue_intro_done", true)
			_cutscene_active = false
		)

func handle_npc_interaction(npc_name: String):
	if _cutscene_active or npc_name != "Honami": return

	# Lần nói chuyện đầu trong lượt ghé Base là đoạn chính, các lần sau chỉ là lời hỏi han ngắn
	var key := "epilogue_honami_idle" if _talked_this_visit else "epilogue_honami_talk"
	_talked_this_visit = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines(key), func():
		_show_honami_menu()
	)

func _show_honami_menu():
	DialogueManager.show_choice(["[Luyện tập]", "[Nâng cấp]", "[Hủy]"])
	var idx: int = await DialogueManager.choice_made
	if idx == 0:
		_show_training_menu()
	elif idx == 1:
		_open_upgrade()

func _open_upgrade():
	var p_list: Array[Entity] = []
	for member in TRAINEES:
		if GameManager.is_member_alive_in_story(member):
			p_list.append(GameManager.get_party_member(member))
	UpgradeUI.show_ui(p_list)

# Luyện tập không giới hạn: chọn Ichika, Honami hoặc cả hai (cả hai = 10 wave). Không đặt cờ training_*_done.
func _show_training_menu():
	var members: Array = []
	for member in TRAINEES:
		if GameManager.is_member_alive_in_story(member):
			members.append(member)

	var opts: Array = []
	var groups: Array = []
	for member in members:
		opts.append("%s (5 Waves)" % member)
		groups.append([member])
	if members.size() > 1:
		opts.append("Cả hai (10 Waves)")
		groups.append(members.duplicate())
	opts.append("Để sau.")

	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	if idx >= groups.size(): return

	_cutscene_active = true # chặn tương tác lặp trong lúc chuyển cảnh
	map.freeze_player()
	GameManager.begin_training(groups[idx])

	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state("res://Maps/Warehouse/TrainingWarehouseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Maps/Warehouse/TrainingWarehouseMap.tscn")

# Không còn nơi nào để đi tối nay: chỉ một dòng dẫn truyện, không đổi map
func handle_exit() -> bool:
	if _cutscene_active:
		return true
	DialogueManager.play_dialogue([{
		"text": "Ngoài kia đêm nay không còn gì đang chờ cô. Nightcord mới chỉ vừa bắt đầu, hãy ở lại đây.",
		"type": "narrator"
	}])
	return true

func get_quest_text() -> String:
	return "MỤC TIÊU: Nightcord mới. Luyện tập cùng Honami."
