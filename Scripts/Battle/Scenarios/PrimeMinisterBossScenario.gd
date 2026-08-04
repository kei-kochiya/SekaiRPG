extends BattleScenario
class_name PrimeMinisterBossScenario

func on_start(battle_scene: Node):
	var pm = null
	for e in battle_scene.enemy_team:
		if e.entity_name == "Thủ Tướng":
			pm = e
			break
			
	if pm:
		pm.apply_status_effect("Buff ATK", 5)
		
	# Khóa kỹ năng hồi máu của phe ta nếu có
	for p in battle_scene.player_team:
		if p.entity_name == "Ichika": 
			# Vô hiệu hóa một số thứ?
			pass

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
				guard1.entity_name = "Cảnh Vệ"
				var guard2 = Guard.new()
				guard2.entity_name = "Cảnh Vệ"
				LevelManager.set_initial_level(guard1, 40)
				LevelManager.set_initial_level(guard2, 40)
				battle_scene.enemy_team.append(guard1)
				battle_scene.enemy_team.append(guard2)
				battle_scene.all_entities.append(guard1)
				battle_scene.all_entities.append(guard2)
				
				# Vị trí tạm
				# Do battle UI không vẽ lại danh sách kẻ địch linh hoạt lắm, ta tạm thời
				# chỉ gọi Guard, cần cập nhật HUD nếu UI hỗ trợ.
				pass
