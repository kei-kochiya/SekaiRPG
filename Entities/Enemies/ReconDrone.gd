extends Entity
class_name ReconDrone

"""
Tóm tắt: Kẻ địch Drone Trinh Sát Cơ Động (Recon Drone).

Đặc điểm:
- Hệ: Cool (Khắc chế Happy, Yếu trước Cute).
- Tốc độ cực cao (SPD 140), khả năng né tránh và quấy rối đội hình phe ta.
- Kỹ năng: Quét Điểm Yếu (hạ DEF) và Xung EMP (đẩy lùi Action Value).
"""

func _init():
	entity_name = "Drone Trinh Sát"
	max_hp = 180
	current_hp = 180
	atk = 65
	defense = 20
	res = 15
	spd = 140
	type = "Cool"
	is_character = false
	max_break_gauge = 80
	break_gauge = 80
	
	skills = [
		{"name": "Xung Sốc EMP", "method": "emp_shock", "cooldown_turns": 2, "target": "enemy"},
		{"name": "Quét Điểm Yếu", "method": "scan_weakness", "cooldown_turns": 3, "target": "enemy"}
	]

func emp_shock(target: Variant = null):
	print(entity_name, " phóng [Xung Sốc EMP]!")
	if target and target.current_hp > 0:
		var dmg = DamageCalculator.calculate_damage(self, target) * 0.9
		target.take_damage(int(dmg), "shock")
		target.action_gauge = max(0.0, target.action_gauge - 2500.0)
		print("   -> Đẩy lùi 2500 Action Value của ", target.entity_name)

func scan_weakness(target: Variant = null):
	print(entity_name, " kích hoạt [Quét Điểm Yếu] lên ", target.entity_name if target else "mục tiêu")
	if target and target.current_hp > 0:
		target.defense = max(0, target.defense - 25)
		target.add_status({"type": "Slow", "duration": 2})

func get_portrait_path() -> String:
	return "res://Assets/Icons/stun.png"
