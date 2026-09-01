extends DefaultScenario
class_name PrimeMinisterBossScenario

func on_start(battle_scene: Node):
	var pm = null
	for e in battle_scene.enemy_team:
		if e.entity_name == "Thủ Tướng":
			pm = e
			break
			
	if pm:
		pm.add_status({"type": "Buff", "duration": 5})
		
	super.on_start(battle_scene)

func on_turn_start(battle_scene: Node, current_actor: Entity):
	if current_actor.entity_name == "Thủ Tướng":
		# Nếu HP dưới 50%, spawn thêm vệ sĩ nếu chưa spawn
		if current_actor.current_hp < current_actor.max_hp * 0.5:
			var has_guards = false
			for e in battle_scene.enemy_team:
				if e.entity_name == "Cảnh Vệ" and e.current_hp > 0:
					has_guards = true
					break
			if not has_guards and not current_actor.has_meta("guards_spawned"):
				current_actor.set_meta("guards_spawned", true)
				print("[Boss] Thủ Tướng gọi chi viện!")
				var guard1 = Guard.new()
				guard1.entity_name = "Cảnh Vệ 1"
				var guard2 = Guard.new()
				guard2.entity_name = "Cảnh Vệ 2"
				LevelManager.set_initial_level(guard1, 40)
				LevelManager.set_initial_level(guard2, 40)
				
				for g in [guard1, guard2]:
					battle_scene.enemy_team.append(g)
					battle_scene.all_entities.append(g)
					if not g.died.is_connected(battle_scene._on_entity_died.bind(g)):
						g.died.connect(battle_scene._on_entity_died.bind(g))
				
				battle_scene._refresh_team_context()
				battle_scene.hud.setup(battle_scene.player_team, battle_scene.enemy_team)
				battle_scene._setup_gauge_teams()
				battle_scene._regenerate_timeline()

