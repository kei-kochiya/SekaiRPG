extends Node
class_name AIManager

# -------------------------------------------------------------------------
# Trọng số (số vé) cho từng mức hiệu quả thuộc tính
# Ví dụ với 1 mục tiêu x1.25 và 1 mục tiêu x0.8:
#   Pool = 10 vé (x1.25) + 1 vé (x0.8) → xác suất chọn x0.8 ≈ 8,3%
# -------------------------------------------------------------------------
const WEIGHT_SUPER_EFFECTIVE = 10  # x1.25 — ưu tiên rất cao
const WEIGHT_NEUTRAL         = 4   # x1.0  — bình thường
const WEIGHT_NOT_EFFECTIVE   = 1   # x0.8  — ít nhưng vẫn có khả năng

# -------------------------------------------------------------------------
# Hàm chính: Chọn mục tiêu dựa theo ưu tiên thuộc tính
# attacker : Entity đang hành động
# enemy_team: Array chứa các Entity phe địch
# Trả về Entity được chọn, hoặc null nếu phe địch đã bị xóa sổ
# -------------------------------------------------------------------------
static func pick_target(attacker: Entity, enemy_team: Array, timeline: Array) -> Entity:
	var alive_targets = TargetingManager.get_alive_targets(enemy_team)
	if alive_targets.is_empty():
		return null

	var target_scores: Array = []
	
	for target in alive_targets:
		var score = 10.0 # Base weight
		
		# 1. Type Advantage (Strongest weight)
		var mult = TypeChart.get_multiplier(attacker.type, target.type)
		if mult >= 1.25:
			score += 20.0
		elif mult <= 0.8:
			score -= 5.0
			
		# 2. SPD Priority (Targets faster units to disrupt them)
		score += target.spd * 0.05
		
		# 3. Timeline Proximity (Target unit whose turn is coming soon)
		var turn_idx = _find_first_turn_index(target.entity_name, timeline)
		if turn_idx >= 0:
			# If turn is in next 5 slots, add priority
			score += max(0, (10 - turn_idx) * 2.0)
		
		# 4. Random variance
		score += randf_range(0, 5.0)
		
		target_scores.append({"target": target, "score": max(1.0, score)})

	# Create weighted pool for selection
	var weighted_pool: Array = []
	for entry in target_scores:
		var weight = int(entry.score)
		for _i in range(weight):
			weighted_pool.append(entry.target)

	if weighted_pool.is_empty():
		return alive_targets[0]

	return weighted_pool[randi() % weighted_pool.size()]

static func _find_first_turn_index(entity_name: String, timeline: Array) -> int:
	for i in range(timeline.size()):
		if timeline[i]["name"] == entity_name:
			return i
	return -1

# -------------------------------------------------------------------------
# Tiện ích: Trả về mô tả debug để log ra console
# -------------------------------------------------------------------------
static func get_target_weights_debug(attacker: Entity, enemy_team: Array) -> String:
	var alive_targets = TargetingManager.get_alive_targets(enemy_team)
	var total_weight = 0
	var lines: Array[String] = []

	for target in alive_targets:
		var mult = TypeChart.get_multiplier(attacker.type, target.type)
		var weight = WEIGHT_NEUTRAL
		if mult >= 1.25:
			weight = WEIGHT_SUPER_EFFECTIVE
		elif mult <= 0.8:
			weight = WEIGHT_NOT_EFFECTIVE
		total_weight += weight
		lines.append("  %s (x%.2f) → %d vé" % [target.entity_name, mult, weight])

	var result = "[AIManager] %s đang chọn mục tiêu (tổng %d vé):\n" % [attacker.entity_name, total_weight]
	for line in lines:
		result += line + "\n"
	return result
