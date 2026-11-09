extends DefaultScenario
class_name PrimeMinisterBossScenario

const GUARD_LEVEL := 40


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
				for i in 2:
					var guard := BattleInitializer.create_enemy("guard", GUARD_LEVEL, "Cảnh Vệ %d" % (i + 1))
					battle_scene.add_combatant(guard)
				battle_scene.refresh_battle_state()

