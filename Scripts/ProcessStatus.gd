extends Node
class_name ProcessStatus

static func handle_turn_start(entity: Entity) -> bool:
	if entity.active_statuses.is_empty():
		return true
	
	var can_act = true
	var statuses_to_remove = []
	
	print("--- ", entity.entity_name, " đang kiểm tra hiệu ứng ---")
	
	for status in entity.active_statuses:
		match status["type"]:
			"Bleed":
				var dmg = int(entity.current_hp * 0.1)
				entity.take_damage(dmg, "dot")
			"Poison":
				var pct = status.get("percent", 0.1)
				var dmg = int(entity.max_hp * pct)
				entity.take_damage(dmg, "dot")
				status["percent"] = max(0.01, pct - 0.03)
			"Stun":
				print(entity.entity_name, " đang bị Choáng và không thể cử động!")
				can_act = false
		
		status["duration"] -= 1
		if status["duration"] <= 0:
			statuses_to_remove.append(status)
	
	# Use Entity helper so status_changed signal fires
	entity.remove_statuses(statuses_to_remove)
	
	return can_act
