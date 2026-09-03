extends Entity
class_name CyborgEnforcer

"""
Tóm tắt: Kẻ địch Vệ Binh Cơ Giới Giáp Thép (Cyborg Enforcer).

Đặc điểm:
- Hệ: Cute (Khắc chế Cool, Yếu trước Happy).
- Chống chịu cực cao (HP 500, DEF 60), Break Gauge dày (180).
- Kỹ năng: Nện Khiên Năng Lượng (Shield Slam - Choáng 1 lượt) và Khiên Phản Lực (Bảo vệ đồng minh).
"""

func _init():
	entity_name = "Vệ Binh Cơ Giới"
	max_hp = 500
	current_hp = 500
	atk = 80
	defense = 60
	res = 30
	spd = 75
	type = "Cute"
	is_character = false
	max_break_gauge = 180
	break_gauge = 180
	
	skills = [
		{"name": "Nện Khiên Năng Lượng", "method": "shield_slam", "cooldown_turns": 2, "target": "enemy"},
		{"name": "Bật Khiên Bảo Hộ", "method": "barrier_boost", "cooldown_turns": 3, "target": "self"}
	]

func shield_slam(target: Variant = null):
	print(entity_name, " tung đòn [Nện Khiên Năng Lượng]!")
	if target and target.current_hp > 0:
		var dmg = DamageCalculator.calculate_damage(self, target) * 1.0
		target.take_damage(int(dmg), "physical")
		target.add_status({"type": "Stun", "duration": 1})
		print("   -> Gây Choáng 1 lượt cho ", target.entity_name)

func barrier_boost(_target: Variant = null):
	print(entity_name, " kích hoạt [Bật Khiên Bảo Hộ] gia cố phòng thủ!")
	defense += 40
	heal(80)

func get_portrait_path() -> String:
	return "res://Assets/Person/suit.png"
