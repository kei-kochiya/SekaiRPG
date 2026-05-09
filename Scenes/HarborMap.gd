extends Node2D

func _ready():
	ScreenFade.fade_in(0.8)
	_spawn_player()
	_spawn_interactables()
	
	if not GameManager.harbor_intro_done:
		# Brief delay to let fade-in finish
		await get_tree().create_timer(0.5).timeout
		_play_intro()

func _play_intro():
	GameManager.harbor_intro_done = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_arrival"))

func _spawn_interactables():
	# Front Gate Route: 3 Waves
	if GameManager.harbor_route == "guards" or GameManager.harbor_route == "":
		if GameManager.harbor_wave <= 3:
			var wave_positions = [
				Vector2(400, 350), # Wave 1
				Vector2(700, 350), # Wave 2
				Vector2(1000, 350) # Wave 3
			]
			_create_trigger(wave_positions[GameManager.harbor_wave - 1], "Đội Tuần Tra (Wave " + str(GameManager.harbor_wave) + ")", "guards")
		else:
			_create_trigger(Vector2(1400, 350), "Đội Trưởng (BOSS)", "guards")
	
	# Back Door Route: Direct to Boss
	if GameManager.harbor_route == "boss" or GameManager.harbor_route == "":
		_create_trigger(Vector2(600, 800), "Đường Vòng (BOSS)", "boss")

func _create_trigger(pos: Vector2, label: String, route: String):
	var root = Node2D.new()
	root.position = pos
	
	var vis = ColorRect.new()
	vis.size = Vector2(32, 48)
	vis.position = Vector2(-16, -48)
	vis.color = Color(0.8, 0.2, 0.2) if route == "guards" else Color(0.2, 0.2, 0.8)
	root.add_child(vis)
	
	var lbl = Label.new()
	lbl.text = label
	lbl.position = Vector2(-40, -70)
	root.add_child(lbl)
	
	var zone = InteractableZone.new()
	zone.prompt_text = "Nhấn ENTER để chiến đấu"
	var col = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 60
	col.shape = shape
	zone.add_child(col)
	root.add_child(zone)
	
	zone.interacted.connect(func():
		GameManager.harbor_route = route
		GameManager.store_map_state("res://Scenes/HarborMap.tscn", get_node("OverworldPlayer").global_position)
		GameManager.trigger_battle()
	)
	
	add_child(root)

func _spawn_player():
	var p = OverworldPlayer.new()
	p.name = "OverworldPlayer"
	if GameManager.last_player_position == Vector2.ZERO:
		p.position = Vector2(100, 350)
	else:
		p.position = GameManager.last_player_position
	add_child(p)
