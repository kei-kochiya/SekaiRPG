extends Node2D

const TILE_SIZE = 32
const ASSET_ROOT = "res://Assets/kenney_micro-roguelike/Tiles/"

const NPC_COLORS := {
	"Mafuyu": Color(0.4,  0.3,  0.5),
	"Ena":    Color(0.72, 0.38, 0.16),
	"Kanade": Color(0.8,  0.8,  0.9),
	"Mizuki": Color(0.85, 0.65, 0.8),
}

var _lighting: CanvasModulate
var _quest_label: Label
var _quest_panel: PanelContainer

func _ready() -> void:
	_lighting = CanvasModulate.new()
	add_child(_lighting)
	_lighting.color = Color.WHITE

	ScreenFade.fade_in(0.8)
	
	_build_map()
	_spawn_npcs()
	_spawn_player()
	_spawn_transitions()
	_build_quest_hud()

	if not GameManager.harbor_mission_unlocked:
		_play_post_warehouse_sequence()
	else:
		AudioManager.play_music("base")
		_refresh_quest_label()

# ─────────────────────────────────────────────
#  MAP CONSTRUCTION
# ─────────────────────────────────────────────

func _build_map():
	# 1. Floors
	_fill_floor(5, 2, 43, 20)
	
	# 2. Rooms
	_draw_room_walls(5, 2, 43, 10)   # Rest Area
	_draw_room_walls(5, 10, 17, 20)  # Office
	_draw_room_walls(17, 10, 31, 20) # Hall
	_draw_room_walls(31, 10, 43, 20) # Dining
	
	# 3. Openings
	_remove_wall_at(Vector2(17, 15))
	_remove_wall_at(Vector2(31, 15))
	
	# 4. Doors
	_remove_wall_at(Vector2(24, 10))
	_place_tile("door_1.png", Vector2(24, 10), false)
	_remove_wall_at(Vector2(24, 20))
	_place_tile("door_1.png", Vector2(24, 20), false)
	
	# 5. Room Labels
	_add_room_label("Khu Nghỉ Ngơi", Vector2(24, 4))
	_add_room_label("Phòng Mafuyu", Vector2(11, 12))
	_add_room_label("Sảnh Chính", Vector2(24, 12))
	_add_room_label("Phòng Ăn", Vector2(37, 12))
	
	# 6. Decor
	_place_tile("dining_table.png", Vector2(37, 15), true)
	_place_tile("dining_seat.png", Vector2(36, 15), false)
	_place_tile("dining_seat.png", Vector2(38, 15), false)
	
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
		body.name = "Body_" + str(grid_pos.x) + "_" + str(grid_pos.y)
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		col.shape = shape
		body.add_child(col)
		add_child(body)

func _place_indoor_asset(file: String, grid_pos: Vector2, has_collision: bool):
	var tile_pos = grid_pos * TILE_SIZE
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/indoors/" + file)
	sprite.scale = Vector2(4, 4)
	sprite.position = tile_pos
	add_child(sprite)
	if has_collision:
		var body = StaticBody2D.new()
		body.position = tile_pos
		body.name = "Indoor_" + file.get_basename() + "_" + str(grid_pos.x) + "_" + str(grid_pos.y)
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

# ─────────────────────────────────────────────
#  NPC SPAWNING
# ─────────────────────────────────────────────

func _spawn_npcs() -> void:
	var positions := {
		"Mafuyu": Vector2(10 * TILE_SIZE, 14 * TILE_SIZE),   # Office
		"Ena":    Vector2(35 * TILE_SIZE, 15 * TILE_SIZE),  # Dining Room
		"Mizuki": Vector2(39 * TILE_SIZE, 15 * TILE_SIZE),  # Dining Room
		"Kanade": Vector2(24 * TILE_SIZE, 15 * TILE_SIZE),  # Main Hall
	}
	for npc_name in positions:
		_create_npc(npc_name, positions[npc_name], NPC_COLORS[npc_name])

func _create_npc(npc_name: String, pos: Vector2, color: Color) -> void:
	var root := Node2D.new()
	root.position = pos
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
	var sb := StaticBody2D.new()
	sb.collision_layer = 2
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	col.shape = shape
	col.position = Vector2(0, -8)
	sb.add_child(col)
	root.add_child(sb)
	var zone := InteractableZone.new()
	zone.prompt_text = "Nói chuyện với " + npc_name
	var zc := CollisionShape2D.new()
	var zs := CircleShape2D.new()
	zs.radius = 40
	zc.shape = zs
	zone.add_child(zc)
	root.add_child(zone)
	zone.interacted.connect(func():
		_handle_interaction(npc_name)
	)
	add_child(root)

func _handle_interaction(npc_name: String):
	if GameManager.is_in_dialogue: return
	
	if npc_name == "Kanade":
		_handle_kanade_interaction()
	elif npc_name == "Mafuyu":
		_handle_mafuyu_interaction()
	elif npc_name == "Ena":
		_handle_ena_interaction()
	else:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("npc_hello_" + npc_name.to_lower()))

func _handle_kanade_interaction():
	var opts: Array = ["Xin chào.", "Nâng cấp chỉ số."]
	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	if idx == 0:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("npc_hello_kanade"))
	else:
		var p_list: Array[Entity] = [
			GameManager.get_party_member("Ichika"),
			GameManager.get_party_member("Kanade"),
			GameManager.get_party_member("Mafuyu"),
			GameManager.get_party_member("Ena"),
			GameManager.get_party_member("Mizuki")
		]
		UpgradeUI.show_ui(p_list)

func _handle_mafuyu_interaction():
	if not GameManager.talked_to_mafuyu_training:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("mafuyu_training_intro"), func():
			GameManager.talked_to_mafuyu_training = true
			_refresh_quest_label()
			_show_training_options()
		)
	else:
		if GameManager.training_ichika_done and GameManager.training_kanade_done:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("mafuyu_training_limit"))
		else:
			_show_training_options()

func _show_training_options():
	var opts: Array = []
	if not GameManager.training_ichika_done: opts.append("Ichika (5 Waves)")
	if not GameManager.training_kanade_done: opts.append("Kanade (5 Waves)")
	if not GameManager.training_ichika_done and not GameManager.training_kanade_done:
		opts.append("Cả hai (10 Waves)")
	opts.append("Để sau.")
	
	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	
	var choice_text = opts[idx]
	if choice_text == "Để sau.": return
	
	GameManager.training_used_opponents.clear()
	GameManager.is_training_mode = true
	GameManager.warehouse_wave = 1
	GameManager.reset_mission_stats()
	
	if choice_text == "Ichika (5 Waves)":
		GameManager.training_participants = ["Ichika"]
	elif choice_text == "Kanade (5 Waves)":
		GameManager.training_participants = ["Kanade"]
	else:
		GameManager.training_participants = ["Ichika", "Kanade"]
		
	await ScreenFade.fade_out(1.0)
	GameManager.store_map_state("res://Scenes/TrainingWarehouseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Scenes/TrainingWarehouseMap.tscn")

func _handle_ena_interaction():
	if not GameManager.accepted_harbor_mission:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_mission_assignment"), func():
			GameManager.accepted_harbor_mission = true
			_refresh_quest_label()
		)
	else:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("npc_hello_ena"))

# ─────────────────────────────────────────────
#  POST WAREHOUSE SEQUENCE
# ─────────────────────────────────────────────

func _play_post_warehouse_sequence():
	_lighting.color = Color(0.4, 0.4, 0.6)
	AudioManager.play_music("after_warehouse")
	DialogueManager.play_dialogue(DialogueLoader.get_lines("post_warehouse_rest"), func():
		await ScreenFade.fade_out(1.5)
		await get_tree().create_timer(1.0).timeout
		_lighting.color = Color.WHITE
		AudioManager.play_music("base")
		await ScreenFade.fade_in(1.0)
		DialogueManager.play_dialogue(DialogueLoader.get_lines("post_warehouse_morning"), func():
			GameManager.harbor_mission_unlocked = true # This just marks the phase
			DialogueManager.play_dialogue(DialogueLoader.get_lines("kanade_upgrade_intro"), func():
				_refresh_quest_label()
			)
		)
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
	sb.border_color = Color(0.4, 0.7, 1.0)
	sb.set_content_margin_all(10)
	_quest_panel.add_theme_stylebox_override("panel", sb)
	_quest_label = Label.new()
	_quest_label.add_theme_font_size_override("font_size", 16)
	_quest_panel.add_child(_quest_label)
	_refresh_quest_label()

func _refresh_quest_label():
	if not _quest_label: return
	
	var tasks: Array = []
	if not GameManager.talked_to_mafuyu_training:
		tasks.append("- Nói chuyện với Mafuyu về chuyện luyện tập.")
	if not GameManager.accepted_harbor_mission:
		tasks.append("- Gặp Ena để nhận nhiệm vụ tiếp theo.")
	
	if tasks.is_empty():
		_quest_label.text = "MỤC TIÊU: Rời khỏi nhà để đến bến cảng.\n(Có thể luyện tập thêm tại Mafuyu)"
	else:
		_quest_label.text = "MỤC TIÊU:\n" + "\n".join(tasks)
	
	_quest_panel.visible = true

# ─────────────────────────────────────────────
#  PLAYER & SCENE HELPERS
# ─────────────────────────────────────────────
func _spawn_player() -> void:
	var player := OverworldPlayer.new()
	player.name = "OverworldPlayer"
	player.position = Vector2(24 * TILE_SIZE, 18 * TILE_SIZE) if GameManager.last_player_position == Vector2.ZERO \
		else GameManager.last_player_position
	add_child(player)

func _spawn_transitions() -> void:
	var exit := InteractableZone.new()
	exit.prompt_text = "Rời khỏi nhà"
	exit.position = Vector2(24 * TILE_SIZE, 21 * TILE_SIZE)
	var ecol := CollisionShape2D.new()
	var erect := RectangleShape2D.new()
	erect.size = Vector2(64, 32)
	ecol.shape = erect
	exit.add_child(ecol)
	add_child(exit)
	exit.interacted.connect(func():
		if GameManager.talked_to_mafuyu_training and GameManager.accepted_harbor_mission:
			await ScreenFade.fade_out(1.0)
			GameManager.harbor_wave = 1
			GameManager.store_map_state("res://Scenes/HarborMap.tscn", Vector2.ZERO)
			get_tree().change_scene_to_file("res://Scenes/HarborMap.tscn")
		else:
			DialogueManager.play_dialogue([{
				"text": "Bạn cần hoàn thành các chuẩn bị trước khi rời đi (Nói chuyện với Mafuyu và Ena).",
				"type": "narrator"
			}])
	)
