extends Entity
class_name Mizuki

"""
Mizuki: Nhân vật hệ Cute, chuyên về khống chế và sát thương duy trì (Poison).

Lối chơi của Mizuki tập trung vào việc áp dụng các hiệu ứng bất lợi lên kẻ địch 
thông qua độc tố và các đòn tấn công tinh tế.
"""

func _init():
	entity_name = "Mizuki"
	max_hp = 250
	current_hp = 250
	atk = 125
	defense = 60
	res = 8
	spd = 125
	type = "Cute"
	is_character = true
	
	skills = [
		{"name": "Ruy Băng Trói Buộc", "method": "ribbon_bind", "cooldown_turns": 2, "target": "enemy", "details": "Gây sát thương vật lý mạnh.\nTỷ lệ: 150% ATK."},
		{"name": "Bí Mật Cay Đắng", "method": "bitter_secret", "cooldown_turns": 3, "target": "enemy", "details": "Gây sát thương và gây Trúng độc (Poison) trong 3 lượt.\nTỷ lệ: 100% ATK."},
		{"name": "Rối Độc Thoại", "method": "lonely_marionette", "initial_cooldown": 5, "once_per_battle": true, "target": "enemy", "details": "Sát thương xuyên thấu (Pure DMG) và gây Poison mạnh trong 4 lượt.\nTỷ lệ: 250% ATK."},
	]

func ribbon_bind(target: Entity):
	# [Ruy Băng Trói Buộc]: Đòn đơn 150% ATK vật lý.
	print(entity_name, " trói chặt bằng [Ruy Băng Trói Buộc]!")
	var raw_dmg = DamageCalculator.calculate_damage(self , target)
	var scaled_dmg = int(raw_dmg * 1.5)
	target.take_damage(scaled_dmg)

func bitter_secret(target: Entity):
	# [Bí Mật Cay Đắng]: Đòn đơn vật lý + Poison 3 lượt (15% HP/lượt).
	print(entity_name, " thì thầm [Bí Mật Cay Đắng]...")
	var dmg = DamageCalculator.calculate_damage(self , target)
	target.take_damage(dmg)
	target.add_status({"type": "Poison", "duration": 3, "percent": 0.15})

func lonely_marionette(target: Entity):
	# [Rối Độc Thoại]: Tuyệt kỹ - Pure DMG 250% ATK + Poison cực mạnh 4 lượt.
	print(entity_name, " giật dây [Rối Độc Thoại]!")
	var multiplier = TypeChart.get_multiplier(self.type, target.type)
	var massive_dmg = int(self.atk * 2.5 * multiplier)
	
	target.take_damage(massive_dmg, "pure")
	target.add_status({"type": "Poison", "duration": 4, "percent": 0.2})
