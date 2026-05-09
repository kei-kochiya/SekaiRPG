extends Node2D

var has_triggered_intro: bool = false
var has_triggered_outro: bool = false

const TILE_SIZE = 32 # 8x8 tiles scaled 4x
const ASSET_ROOT = "res://Assets/kenney_micro-roguelike/Tiles/"

func _ready():
	ScreenFade.fade_in(1.0)
	_build_map()
	
	if GameManager.prologue_phase == 0:
		_setup_phase_0()
	else:
		_setup_phase_1()

# ─────────────────────────────────────────────
#  MAP CONSTRUCTION
# ─────────────────────────────────────────────

func _build_map():
	# 1. Warehouse Floor (Center of the map)
	# Grid: 6 to 14 wide, 6 to 12 deep
	for x in range(6, 15):
		for y in range(6, 13):
			_place_tile("floor.png", Vector2(x, y), false)
	
	# 2. Warehouse Walls
	for x in range(6, 15):
		var type = "horizontal_wall.png"
		if x == 6: type = "top_left_wall.png"
		elif x == 14: type = "top_right_wall.png"
		_place_tile(type, Vector2(x, 6), true)
		
		# Bottom wall with door
		if x == 10:
			_place_tile("door_1.png", Vector2(x, 12), false)
		else:
			var b_type = "horizontal_wall.png"
			if x == 6: b_type = "bottom_left_wall.png"
			elif x == 14: b_type = "bottom_right_wall.png"
			_place_tile(b_type, Vector2(x, 12), true)
			
	for y in range(7, 12):
		_place_tile("left_vertical_wall.png", Vector2(6, y), true)
		_place_tile("right_vertical_wall.png", Vector2(14, y), true)

	# 3. Decor: Sword near Ichika
	_place_tile("sword.png", Vector2(9, 9), false)

	# 4. Trees around the warehouse (outside)
	var tree_spots = [
		Vector2(4, 5), Vector2(16, 7), Vector2(5, 14), 
		Vector2(15, 13), Vector2(3, 10), Vector2(12, 15)
	]
	for spot in tree_spots:
		_place_tile("tree.png", spot, true)

func _place_tile(file: String, grid_pos: Vector2, has_collision: bool):
	var sprite = Sprite2D.new()
	sprite.texture = load(ASSET_ROOT + file)
	sprite.scale = Vector2(4, 4) # 8x4 = 32
	sprite.position = grid_pos * TILE_SIZE
	add_child(sprite)
	
	if has_collision:
		var body = StaticBody2D.new()
		body.position = sprite.position
		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(TILE_SIZE, TILE_SIZE)
		col.shape = shape
		body.add_child(col)
		add_child(body)

# ─────────────────────────────────────────────
#  PHASE 0: Ichika surrounded by kidnappers
# ─────────────────────────────────────────────
func _setup_phase_0():
	var player = OverworldPlayer.new()
	player.name = "OverworldPlayer"
	# Positioned inside the warehouse
	player.position = Vector2(10 * TILE_SIZE, 8 * TILE_SIZE) 
	add_child(player)

	# Kidnappers surrounding Ichika
	_create_enemy_npc(Vector2(9 * TILE_SIZE, 7 * TILE_SIZE), Color(0.8, 0.2, 0.2))
	_create_enemy_npc(Vector2(11 * TILE_SIZE, 7 * TILE_SIZE), Color(0.8, 0.2, 0.2))
	_create_enemy_npc(Vector2(10 * TILE_SIZE, 10 * TILE_SIZE), Color(0.8, 0.2, 0.2))

	# Mafuyu visible outside the door
	_create_visual_npc("Mafuyu", Vector2(10 * TILE_SIZE, 14 * TILE_SIZE), Color(0.4, 0.3, 0.5))

	get_tree().create_timer(0.8).timeout.connect(func():
		if has_triggered_intro:
			return
		has_triggered_intro = true

		DialogueManager.play_dialogue(DialogueLoader.get_lines("prologue_phase0"), func():
			GameManager.is_tutorial = true
			GameManager.store_map_state("res://Scenes/PrologueMap.tscn", Vector2.ZERO)
			GameManager.trigger_battle()
		)
	)

# ─────────────────────────────────────────────
#  PHASE 1: Mafuyu arrives after the battle
# ─────────────────────────────────────────────
func _setup_phase_1():
	var player = OverworldPlayer.new()
	player.name = "OverworldPlayer"
	# Mafuyu starts outside
	player.position = Vector2(10 * TILE_SIZE, 15 * TILE_SIZE)
	player.character_color = Color(0.4, 0.3, 0.5)
	add_child(player)

	# Ichika inside, exhausted
	_create_recruitable_npc("Ichika", Vector2(10 * TILE_SIZE, 8 * TILE_SIZE), Color(0.29, 0.62, 0.62),
		DialogueLoader.get_lines("prologue_phase1_recruit"))

	# Dead bodies from the fight
	_create_dead_body(Vector2(9 * TILE_SIZE, 7 * TILE_SIZE))
	_create_dead_body(Vector2(11 * TILE_SIZE, 7 * TILE_SIZE))
	_create_dead_body(Vector2(10 * TILE_SIZE, 10 * TILE_SIZE))

	get_tree().create_timer(0.8).timeout.connect(func():
		DialogueManager.play_dialogue(DialogueLoader.get_lines("prologue_phase1_intro"))
	)

# ─────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────

func _create_enemy_npc(pos: Vector2, color: Color):
	var root = Node2D.new()
	root.position = pos
	var vis = ColorRect.new()
	vis.size = Vector2(16, 24)
	vis.position = Vector2(-8, -24)
	vis.color = color
	root.add_child(vis)
	add_child(root)

func _create_visual_npc(_npc_name: String, pos: Vector2, color: Color):
	var root = Node2D.new()
	root.position = pos
	var vis = ColorRect.new()
	vis.size = Vector2(16, 24)
	vis.position = Vector2(-8, -24)
	vis.color = color
	root.add_child(vis)
	add_child(root)

func _create_recruitable_npc(_npc_name: String, pos: Vector2, color: Color, lines: Array):
	var root = Node2D.new()
	root.position = pos

	var vis = ColorRect.new()
	vis.size = Vector2(16, 24)
	vis.position = Vector2(-8, -24)
	vis.color = color
	root.add_child(vis)

	var static_body = StaticBody2D.new()
	static_body.collision_layer = 2
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	col.shape = shape
	col.position = Vector2(0, -8)
	static_body.add_child(col)
	root.add_child(static_body)

	var zone = InteractableZone.new()
	var zone_col = CollisionShape2D.new()
	var zone_shape = CircleShape2D.new()
	zone_shape.radius = 40
	zone_col.shape = zone_shape
	zone.add_child(zone_col)
	root.add_child(zone)

	zone.interacted.connect(func():
		if has_triggered_outro:
			return
		has_triggered_outro = true
		DialogueManager.play_dialogue(lines, func():
			_transition_to_safehouse()
		)
	)

	add_child(root)

func _transition_to_safehouse() -> void:
	await ScreenFade.fade_out(0.6)
	await get_tree().create_timer(1.0).timeout
	GameManager.store_map_state("res://Scenes/BaseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Scenes/BaseMap.tscn")

func _create_dead_body(pos: Vector2):
	var root = Node2D.new()
	root.position = pos
	var vis = ColorRect.new()
	vis.size = Vector2(24, 12)
	vis.position = Vector2(-12, -6)
	vis.color = Color(0.4, 0.1, 0.1)
	root.add_child(vis)
	add_child(root)
