extends Entity
class_name Ena

"""
Ena: Nhân vật hệ Happy, kết hợp giữa sát thương duy trì (Poison) và hỗ trợ hồi phục.

Lối chơi của Ena tập trung vào việc bào mòn kẻ địch bằng độc tố và cung cấp 
khả năng hồi phục khẩn cấp cho đồng minh có lượng máu thấp nhất thông qua tuyệt kỹ.
"""

func _init():
	entity_name = "Ena"
	max_hp = 300
	current_hp = 300
	atk = 160
	defense = 95
	res = 15
	spd = 120
	type = "Happy"
	is_character = true
	
	skills = [
		{"name": "Nét Cọ Tàn Nhẫn", "method": "brush_stroke", "cooldown_turns": 2, "target": "enemy", "details": "Gây sát thương vật lý mạnh.\nTỷ lệ: 150% ATK."},
		{"name": "Bức Tranh Độc Đáo", "method": "toxic_criticism", "cooldown_turns": 3, "target": "enemy", "details": "Gây sát thương và gây Trúng độc (Poison) trong 3 lượt.\nTỷ lệ: 100% ATK."},
		{"name": "Kiệt Tác Dang Dở", "method": "masterpiece", "initial_cooldown": 5, "once_per_battle": true, "target": "enemy", "details": "Sát thương xuyên thấu cực lớn, gây Poison và hồi máu cho đồng đội yếu nhất.\nTỷ lệ: 250% ATK (Sát thương) / 150% ATK (Hồi máu)."},
	]

func brush_stroke(target: Entity):
	# Nét Cọ Toàn Nhẫn
	# Gây sát thương vật lý tương đương 150% lượng sát thương tính toán cơ bản.
	print(entity_name, " vung [Nét Cọ Tàn Nhẫn]!")
	var raw_dmg = DamageCalculator.calculate_damage(self , target)
	var scaled_dmg = int(raw_dmg * 1.5)
	target.take_damage(scaled_dmg)

func toxic_criticism(target: Entity):
	#Bức Tranh Độc Đáo
	#Gây sát thương vật lý và áp dụng trạng thái Trúng độc (Poison) 
	# mạnh lên mục tiêu trong 3 lượt.
	print(entity_name, " tung ra [Bức Tranh Độc Đáo]!")
	var dmg = DamageCalculator.calculate_damage(self , target)
	target.take_damage(dmg)
	target.add_status({"type": "Poison", "duration": 3, "percent": 0.15})

func masterpiece(target: Entity):
	#Kiệt Tác Dang Dở
	#Giải phóng một đòn tấn công gây sát thương thuần (Pure Damage) 250% ATK, 
	#áp dụng Poison cực mạnh. Sau đó, Ena tự động tìm và hồi phục cho đồng đội 
	#có lượng máu thấp nhất một lượng máu tương đương 150% ATK.
	print(entity_name, " hoàn thành [Kiệt Tác Dang Dở]!")
	var multiplier = TypeChart.get_multiplier(self.type, target.type)
	var massive_dmg = int(self.atk * 2.5 * multiplier)
	
	target.take_damage(massive_dmg, "pure")
	target.add_status({"type": "Poison", "duration": 4, "percent": 0.2})
	
	var lowest_ally = null
	var lowest_hp = 999999
	for ally in allies:
		if ally.current_hp > 0 and ally.current_hp < lowest_hp:
			lowest_hp = ally.current_hp
			lowest_ally = ally
			
	if lowest_ally != null:
		var heal_amount = int(self.atk * 1.5)
		lowest_ally.heal(heal_amount)
