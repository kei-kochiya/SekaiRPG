extends Entity
class_name Captain

"""
Captain: Đội trưởng vệ binh, Boss chính tại Cảng (Harbor Boss).
Có lượng máu và sát thương cực lớn, là thử thách lớn nhất cho người chơi ở giai đoạn đầu.
"""

func _init():
	entity_name = "Đội Trưởng"
	max_hp = 3500
	current_hp = 3500
	atk = 240
	defense = 130
	res = 15
	spd = 110
	type = "Mysterious"
	is_character = false
	
	skills = [
		{"name": "Xử Quyết", "method": "execution", "cooldown_turns": 1, "target": "enemy"}
	]

func execution(target: Entity):
	# [Xử Quyết]: Đòn tấn công vật lý đơn mục tiêu.
	print(entity_name, " tung đòn [Xử Quyết]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
