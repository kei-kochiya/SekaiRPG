extends Node
class_name TargetingManager

# Lấy danh sách những người còn sống
static func get_alive_targets(team: Array) -> Array:
	var alive_units = []
	for unit in team:
		if unit.current_hp > 0:
			alive_units.append(unit)
	return alive_units

# Tiện ích: Tự động chọn mục tiêu yếu máu nhất (Dùng cho quái hoặc Auto-battle)
static func get_lowest_hp_target(team: Array) -> Entity:
	var alive_targets = get_alive_targets(team)
	if alive_targets.is_empty():
		return null
		
	var target = alive_targets[0]
	for unit in alive_targets:
		if unit.current_hp < target.current_hp:
			target = unit
	return target
