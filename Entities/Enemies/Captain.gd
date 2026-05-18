extends Entity
class_name Captain

"""
Tóm tắt: Định nghĩa lớp kẻ địch Captain (Harbor Boss).

Chức năng chính:
- Khởi tạo chỉ số vượt trội (Boss) với lượng HP khổng lồ và ATK cao.
- Thực thi kỹ năng [Xử Quyết]: Đòn tấn công đơn mục tiêu gây sát thương vật lý lớn.
"""

# ── Khởi Tạo ───────────────────────────────────────────────────────────────


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

# ── Kỹ Năng Kích Hoạt ──────────────────────────────────────────────────────

func execution(target: Entity):
	# [Xử Quyết]: Đòn tấn công vật lý đơn mục tiêu.
	print(entity_name, " tung đòn [Xử Quyết]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
