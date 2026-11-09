extends BaseMapStage

"""
RevealStage: "Kẻ Nằm Vùng" - cảnh về căn cứ sau cái chết của Kanade.
Base vắng tanh, chỉ còn Mafuyu và Ichika, ánh sáng tối. Mafuyu hé lộ chính cô là kẻ muốn giết hết đồng đội
(reveal_mafuyu), rời đi; Honami xông vào đưa Ichika đi (honami_rescue) -> sang nhà Honami.

Chạy khi: kanade_killed && !honami_rescue_done.
honami_rescue_done chỉ được đặt SAU khi màn hình đã tối, ngay trước khi đổi scene
(lưu/tải giữa chừng chỉ khiến cảnh phát lại, không bao giờ kẹt ở Base).
"""

const NEXT_SCENE := MapPaths.HONAMI_HOUSE

var _phase: int = 0 # 0 = nghe Mafuyu, 1 = Honami tới

# Cửa ra bị khoá suốt cảnh này
func _init():
	exit_locked = true

func get_npc_positions() -> Dictionary:
	return {
		"Mafuyu": Vector2(26 * map.TILE_SIZE, 13 * map.TILE_SIZE),
	}

# Rất tối: căn cứ trống rỗng
func get_scene_lighting() -> Color:
	return Color(0.6, 0.63, 0.8)

func get_bgm_track() -> String:
	return "night"

func on_stage_start():
	map.set_player("Ichika")
	map.place_player(Vector2(23, 16), "right")

	lock_scene()
	DialogueManager.play_dialogue(DialogueLoader.get_lines("reveal_mafuyu"), _on_reveal_done)

func _on_reveal_done():
	# Mafuyu bước ra khỏi căn cứ, bỏ lại Ichika một mình
	var mafuyu = map.get_npc_node("Mafuyu")
	await map.walk_node(mafuyu, [
		Vector2(26, 19) * map.TILE_SIZE,
		Vector2(24, 20) * map.TILE_SIZE,
		Vector2(24, 21) * map.TILE_SIZE,
	])
	if mafuyu and is_instance_valid(mafuyu):
		mafuyu.queue_free()

	# Honami xông vào từ cửa chính
	_phase = 1
	map._refresh_quest_label()
	var honami: Node2D = map.spawn_dummy("Honami", Vector2(24, 21), map.NPC_COLORS["Honami"])
	await map.walk_node(honami, [
		Vector2(24, 19) * map.TILE_SIZE,
		Vector2(25, 17) * map.TILE_SIZE,
	], 220.0)

	DialogueManager.play_dialogue(DialogueLoader.get_lines("honami_rescue"), _on_rescue_done)

func _on_rescue_done():
	await ScreenFade.fade_out(1.5)
	GameManager.set_flag("honami_rescue_done", true)
	GameManager.store_map_state(NEXT_SCENE, Vector2.ZERO)
	get_tree().change_scene_to_file(NEXT_SCENE)

func get_quest_text() -> String:
	if _phase == 0:
		return "MỤC TIÊU: Nghe Mafuyu nói."
	return "MỤC TIÊU: Đi cùng Honami."
