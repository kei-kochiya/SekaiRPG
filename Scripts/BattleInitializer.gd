extends Node
class_name BattleInitializer

## Handles team setup and entity initialization for different battle contexts.

static func setup_battle(main: Node) -> Dictionary:
	var ichika = GameManager.get_party_member("Ichika")
	var mafuyu = GameManager.get_party_member("Mafuyu")
	var ena    = GameManager.get_party_member("Ena")
	var kanade = GameManager.get_party_member("Kanade")
	
	var player_team = []
	var enemy_team = []
	var is_harbor_boss = false

	var current_map = GameManager.current_map_file
	
	if current_map == "res://Scenes/HarborMap.tscn":
		if GameManager.harbor_route == "boss" or GameManager.harbor_wave > 3:
			is_harbor_boss = true
			player_team = [ichika, ena]
			var boss = _create_boss("Đội Trưởng", 3500, 240, 130, 110, "Hard")
			LevelManager.set_initial_level(boss, 8)
			enemy_team = [boss]
		else:
			player_team = [ichika, ena]
			var wave_lv = 5 + GameManager.harbor_wave # Wave 1:6, 2:7, 3:8
			enemy_team = _create_guards(4, wave_lv)
			
	elif current_map == "res://Scenes/WarehouseMap.tscn":
		player_team = [ichika, kanade]
		var wave_lv = clamp(GameManager.warehouse_wave, 1, 5)
		enemy_team = _create_targets(5, wave_lv)
		
	elif GameManager.prologue_phase == 0:
		player_team = [ichika]
		enemy_team = _create_kidnappers(3, 1)
		
	else:
		# Fallback
		player_team = [ichika, mafuyu]
		enemy_team = [ena, kanade]
		
	# Health Recovery Policy: If < 50% or dead, restore to 50%
	for p in player_team:
		var min_hp = int(p.max_hp * 0.5)
		if p.current_hp < min_hp:
			p.current_hp = min_hp
			print("[BattleInitializer] ", p.entity_name, " hồi phục tối thiểu 50% máu.")

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
