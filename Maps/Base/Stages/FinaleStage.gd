extends BaseMapStage
class_name FinaleStage

"""
FinaleStage: "Ghế Thủ Tướng Mới" - sảnh Base ngay sau khi Thủ Tướng chết.
Cảnh tự chạy: ăn mừng và bàn chuyện tân Thủ Tướng (base_celebration) -> Ena bỏ đi giữa chừng
-> dư âm (ena_leaves_aftermath) -> sang BountyMap (Ena là nhân vật chơi được).

Chạy khi: pm_boss_defeated && !finale_done.
Cờ finale_done + ena_left_nightcord chỉ được đặt SAU khi màn hình đã tối, ngay trước khi đổi scene,
nên lưu/tải giữa chừng chỉ khiến cảnh phát lại từ đầu, không bao giờ kẹt ở Base.
"""

const NEXT_SCENE := "res://Maps/Bounty/BountyMap.tscn"

var _cutscene_active: bool = false
var _honami: Node2D = null

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
	_honami = map.spawn_dummy("Honami", Vector2(28, 17), map.NPC_COLORS["Honami"])
	
	DialogueManager.play_dialogue(DialogueLoader.get_lines("base_celebration"), _on_celebration_done)

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

func handle_npc_interaction(_npc_name: String):
	if _cutscene_active: return

# Cửa ra bị khoá suốt cảnh này (xử lý xong, không làm gì)
func handle_exit() -> bool:
	return true

func get_quest_text() -> String:
	return "MỤC TIÊU: Ở lại Nightcord và nghe cuộc trò chuyện về ghế Thủ Tướng mới."
