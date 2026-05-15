extends BaseMapStage
class_name PostHarborMorningStage

var _cutscene_active: bool = false

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
		# Bị treo ở sảnh chính
		pos["Ena"] = Vector2(24 * map.TILE_SIZE, 15 * map.TILE_SIZE)
		
	return pos

func on_stage_start():
	# Hủy góc nhìn Mizuki
	GameManager.set_flag("mizuki_control_phase", false)
	
	# Đặt người chơi (Ichika) cạnh giường ban đầu nếu chưa xem cutscene
	if not GameManager.get_flag("post_harbor_morning_done"):
		_cutscene_active = true
		map._spawn_player()
		var player = map.get_node_or_null("OverworldPlayer")
		if player: player.position = Vector2(6 * map.TILE_SIZE, 6 * map.TILE_SIZE)
		
	# Hiệu ứng ánh sáng buổi sáng
	var lighting = CanvasModulate.new()
	map.add_child(lighting)
	lighting.color = Color(0.9, 0.9, 1.0) # Sáng sủa
	
	if not GameManager.get_flag("post_harbor_morning_done"):
		_play_morning_cutscene()
	else:
		_update_ena_visuals()

func _play_morning_cutscene():
	DialogueManager.play_dialogue(DialogueLoader.get_lines("morning_p1"), func():
		_show_morning_choices()
	)

func _show_morning_choices():
	DialogueManager.show_choice(["Đẩy ra nhẹ nhàng", "Đá khỏi giường"])
	var choice_idx = await DialogueManager.choice_made
	
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
	
	var player = map.get_node_or_null("OverworldPlayer")
	if player: player.position = Vector2(24 * map.TILE_SIZE, 20 * map.TILE_SIZE) # Trở về từ cửa sổ/cửa chính
	
	_update_ena_visuals()
	
	await ScreenFade.fade_in(1.0)
	
	DialogueManager.play_dialogue(DialogueLoader.get_lines("return_home"), func():
		_cutscene_active = false
		map._refresh_quest_label()
	)

func _update_ena_visuals():
	if GameManager.get_flag("ena_released"): return
	
	# Tìm Ena và quay ngược 180 độ
	for child in map.get_children():
		if child.has_meta("is_npc"):
			var lbl = child.get_node_or_null("Label")
			if lbl and lbl.text == "Ena":
				child.rotation_degrees = 180
				# Điều chỉnh offset do quay ngược
				child.position.y += 24
				break

func handle_npc_interaction(npc_name: String):
	if _cutscene_active: return
	
	if npc_name == "Kanade":
		if not GameManager.get_flag("ena_released"):
			DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_kanade"))
		else:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_kanade_post"), func():
				get_tree().change_scene_to_file("res://Menus/UpgradeMenu.tscn")
			)
	elif npc_name == "Mizuki":
		DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_mizuki"))
	elif npc_name == "Ena":
		if not GameManager.get_flag("ena_released"):
			DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_ena_hanging"))
		else:
			DialogueManager.play_dialogue([{"text": "Xê ra! Chị mày đang đau lưng!", "type": "dialogue", "name": "Ena", "color": Color("#b86028")}])
	elif npc_name == "Mafuyu":
		if not GameManager.get_flag("ena_released"):
			DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_mafuyu_release"), func():
				GameManager.set_flag("ena_released", true)
				# Hủy quay ngược
				for child in map.get_children():
					if child.has_meta("is_npc"):
						var lbl = child.get_node_or_null("Label")
						if lbl and lbl.text == "Ena":
							child.rotation_degrees = 0
							child.position.y -= 24
							break
				map._refresh_quest_label()
			)
		else:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_mafuyu_post"), func():
				_show_training_menu()
			)

func _show_training_menu():
	GameManager.set_flag("talked_to_mafuyu_training", true)
	# Mở Training Menu có thêm Ena
	var participants = ["Ichika", "Kanade", "Mizuki", "Ena"]
	GameManager.is_training_mode = true
	GameManager.training_participants = participants
	GameManager.trigger_battle()

func get_quest_text() -> String:
	if not GameManager.get_flag("ena_released"):
		return "MỤC TIÊU: Nói chuyện với Mafuyu để thả Ena."
	else:
		return "MỤC TIÊU: Tự do khám phá (Kanade: Upgrade, Mafuyu: Training)"
