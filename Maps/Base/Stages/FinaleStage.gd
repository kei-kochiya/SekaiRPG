extends BaseMapStage
class_name FinaleStage

"""
FinaleStage: "Ghế Thủ Tướng Mới" - sảnh Base ngay sau khi Thủ Tướng chết.
Cảnh tự chạy: Khóa huấn luyện sinh tử -> bài kiểm tra (trận training_trial) -> chào mừng thành viên thứ năm -> ăn mừng và bàn chuyện tân Thủ Tướng (base_celebration) -> Ena bỏ đi giữa chừng
-> dư âm (ena_leaves_aftermath) -> sang BountyMap (Ena là nhân vật chơi được).

Chạy khi: pm_boss_defeated && !finale_done.
Cờ finale_done + ena_left_nightcord chỉ được đặt SAU khi màn hình đã tối, ngay trước khi đổi scene,
nên lưu/tải giữa chừng chỉ khiến cảnh phát lại từ đầu, không bao giờ kẹt ở Base.
"""

const NEXT_SCENE := "res://Maps/Bounty/BountyMap.tscn"
# Ai được luyện tập/nâng cấp trong lúc chuẩn bị lại bài kiểm tra
const PREP_TRAINEES := ["Ichika", "Kanade", "Ena", "Mizuki", "Mafuyu"]

var _cutscene_active: bool = false
# Sau khi thua bài kiểm tra: người chơi được tự do chuẩn bị (luyện tập, nâng cấp) rồi nói chuyện với Mafuyu để làm lại
var _prep_mode: bool = false
var _honami: Node2D = null
# Phần của base_celebration từ tiếng sập cửa trở đi: chỉ phát sau khi Ena đã bước ra tới cửa
var _after_slam: Array = []

func get_npc_positions() -> Dictionary:
	return {
		"Mafuyu": Vector2(24 * map.TILE_SIZE, 12 * map.TILE_SIZE),
		"Kanade": Vector2(26 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mizuki": Vector2(28 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Ena": Vector2(22 * map.TILE_SIZE, 13 * map.TILE_SIZE),
	}

func get_scene_lighting() -> Color:
	return Color(0.9, 0.9, 1.0)

func on_stage_start():
	var player = map.get_node_or_null("OverworldPlayer")
	if player:
		player.character_color = map.NPC_COLORS["Ichika"]
		player.position = Vector2(25 * map.TILE_SIZE, 17 * map.TILE_SIZE)
	
	if GameManager.get_flag("finale_done"):
		return
	
	# Cảnh tự chạy: khoá người chơi cho tới khi sang map khác
	_cutscene_active = true
	map.freeze_player()
	_next_beat()

# Chuỗi cảnh: Khóa huấn luyện sinh tử (chương 10) -> bài kiểm tra ngày thứ bảy (trận) -> chào mừng thành viên thứ năm
# -> buổi ăn mừng. Mỗi cờ chỉ được đặt khi cảnh tương ứng xong, nên tải save giữa chừng chỉ phát lại cảnh đang dở.
func _next_beat():
	if not GameManager.get_flag("training_week_intro_done"):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("training_week_intro"), func():
			DialogueManager.play_dialogue(DialogueLoader.get_lines("training_week_drills"), func():
				GameManager.set_flag("training_week_intro_done", true)
				_start_trial()
			)
		)
	elif not GameManager.get_flag("training_trial_won"):
		if GameManager.get_flag("training_trial_failed"):
			_enter_prep_mode() # về lại sau khi thua: không ép đánh lại ngay, để người chơi chuẩn bị thêm
		else:
			_start_trial()
	elif not GameManager.get_flag("training_welcome_done"):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("training_trial_post"), func():
			DialogueManager.play_dialogue(DialogueLoader.get_lines("training_welcome"), func():
				GameManager.set_flag("training_welcome_done", true)
				_start_celebration()
			)
		)
	else:
		_start_celebration()

func _enter_prep_mode():
	# Lời của Mafuyu chỉ phát ngay sau lần thua; những lần quay lại từ luyện tập thì vào thẳng chế độ chuẩn bị
	var lines: Array = []
	if not GameManager.get_flag("training_trial_prep_seen"):
		lines = DialogueLoader.get_lines("training_trial_retry")
		GameManager.set_flag("training_trial_prep_seen", true)
	DialogueManager.play_dialogue(lines, func():
		_prep_mode = true
		_cutscene_active = false
		map.unfreeze_player()
	)

# Menu của Mafuyu trong lúc chuẩn bị lại: làm lại bài kiểm tra, luyện tập, nâng cấp
func _show_prep_menu():
	DialogueManager.show_choice(["[Bắt đầu bài kiểm tra]", "[Luyện tập]", "[Nâng cấp]", "[Hủy]"])
	var idx: int = await DialogueManager.choice_made
	if idx == 0:
		_cutscene_active = true
		map.freeze_player()
		_start_trial()
	elif idx == 1:
		_show_prep_training_menu()
	elif idx == 2:
		var p_list: Array[Entity] = []
		for member in PREP_TRAINEES:
			if GameManager.is_member_alive_in_story(member):
				p_list.append(GameManager.get_party_member(member))
		UpgradeUI.show_ui(p_list)

func _show_prep_training_menu():
	var members: Array = PREP_TRAINEES.filter(func(m): return GameManager.is_member_alive_in_story(m))
	var opts: Array = []
	for m in members:
		opts.append("%s (5 Waves)" % m)
	opts.append("Để sau.")
	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	if idx >= members.size():
		return
	_cutscene_active = true
	map.freeze_player()
	GameManager.begin_training([members[idx]])
	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state("res://Maps/Warehouse/TrainingWarehouseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Maps/Warehouse/TrainingWarehouseMap.tscn")

func _start_trial():
	# Lần đầu: lời mở đầu bài kiểm tra. Làm lại sau khi chuẩn bị thì vào thẳng trận (Mafuyu đã nói ở lúc thua)
	var lines: Array = []
	if not GameManager.get_flag("training_trial_started"):
		lines = DialogueLoader.get_lines("training_trial_pre")
	GameManager.set_flag("training_trial_started", true)
	GameManager.set_flag("training_trial_prep_seen", false)
	DialogueManager.play_dialogue(lines, func():
		GameManager.is_scripted_battle = true
		GameManager.scripted_battle_id = "training_trial"
		GameManager.store_map_state("res://Maps/Base/BaseMap.tscn", Vector2.ZERO)
		await ScreenFade.fade_out(1.0)
		GameManager.trigger_battle()
	)

func _start_celebration():
	_honami = map.spawn_dummy("Honami", Vector2(28, 17), map.NPC_COLORS["Honami"])
	# Tách base_celebration ở tiếng sập cửa ("RẦM!"): Ena phải đi khuất rồi cửa mới sập, không thì Mafuyu
	# nói "Để cô ta nguội" khi Ena vẫn đứng ngay đó.
	var lines: Array = DialogueLoader.get_lines("base_celebration")
	_after_slam = []
	for i in lines.size():
		if str(lines[i].get("text", "")).begins_with("RẦM!"):
			_after_slam = lines.slice(i)
			lines = lines.slice(0, i)
			break
	DialogueManager.play_dialogue(lines, _on_celebration_done)

func _on_celebration_done():
	# Ena giận dữ bỏ ra cửa, rồi mới tới đoạn dư âm
	var ena = map.get_npc_node("Ena")
	await map.walk_node(ena, [
		Vector2(22, 19) * map.TILE_SIZE,
		Vector2(24, 20) * map.TILE_SIZE,
		Vector2(24, 21) * map.TILE_SIZE,
	], 260.0)
	if ena and is_instance_valid(ena):
		ena.queue_free()

	if _after_slam.is_empty():
		_play_aftermath()
	else:
		DialogueManager.play_dialogue(_after_slam, _play_aftermath)

func _play_aftermath():
	DialogueManager.play_dialogue(DialogueLoader.get_lines("ena_leaves_aftermath"), _on_aftermath_done)

func _on_aftermath_done():
	# Honami rời Base
	await map.walk_node(_honami, [
		Vector2(28, 19) * map.TILE_SIZE,
		Vector2(24, 20) * map.TILE_SIZE,
		Vector2(24, 21) * map.TILE_SIZE,
	])
	if _honami and is_instance_valid(_honami):
		_honami.queue_free()
	
	await ScreenFade.fade_out(1.5)
	GameManager.set_flag("finale_done", true)
	GameManager.set_flag("ena_left_nightcord", true)
	GameManager.store_map_state(NEXT_SCENE, Vector2.ZERO)
	get_tree().change_scene_to_file(NEXT_SCENE)

func handle_npc_interaction(npc_name: String):
	if _cutscene_active or not _prep_mode or npc_name != "Mafuyu":
		return
	_show_prep_menu()

# Cửa ra bị khoá suốt cảnh này (xử lý xong, không làm gì)
func handle_exit() -> bool:
	return true

func get_quest_text() -> String:
	if _prep_mode:
		return "MỤC TIÊU: Chuẩn bị thêm, rồi nói chuyện với Mafuyu để làm lại bài kiểm tra."
	if not GameManager.get_flag("training_welcome_done"):
		return "MỤC TIÊU: Khóa huấn luyện sinh tử. Vượt qua bài kiểm tra ngày thứ bảy."
	return "MỤC TIÊU: Ở lại Nightcord và nghe cuộc trò chuyện về ghế Thủ Tướng mới."
