extends Node2D

"""
PrologueMap: Scene màn hình mở đầu của game.

Chứa 2 phase:
- Phase 0: Ichika bị bao vây bởi các kẻ cưỡp, cần chiến đấu. Mafuyu xuất hiện bên ngoài.
- Phase 1: Mafuyu đã vào sau trận, gặp Ichika đang mệt mỏi. Kết thúc chuyển về BaseMap.
"""

var has_triggered_outro: bool = false

const TILE_SIZE = MapUtils.TILE_SIZE

func _ready():
	AudioManager.play_music("map")
	_build_map()
	
	# Phase 0: Ichika bị vây, dẫn đến trận đầu với kiết tặc.
	# Phase 1: Sau trận, Mafuyu gặp và tuyển Ichika vào nhóm.
	if GameManager.get_flag("prologue_phase", 0) == 0:
		_setup_phase_0()
	else:
		_setup_phase_1()
	
	# Chờ màn hình sáng hẳn rồi mới phát hội thoại mở đầu (hộp thoại ở layer 100 sẽ bị ScreenFade layer 200 che nếu phát sớm)
	await ScreenFade.fade_in(1.0)
	if GameManager.get_flag("prologue_phase", 0) == 0:
		_play_phase_0_intro()
	else:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("prologue_phase1_intro"))

# ─────────────────────────────────────────────
#  MAP CONSTRUCTION
# ─────────────────────────────────────────────

func _build_map():
	# 0. Large Ground Background
	# Covers a wide area so it's not a black void
	MapUtils.fill_floor(self, -35, -35, 34, 34)

	# 1. Warehouse Floor (Already covered by ground, but we can re-place or skip)
	# Keeping this loop as reference for walls logic if needed.
	
	# 2. Warehouse Walls
	var w_x1 = 4
	var w_x2 = 20
	var w_y1 = 4
	var w_y2 = 16
	var door_x = 12

	for x in range(w_x1, w_x2 + 1):
		var type = "horizontal_wall.png"
		if x == w_x1: type = "top_left_wall.png"
		elif x == w_x2: type = "top_right_wall.png"
		_place_tile(type, Vector2(x, w_y1), true)
		
		# Bottom wall with door
		if x == door_x:
			_place_tile("door_1.png", Vector2(x, w_y2), false)
		else:
			var b_type = "horizontal_wall.png"
			if x == w_x1: b_type = "bottom_left_wall.png"
			elif x == w_x2: b_type = "bottom_right_wall.png"
			_place_tile(b_type, Vector2(x, w_y2), true)
			
	for y in range(w_y1 + 1, w_y2):
		_place_tile("left_vertical_wall.png", Vector2(w_x1, y), true)
		_place_tile("right_vertical_wall.png", Vector2(w_x2, y), true)

	# 3. Decor: Sword near Ichika
	_place_tile("sword.png", Vector2(11, 11), false)

	# 4. Trees around the warehouse (outside)
	var tree_spots = [
		Vector2(2, 3), Vector2(22, 5), Vector2(3, 18),
		Vector2(21, 17), Vector2(1, 10), Vector2(12, 20)
	]
	for spot in tree_spots:
		_place_tile("tree.png", spot, true)

func _place_tile(file: String, grid_pos: Vector2, has_collision: bool):
	MapUtils.place_tile(self, file, grid_pos, has_collision)

# ─────────────────────────────────────────────
#  PHASE 0: Ichika surrounded by kidnappers
# ─────────────────────────────────────────────
func _setup_phase_0():
	var player = OverworldPlayer.new()
	# Positioned inside the warehouse
	player.position = Vector2(12 * TILE_SIZE, 10 * TILE_SIZE)
	add_child(player)

	# Kidnappers surrounding Ichika (repositioned horizontally and center-back)
	_create_enemy_npc(Vector2(9 * TILE_SIZE, 9 * TILE_SIZE), "kidnapper.svg")
	_create_enemy_npc(Vector2(15 * TILE_SIZE, 9 * TILE_SIZE), "kidnapper.svg")
	_create_enemy_npc(Vector2(12 * TILE_SIZE, 7 * TILE_SIZE), "kidnapper.svg")

	# Mafuyu visible outside the door
	_create_visual_npc("Mafuyu", Vector2(12 * TILE_SIZE, 18 * TILE_SIZE), MapUtils.CHARACTER_COLORS["Mafuyu"])

# Đoạn mở đầu bị bắt cóc, xong thì vào trận hướng dẫn đầu tiên
func _play_phase_0_intro():
	# Thua trận hướng dẫn thì vào lại thẳng trận, không phát lại cả đoạn mở đầu dài
	if GameManager.get_flag("last_scripted_loss") == "prologue":
		await get_tree().create_timer(1.0, false).timeout
		GameManager.is_tutorial = true
		GameManager.start_scripted_battle("prologue", MapPaths.PROLOGUE)
		return
	DialogueManager.play_dialogue(DialogueLoader.get_lines("prologue_phase0"), func():
		GameManager.is_tutorial = true
		GameManager.start_scripted_battle("prologue", MapPaths.PROLOGUE)
	)

# ─────────────────────────────────────────────
#  PHASE 1: Mafuyu arrives after the battle
# ─────────────────────────────────────────────
func _setup_phase_1():
	GameManager.last_player_position = Vector2.ZERO
	var player = OverworldPlayer.new()
	# Mafuyu starts outside facing up towards warehouse
	player.position = Vector2(12 * TILE_SIZE, 19 * TILE_SIZE)
	player.character_color = MapUtils.CHARACTER_COLORS["Mafuyu"]
	player.set_facing("up")
	add_child(player)

	# Ichika inside, exhausted
	_create_recruitable_npc("Ichika", Vector2(12 * TILE_SIZE, 10 * TILE_SIZE), MapUtils.CHARACTER_COLORS["Ichika"],
		DialogueLoader.get_lines("prologue_phase1_recruit"))

	# Dead bodies from the fight
	_create_dead_body(Vector2(9 * TILE_SIZE, 9 * TILE_SIZE))
	_create_dead_body(Vector2(15 * TILE_SIZE, 9 * TILE_SIZE))
	_create_dead_body(Vector2(12 * TILE_SIZE, 7 * TILE_SIZE))

# ─────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────

func _create_enemy_npc(pos: Vector2, sprite_file: String):
	MapUtils.create_enemy_npc(self, pos, sprite_file)

func _create_visual_npc(_npc_name: String, pos: Vector2, color: Color):
	MapUtils.create_visual_npc(self, _npc_name, pos, color)

func _create_recruitable_npc(npc_name: String, pos: Vector2, color: Color, lines: Array):
	var root = Node2D.new()
	root.position = pos
	root.add_to_group("objectives")

	MapUtils.add_character_body(root, npc_name, color)

	MapUtils.add_static_box(root, Vector2(16, 16), Vector2.ZERO, 2, Vector2(0, -8)) # thân NPC: người chơi không đi xuyên được

	var zone = MapUtils.circle_zone(40, "Nói chuyện với " + npc_name)
	root.add_child(zone)

	zone.interacted.connect(func():
		if has_triggered_outro:
			return
		has_triggered_outro = true
		DialogueManager.play_dialogue(lines, func():
			_transition_to_safehouse()
		)
	)

	root.z_index = 2
	add_child(root)

func _transition_to_safehouse() -> void:
	await ScreenFade.fade_out(0.6)
	await get_tree().create_timer(1.0, false).timeout
	GameManager.last_player_position = Vector2.ZERO
	GameManager.store_map_state(MapPaths.BASE, Vector2.ZERO)
	get_tree().change_scene_to_file(MapPaths.BASE)

func _create_dead_body(pos: Vector2):
	var root = Node2D.new()
	root.position = pos
	var sprite = Sprite2D.new()
	sprite.texture = load("res://Assets/Person/kidnapper.svg")
	sprite.scale = Vector2(1, 1)
	sprite.rotation = PI / 2 # Rotate to look like they are lying down
	sprite.position = Vector2(0, 0)
	root.add_child(sprite)
	root.z_index = 1
	add_child(root)
