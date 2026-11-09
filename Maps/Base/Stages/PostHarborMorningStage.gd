extends BaseMapStage
class_name PostHarborMorningStage

"""
PostHarborMorningStage: Kịch bản buổi sáng sau khi hoàn thành nhiệm vụ Bến cảng.

Quản lý chuỗi sự kiện thức dậy, các lựa chọn tương tác buổi sáng, trạng thái treo Ena 
ở sảnh chính, và logic chuyển quyền điều khiển sang Ena khi các điều kiện tương tác 
hoặc luyện tập được thỏa mãn.
"""

# Mafuyu cho luyện tập bốn người này; ai đã tập xong thì không hiện nữa
const TRAINEES := ["Ichika", "Kanade", "Ena", "Mizuki"]

func get_npc_positions() -> Dictionary:
	var pos = {
		"Kanade": Vector2(33 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mizuki": Vector2(35 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mafuyu": Vector2(8 * map.TILE_SIZE, 14 * map.TILE_SIZE),
	}
	
	if not GameManager.get_flag("post_harbor_morning_done"):
		# Đang ở trong giường
		pos["Ena"] = Vector2(7 * map.TILE_SIZE, 6 * map.TILE_SIZE)
	else:
		if GameManager.get_flag("ena_control_phase"):
			pos["Ichika"] = Vector2(24 * map.TILE_SIZE, 15 * map.TILE_SIZE)
		else:
			# Bị treo ở sảnh chính / Đứng ở sảnh chính
			pos["Ena"] = Vector2(24 * map.TILE_SIZE, 15 * map.TILE_SIZE)
		
	return pos

# Ánh sáng buổi sáng sủa; BaseMap áp trước fade_in nên không bị "nháy sáng"
func get_scene_lighting() -> Color:
	return Color(0.9, 0.9, 1.0)

# BaseMap._spawn_player chạy trước on_stage_start: nếu cờ Mizuki còn bật, người chơi hiện ra là Mizuki chồng lên NPC Mizuki suốt lúc fade-in
func setup(p_map: Node2D):
	GameManager.set_flag("mizuki_control_phase", false)
	super.setup(p_map)

func on_stage_start():
	# Hủy góc nhìn Mizuki
	GameManager.set_flag("mizuki_control_phase", false)
	
	# Đảm bảo player là đúng nhân vật
	map.set_player("Ena" if GameManager.get_flag("ena_control_phase") else "Ichika")
	
	# Reset training flags
	if not GameManager.get_flag("post_harbor_training_reset"):
		GameManager.reset_training_progress()
		GameManager.set_flag("post_harbor_training_reset", true)
	
	# Đặt người chơi (Ichika) cạnh giường ban đầu nếu chưa xem cutscene
	if not GameManager.get_flag("post_harbor_morning_done"):
		lock_scene()
		map.place_player(Vector2(6, 6))
		
	if not GameManager.get_flag("post_harbor_morning_done"):
		_play_morning_cutscene()
	else:
		_update_ena_visuals()
		_check_ena_phase_trigger()

# Kiểm tra lại ngay khi hội thoại của lần nói chuyện này kết thúc (không chồng lên hội thoại đang chạy)
func _queue_ena_check():
	if not DialogueManager.dialogue_finished.is_connected(_on_talk_finished):
		DialogueManager.dialogue_finished.connect(_on_talk_finished, CONNECT_ONE_SHOT)

func _on_talk_finished():
	# Hội thoại vừa xong có thể mở tiếp một lựa chọn/bảng nâng cấp; lúc đó chờ lần đóng của chúng
	if DialogueManager.active or DialogueManager._in_choice or UpgradeUI._open:
		return
	_check_ena_phase_trigger()

func _check_ena_phase_trigger():
	if GameManager.get_flag("ena_control_phase"): return
	if not GameManager.get_flag("ena_released"): return
	
	var trained = GameManager.get_flag("training_ichika_done") or GameManager.get_flag("training_kanade_done") or GameManager.get_flag("training_ena_done") or GameManager.get_flag("training_mizuki_done")
	var count = GameManager.get_flag("interaction_count", 0)
	
	if trained or count >= 4:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("ena_bored_intro"), func():
			GameManager.set_flag("ena_control_phase", true)
			map.set_player("Ena")
			map._spawn_npcs()
			map._refresh_quest_label()
		)

func _play_morning_cutscene():
	DialogueManager.play_dialogue(DialogueLoader.get_lines("morning_p1"), func():
		_show_morning_choices()
	)

func _show_morning_choices():
	var choice_idx: int = await DialogueManager.ask(["Đẩy ra nhẹ nhàng", "Đá khỏi giường"])
	
	if choice_idx == 0:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("morning_push"), func():
			# Quay lại lựa chọn
			_show_morning_choices()
		)
	else:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("morning_kick"), func():
			# Tiếp tục thoại của Mafuyu
			DialogueManager.play_dialogue(DialogueLoader.get_lines("mafuyu_order"), func():
				_simulate_food_run()
			)
		)

func _simulate_food_run():
	await ScreenFade.fade_out(1.0)
	
	GameManager.set_flag("post_harbor_morning_done", true)
	map._spawn_npcs() # Respawn để dời Ena ra sảnh chính
	
	map.place_player(Vector2(24, 20)) # Trở về từ cửa sổ/cửa chính
	
	_update_ena_visuals()
	
	await ScreenFade.fade_in(1.0)
	
	DialogueManager.play_dialogue(DialogueLoader.get_lines("return_home"), func():
		unlock_scene()
		map._refresh_quest_label()
	)

func _update_ena_visuals():
	if GameManager.get_flag("ena_released"): return
	_set_ena_hanging(true)

# Ena bị treo ngược trên ròng rọc (sprite quay 180 độ quanh tâm) hoặc được thả xuống. Chỉ quay sprite, không quay cả node,
# để nhãn tên và gợi ý "Nói chuyện với Ena" vẫn đọc được; gọi lặp với cùng trạng thái thì không làm gì.
func _set_ena_hanging(hanging: bool):
	var ena = map.get_npc_node("Ena")
	if ena == null:
		return
	var body = ena.get_child(0)
	if body is Sprite2D:
		body.rotation_degrees = 180.0 if hanging else 0.0

func handle_npc_interaction(npc_name: String):
	var is_ena = GameManager.get_flag("ena_control_phase")
	
	if not is_ena:
		var count = GameManager.get_flag("interaction_count", 0)
		GameManager.set_flag("interaction_count", count + 1)
		# Gợi ý "Nói chuyện 4 lần" phải có hiệu lực ngay trong cảnh, không đợi vào lại căn cứ
		_queue_ena_check()

	if npc_name == "Ichika":
		if is_ena:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("ena_talk_ichika"))
			
	elif npc_name == "Kanade":
		if not GameManager.get_flag("ena_released"):
			DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_kanade"))
		else:
			var lines = "talk_kanade_post_ena" if is_ena else "talk_kanade_post"
			DialogueManager.play_dialogue(DialogueLoader.get_lines(lines), func():
				open_upgrade_ui()
				if not UpgradeUI.closed.is_connected(_check_ena_phase_trigger):
					UpgradeUI.closed.connect(_check_ena_phase_trigger, CONNECT_ONE_SHOT)
			)
	elif npc_name == "Mizuki":
		if is_ena:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("ena_invite_mizuki"), func():
				await GameManager.change_map(MapPaths.CAFE, 1.0)
			)
		else:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_mizuki"))
			
	elif npc_name == "Ena":
		if not is_ena:
			if not GameManager.get_flag("ena_released"):
				DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_ena_hanging"))
			else:
				DialogueManager.play_dialogue([say("Ena", "Xê ra! Chị mày đang đau lưng!")])
				
	elif npc_name == "Mafuyu":
		if not GameManager.get_flag("ena_released"):
			DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_mafuyu_release"), func():
				GameManager.set_flag("ena_released", true)
				_set_ena_hanging(false)
				map._refresh_quest_label()
			)
		else:
			var lines = "talk_mafuyu_post_ena" if is_ena else "talk_mafuyu_post"
			DialogueManager.play_dialogue(DialogueLoader.get_lines(lines), func():
				_show_training_menu()
			)

func _show_training_menu():
	if not await offer_training(TRAINEES, true):
		_check_ena_phase_trigger()

func get_quest_text() -> String:
	if not GameManager.get_flag("ena_released"):
		return "MỤC TIÊU: Nói chuyện với Mafuyu để thả Ena."
	elif GameManager.get_flag("ena_control_phase"):
		return "MỤC TIÊU: (Góc nhìn Ena) Rủ Mizuki đi chơi cho đỡ chán."
	else:
		return "MỤC TIÊU: Tự do khám phá (Nói chuyện 4 lần hoặc Đi tập luyện để tiếp tục)"
