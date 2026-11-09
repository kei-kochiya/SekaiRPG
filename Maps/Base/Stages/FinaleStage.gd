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

const NEXT_SCENE := MapPaths.BOUNTY
# Ai được luyện tập/nâng cấp trong lúc chuẩn bị lại bài kiểm tra: cả đội chính
const PREP_TRAINEES := MAIN_TEAM

# Sau khi thua bài kiểm tra: người chơi được tự do chuẩn bị (luyện tập, nâng cấp) rồi nói chuyện với Mafuyu để làm lại
var _prep_mode: bool = false
var _honami: Node2D = null
# Phần của base_celebration từ tiếng sập cửa trở đi: chỉ phát sau khi Ena đã bước ra tới cửa
var _after_slam: Array = []

# Cửa ra bị khoá suốt cảnh này, kể cả lúc chuẩn bị lại
func _init():
	exit_locked = true

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
	map.set_player("Ichika")
	map.place_player(Vector2(25, 17))
	
	# Cảnh tự chạy: khoá người chơi cho tới khi sang map khác
	lock_scene()
	_next_beat()

# Chuỗi cảnh: Khóa huấn luyện sinh tử (chương 10) -> bài kiểm tra ngày thứ bảy (trận) -> chào mừng thành viên thứ năm
# -> buổi ăn mừng. Mỗi cờ chỉ được đặt khi cảnh tương ứng xong, nên tải save giữa chừng chỉ phát lại cảnh đang dở.
func _next_beat():
	if not GameManager.get_flag("training_week_intro_done"):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("training_week_intro"), func():
			DialogueManager.play_dialogue(DialogueLoader.get_lines("training_week_drills"), func():
				GameManager.set_flag("training_week_intro_done", true)
				map._refresh_quest_label()
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
				map._refresh_quest_label()
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
		unlock_scene()
		map._refresh_quest_label() # HUD được dựng trước on_stage_start nên phải làm mới để hiện lời nhắc chuẩn bị
	)

# Menu của Mafuyu trong lúc chuẩn bị lại: làm lại bài kiểm tra, luyện tập, nâng cấp
func _show_prep_menu():
	var idx: int = await DialogueManager.ask(["[Bắt đầu bài kiểm tra]", "[Luyện tập]", "[Nâng cấp]", "[Hủy]"])
	if idx == 0:
		lock_scene()
		_start_trial()
	elif idx == 1:
		offer_training(PREP_TRAINEES, false, lock_scene, true)
	elif idx == 2:
		open_upgrade_ui(PREP_TRAINEES)

func _start_trial():
	# Lần đầu: lời mở đầu bài kiểm tra. Làm lại sau khi chuẩn bị thì vào thẳng trận (Mafuyu đã nói ở lúc thua)
	var lines: Array = []
	if not GameManager.get_flag("training_trial_started"):
		lines = DialogueLoader.get_lines("training_trial_pre")
	GameManager.set_flag("training_trial_started", true)
	GameManager.set_flag("training_trial_prep_seen", false)
	DialogueManager.play_dialogue(lines, func():
		GameManager.start_scripted_battle("training_trial", MapPaths.BASE, Vector2.ZERO, 1.0)
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

# Cửa ra bị khóa suốt Stage này; trong chế độ chuẩn bị người chơi đi lại được nên cần một dòng dẫn truyện thay vì im lặng
func handle_exit() -> bool:
	if _prep_mode:
		DialogueManager.play_dialogue([{
			"text": "Chưa phải lúc rời đi. Hãy chuẩn bị xong rồi nói chuyện với Mafuyu để làm lại bài kiểm tra.",
			"type": "narrator"
		}])
	return true

func handle_npc_interaction(npc_name: String):
	if not _prep_mode or npc_name != "Mafuyu":
		return
	_show_prep_menu()

func get_quest_text() -> String:
	if _prep_mode:
		return "MỤC TIÊU: Chuẩn bị thêm, rồi nói chuyện với Mafuyu để làm lại bài kiểm tra."
	if not GameManager.get_flag("training_welcome_done"):
		return "MỤC TIÊU: Khóa huấn luyện sinh tử. Vượt qua bài kiểm tra ngày thứ bảy."
	return "MỤC TIÊU: Ở lại Nightcord và nghe cuộc trò chuyện về ghế Thủ Tướng mới."
