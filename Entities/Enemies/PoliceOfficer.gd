extends Entity
class_name PoliceOfficer

"""
Tóm tắt: Định nghĩa lớp kẻ địch PoliceOfficer (Cảnh sát Quốc tế).

Chức năng chính:
- Khởi tạo chỉ số của đặc nhiệm cảnh sát (hệ Pure: không khắc/bị khắc bởi Ena hay Mizuki): đông người, phòng thủ khá, tốc độ cao.
- Kỹ năng [Dùi Cui]: đòn vật lý có tỷ lệ làm choáng.
- Kỹ năng [Súng Điện]: sát thương kèm Choáng 1 lượt (hồi 3 lượt).
"""

# ── Khởi Tạo ───────────────────────────────────────────────────────────────

func _init():
	entity_name = "Cảnh Sát Quốc Tế"
	max_hp = 280
	current_hp = 280
	atk = 80
	defense = 45
	res = 10
	spd = 100
	type = "Pure"
	is_character = false
	
	skills = [
		{"name": "Dùi Cui", "method": "baton_strike", "cooldown_turns": 1, "target": "enemy"},
		{"name": "Súng Điện", "method": "taser_shock", "cooldown_turns": 3, "target": "enemy"},
	]

# ── Kỹ Năng Kích Hoạt ──────────────────────────────────────────────────────

func baton_strike(target: Entity):
	# [Dùi Cui]: Tấn công vật lý + 25% tỷ lệ gây Stun 1 lượt.
	print(entity_name, " vung [Dùi Cui]!")
	var dmg = DamageCalculator.calculate_damage(self, target)
	target.take_damage(dmg)
	if randf() < 0.25:
		target.add_status({"type": "Stun", "duration": 1})

func taser_shock(target: Entity):
	# [Súng Điện]: Sát thương 80% + Stun 1 lượt chắc chắn.
	print(entity_name, " bóp cò [Súng Điện]!")
	var dmg = DamageCalculator.calculate_damage(self, target, 0.8)
	target.take_damage(int(dmg), "shock")
	target.add_status({"type": "Stun", "duration": 1})

func get_portrait_path() -> String:
	return "res://Assets/Person/police.svg"
