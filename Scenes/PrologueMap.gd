extends Node2D

var has_triggered_intro: bool = false
var has_triggered_outro: bool = false

func _ready():

	if GameManager.prologue_phase == 0:
		_setup_phase_0()
	else:
		_setup_phase_1()

# ─────────────────────────────────────────────
#  PHASE 0: Ichika surrounded by kidnappers
# ─────────────────────────────────────────────
func _setup_phase_0():
	var player = OverworldPlayer.new()
	player.name = "OverworldPlayer"
	player.position = Vector2(500, 500)
	add_child(player)

	_create_enemy_npc(Vector2(400, 400), Color(0.8, 0.2, 0.2))
	_create_enemy_npc(Vector2(600, 400), Color(0.8, 0.2, 0.2))
	_create_enemy_npc(Vector2(500, 650), Color(0.8, 0.2, 0.2))

	# Play the Vietnamese prologue from JSON, then trigger battle
	get_tree().create_timer(0.8).timeout.connect(func():
		if has_triggered_intro:
			return
		has_triggered_intro = true

		DialogueManager.play_dialogue(DialogueLoader.get_lines("prologue_phase0"), func():
			GameManager.is_tutorial = true   # flag so Main.gd shows tutorial
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
	player.position = Vector2(100, 800)
	player.character_color = Color(0.4, 0.3, 0.5)
	add_child(player)

	_create_recruitable_npc("Ichika", Vector2(500, 500), Color(0.29, 0.62, 0.62),
		DialogueLoader.get_lines("prologue_phase1_recruit"))

	_create_dead_body(Vector2(450, 450))
	_create_dead_body(Vector2(550, 480))
	_create_dead_body(Vector2(500, 580))

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
	vis.size = Vector2(32, 48)
	vis.position = Vector2(-16, -48)
	vis.color = color
	root.add_child(vis)
	add_child(root)

func _create_recruitable_npc(npc_name: String, pos: Vector2, color: Color, lines: Array):
	var root = Node2D.new()
	root.position = pos

	var vis = ColorRect.new()
	vis.size = Vector2(32, 48)
	vis.position = Vector2(-16, -48)
	vis.color = color
	root.add_child(vis)

	var static_body = StaticBody2D.new()
	static_body.collision_layer = 2
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 16)
	col.shape = shape
	col.position = Vector2(0, -8)
	static_body.add_child(col)
	root.add_child(static_body)

	var zone = InteractableZone.new()
	var zone_col = CollisionShape2D.new()
	var zone_shape = CircleShape2D.new()
	zone_shape.radius = 60
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
	vis.size = Vector2(48, 24)
	vis.position = Vector2(-24, -12)
	vis.color = Color(0.4, 0.1, 0.1)
	root.add_child(vis)
	add_child(root)
