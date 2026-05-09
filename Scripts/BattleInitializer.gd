extends Node
class_name BattleInitializer

## Handles team setup and entity initialization for different battle contexts.

static func setup_battle(_main: Node) -> Dictionary:
	var ichika = GameManager.get_party_member("Ichika")
	var mafuyu = GameManager.get_party_member("Mafuyu")
	var ena    = GameManager.get_party_member("Ena")
	var kanade = GameManager.get_party_member("Kanade")
	
	var player_team = []
	var enemy_team = []
	var is_harbor_boss = false

	var current_map = GameManager.current_map_file
	
	if GameManager.is_sandbox:
		return {
			"player_team": GameManager.sandbox_player_team,
			"enemy_team": GameManager.sandbox_enemy_team,
			"is_harbor_boss": false
		}
	
	if GameManager.is_training_mode:
		var training_data = _setup_training_battle()
		player_team = training_data["player_team"]
		enemy_team = training_data["enemy_team"]
		is_harbor_boss = false
	elif current_map == "res://Scenes/HarborMap.tscn":
		if GameManager.harbor_route == "boss" or GameManager.harbor_wave > 3:
			is_harbor_boss = true
			player_team = [ichika, ena]
			var boss = _create_boss("Đội Trưởng", 3500, 240, 130, 110, "Hard")
			LevelManager.set_initial_level(boss, 8)
			enemy_team = [boss]
		else:
			player_team = [ichika, ena]
			var wave_lv = 5 + GameManager.harbor_wave 
			enemy_team = _create_guards(4, wave_lv)
			
	elif current_map == "res://Scenes/WarehouseMap.tscn":
		player_team = [ichika, kanade]
		var wave_lv = clamp(GameManager.warehouse_wave, 1, 5)
		enemy_team = _create_targets(5, wave_lv)
		
	elif GameManager.prologue_phase == 0:
		player_team = [ichika]
		enemy_team = _create_kidnappers(3, 1)
		
	else:
		# Fallback - ensure no unintended matches occur
		print("[BattleInitializer] WARNING: Undefined battle context. Returning empty teams.")
		player_team = []
		enemy_team = []
		
	# Health Recovery Policy (Applied to ALL modes including training)
	for p in player_team:
		var min_hp = int(p.max_hp * 0.5)
		if p.current_hp < min_hp:
			p.current_hp = min_hp

	return {
		"player_team": player_team,
		"enemy_team": enemy_team,
		"is_harbor_boss": is_harbor_boss
	}

static func _setup_training_battle() -> Dictionary:
	var player_team = []
	var base_lv = 1
	for p_name in GameManager.training_participants:
		var p = GameManager.get_party_member(p_name)
		if p:
			player_team.append(p)
			base_lv = max(base_lv, p.level)
	
	var enemies = []
	var max_lv = 1
	var target_lv = clamp(base_lv + randi_range(-3, 3), 1, 100)
	max_lv = target_lv
	
	# 70% chance for Characters, 30% chance for Monsters
	if randf() < 0.7:
		var pool = ["Mafuyu", "Ena", "Mizuki", "Kanade", "Ichika"]
		var candidates = []
		for name in pool:
			if name not in GameManager.training_participants and name not in GameManager.training_used_opponents:
				candidates.append(name)
		
		candidates.shuffle()
		
		# Decide 1 or 2 enemies
		var count = 1 if (randf() < 0.5 or candidates.size() < 2) else 2
		
		if count == 2:
			# If 2 enemies, NO Mafuyu allowed
			var no_mafuyu_pool = []
			for c in candidates:
				if c != "Mafuyu": no_mafuyu_pool.append(c)
			
			if no_mafuyu_pool.size() >= 2:
				no_mafuyu_pool.shuffle()
				for i in range(2):
					var e_name = no_mafuyu_pool.pop_back()
					GameManager.training_used_opponents.append(e_name)
					var enemy = GameManager.get_party_member(e_name).duplicate(7)
					LevelManager.set_initial_level(enemy, target_lv)
					enemies.append(enemy)
			else:
				count = 1
				
		if count == 1 and not candidates.is_empty():
			var e_name = candidates.pop_back()
			GameManager.training_used_opponents.append(e_name)
			var enemy = GameManager.get_party_member(e_name).duplicate(7)
			LevelManager.set_initial_level(enemy, target_lv)
			enemies.append(enemy)
	
	# Fallback to monsters if no characters selected or 30% chance hit
	if enemies.is_empty():
		enemies = _create_targets(5, target_lv)
		for e in enemies:
			e.entity_name = "Training Bot " + e.entity_name.split(" ")[1]

	GameManager.last_battle_max_lv = max_lv
	return {
		"player_team": player_team,
		"enemy_team": enemies
	}

static func _create_boss(p_name: String, hp: int, atk: int, def: int, spd: int, type: String) -> Entity:
	var boss = Entity.new()
	boss.entity_name = p_name
	boss.max_hp = hp
	boss.current_hp = hp
	boss.atk = atk
	boss.defense = def
	boss.spd = spd
	boss.type = type
	boss.skills = [{"name": "Execution", "method": "basic_attack", "cooldown_turns": 1}]
	return boss

static func _create_guards(count: int, lv: int) -> Array:
	var team = []
	for i in range(count):
		var g = Entity.new()
		g.entity_name = "Lính Cảng " + str(i+1)
		g.max_hp = 250
		g.current_hp = 250
		g.atk = 75
		g.defense = 40
		g.spd = 95
		g.type = "Hard"
		LevelManager.set_initial_level(g, lv)
		team.append(g)
	return team

static func _create_kidnappers(count: int, lv: int) -> Array:
	var team = []
	for i in range(count):
		var k = Entity.new()
		k.entity_name = "Kidnapper " + str(i+1)
		k.max_hp = 80
		k.current_hp = 80
		k.atk = 40
		k.defense = 20
		k.spd = 80
		k.type = "None"
		k.skills = [{"name": "Shank", "method": "basic_attack", "cooldown_turns": 1}]
		LevelManager.set_initial_level(k, lv)
		team.append(k)
	return team

static func _create_targets(count: int, lv: int) -> Array:
	var team = []
	for i in range(count):
		var e = Entity.new()
		e.entity_name = "Target " + str(i+1)
		e.max_hp = 100
		e.current_hp = 100
		e.atk = 45
		e.defense = 25
		e.spd = 90 + i * 2
		e.type = "None"
		LevelManager.set_initial_level(e, lv)
		team.append(e)
	return team
