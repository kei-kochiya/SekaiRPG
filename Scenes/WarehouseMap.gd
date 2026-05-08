extends Node2D

func _ready():
	ScreenFade.fade_in(0.8)
	var player = OverworldPlayer.new()
	player.name = "OverworldPlayer"
	if GameManager.last_player_position == Vector2.ZERO:
		player.position = Vector2(100, 100)
	else:
		player.position = GameManager.last_player_position
	add_child(player)
	
	# Check Win Condition
	if GameManager.warehouse_wave > 5:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_clear"), func():
			_return_to_base_with_fade()
		)
		return
	
	# Spawn dialogue triggers (Ensure it only plays ONCE per wave start)
	if GameManager.warehouse_wave == 1 and GameManager.enemies_defeated == 0:
		var intro = DialogueLoader.get_lines("warehouse_wave1_intro")
		var start = DialogueLoader.get_lines("warehouse_wave1_start")
		DialogueManager.play_dialogue(intro + start)
	elif GameManager.warehouse_wave == 3 and (GameManager.enemies_defeated % 5 == 0):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_wave3_start"))
	elif GameManager.warehouse_wave == 5 and (GameManager.enemies_defeated % 5 == 0):
		DialogueManager.play_dialogue(DialogueLoader.get_lines("warehouse_wave5_start"))
	
	_build_mission_hud()
	
	# Determine fixed spawn locations
	var spawn_points = [
		Vector2(1000, 500),
		Vector2(1400, 1200),
		Vector2(800, 1400),
		Vector2(400, 800),
		Vector2(1500, 600)
	]
	
	# Spawn ONE enemy zone representing the current wave
	if GameManager.warehouse_wave >= 1 and GameManager.warehouse_wave <= 5:
		_create_enemy_zone(spawn_points[GameManager.warehouse_wave - 1])

func _return_to_base_with_fade():
	await ScreenFade.fade_out(1.5)
	GameManager.store_map_state("res://Scenes/BaseMap.tscn", Vector2.ZERO)
	get_tree().change_scene_to_file("res://Scenes/BaseMap.tscn")

func _create_enemy_zone(pos: Vector2):
	var root = Node2D.new()
	root.position = pos
	root.add_to_group("objectives")
	
	var vis = ColorRect.new()
	vis.size = Vector2(32, 48)
	vis.position = Vector2(-16, -48)
	vis.color = Color(0.8, 0.2, 0.2) 
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

func _build_mission_hud():
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	var panel = PanelContainer.new()
	panel.position = Vector2(20, 20)
	canvas.add_child(panel)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.6)
	sb.border_width_left = 4
	sb.border_color = Color(1.0, 0.9, 0.2) # Gold/Yellow accent
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 16)
	label.text = "MỤC TIÊU: Dọn dẹp kho hàng\nTiến độ: Wave " + str(GameManager.warehouse_wave) + " / 5"
	panel.add_child(label)
