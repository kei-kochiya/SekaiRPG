extends Node
class_name AIManager

# -------------------------------------------------------------------------
# Main AI: Heuristic target selection for enemies.
# -------------------------------------------------------------------------

static func get_alive_targets(team: Array) -> Array:
	var alive_units = []
	for unit in team:
		if unit.current_hp > 0:
			alive_units.append(unit)
	return alive_units

static func pick_target(attacker: Entity, enemy_team: Array, timeline: Array) -> Entity:
	var alive_targets = get_alive_targets(enemy_team)
	if alive_targets.is_empty():
		return null

	var target_scores: Array = []
	
	for target in alive_targets:
		var score = 10.0 # Base weight
		
		# 1. Type Advantage
		var mult = TypeChart.get_multiplier(attacker.type, target.type)
		if mult >= 1.25: score += 15.0
		elif mult <= 0.8: score -= 5.0
			
		# 2. Low HP Aggro (Heuristic)
		var hp_percent = float(target.current_hp) / target.max_hp
		if hp_percent < 0.3: score += 10.0 # Focus low HP
		
		# 3. Timeline Proximity
		var turn_idx = _find_first_turn_index(target.entity_name, timeline)
		if turn_idx >= 0 and turn_idx < 5:
			score += (5 - turn_idx) * 2.0
		
		# 4. Random variance
		score += randf_range(0, 5.0)
		
		target_scores.append({"target": target, "score": max(1.0, score)})

	# Weighted selection
	var weighted_pool: Array = []
	for entry in target_scores:
		for _i in range(int(entry.score)):
			weighted_pool.append(entry.target)

	return weighted_pool.pick_random() if not weighted_pool.is_empty() else alive_targets.pick_random()

static func _find_first_turn_index(entity_name: String, timeline: Array) -> int:
	for i in range(timeline.size()):
		if timeline[i]["name"] == entity_name:
			return i
	return -1
