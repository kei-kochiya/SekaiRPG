extends Node2D

func _ready():
	
	var player = OverworldPlayer.new()
	player.name = "OverworldPlayer"
	if GameManager.last_player_position == Vector2.ZERO:
		player.position = Vector2(100, 100)
	else:
		player.position = GameManager.last_player_position
	add_child(player)
	
	# Check Win Condition
	if GameManager.warehouse_wave > 5:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_clear"))
		
		# Return to base trigger
		var transition_zone = InteractableZone.new()
		transition_zone.prompt_text = "Press ENTER to Return to Base"
		transition_zone.position = Vector2(300, 300)
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(150, 150)
		col.shape = rect
		transition_zone.add_child(col)
		var vis = ColorRect.new()
		vis.size = Vector2(150, 150)
		vis.position = Vector2(-75, -75)
		vis.color = Color(0.2, 0.8, 0.2, 0.4)
		transition_zone.add_child(vis)
		add_child(transition_zone)
		
		transition_zone.interacted.connect(func():
			GameManager.store_map_state("res://Scenes/BaseMap.tscn", Vector2.ZERO)
			get_tree().change_scene_to_file("res://Scenes/BaseMap.tscn")
		)
		return
	
	# Spawn dialogue triggers (Ensure it only plays ONCE per wave start)
	# enemies_remaining_in_wave = 5 means the wave JUST started
	var alive_enemies = 5 - (GameManager.enemies_defeated % 5)
	
	if alive_enemies == 5:
		if GameManager.warehouse_wave == 1 and GameManager.enemies_defeated == 0:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_wave1_start"))
		elif GameManager.warehouse_wave == 3:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_wave3_start"))
		elif GameManager.warehouse_wave == 5:
			DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_wave5_start"))
	
	# Determine fixed spawn locations so they don't jump around randomly every reload
	var spawn_points = [
		Vector2(1000, 500),
		Vector2(1400, 1200),
		Vector2(800, 1400),
		Vector2(400, 800),
		Vector2(1500, 600)
	]
	
	for i in range(alive_enemies):
		_create_enemy_zone(spawn_points[i])

func _create_enemy_zone(pos: Vector2):
	var root = Node2D.new()
	root.position = pos
	
	var vis = ColorRect.new()
	vis.size = Vector2(32, 48)
	vis.position = Vector2(-16, -48)
	vis.color = Color(0.8, 0.2, 0.2) # Generic enemy red
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
	zone.prompt_text = "Press ENTER to Engage"
	var zone_col = CollisionShape2D.new()
	var zone_shape = CircleShape2D.new()
	zone_shape.radius = 80
	zone_col.shape = zone_shape
	zone.add_child(zone_col)
	root.add_child(zone)
	
	zone.interacted.connect(func():
		var player_node = get_node("OverworldPlayer")
		if player_node:
			GameManager.store_map_state("res://Scenes/WarehouseMap.tscn", player_node.global_position)
		GameManager.trigger_battle()
	)
	
	add_child(root)
