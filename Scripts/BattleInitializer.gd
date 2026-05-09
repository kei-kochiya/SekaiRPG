extends Node
class_name BattleInitializer

## Data-driven Battle Initializer.
## Loads configurations from res://Data/battles/ and sets up teams.

static var enemy_types: Dictionary = {}
static var mission_battles: Dictionary = {}

static func _ensure_data_loaded():
	if enemy_types.is_empty():
		enemy_types = _load_json("res://Data/battles/enemy_types.json")
	if mission_battles.is_empty():
		mission_battles = _load_json("res://Data/battles/mission_battles.json")

static func _load_json(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if not f: return {}
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	return d if d is Dictionary else {}

static func setup_battle(_main: Node) -> Dictionary:
	_ensure_data_loaded()
	
	if GameManager.is_sandbox:
		return {
			"player_team": GameManager.sandbox_player_team,
			"enemy_team": GameManager.sandbox_enemy_team,
			"is_harbor_boss": false
		}
	
	if GameManager.is_training_mode:
		return _setup_training_battle()
	
	var current_map = GameManager.current_map_file
	var battle_key = ""
	
	# Map File -> Battle Key mapping
	if current_map == "res://Scenes/HarborMap.tscn":
		if GameManager.harbor_route == "boss" or GameManager.harbor_wave > 3:
			battle_key = "harbor_boss"
		else:
			battle_key = "harbor_guards"
	elif current_map == "res://Scenes/WarehouseMap.tscn":
		battle_key = "warehouse"
	elif GameManager.prologue_phase == 0:
		battle_key = "prologue"
	
	if mission_battles.has(battle_key):
		return _setup_mission_battle(mission_battles[battle_key])
	
	# Fallback
	print("[BattleInitializer] WARNING: No battle config for ", current_map)
	return {"player_team": [], "enemy_team": [], "is_harbor_boss": false}

static func _setup_mission_battle(cfg: Dictionary) -> Dictionary:
	var p_team = []
	for p_name in cfg.get("player_party", []):
		var p = GameManager.get_party_member(p_name)
		if p: p_team.append(p)
	
	# Determine Level
	var lv = 1
	if cfg.has("level_val"):
		lv = cfg["level_val"]
	elif cfg.has("level_key"):
		var key = cfg["level_key"]
		if key == "warehouse_wave":
			lv = clamp(GameManager.warehouse_wave, 1, 5)
		elif key == "harbor_guards":
			lv = 5 + GameManager.harbor_wave
	
	var e_type = cfg.get("enemy_type", "")
	var count = cfg.get("enemy_count", 1)
	var enemies = _create_entities_from_type(e_type, count, lv)
	
	# Recovery policy
	for p in p_team:
		var min_hp = int(p.max_hp * 0.5)
		if p.current_hp < min_hp: p.current_hp = min_hp

	return {
		"player_team": p_team,
		"enemy_team": enemies,
		"is_harbor_boss": cfg.get("is_harbor_boss", false)
	}

static func _create_entities_from_type(type_id: String, count: int, lv: int) -> Array:
	var team = []
	var data = enemy_types.get(type_id, {})
	if data.is_empty(): return []
	
	for i in range(count):
		var e = Entity.new()
		e.entity_name = data.get("name", "Unknown")
		if count > 1: e.entity_name += " " + str(i + 1)
		
		e.max_hp = data.get("hp", 100)
		e.current_hp = e.max_hp
		e.atk = data.get("atk", 10)
		e.defense = data.get("def", 10)
		e.spd = data.get("spd", 10)
		e.type = data.get("type", "None")
		e.skills = data.get("skills", [])
		
		LevelManager.set_initial_level(e, lv)
		team.append(e)
	return team

static func _setup_training_battle() -> Dictionary:
	_ensure_data_loaded()
	var player_team = []
	var base_lv = 1
	for p_name in GameManager.training_participants:
		var p = GameManager.get_party_member(p_name)
		if p:
			player_team.append(p)
			base_lv = max(base_lv, p.level)
	
	var enemies = []
	var target_lv = clamp(base_lv + randi_range(-3, 3), 1, 100)
	
	if randf() < 0.7:
		var pool = ["Mafuyu", "Ena", "Mizuki", "Kanade", "Ichika"]
		var candidates = []
		for name in pool:
			if name not in GameManager.training_participants and name not in GameManager.training_used_opponents:
				candidates.append(name)
		candidates.shuffle()
		
		var count = 1 if (randf() < 0.5 or candidates.size() < 2) else 2
		if count == 2:
			var no_mafuyu = candidates.filter(func(n): return n != "Mafuyu")
			if no_mafuyu.size() >= 2:
				no_mafuyu.shuffle()
				for i in range(2):
					var e_name = no_mafuyu.pop_back()
					GameManager.training_used_opponents.append(e_name)
					var enemy = GameManager.get_party_member(e_name).duplicate(7)
					LevelManager.set_initial_level(enemy, target_lv)
					enemies.append(enemy)
			else: count = 1
		
		if count == 1 and not candidates.is_empty():
			var e_name = candidates.pop_back()
			GameManager.training_used_opponents.append(e_name)
			var enemy = GameManager.get_party_member(e_name).duplicate(7)
			LevelManager.set_initial_level(enemy, target_lv)
			enemies.append(enemy)
	
	if enemies.is_empty():
		enemies = _create_entities_from_type("target", 5, target_lv)
		for e in enemies: e.entity_name = "Training Bot " + e.entity_name.split(" ")[1]

	GameManager.last_battle_max_lv = target_lv
	
	# Recovery policy for training
	for p in player_team:
		var min_hp = int(p.max_hp * 0.5)
		if p.current_hp < min_hp: p.current_hp = min_hp

	return {"player_team": player_team, "enemy_team": enemies}
