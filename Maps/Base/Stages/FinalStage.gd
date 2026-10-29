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

const HOUSE_SCENE := "res://Maps/HonamiHouse/HonamiHouseMap.tscn"
const ENDING_SCENE := "res://UI/Menus/Ending/EndingCard.tscn"
const BATTLE_ID := "final_mafuyu"

var _honami: Node2D = null

func get_npc_positions() -> Dictionary:
	return {
		"Mafuyu": Vector2(24 * map.TILE_SIZE, 12 * map.TILE_SIZE),
	}

func get_scene_lighting() -> Color:
	return Color(0.62, 0.65, 0.82)

func get_bgm_track() -> String:
	return "night"

func on_stage_start():
	var player = map.get_node_or_null("OverworldPlayer")
	if player:
		player.character_color = map.NPC_COLORS["Ichika"]
		player.position = Vector2(24 * map.TILE_SIZE, 17 * map.TILE_SIZE)
		player.set_facing("up")
	map.freeze_player()
	_honami = map.spawn_dummy("Honami", Vector2(22, 17), map.NPC_COLORS["Honami"])

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
	GameManager.is_scripted_battle = true
	GameManager.scripted_battle_id = BATTLE_ID
	GameManager.store_map_state("res://Maps/Base/BaseMap.tscn", Vector2.ZERO)
	await ScreenFade.fade_out(1.0)
	GameManager.trigger_battle()

func _on_lost():
	# Thua: về nhà Honami, luyện thêm rồi quay lại
	GameManager.set_flag("last_scripted_loss", "")
	await ScreenFade.fade_out(1.0)
	GameManager.set_flag("final_confront_started", false)
	GameManager.store_map_state(HOUSE_SCENE, Vector2.ZERO)
	get_tree().change_scene_to_file(HOUSE_SCENE)

func _open_end_card():
	await ScreenFade.fade_out(1.5)
	GameManager.store_map_state("res://Maps/Base/BaseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file(ENDING_SCENE)

func handle_npc_interaction(_npc_name: String):
	pass

# Cửa ra bị khoá suốt cảnh này
func handle_exit() -> bool:
	return true

func get_quest_text() -> String:
	if GameManager.get_flag("final_mafuyu_defeated"):
		return ""
	return "MỤC TIÊU: Hạ Mafuyu."
