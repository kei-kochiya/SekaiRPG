extends BaseMapStage
class_name PostHarborMorningStage

"""
PostHarborMorningStage: Kịch bản buổi sáng sau khi hoàn thành nhiệm vụ Bến cảng.

Quản lý chuỗi sự kiện thức dậy, các lựa chọn tương tác buổi sáng, trạng thái treo Ena 
ở sảnh chính, và logic chuyển quyền điều khiển sang Ena khi các điều kiện tương tác 
hoặc luyện tập được thỏa mãn.
"""

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
		if GameManager.get_flag("ena_control_phase"):
			pos["Ichika"] = Vector2(24 * map.TILE_SIZE, 15 * map.TILE_SIZE)
		else:
			# Bị treo ở sảnh chính / Đứng ở sảnh chính
			pos["Ena"] = Vector2(24 * map.TILE_SIZE, 15 * map.TILE_SIZE)
		
	return pos

func on_stage_start():
	# Hủy góc nhìn Mizuki
	GameManager.set_flag("mizuki_control_phase", false)
	
	# Đảm bảo player là đúng nhân vật
	var player = map.get_node_or_null("OverworldPlayer")
	if player:
		if GameManager.get_flag("ena_control_phase"):
			player.character_color = map.NPC_COLORS["Ena"]
		else:
			player.character_color = map.NPC_COLORS["Ichika"]
		player.queue_redraw()
	
	# Reset training flags
	if not GameManager.get_flag("post_harbor_training_reset"):
		GameManager.set_flag("training_ichika_done", false)
		GameManager.set_flag("training_kanade_done", false)
		GameManager.set_flag("training_ena_done", false)
		GameManager.set_flag("training_mizuki_done", false)
		GameManager.set_flag("post_harbor_training_reset", true)
	
	# Đặt người chơi (Ichika) cạnh giường ban đầu nếu chưa xem cutscene
	if not GameManager.get_flag("post_harbor_morning_done"):
		_cutscene_active = true
		if player: player.position = Vector2(6 * map.TILE_SIZE, 6 * map.TILE_SIZE)
		
	# Hiệu ứng ánh sáng buổi sáng
	var lighting = CanvasModulate.new()
	map.add_child(lighting)
	lighting.color = Color(0.9, 0.9, 1.0) # Sáng sủa
	
	if not GameManager.get_flag("post_harbor_morning_done"):
		_play_morning_cutscene()
	else:
		_update_ena_visuals()
		_check_ena_phase_trigger()

func _check_ena_phase_trigger():
	if GameManager.get_flag("ena_control_phase"): return
	if not GameManager.get_flag("ena_released"): return
	
	var trained = GameManager.get_flag("training_ichika_done") or GameManager.get_flag("training_kanade_done") or GameManager.get_flag("training_ena_done") or GameManager.get_flag("training_mizuki_done")
	var count = GameManager.get_flag("interaction_count", 0)
	
	if trained or count >= 4:
		if not GameManager.get_flag("ena_cafe_unlocked"):
			DialogueManager.play_dialogue(DialogueLoader.get_lines("ena_bored_intro"), func():
				GameManager.set_flag("ena_cafe_unlocked", true)
				GameManager.set_flag("ena_control_phase", true)
				var player = map.get_node_or_null("OverworldPlayer")
				if player:
					player.character_color = map.NPC_COLORS["Ena"]
					player.queue_redraw()
				map._spawn_npcs()
				map._refresh_quest_label()
			)

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
	
	var is_ena = GameManager.get_flag("ena_control_phase")
	
	if not is_ena:
		var count = GameManager.get_flag("interaction_count", 0)
		GameManager.set_flag("interaction_count", count + 1)
		
	if npc_name == "Ichika":
		if is_ena:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("ena_talk_ichika"))
			
	elif npc_name == "Kanade":
		if not GameManager.get_flag("ena_released"):
			DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_kanade"))
		else:
			var lines = "talk_kanade_post_ena" if is_ena else "talk_kanade_post"
			DialogueManager.play_dialogue(DialogueLoader.get_lines(lines), func():
				var p_list: Array[Entity] = [
					GameManager.get_party_member("Ichika"),
					GameManager.get_party_member("Kanade"),
					GameManager.get_party_member("Mafuyu"),
					GameManager.get_party_member("Ena"),
					GameManager.get_party_member("Mizuki")
				]
				UpgradeUI.show_ui(p_list)
			)
	elif npc_name == "Mizuki":
		if is_ena:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("ena_invite_mizuki"), func():
				await ScreenFade.fade_out(1.0)
				GameManager.last_player_position = Vector2.ZERO
				get_tree().change_scene_to_file("res://Maps/Cafe/CafeMap.tscn")
			)
		else:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("talk_mizuki"))
			
	elif npc_name == "Ena":
		if not is_ena:
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
			var lines = "talk_mafuyu_post_ena" if is_ena else "talk_mafuyu_post"
			DialogueManager.play_dialogue(DialogueLoader.get_lines(lines), func():
				_show_training_menu()
			)

func _show_training_menu():
	GameManager.set_flag("talked_to_mafuyu_training", true)
	
	var opts: Array = []
	var mapping = []
	if not GameManager.get_flag("training_ichika_done"):
		opts.append("Ichika (5 Waves)")
		mapping.append("Ichika")
	if not GameManager.get_flag("training_kanade_done"):
		opts.append("Kanade (5 Waves)")
		mapping.append("Kanade")
	if not GameManager.get_flag("training_ena_done"):
		opts.append("Ena (5 Waves)")
		mapping.append("Ena")
	if not GameManager.get_flag("training_mizuki_done"):
		opts.append("Mizuki (5 Waves)")
		mapping.append("Mizuki")
	
	opts.append("Để sau.")
	
	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	if opts[idx] == "Để sau.": return
	
	GameManager.is_training_mode = true
	GameManager.warehouse_wave = 1
	GameManager.training_participants = [mapping[idx]]
	
	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state("res://Maps/Warehouse/TrainingWarehouseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Maps/Warehouse/TrainingWarehouseMap.tscn")

func get_quest_text() -> String:
	if not GameManager.get_flag("ena_released"):
		return "MỤC TIÊU: Nói chuyện với Mafuyu để thả Ena."
	elif GameManager.get_flag("ena_control_phase"):
		return "MỤC TIÊU: (Góc nhìn Ena) Rủ Mizuki đi chơi cho đỡ chán."
	else:
		return "MỤC TIÊU: Tự do khám phá (Nói chuyện 4 lần hoặc Đi tập luyện để tiếp tục)"
