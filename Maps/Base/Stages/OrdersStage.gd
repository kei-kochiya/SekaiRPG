extends BaseMapStage

"""
OrdersStage: "Mệnh lệnh" - sảnh Base sau khi Ena bị bắt và bị tra tấn.
Ichika (người chơi) đứng giữa Mafuyu, Mizuki và Kanade; Ena đã đi, Bộ trưởng Quốc phòng không có mặt.
Cảnh tự chạy một lần: orders_mafuyu -> sang InterrogationMap (Mizuki là nhân vật chơi được).

Chạy khi: interrogation_seen && !ena_kill_ordered.
Cờ ena_kill_ordered chỉ được đặt SAU khi màn hình đã tối, ngay trước khi đổi scene
(lưu/tải giữa chừng chỉ khiến cảnh phát lại, không bao giờ kẹt ở Base).
"""

const NEXT_SCENE := "res://Maps/Interrogation/InterrogationMap.tscn"

var _cutscene_active: bool = false

func get_npc_positions() -> Dictionary:
	return {
		"Mafuyu": Vector2(24 * map.TILE_SIZE, 12 * map.TILE_SIZE),
		"Kanade": Vector2(21 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mizuki": Vector2(27 * map.TILE_SIZE, 13 * map.TILE_SIZE),
	}

# Căn cứ lạnh và tối hơn bình thường
func get_scene_lighting() -> Color:
	return Color(0.8, 0.83, 0.95)

func get_bgm_track() -> String:
	return "night"

func on_stage_start():
	var player = map.get_node_or_null("OverworldPlayer")
	if player:
		player.character_color = map.NPC_COLORS["Ichika"]
		player.position = Vector2(24 * map.TILE_SIZE, 17 * map.TILE_SIZE)

	if GameManager.get_flag("ena_kill_ordered"):
		return

	_cutscene_active = true
	map.freeze_player()
	DialogueManager.play_dialogue(DialogueLoader.get_lines("orders_mafuyu"), _on_orders_done)

func _on_orders_done():
	await ScreenFade.fade_out(1.0)
	GameManager.set_flag("ena_kill_ordered", true)
	GameManager.store_map_state(NEXT_SCENE, Vector2.ZERO)
	get_tree().change_scene_to_file(NEXT_SCENE)

func handle_npc_interaction(_npc_name: String):
	if _cutscene_active: return

# Cửa ra bị khoá suốt cảnh này (xử lý xong, không làm gì)
func handle_exit() -> bool:
	return true

func get_quest_text() -> String:
	return "MỤC TIÊU: Nghe lệnh của Mafuyu."
