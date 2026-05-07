extends Node
class_name BattleInitializer

## Handles team setup and entity initialization for different battle contexts.

static func setup_battle(main: Node) -> Dictionary:
	var ichika = Ichika.new()
	var mafuyu = Mafuyu.new()
	var ena = Ena.new()
	var kanade = Kanade.new()
	
	var player_team = []
	var enemy_team = []
	var is_harbor_boss = false

	var current_map = GameManager.current_map_file
	
	if current_map == "res://Scenes/HarborMap.tscn":
		if GameManager.harbor_route == "boss":
			is_harbor_boss = true
			player_team = [ichika, ena]
			enemy_team = [_create_boss("Đội Trưởng", 3000, 220, 120, 105, "Hard")]
		else:
			player_team = [ichika, ena]
			enemy_team = _create_guards(4)
			
	elif GameManager.prologue_phase == 0:
		player_team = [ichika]
		enemy_team = _create_kidnappers(3)
		
	elif current_map == "res://Scenes/WarehouseMap.tscn":
		player_team = [ichika, kanade]
		enemy_team = _create_targets(5)
		
	else:
		# Fallback
		player_team = [ichika, mafuyu]
		enemy_team = [ena, kanade]

	return {
		"player_team": player_team,
		"enemy_team": enemy_team,
		"is_harbor_boss": is_harbor_boss
	}

static func _create_boss(name: String, hp: int, atk: int, def: int, spd: int, type: String) -> Entity:
	var boss = Entity.new()
	boss.entity_name = name
	boss.max_hp = hp
	boss.current_hp = hp
	boss.atk = atk
	boss.defense = def
	boss.spd = spd
	boss.type = type
	boss.skills = [{"name": "Execution", "method": "basic_attack", "cooldown_turns": 1}]
	return boss

static func _create_guards(count: int) -> Array:
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
		team.append(g)
	return team

static func _create_kidnappers(count: int) -> Array:
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
		team.append(k)
	return team

static func _create_targets(count: int) -> Array:
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
		team.append(e)
	return team
