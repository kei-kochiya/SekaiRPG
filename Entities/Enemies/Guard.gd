extends Entity
class_name Guard

"""
Guard: Vệ binh tuần tra tại Cảng. 
Sở hữu lượng máu khá và có khả năng gây Choáng (Stun).
"""

func _init():
	entity_name = "Lính Cảng"
	max_hp = 250
	current_hp = 250
	atk = 75
	defense = 40
	res = 10
	spd = 95
	type = "Mysterious"
	is_character = false
	
	skills = [
		{"name": "Trấn Áp", "method": "suppress", "cooldown_turns": 2, "target": "enemy"}
	]

func suppress(target: Entity):
	"""
	[Trấn Áp]: Tấn công mục tiêu và có 30% tỉ lệ gây Choáng trong 1 lượt.
	"""
	print(entity_name, " sử dụng [Trấn Áp]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
	if randf() < 0.3:
		print(entity_name, " đã làm choáng mục tiêu!")
		target.add_status({"type": "Stun", "duration": 1})
