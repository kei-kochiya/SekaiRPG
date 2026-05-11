extends Entity
class_name Mafuyu

"""
Mafuyu: Nhân vật hệ Mysterious, sở hữu chỉ số toàn diện và sát thương diện rộng (AoE).

Lối chơi của Mafuyu tập trung vào việc duy trì sát thương duy trì thông qua 
hiệu ứng Chảy máu (Bleed) và dọn dẹp kẻ địch bằng các đòn đánh diện rộng mạnh mẽ.
"""

func _init():
	entity_name = "Mafuyu"
	max_hp = 500
	current_hp = 500
	atk = 300
	defense = 135
	res = 20
	spd = 150
	type = "Mysterious"
	is_character = true
	
	skills = [
		{"name": "Lưỡi Dao Vô Hồn", "method": "numb_blade", "cooldown_turns": 2, "target": "enemy", "details": "Phóng dao găm từ xa. Gây sát thương và 1 stack Bleed."},
		{"name": "Vực Thẳm Vô Định", "method": "freezing_void", "cooldown_turns": 3, "target": "all_enemies", "details": "Gây DMG và 2 stack Bleed cho 2 kẻ địch bất kỳ."},
		{"name": "Lost World", "method": "lost_world", "initial_cooldown": 5, "once_per_battle": true, "target": "all_enemies", "details": "Sát thương scale theo máu đã mất. Nếu có người sống sót, gây 2 stack Bleed cho cả 2 phe."},
	]

func numb_blade(target: Entity):
	#Lưỡi Dao Vô Hồn
	#Sát thương đơn và 1 Bleed.
	print(entity_name, " phóng [Lưỡi Dao Vô Hồn]!")
	var dmg = DamageCalculator.calculate_damage(self , target)
	target.take_damage(dmg)
	target.add_status({"type": "Bleed", "duration": 3})

func freezing_void(_target: Entity):
	#Vực Thẳm Vô Định
	#Tấn công 2 kẻ địch ngẫu nhiên (hoặc 1 kẻ địch 2 lần).
	print(entity_name, " giải phóng [Vực Thẳm Vô Định]!")
	var alive_enemies = []
	for e in enemies:
		if e.current_hp > 0: alive_enemies.append(e)
	
	if alive_enemies.is_empty(): return
	
	for i in range(2):
		var target = alive_enemies.pick_random()
		var dmg = DamageCalculator.calculate_damage(self , target)
		target.take_damage(int(dmg * 0.7)) # Giảm sát thương mỗi hit
		target.add_status({"type": "Bleed", "duration": 3})

func lost_world(_target: Entity):
	#Lost World
	#Sát thương cực lớn dựa trên HP đã mất.
	print(entity_name, " kích hoạt [Lost World]...")
	
	var lost_hp_ratio = 1.0 - (float(current_hp) / max_hp)
	var dmg_mult = 1.0 + (lost_hp_ratio * 2.0) # Tối đa x3 sát thương khi gần hết máu
	
	for e in enemies:
		if e.current_hp > 0:
			var base_dmg = DamageCalculator.calculate_damage(self , e)
			var final_dmg = int(base_dmg * dmg_mult)
			e.take_damage(final_dmg, "pure")
	
	# Kiểm tra xem còn ai sống sót
	var survivors = false
	for e in enemies + allies:
		if e.current_hp > 0:
			survivors = true
			break
	
	if survivors:
		print("Vẫn còn kẻ sống sót... Bóng tối lan tỏa (2 Bleed stacks cho tất cả).")
		for e in enemies + allies:
			if e.current_hp > 0:
				e.add_status({"type": "Bleed", "duration": 3})
				e.add_status({"type": "Bleed", "duration": 3})
