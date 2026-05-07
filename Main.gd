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

var is_harbor_boss_fight: bool = false
var harbor_boss_phase: int = 0 # 0: Start, 1: Fighting, 2: Reinforcements arrived
var is_scripting: bool = false # Pause battle end checks during sequences

func _ready():
	# --- Setup teams and context ---
	var data = BattleInitializer.setup_battle(self)
	player_team = data["player_team"]
	enemy_team = data["enemy_team"]
	is_harbor_boss_fight = data["is_harbor_boss"]
	
	all_entities = player_team + enemy_team
	_refresh_team_context()
		
	for e in all_entities:
		for s in e.skills:
			if s.has("initial_cooldown"):
				e.cooldowns[s["method"]] = s["initial_cooldown"]
				
	# --- Build HUD ---
	hud = BattleHUD.new()
	add_child(hud)
	hud.build(player_team, enemy_team)
	_update_gauge_player_names()
	
	# --- Screen shake node ---
	shaker = ScreenShake.new()
	add_child(shaker)
	
	for entity in all_entities:
		entity.died.connect(_on_entity_died.bind(entity))
	
	# --- Start battle ---
	if is_harbor_boss_fight:
		HarborBattleScript.run_intro(self, func(): run_battle())
	else:
		run_battle()

func _refresh_team_context():
	for e in player_team:
		e.allies = player_team
		e.enemies = enemy_team
	for e in enemy_team:
		e.allies = enemy_team
		e.enemies = player_team

func _update_gauge_player_names():
	var p_names: Array[String] = []
	for p in player_team:
		p_names.append(p.entity_name)
	hud.action_gauge.set_player_names(p_names)

# ===========================================================================
# Tutorial
# ===========================================================================

func _show_tutorial():
	await BattleTutorial.run_tutorial(self)

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
	var enemy_count = enemy_team.size()
	
	if is_victory:
		# Award EXP to survivors
		for p in player_team:
			LevelManager.gain_exp(p, 50)
		
		if GameManager.current_map_file == "res://Scenes/HarborMap.tscn" and GameManager.harbor_route == "guards":
			GameManager.guards_defeated = true
			
	if is_victory and GameManager.prologue_phase == 0:
		GameManager.prologue_phase = 1
	
	if is_victory and is_harbor_boss_fight:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_victory"), func():
			GameManager.harbor_mission_done = true
			GameManager.finish_battle(is_victory, enemy_count)
		)
	else:
		GameManager.finish_battle(is_victory, enemy_count)

# ===========================================================================
# Player Turn
# ===========================================================================

func _player_turn(actor: Entity):
	# Show tutorial before the very first player action
	if GameManager.is_tutorial:
		await _show_tutorial()

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
	
	var target = AIManager.pick_target(actor, player_team, timeline)
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
	if is_scripting: return false
	
	if TargetingManager.get_alive_targets(enemy_team).is_empty():
		hud.show_result("VICTORY", Color(0.3, 1.0, 0.5))
		battle_over = true
		print("=== CHIẾN THẮNG ===")
		return true
	
	if TargetingManager.get_alive_targets(player_team).is_empty():
		if is_harbor_boss_fight and harbor_boss_phase == 1:
			HarborBattleScript.handle_loss(self)
			return false # Keep loop running, phase will change
		
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
