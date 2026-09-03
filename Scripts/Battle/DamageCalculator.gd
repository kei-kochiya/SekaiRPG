extends Node
class_name DamageCalculator

"""
Tóm tắt: DamageCalculator phụ trách tính toán lượng sát thương cuối cùng trong trận đấu.

Chức năng chính:
- Cung cấp phương thức tĩnh `calculate_damage` để xử lý công thức sát thương: raw_dmg = (ATK * Multiplier) - DEF.
- Tự động áp dụng hệ số giảm trừ theo kháng (RES) và tương khắc thuộc tính (thông qua TypeChart).
- Đảm bảo sát thương tối thiểu gây ra không bao giờ thấp hơn 5% ATK của người tấn công.
"""

# ── Xử Lý Sát Thương ───────────────────────────────────────────────────────


static func calculate_damage_detailed(attacker: Entity, defender: Entity, skill_multiplier: float = 1.0) -> Dictionary:
	"""
	Tính toán lượng sát thương chi tiết kèm cờ Chí mạng (Crit) và Phá điểm yếu (Break).
	"""
	if attacker == null or defender == null:
		return {"damage": 0, "is_crit": false, "is_weakness": false, "is_break": false}
		
	var modified_atk = attacker.atk * skill_multiplier
	var raw_damage = max(0, modified_atk - defender.defense)
	
	var after_res = raw_damage * (1.0 - (defender.res / 100.0))
	
	var multiplier = TypeChart.get_multiplier(attacker.type, defender.type)
	var is_weakness = (multiplier > 1.0)
	var final_damage = after_res * multiplier
	
	var min_damage = modified_atk * 0.05
	if final_damage < min_damage:
		final_damage = min_damage
		
	# Tính toán Chí Mạng (Critical Hit)
	var is_crit = false
	var crit_rate = attacker.get("crit_rate") if "crit_rate" in attacker else 0.10
	if randf() < crit_rate:
		is_crit = true
		var crit_dmg = attacker.get("crit_dmg") if "crit_dmg" in attacker else 1.50
		final_damage *= crit_dmg
		
	# Tính toán Phá Điểm Yếu (Weakness Break) nếu đánh trúng hệ yếu của quái
	var is_break = false
	if is_weakness and "break_gauge" in defender and not defender.is_character:
		var break_damage = int(final_damage * 0.4) + 25
		defender.break_gauge = max(0, defender.break_gauge - break_damage)
		if defender.break_gauge <= 0:
			defender.break_gauge = defender.max_break_gauge
			is_break = true
			defender.set_meta("was_broken", true)
			if "is_staggered" in defender:
				defender.is_staggered = true
			defender.action_gauge = max(0.0, defender.action_gauge - 3000.0)
			defender.add_status({"type": "Stun", "duration": 1})
			print("[Weakness Break] ", defender.entity_name, " bị phá vỡ điểm yếu! Choáng 1 lượt và trễ thanh hành động.")

	return {
		"damage": int(final_damage),
		"is_crit": is_crit,
		"is_weakness": is_weakness,
		"is_break": is_break
	}

static func calculate_damage(attacker: Entity, defender: Entity, skill_multiplier: float = 1.0) -> int:
	var result = calculate_damage_detailed(attacker, defender, skill_multiplier)
	if attacker:
		attacker.set_meta("last_hit_crit", result["is_crit"])
		attacker.set_meta("last_hit_break", result["is_break"])
	return result["damage"]
