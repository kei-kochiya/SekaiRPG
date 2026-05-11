extends Node2D

const TILE_SIZE = 32
const ASSET_ROOT = "res://Assets/kenney_micro-roguelike/Tiles/"

const NPC_COLORS := {
	"Mafuyu": Color(0.4,  0.3,  0.5),
	"Ena":    Color(0.72, 0.38, 0.16),
	"Kanade": Color(0.8,  0.8,  0.9),
	"Mizuki": Color(0.85, 0.65, 0.8),
}

const QUEST_NPCS := ["Mafuyu", "Ena", "Kanade", "Mizuki"]

var _quest_label: Label
var _quest_panel: PanelContainer

func _ready() -> void:
	AudioManager.play_music("base")
	ScreenFade.fade_in(0.8)
	
	_build_map()
	_spawn_npcs()
	_spawn_player()
	_spawn_transitions()
	_build_quest_hud()

	if not GameManager.safehouse_intro_done:
		_play_safehouse_intro()
	else:
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
	sprite.texture = load("res://Assets/Indoors/" + file)
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
		"Mafuyu": Vector2(10 * TILE_SIZE, 14 * TILE_SIZE),
		"Kanade": Vector2(24 * TILE_SIZE, 15 * TILE_SIZE),
		"Ena":    Vector2(28 * TILE_SIZE, 13 * TILE_SIZE),
		"Mizuki": Vector2(24 * TILE_SIZE, 12 * TILE_SIZE),
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
		_handle_npc_interaction(npc_name)
	)
	add_child(root)

# ─────────────────────────────────────────────
#  INTERACTION LOGIC
# ─────────────────────────────────────────────
func _handle_npc_interaction(npc_name: String) -> void:
	if GameManager.is_in_dialogue: return
	if GameManager.prologue_phase >= 1 and not GameManager.safehouse_intro_done: return
	
	if not GameManager.intro_quest_done:
		_quest_phase_interact(npc_name)
	elif not GameManager.warehouse_mission_accepted:
		_mission_briefing_interact(npc_name)
	else:
		_free_roam_interact(npc_name)

func _quest_phase_interact(npc_name: String) -> void:
	var key := "safehouse_meet_" + npc_name.to_lower()
	if npc_name not in GameManager.npcs_greeted:
		GameManager.npcs_greeted.append(npc_name)
		DialogueManager.play_dialogue(DialogueLoader.get_lines(key), func():
			_refresh_quest_label()
			_check_quest_complete()
		)
	else:
		DialogueManager.play_dialogue(DialogueLoader.get_lines(key + "_repeat"))

func _mission_briefing_interact(npc_name: String) -> void:
	if npc_name == "Kanade":
		_start_warehouse_mission_sequence()
	else:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("npc_hello_" + npc_name.to_lower()))

func _free_roam_interact(npc_name: String) -> void:
	var opts: Array = ["Xin chào.", "Hỏi thêm về " + npc_name + "."]
	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made
	match idx:
		0: DialogueManager.play_dialogue(DialogueLoader.get_lines("npc_hello_" + npc_name.to_lower()))
		1: DialogueManager.play_dialogue(DialogueLoader.get_lines("npc_info_" + npc_name.to_lower()))

func _check_quest_complete() -> void:
	for n in QUEST_NPCS:
		if n not in GameManager.npcs_greeted: return
	GameManager.intro_quest_done = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines("quest_intro_complete"), func():
		_refresh_quest_label()
	)

func _start_warehouse_mission_sequence() -> void:
	DialogueManager.play_dialogue(DialogueLoader.get_lines("kanade_mission"), func():
		GameManager.warehouse_mission_accepted = true
		_refresh_quest_label()
	)

# ─────────────────────────────────────────────
#  QUEST HUD
# ─────────────────────────────────────────────
func _build_quest_hud() -> void:
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

func _refresh_quest_label() -> void:
	if not _quest_label: return
	
	if not GameManager.intro_quest_done:
		var remaining: Array = []
		for n in QUEST_NPCS:
			if n not in GameManager.npcs_greeted: remaining.append(n)
		_quest_label.text = "MỤC TIÊU: Làm quen với mọi người\nCòn lại: " + ", ".join(remaining)
	elif not GameManager.warehouse_mission_accepted:
		_quest_label.text = "MỤC TIÊU: Nói chuyện với Kanade để nhận nhiệm vụ"
	else:
		_quest_label.text = "MỤC TIÊU: Rời khỏi nhà để bắt đầu nhiệm vụ\n(Có thể nói chuyện thêm với mọi người)"
	
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
		if GameManager.warehouse_mission_accepted:
			await ScreenFade.fade_out(1.0)
			GameManager.reset_mission_stats()
			GameManager.store_map_state("res://Scenes/WarehouseMap.tscn", Vector2.ZERO)
			get_tree().change_scene_to_file("res://Scenes/WarehouseMap.tscn")
		else:
			# Fix crash by using correct dictionary format
			DialogueManager.play_dialogue([{
				"text": "Bên ngoài hiện tại quá nguy hiểm. Hãy nói chuyện với mọi người trước.",
				"type": "narrator"
			}])
	)

func _play_safehouse_intro() -> void:
	GameManager.safehouse_intro_done = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines("safehouse_intro"), func():
		_refresh_quest_label()
	)
