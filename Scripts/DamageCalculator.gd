extends Node
class_name DamageCalculator

static func calculate_damage(attacker: Entity, defender: Entity) -> int:
	# 1. Lấy sát thương cơ bản (Công - Thủ), không được nhỏ hơn 0
	var raw_damage = max(0, attacker.atk - defender.defense)
	
	# 2. Tính giảm trừ theo kháng (Resistance)
	# Công thức: raw * (1 - res/100)
	var after_res = raw_damage * (1.0 - (defender.res / 100.0))
	
	# 3. Nhân hệ số thuộc tính (Type Chart)
	var multiplier = TypeChart.get_multiplier(attacker.type, defender.type)
	var final_damage = after_res * multiplier
	
	# 4. Kiểm tra sát thương tối thiểu (5% công của người đánh)
	var min_damage = attacker.atk * 0.05
	if final_damage < min_damage:
		final_damage = min_damage
		
	# Trả về số nguyên (Làm tròn xuống)
	return int(final_damage)
