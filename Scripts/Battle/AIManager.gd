extends Node
class_name AIManager

"""
AIManager: Quản lý trí tuệ nhân tạo (AI) cho kẻ địch trong trận đấu.

Lớp này cung cấp các phương thức tĩnh để chọn mục tiêu và hành động cho kẻ địch 
dựa trên các yếu tố chiến thuật như hệ thuộc tính, lượng máu còn lại và thứ tự lượt.
Sử dụng hệ thống Heuristic để đưa ra quyết định tối ưu.
"""

static func get_alive_targets(team: Array) -> Array:
	# Lấy danh sách các đơn vị còn sống trong một đội.
	var alive_units = []
	for unit in team:
		if unit.current_hp > 0:
			alive_units.append(unit)
	return alive_units

static func pick_target(attacker: Entity, enemy_team: Array, timeline: Array) -> Entity:
	"""
	Hàm này chọn mục tiêu tối ưu cho AI dựa trên hệ thống tính điểm Heuristic.
	- attacker: Thực thể tấn công (Entity).
	- enemy_team: Danh sách kẻ địch (Array).
	- timeline: Thứ tự lượt đi hiện tại (Array).
	- Return: Thực thể mục tiêu được chọn (Entity).
	"""
	var alive_targets = get_alive_targets(enemy_team)
	if alive_targets.is_empty():
		return null

	var target_scores: Array = []
	
	for target in alive_targets:
		var score = 10.0
		
		var mult = TypeChart.get_multiplier(attacker.type, target.type)
		if mult >= 1.25: score += 15.0
		elif mult <= 0.8: score -= 5.0
			
		var hp_percent = float(target.current_hp) / target.max_hp
		if hp_percent < 0.3: score += 10.0
		
		var turn_idx = _find_first_turn_index(target, timeline)
		if turn_idx >= 0 and turn_idx < 5:
			score += (5 - turn_idx) * 2.0
		
		score += randf_range(0, 5.0)
		target_scores.append({"target": target, "score": max(1.0, score)})

	var weighted_pool: Array = []
	for entry in target_scores:
		for _i in range(int(entry.score)):
			weighted_pool.append(entry.target)

	if weighted_pool.is_empty():
		return alive_targets.pick_random()

	return weighted_pool.pick_random()

static func pick_action(actor: Entity, enemies: Array, allies: Array, timeline: Array) -> Dictionary:
	"""
	Hàm quyết định hành động tiếp theo của AI (Tấn công thường hoặc dùng kỹ năng).
	- actor: Thực thể AI (Entity).
	- enemies: Danh sách kẻ địch (Array).
	- allies: Danh sách đồng minh (Array).
	- timeline: Dòng thời gian lượt đi (Array).
	- Return: Dictionary chứa tên hành động và mục tiêu.
	"""
	var target = pick_target(actor, enemies, timeline)
	if target == null:
		return {"action": "attack", "target": null}

	var usable_skills = []
	for s in actor.skills:
		if actor.can_use_skill(s["method"]):
			usable_skills.append(s)

	if not usable_skills.is_empty() and randf() < 0.7:
		var skill = usable_skills.pick_random()
		
		var final_target = target
		if skill.get("target_type") == "ally":
			var wounded = get_alive_targets(allies)
			if not wounded.is_empty():
				final_target = wounded.pick_random()

		return {"action": skill["method"], "target": final_target}

	return {"action": "attack", "target": target}

static func _find_first_turn_index(target: Entity, timeline: Array) -> int:
	# Tìm vị trí lượt tiếp theo của một thực thể trong timeline.
	for i in range(timeline.size()):
		if timeline[i]["entity"] == target:
			return i
	return -1
