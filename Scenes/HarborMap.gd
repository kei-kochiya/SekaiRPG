extends Node2D

func _ready():
	_spawn_player()
	_spawn_interactables()
	# Brief delay to let fade-in finish or start
	await get_tree().create_timer(0.5).timeout
	_play_intro()

func _play_intro():
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_arrival"))

func _spawn_interactables():
	# Front Gate (Guards)
	if not GameManager.guards_defeated:
		var gate = InteractableZone.new()
		gate.prompt_text = "Tấn công cửa chính (Lính canh)"
		gate.position = Vector2(800, 300)
		var col1 = CollisionShape2D.new()
		var shape1 = CircleShape2D.new()
		shape1.radius = 100
		col1.shape = shape1
		gate.add_child(col1)
		
		# Visual for gate
		var vis1 = ColorRect.new()
		vis1.size = Vector2(40, 100)
		vis1.position = Vector2(-20, -50)
		vis1.color = Color(0.6, 0.2, 0.2)
		gate.add_child(vis1)
		
		gate.interacted.connect(func():
			GameManager.harbor_route = "guards"
			GameManager.store_map_state("res://Scenes/HarborMap.tscn", get_node("OverworldPlayer").global_position)
			GameManager.trigger_battle()
		)
		add_child(gate)
		gate.add_to_group("objectives")
	
	# Back Door (Boss)
	var back = InteractableZone.new()
	back.prompt_text = "Lẻn ra cửa sau (Trực tiếp gặp Boss)"
	back.position = Vector2(1200, 800)
	var col2 = CollisionShape2D.new()
	var shape2 = CircleShape2D.new()
	shape2.radius = 100
	col2.shape = shape2
	back.add_child(col2)
	
	# Visual for back door
	var vis2 = ColorRect.new()
	vis2.size = Vector2(60, 60)
	vis2.position = Vector2(-30, -30)
	vis2.color = Color(0.2, 0.2, 0.6)
	back.add_child(vis2)
	
	back.interacted.connect(func():
		GameManager.harbor_route = "boss"
		GameManager.store_map_state("res://Scenes/HarborMap.tscn", get_node("OverworldPlayer").global_position)
		GameManager.trigger_battle()
	)
	add_child(back)
	back.add_to_group("objectives")

func _spawn_player():
	var p = OverworldPlayer.new()
	p.name = "OverworldPlayer"
	p.position = Vector2(100, 300)
	add_child(p)
