extends BaseMapStage

"""
FinalStage: "Dạ Khúc Cuối" - trận chiến cuối với Mafuyu và đoạn kết, diễn ra tại căn cứ Nightcord.
Ichika (người chơi) và Honami tới căn cứ, Mafuyu ngồi đầu bàn ăn chờ sẵn.

Chạy khi: final_confront_started && !game_completed. Ba trạng thái con, suy ra hoàn toàn từ cờ:
  - chưa đánh                      : final_mafuyu_pre rồi vào trận final_mafuyu
  - vừa thua (last_scripted_loss)  : final_mafuyu_lose rồi về nhà Honami luyện tập tiếp
  - final_mafuyu_defeated          : final_mafuyu_post, ending_honami_offer, ending_narration rồi EndingCard
Lưu/tải giữa chừng chỉ khiến cảnh phát lại (current_map_file luôn là Base trong cả ba trạng thái).
"""

const HOUSE_SCENE := MapPaths.HONAMI_HOUSE
const ENDING_SCENE := MapPaths.ENDING_CARD
const BATTLE_ID := "final_mafuyu"


# Cửa ra bị khoá suốt cảnh này
func _init():
	exit_locked = true

func get_npc_positions() -> Dictionary:
	return {
		"Mafuyu": Vector2(24 * map.TILE_SIZE, 12 * map.TILE_SIZE),
	}

func get_scene_lighting() -> Color:
	return Color(0.62, 0.65, 0.82)

func get_bgm_track() -> String:
	return "night"

func on_stage_start():
	map.set_player("Ichika")
	map.place_player(Vector2(24, 17), "up")
	map.freeze_player()
	map.spawn_dummy("Honami", Vector2(22, 17), map.NPC_COLORS["Honami"])

	if GameManager.get_flag("final_mafuyu_defeated"):
		_play_sequence(["final_mafuyu_post", "ending_honami_offer", "ending_narration"], _open_end_card)
	elif GameManager.get_flag("last_scripted_loss", "") == BATTLE_ID:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("final_mafuyu_lose"), _on_lost)
	else:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("final_mafuyu_pre"), _start_battle)

# Phát lần lượt các khoá hội thoại, xong hết mới gọi on_done
func _play_sequence(keys: Array, on_done: Callable, index: int = 0):
	if index >= keys.size():
		on_done.call()
		return
	DialogueManager.play_dialogue(DialogueLoader.get_lines(keys[index]), func():
		_play_sequence(keys, on_done, index + 1)
	)

func _start_battle():
	GameManager.start_scripted_battle(BATTLE_ID, MapPaths.BASE, Vector2.ZERO, 1.0)

func _on_lost():
	# Thua: về nhà Honami, luyện thêm rồi quay lại
	GameManager.set_flag("last_scripted_loss", "")
	await ScreenFade.fade_out(1.0)
	GameManager.set_flag("final_confront_started", false)
	GameManager.store_map_state(HOUSE_SCENE, Vector2.ZERO)
	get_tree().change_scene_to_file(HOUSE_SCENE)

func _open_end_card():
	await ScreenFade.fade_out(1.5)
	GameManager.store_map_state(MapPaths.BASE, Vector2.ZERO)
	get_tree().change_scene_to_file(ENDING_SCENE)

func get_quest_text() -> String:
	if GameManager.get_flag("final_mafuyu_defeated"):
		return ""
	return "MỤC TIÊU: Hạ Mafuyu."
