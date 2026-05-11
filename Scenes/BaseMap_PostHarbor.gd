extends Node2D

const TILE_SIZE = 32
const ASSET_ROOT = "res://Assets/kenney_micro-roguelike/Tiles/"

const NPC_COLORS := {
	"Mafuyu": Color(0.4, 0.3, 0.5),
	"Ena": Color(0.72, 0.38, 0.16),
	"Kanade": Color(0.8, 0.8, 0.9),
	"Mizuki": Color(0.85, 0.65, 0.8),
}

var _lighting: CanvasModulate
var _quest_label: Label
var _quest_panel: PanelContainer

func _ready() -> void:
	_lighting = CanvasModulate.new()
	_lighting.color = Color(0.4, 0.4, 0.5) # Dark Ambience
	add_child(_lighting)
	
	AudioManager.play_music("after_warehouse")
	ScreenFade.fade_in(0.8)
	
	_build_map()
	_spawn_npcs()
	_spawn_player()
	_spawn_transitions()
	_build_quest_hud()
	
	await get_tree().create_timer(1.0).timeout
	_check_story_state()

func _check_story_state():
	# F6 Debug: If running directly, default to the first phase (Meeting) for testing
	if GameManager.story.harbor_wave <= 1:
		GameManager.story.harbor_wave = 5
	
	print("[Story] Current Wave: ", GameManager.story.harbor_wave)
	print("[Story] Honami Talked: ", GameManager.story.get_flag("mafuyu_honami_talked"))
	print("[Story] Snack Done: ", GameManager.story.get_flag("harbor_mizuki_snack_done"))
		
	if GameManager.story.get_flag("mizuki_vs_mafuyu_done"):
		GameManager.story.set_flag("mizuki_vs_mafuyu_done", false)
		_play_report_p2()
		return

	if GameManager.story.harbor_wave <= 5:
		if not GameManager.story.get_flag("harbor_meeting_p1_done"):
			DialogueManager.play_dialogue(DialogueLoader.get_lines("base_meeting_p1"), func():
				GameManager.story.set_flag("harbor_meeting_p1_done", true)
				_refresh_quest_label()
			)
		else:
			_refresh_quest_label()
	elif GameManager.story.harbor_wave >= 6 and not GameManager.story.get_flag("harbor_mizuki_snack_done"):
		_play_mizuki_snack_sequence()
	else:
		_refresh_quest_label()

func _play_mizuki_snack_sequence():
	DialogueManager.play_dialogue(DialogueLoader.get_lines("base_mizuki_snack_p1"), func():
		# Activate Mizuki Control Phase
		GameManager.story.set_flag("mizuki_control_phase", true)
		
		# Get Mizuki NPC position and remove it
		var mizuki_pos = Vector2(35 * TILE_SIZE, 13 * TILE_SIZE)
		
		# Teleport Player to Mizuki's position and change color
		var p = get_node_or_null("OverworldPlayer")
		if p:
			var old_pos = p.position
			p.position = mizuki_pos
			p.character_color = NPC_COLORS["Mizuki"]
			
			# Respawn NPCs to reflect the new state (Ichika as NPC, Mizuki as Player)
			# First, clear existing NPCs
			for child in get_children():
				if child.has_meta("is_npc"):
					child.queue_free()
			
			# Wait a frame then respawn
			await get_tree().process_frame
			_spawn_npcs()
		
		_refresh_quest_label()
	)

# ─────────────────────────────────────────────
#  QUEST HUD
# ─────────────────────────────────────────────
func _build_quest_hud():
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)
	_quest_panel = PanelContainer.new()
	_quest_panel.position = Vector2(20, 20)
	canvas.add_child(_quest_panel)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.6)
	sb.border_width_left = 4
	sb.border_color = Color(1.0, 0.4, 0.4) # Red for high tension
	sb.set_content_margin_all(10)
	_quest_panel.add_theme_stylebox_override("panel", sb)
	_quest_label = Label.new()
	_quest_label.add_theme_font_size_override("font_size", 16)
	_quest_panel.add_child(_quest_label)
	_refresh_quest_label()

func _refresh_quest_label():
	if not _quest_label: return
	
	if GameManager.story.get_flag("mizuki_control_phase"):
		_quest_label.text = "MỤC TIÊU: Báo cáo tình hình cho Mafuyu"
	elif not GameManager.story.get_flag("mafuyu_honami_talked"):
		_quest_label.text = "MỤC TIÊU: Nói chuyện với Mafuyu về Honami"
	elif GameManager.story.harbor_wave == 6:
		_quest_label.text = "MỤC TIÊU: Nghỉ ngơi sau nhiệm vụ"
	else:
		_quest_label.text = "MỤC TIÊU: Hoàn thành chuẩn bị cho ngày mai"
	
	_quest_panel.visible = true

# ─────────────────────────────────────────────
#  NPC SPAWNING
# ─────────────────────────────────────────────

func _spawn_npcs() -> void:
	var positions := {
		"Mafuyu": Vector2(24 * TILE_SIZE, 13 * TILE_SIZE),
		"Ena": Vector2(27 * TILE_SIZE, 15 * TILE_SIZE),
		"Kanade": Vector2(6 * TILE_SIZE, 4 * TILE_SIZE),
	}
	
	if GameManager.story.get_flag("mizuki_control_phase"):
		# Mizuki is the player, so spawn Ichika at the table (where player was)
		positions["Ichika"] = Vector2(21 * TILE_SIZE, 15 * TILE_SIZE)
	else:
		# Normal state: Mizuki is in the kitchen
		positions["Mizuki"] = Vector2(35 * TILE_SIZE, 13 * TILE_SIZE)
		
	for npc_name in positions:
		var color = NPC_COLORS.get(npc_name, Color(0.29, 0.62, 0.62)) # Default Ichika color
		_create_npc(npc_name, positions[npc_name], color)

func _create_npc(npc_name: String, pos: Vector2, color: Color) -> void:
	var root := Node2D.new()
	root.position = pos
	root.set_meta("is_npc", true) # For easy clearing
	
	var vis := ColorRect.new()
	vis.size = Vector2(16, 24)
	vis.position = Vector2(-8, -24)
	vis.color = color
	root.add_child(vis)
	
	var lbl := Label.new()
	lbl.text = npc_name
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.position = Vector2(-20, -40)
	root.add_child(lbl)
	
	var zone := InteractableZone.new()
	zone.prompt_text = "Nói chuyện với " + npc_name
	var zc := CollisionShape2D.new()
	var zs := CircleShape2D.new()
	zs.radius = 40
	zc.shape = zs
	zone.add_child(zc)
	root.add_child(zone)
	
	zone.interacted.connect(func():
		_handle_npc_interaction(npc_name)
	)
	
	var sb := StaticBody2D.new()
	sb.collision_layer = 2
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	col.shape = shape
	col.position = Vector2(0, -8)
	sb.add_child(col)
	root.add_child(sb)
	add_child(root)

func _handle_npc_interaction(npc_name: String):
	if GameManager.is_in_dialogue: return
	
	# MIZUKI CONTROL PHASE
	if GameManager.story.get_flag("mizuki_control_phase"):
		if npc_name == "Ichika":
			DialogueManager.play_dialogue(DialogueLoader.get_lines("mizuki_trash_talk_ichika"))
		elif npc_name == "Ena":
			DialogueManager.play_dialogue(DialogueLoader.get_lines("mizuki_trash_talk_ena"))
		elif npc_name == "Mafuyu":
			# XP Award
			var ichika = GameManager.get_party_member("Ichika")
			var ena = GameManager.get_party_member("Ena")
			if ichika: LevelManager.gain_exp(ichika, 3000)
			if ena: LevelManager.gain_exp(ena, 3000)
			
			DialogueManager.play_dialogue(DialogueLoader.get_lines("base_mizuki_report_p1"), func():
				GameManager.is_scripted_battle = true
				GameManager.scripted_battle_id = "mizuki_vs_mafuyu"
				GameManager.trigger_battle()
			)
		return

	# NORMAL PHASE
	if npc_name == "Mafuyu" and not GameManager.story.get_flag("mafuyu_honami_talked"):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("mafuyu_honami_info"), func():
			GameManager.story.set_flag("mafuyu_honami_talked", true)
			GameManager.story.harbor_wave = 6 # Transition to phase 2
			await ScreenFade.fade_out(1.5)
			get_tree().change_scene_to_file("res://Scenes/AlleywayMap.tscn")
		)
	elif npc_name == "Ichika":
		DialogueManager.play_dialogue([ {
			"text": "Tên đội trưởng đó... thực sự rất mạnh.",
			"type": "dialogue",
			"name": "Ichika",
			"color": Color(0.29, 0.62, 0.62)
		}])
	else:
		DialogueManager.play_dialogue([ {
			"text": "..." if npc_name == "Mafuyu" else "Mọi người mệt rồi, hãy nghỉ ngơi đi.",
			"type": "dialogue",
			"name": npc_name,
			"color": NPC_COLORS[npc_name]
		}])

func _play_report_p2():
	DialogueManager.play_dialogue(DialogueLoader.get_lines("base_mizuki_report_p2"), func():
		GameManager.story.set_flag("mizuki_control_phase", false)
		GameManager.story.set_flag("harbor_mizuki_snack_done", true)
		GameManager.story.harbor_wave = 7
		_refresh_quest_label()
	)

# ─────────────────────────────────────────────
#  MAP CONSTRUCTION (Structural Clone of BaseMap)
# ─────────────────────────────────────────────

func _build_map():
	_fill_floor(5, 2, 43, 20)
	_draw_room_walls(5, 2, 43, 10) # Rest Area
	_draw_room_walls(5, 10, 17, 20) # Office
	_draw_room_walls(17, 10, 31, 20) # Hall
	_draw_room_walls(31, 10, 43, 20) # Dining
	
	_remove_wall_at(Vector2(17, 15))
	_remove_wall_at(Vector2(31, 15))
	
	_remove_wall_at(Vector2(24, 10))
	_place_tile("door_1.png", Vector2(24, 10), false)
	_remove_wall_at(Vector2(24, 20))
	_place_tile("door_1.png", Vector2(24, 20), false)
	
	_add_room_label("Khu Nghỉ Ngơi", Vector2(24, 4))
	_add_room_label("Phòng Mafuyu", Vector2(11, 12))
	_add_room_label("Sảnh Chính", Vector2(24, 12))
	_add_room_label("Phòng Ăn", Vector2(37, 12))
	
	_place_indoor_assets()

func _place_indoor_assets():
	# Mafuyu's Room (Office)
	_place_indoor_asset("table_1.png", Vector2(13, 13), true)
	_place_indoor_asset("table_2.png", Vector2(13, 14), true)
	_place_indoor_asset("table_3.png", Vector2(13, 15), true)
	_place_indoor_asset("chair_facing_right.png", Vector2(10, 14), false)
	_place_indoor_asset("office_1.png", Vector2(6, 11), true)
	_place_indoor_asset("office_2.png", Vector2(7, 11), true)
	_place_indoor_asset("office_3.png", Vector2(8, 11), true)
	_place_indoor_asset("plant_decor_1.png", Vector2(6, 18), false)
	
	# Sảnh Chính (Meeting Hall)
	_place_indoor_asset("piano_1.png", Vector2(18, 11), true)
	_place_indoor_asset("piano_2.png", Vector2(19, 11), true)
	_place_indoor_asset("plant_decor_2.png", Vector2(30, 11), false)
	
	# Khu Nghỉ Ngơi (Rest Area)
	for y in [4, 6, 8]:
		_place_indoor_asset("green_bed_facing_right.png", Vector2(6, y), true)
		_place_indoor_asset("red_bed_facing_left.png", Vector2(42, y), true)
	_place_indoor_asset("plant_decor_2.png", Vector2(6, 3), false)
	
	# Phòng Ăn (Dining Room)
	for i in range(1, 7):
		_place_indoor_asset("kitchen_%d.png" % i, Vector2(31 + i, 11), true)
	_place_indoor_asset("plant_decor_1.png", Vector2(42, 18), false)

func _fill_floor(x1, y1, x2, y2):
	for x in range(x1, x2 + 1):
		for y in range(y1, y2 + 1):
			_place_tile("floor.png", Vector2(x, y), false)

func _draw_room_walls(x1, y1, x2, y2):
	for x in range(x1, x2 + 1):
		_place_tile("horizontal_wall.png", Vector2(x, y1), true)
		_place_tile("horizontal_wall.png", Vector2(x, y2), true)
	for y in range(y1, y2 + 1):
		_place_tile("left_vertical_wall.png", Vector2(x1, y), true)
		_place_tile("right_vertical_wall.png", Vector2(x2, y), true)
	_place_tile("top_left_wall.png", Vector2(x1, y1), true)
	_place_tile("top_right_wall.png", Vector2(x2, y1), true)
	_place_tile("bottom_left_wall.png", Vector2(x1, y2), true)
	_place_tile("bottom_right_wall.png", Vector2(x2, y2), true)

func _place_tile(file: String, grid_pos: Vector2, has_collision: bool):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load(ASSET_ROOT + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = tile_pos
	add_child(sprite)
	if has_collision:
		var body = StaticBody2D.new()
		body.position = tile_pos
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		col.shape = shape
		body.add_child(col)
		add_child(body)

func _place_indoor_asset(file: String, grid_pos: Vector2, has_collision: bool):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/Indoors/" + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = tile_pos
	add_child(sprite)
	if has_collision:
		var body = StaticBody2D.new()
		body.position = tile_pos
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		col.shape = shape
		body.add_child(col)
		add_child(body)

func _remove_wall_at(grid_pos: Vector2):
	var target_pos = grid_pos * TILE_SIZE
	for child in get_children():
		if child is Node2D:
			if child.position.distance_to(target_pos) < 1.0:
				child.queue_free()
	_place_tile("floor.png", grid_pos, false)

func _add_room_label(text: String, grid_pos: Vector2):
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.4))
	lbl.position = grid_pos * TILE_SIZE - Vector2(40, 0)
	add_child(lbl)

func _spawn_player() -> void:
	var player := OverworldPlayer.new()
	player.name = "OverworldPlayer"
	player.position = Vector2(23 * TILE_SIZE, 15 * TILE_SIZE)
	add_child(player)

func _spawn_transitions() -> void:
	pass
