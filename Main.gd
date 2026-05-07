extends Node2D

## BattleManager: drives the turn-based battle loop.
## Creates teams, builds HUD, runs turns via coroutine with await.

var player_team: Array = []
var enemy_team: Array = []
var all_entities: Array = []
var timeline: Array = []
var battle_over: bool = false

var hud: BattleHUD
var shaker: ScreenShake

func _ready():
	# --- Setup teams ---
	var ichika = Ichika.new()
	var mafuyu = Mafuyu.new()
	var ena = Ena.new()
	var kanade = Kanade.new()
	LevelManager.set_initial_level(kanade, 5)
	
	if GameManager.prologue_phase == 0:
		# Prologue: Ichika vs 3 generic Kidnappers
		player_team = [ichika]
		enemy_team = []
		for i in range(3):
			var k = Entity.new()
			k.entity_name = "Kidnapper " + str(i+1)
			k.max_hp = 80
			k.current_hp = 80
			k.atk = 40
			k.defense = 20
			k.spd = 80
			k.type = "None"
			k.skills = [{"name": "Shank", "method": "basic_attack", "cooldown_turns": 1}]
			enemy_team.append(k)
	else:
		if GameManager.current_map_file == "res://Scenes/WarehouseMap.tscn":
			player_team = [ichika, kanade]
			enemy_team = []
			for i in range(5):
				var e = Entity.new()
				e.entity_name = "Target " + str(i+1)
				e.max_hp = 100
				e.current_hp = 100
				e.atk = 45
				e.defense = 25
				e.spd = 90 + i * 2
				e.type = "None"
				enemy_team.append(e)
		else:
			# Standard testing fallback layout if ever loaded directly
			player_team = [ichika, mafuyu]
			enemy_team = [ena, kanade]
		
	all_entities = player_team + enemy_team
	
	# --- Setup context and initial cooldowns ---
	for e in player_team:
		e.allies = player_team
		e.enemies = enemy_team
	for e in enemy_team:
		e.allies = enemy_team
		e.enemies = player_team
		
	for e in all_entities:
		for s in e.skills:
			if s.has("initial_cooldown"):
				e.cooldowns[s["method"]] = s["initial_cooldown"]
				
	# --- Build HUD ---
	hud = BattleHUD.new()
	add_child(hud)
	hud.build(player_team, enemy_team)
	
	# Tell the gauge which names are player-side
	var player_names: Array[String] = []
	for e in player_team:
		player_names.append(e.entity_name)
	hud.action_gauge.set_player_names(player_names)
	
	# --- Screen shake node ---
	shaker = ScreenShake.new()
	add_child(shaker)
	
	# --- Wire died signals to clean timeline ---
	for entity in all_entities:
		entity.died.connect(_on_entity_died.bind(entity))
	
	# --- Start battle ---
	run_battle()

func _build_tutorial_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.96)
	style.border_color = Color(0.4, 0.6, 0.9)
	style.set_border_width_all(2)
	style.corner_radius_top_left    = 6
	style.corner_radius_top_right   = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)

	var canvas := CanvasLayer.new()
	canvas.layer = 90
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left   = -320
	panel.offset_right  =  320
	panel.offset_top    = -220
	panel.offset_bottom =  220

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)
	canvas.add_child(panel)
	add_child(canvas)
	return panel

func _show_tutorial_step(vbox: VBoxContainer, title: String, body: String) -> void:
	# Clear previous content
	for c in vbox.get_children():
		c.queue_free()
	await get_tree().process_frame

	var lbl_title := Label.new()
	lbl_title.text = title
	lbl_title.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
	lbl_title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(lbl_title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var lbl_body := RichTextLabel.new()
	lbl_body.bbcode_enabled = true
	lbl_body.text = body
	lbl_body.fit_content = true
	lbl_body.add_theme_font_size_override("normal_font_size", 17)
	vbox.add_child(lbl_body)

	var hint := Label.new()
	hint.text = "[ Nhấn ENTER để tiếp tục ]"
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.add_theme_font_size_override("font_size", 13)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(hint)

	await get_tree().create_timer(0.3).timeout
	await _wait_for_accept()

func _wait_for_accept() -> void:
	while not Input.is_action_just_pressed("ui_accept"):
		await get_tree().process_frame

func _run_tutorial() -> void:
	GameManager.is_tutorial = false   # Only show once

	var panel := _build_tutorial_panel()
	var vbox  := panel.get_child(0) as VBoxContainer

	var steps := [
		["⚔️  Hướng dẫn chiến đấu (1/5)",
		 "Chào mừng đến với màn hình chiến đấu lượt theo lượt!\n\nBạn điều khiển [color=#4a9e9e]Ichika[/color]. Mỗi nhân vật hành động theo thứ tự dựa trên [color=#ffdd77]chỉ số Tốc độ (SPD)[/color]."],
		["📊  Thanh hành động (2/5)",
		 "[color=#ffdd77]Action Gauge[/color] ở góc màn hình hiển thị thứ tự lượt của tất cả nhân vật.\n\n• Màu [color=#88ccff]xanh[/color] = đồng đội\n• Màu [color=#ff7777]đỏ[/color] = kẻ địch"],
		["🗡️  Lệnh tấn công (3/5)",
		 "Khi đến lượt bạn, [color=#aaffaa]menu lệnh[/color] sẽ hiện ra.\n\n• [color=#ffffff]Attack[/color] — Đòn thường, không hồi chiêu.\n• [color=#ffaaff]Skill[/color] — Kỹ năng đặc biệt, có thể có hồi chiêu."],
		["💀  Kỹ năng: Shadow Blade (4/5)",
		 "[color=#cc88ff]Shadow Blade[/color] là kỹ năng chủ lực của Ichika.\n\nGây sát thương cao và hút máu một phần. Chỉ dùng được [color=#ffdd77]1 lần mỗi trận[/color]. Dùng đúng lúc!"],
		["✅  Sẵn sàng chiến đấu (5/5)",
		 "Chọn lệnh rồi chọn mục tiêu để hành động.\n\nHãy tiêu diệt tất cả kẻ địch để [color=#aaffaa]chiến thắng[/color]. Nếu toàn bộ đồng đội bị hạ, bạn [color=#ff7777]thua[/color].\n\nChúc may mắn, [color=#4a9e9e]Ichika[/color]!"]
	]

	for step in steps:
		await _show_tutorial_step(vbox, step[0], step[1])

	panel.get_parent().queue_free()   # Remove the CanvasLayer+panel

# ===========================================================================
# Battle Loop (coroutine)
# ===========================================================================

func run_battle():
	# Generate initial turn queue (larger pool so we don't run out fast)
	_regenerate_timeline()
	
	print("=== TRẬN CHIẾN BẮT ĐẦU ===")
	print("Đội Player: ", _names(player_team))
	print("Đội Enemy:  ", _names(enemy_team))
	print("")
	
	while not battle_over:
		# Refill timeline when it runs out
		if timeline.is_empty():
			_regenerate_timeline()
			if timeline.is_empty():
				break
		
		# Pop next turn from the queue
		var turn = timeline.pop_front()
		var actor = _get_entity(turn["name"])
		
		# Skip dead or missing actors
		if actor == null or actor.current_hp <= 0:
			continue
		
		print("--- Lượt của: ", actor.entity_name, " ---")
		
		# Show turn indicator
		var is_player_turn = actor in player_team
		hud.show_turn_indicator(actor.entity_name, is_player_turn)
		
		# Update gauge display (show remaining queue, don't regenerate)
		_update_gauge_display()
		
		# Process status effects at turn start
		var can_act = ProcessStatus.handle_turn_start(actor)
		CooldownManager.process_cooldowns(actor)
		
		if not can_act:
			print(actor.entity_name, " bị bỏ qua lượt!")
			await get_tree().create_timer(0.8).timeout
			continue
		
		if _check_battle_end():
			break
		
		# --- Player turn or AI turn ---
		if is_player_turn:
			await _player_turn(actor)
		else:
			await _ai_turn(actor)
		
		# Update gauge after action (dead entities removed by _on_entity_died)
		_update_gauge_display()
		
		if _check_battle_end():
			break
		
		# Brief pause between turns
		await get_tree().create_timer(0.4).timeout
	
	# Hide turn indicator when battle ends
	hud.hide_turn_indicator()
	
	# Transition back to Overworld
	await get_tree().create_timer(2.0).timeout
	var is_victory = TargetingManager.get_alive_targets(enemy_team).is_empty()
	
	if is_victory and GameManager.prologue_phase == 0:
		GameManager.prologue_phase = 1
		
	GameManager.finish_battle(is_victory)

# ===========================================================================
# Player Turn
# ===========================================================================

func _player_turn(actor: Entity):
	# Show tutorial before the very first player action
	if GameManager.is_tutorial:
		await _run_tutorial()

	hud.command_menu.show_for(actor, enemy_team)
	var result = await hud.command_menu.command_chosen
	var action: String = result[0]
	var target: Entity = result[1]
	_execute_action(actor, action, target)

# ===========================================================================
# AI Turn
# ===========================================================================

func _ai_turn(actor: Entity):
	await get_tree().create_timer(0.5).timeout   # "thinking" pause
	
	var target = AIManager.pick_target(actor, player_team)
	if target == null:
		return
	
	print(actor.entity_name, " (AI) tấn công ", target.entity_name)
	var dmg = DamageCalculator.calculate_damage(actor, target)
	target.take_damage(dmg)

# ===========================================================================
# Execute Action
# ===========================================================================

func _execute_action(actor: Entity, action: String, target: Entity):
	if action == "attack":
		print(actor.entity_name, " đánh thường vào ", target.entity_name)
		var dmg = DamageCalculator.calculate_damage(actor, target)
		target.take_damage(dmg)
		return
	
	# Skill execution
	if actor.has_method(action):
		var cd_turns = 0
		var once_per_battle = false
		for s in actor.skills:
			if s["method"] == action:
				cd_turns = s.get("cooldown_turns", 0)
				once_per_battle = s.get("once_per_battle", false)
				break
		
		var is_shadow_blade = (action == "shadow_blade")
		
		actor.call(action, target)
		
		if once_per_battle:
			CooldownManager.set_cooldown(actor, action, 99)
		elif cd_turns > 0:
			CooldownManager.set_cooldown(actor, action, cd_turns)
		
		# Hitstop + shake for Shadow Blade
		if is_shadow_blade and actor.current_hp > 0:
			await shaker.hitstop(0.1)
			shaker.shake(8.0, 0.3)
	else:
		print("[Warning] ", actor.entity_name, " không có skill: ", action)

# ===========================================================================
# Timeline Management
# ===========================================================================

# Full regeneration — only called when queue is empty or at battle start
func _regenerate_timeline():
	var alive = TargetingManager.get_alive_targets(all_entities)
	timeline = TurnCalculator.get_timeline(alive, 20)
	_update_gauge_display()

# Display-only update — shows remaining queue in the ActionGauge without regenerating
func _update_gauge_display():
	hud.action_gauge.refresh(timeline.slice(0, 10))

# Remove a dead entity's turns from the queue
func _purge_dead_from_timeline(dead_name: String):
	timeline = TurnCalculator.remove_dead_from_timeline(timeline, dead_name)

# ===========================================================================
# Helpers
# ===========================================================================

func _get_entity(e_name: String) -> Entity:
	for entity in all_entities:
		if entity.entity_name == e_name:
			return entity
	return null

func _on_entity_died(entity: Entity):
	print(">>> ", entity.entity_name, " đã bị hạ gục! <<<")
	_purge_dead_from_timeline(entity.entity_name)

func _check_battle_end() -> bool:
	if TargetingManager.get_alive_targets(enemy_team).is_empty():
		hud.show_result("VICTORY", Color(0.3, 1.0, 0.5))
		battle_over = true
		print("=== CHIẾN THẮNG ===")
		return true
	if TargetingManager.get_alive_targets(player_team).is_empty():
		hud.show_result("DEFEAT", Color(1.0, 0.3, 0.3))
		battle_over = true
		print("=== THẤT BẠI ===")
		return true
	return false

func _names(team: Array) -> String:
	var n = []
	for e in team:
		n.append(e.entity_name)
	return ", ".join(n)
