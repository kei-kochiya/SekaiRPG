extends Node2D

# NPC definitions — position and color only
const NPC_DEFS := {
	"Mafuyu": {"pos": Vector2(100, 100), "color": Color(0.4,  0.3,  0.5)},
	"Ena":    {"pos": Vector2(500, 150), "color": Color(0.72, 0.38, 0.16)},
	"Kanade": {"pos": Vector2(300, 400), "color": Color(0.8,  0.8,  0.9)},
	"Mizuki": {"pos": Vector2(700, 300), "color": Color(0.85, 0.65, 0.8)},
}

const QUEST_NPCS := ["Mafuyu", "Ena", "Kanade", "Mizuki"]

var _quest_label: Label   # HUD hint for the intro quest

func _ready() -> void:
	# ── Background ──────────────────────────────
	_spawn_npcs()
	_spawn_player()
	_spawn_warehouse_transition()
	_build_quest_hud()

	# ── Entry logic ─────────────────────────────
	if GameManager.prologue_phase >= 1 and not GameManager.safehouse_intro_done:
		_play_safehouse_intro()
	elif not GameManager.intro_quest_done:
		_refresh_quest_label()
	else:
		_quest_label.visible = false

# ─────────────────────────────────────────────
#  SAFEHOUSE INTRO  (first time entering after prologue)
# ─────────────────────────────────────────────
func _play_safehouse_intro() -> void:
	await ScreenFade.fade_in(0.8)
	await get_tree().create_timer(0.4).timeout
	GameManager.safehouse_intro_done = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines("safehouse_intro"), func():
		_refresh_quest_label()
	)

# ─────────────────────────────────────────────
#  QUEST HUD  — "Hãy nói chuyện với…"
# ─────────────────────────────────────────────
func _build_quest_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	_quest_label = Label.new()
	_quest_label.add_theme_font_size_override("font_size", 14)
	_quest_label.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	_quest_label.position = Vector2(20, 20)
	canvas.add_child(_quest_label)

func _refresh_quest_label() -> void:
	if GameManager.intro_quest_done:
		_quest_label.visible = false
		return
	var remaining: Array = []
	for n in QUEST_NPCS:
		if n not in GameManager.npcs_greeted:
			remaining.append(n)
	_quest_label.text = "Nhiệm vụ: Làm quen với mọi người\nCòn lại: " + ", ".join(remaining)
	_quest_label.visible = true

# ─────────────────────────────────────────────
#  NPC SPAWNING
# ─────────────────────────────────────────────
func _spawn_npcs() -> void:
	for npc_name: String in NPC_DEFS:
		var def: Dictionary = NPC_DEFS[npc_name]
		_create_npc(npc_name, def["pos"], def["color"])

func _create_npc(npc_name: String, pos: Vector2, color: Color) -> void:
	var root := Node2D.new()
	root.position = pos

	var vis := ColorRect.new()
	vis.size = Vector2(32, 48)
	vis.position = Vector2(-16, -48)
	vis.color = color
	root.add_child(vis)

	var lbl := Label.new()
	lbl.text = npc_name
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.position = Vector2(-20, -64)
	root.add_child(lbl)

	var sb := StaticBody2D.new()
	sb.collision_layer = 2
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 16)
	col.shape = shape
	col.position = Vector2(0, -8)
	sb.add_child(col)
	root.add_child(sb)

	var zone := InteractableZone.new()
	zone.prompt_text = "Nói chuyện với " + npc_name
	var zc := CollisionShape2D.new()
	var zs := CircleShape2D.new()
	zs.radius = 60
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
	if GameManager.is_in_dialogue:
		return
	# Block interaction before the intro cutscene finishes
	if GameManager.prologue_phase >= 1 and not GameManager.safehouse_intro_done:
		return

	if not GameManager.intro_quest_done:
		_quest_phase_interact(npc_name)
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
		# Already greeted — short repeat
		DialogueManager.play_dialogue(DialogueLoader.get_lines(key + "_repeat"))

func _free_roam_interact(npc_name: String) -> void:
	var opts: Array = ["Xin chào.", "Hỏi thêm về " + npc_name + "."]
	if npc_name == "Kanade":
		opts.append("Nhận nhiệm vụ tiếp theo.")

	DialogueManager.show_choice(opts)
	var idx: int = await DialogueManager.choice_made

	match idx:
		0:
			DialogueManager.play_dialogue(
				DialogueLoader.get_lines("npc_hello_" + npc_name.to_lower()))
		1:
			DialogueManager.play_dialogue(
				DialogueLoader.get_lines("npc_info_" + npc_name.to_lower()))
		2:
			_start_warehouse_mission()

func _check_quest_complete() -> void:
	for n in QUEST_NPCS:
		if n not in GameManager.npcs_greeted:
			return
	GameManager.intro_quest_done = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines("quest_intro_complete"))

func _start_warehouse_mission() -> void:
	DialogueManager.play_dialogue(DialogueLoader.get_lines("kanade_mission"), func():
		GameManager.store_map_state("res://Scenes/WarehouseMap.tscn", Vector2.ZERO)
		get_tree().change_scene_to_file("res://Scenes/WarehouseMap.tscn")
	)

# ─────────────────────────────────────────────
#  PLAYER & SCENE HELPERS
# ─────────────────────────────────────────────
func _spawn_player() -> void:
	var player := OverworldPlayer.new()
	player.name = "OverworldPlayer"
	player.position = Vector2(200, 200) if GameManager.last_player_position == Vector2.ZERO \
		else GameManager.last_player_position
	add_child(player)

func _spawn_warehouse_transition() -> void:
	# Only show after intro quest is complete
	if not GameManager.intro_quest_done:
		return
	var tz := InteractableZone.new()
	tz.prompt_text = "Đến kho hàng"
	tz.position = Vector2(800, 800)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(100, 100)
	col.shape = rect
	tz.add_child(col)
	var vis := ColorRect.new()
	vis.size = Vector2(100, 100)
	vis.position = Vector2(-50, -50)
	vis.color = Color(1, 1, 0, 0.3)
	tz.add_child(vis)
	add_child(tz)
	tz.interacted.connect(func():
		GameManager.store_map_state("res://Scenes/WarehouseMap.tscn", Vector2.ZERO)
		get_tree().change_scene_to_file("res://Scenes/WarehouseMap.tscn")
	)
