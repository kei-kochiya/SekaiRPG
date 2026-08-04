extends Entity
class_name PrimeMinister

"""
Tóm tắt: Định nghĩa lớp kẻ địch Prime Minister (Boss cuối).

Chức năng chính:
- Khởi tạo chỉ số cực cao.
- Có kỹ năng diện rộng (Triệu hồi vệ sĩ bắn tỉa) và khóa buff.
"""

func _init():
	entity_name = "Thủ Tướng"
	max_hp = 12000
	current_hp = 12000
	atk = 400
	defense = 250
	res = 50
	spd = 130
	type = "Corrupt"
	is_character = false
	
	skills = [
		{"name": "Lệnh Bắn Tỉa", "method": "snipe_order", "cooldown_turns": 2, "target": "all_enemies"},
		{"name": "Khóa Quyền Bính", "method": "lock_power", "cooldown_turns": 4, "target": "all_enemies"}
	]

func snipe_order(targets: Array):
	# Tấn công diện rộng gây sát thương vật lý
	print(entity_name, " tung đòn [Lệnh Bắn Tỉa]!")
	for t in targets:
		if t.current_hp > 0:
			var dmg = DamageCalculator.calculate_damage(self, t) * 0.8
			t.take_damage(int(dmg))

func lock_power(targets: Array):
	print(entity_name, " tung đòn [Khóa Quyền Bính]!")
	for t in targets:
		if t.current_hp > 0:
			t.apply_status_effect("Stun", 1)
			t.take_damage(50)

func get_portrait_path() -> String:
	return "res://Assets/Person/suit.png"
