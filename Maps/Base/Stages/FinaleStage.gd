extends BaseMapStage
class_name FinaleStage

func get_npc_positions() -> Dictionary:
	return {
		"Ena": Vector2(17 * map.TILE_SIZE, 11 * map.TILE_SIZE),
		"Kanade": Vector2(23 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mizuki": Vector2(19 * map.TILE_SIZE, 12 * map.TILE_SIZE),
		"Mafuyu": Vector2(24 * map.TILE_SIZE, 11 * map.TILE_SIZE),
	}

func on_stage_start():
	var player = map.get_node_or_null("OverworldPlayer")
	if player:
		player.character_color = map.NPC_COLORS["Ichika"]
		player.position = Vector2(20 * map.TILE_SIZE, 16 * map.TILE_SIZE)
		player.queue_redraw()
		
	var lighting = CanvasModulate.new()
	map.add_child(lighting)
	lighting.color = Color(0.9, 0.9, 1.0)
	
	if not GameManager.get_flag("finale_done"):
		# Tự động trigger cutscene ăn mừng
		MapUtils.create_dummy_char(map, "Honami", Vector2(17, 16), Color(0.5, 0.35, 0.25))
		
		DialogueManager.play_dialogue(DialogueLoader.get_lines("base_celebration"), func():
			GameManager.set_flag("finale_done", true)
			# Transition Ichika to Honami's house
			await ScreenFade.fade_out(1.5)
			GameManager.store_map_state("res://Maps/HonamiHouse/HonamiHouseMap.tscn", Vector2.ZERO)
			get_tree().change_scene_to_file("res://Maps/HonamiHouse/HonamiHouseMap.tscn")
		)

func handle_npc_interaction(npc_name: String):
	pass

func get_quest_text() -> String:
	return "MỤC TIÊU: Kết thúc."
