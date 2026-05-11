extends Entity
class_name Kanade

"""
Kanade: Nhân vật hệ Cool, thiên hướng sát thương bùng nổ nhưng phòng thủ thấp.

Lối chơi của Kanade tập trung vào việc gây sát thương lớn và khống chế (Stun). 
Cô có khả năng đặc biệt giúp chuyển hướng một phần sát thương sang đồng minh 
để bù đắp cho chỉ số phòng thủ cực thấp của mình.
"""

func _init():
	entity_name = "Kanade"
	max_hp = 110
	current_hp = 110
	atk = 200
	defense = 30
	res = 5
	spd = 90
	type = "Cool"
	is_character = true
	
	skills = [
		{"name": "Tuyệt Âm Phân Rã", "method": "resonance", "cooldown_turns": 2, "target": "enemy", "details": "Gây sát thương vật lý mạnh.\nTỷ lệ: 150% ATK."},
		{"name": "Giọng Ca Vô Thanh", "method": "soundless_voice", "cooldown_turns": 3, "target": "enemy", "details": "Gây sát thương và Làm choáng (Stun) trong 1 lượt.\nTỷ lệ: 100% ATK."},
		{"name": "Final Requiem", "method": "salvation_song", "initial_cooldown": 5, "once_per_battle": true, "target": "enemy", "details": "Sát thương diện rộng xuyên thấu (Pure DMG) và Làm choáng 2 lượt.\nTỷ lệ: 350% ATK."},
	]

func resonance(target: Entity):
	"""
	[Cộng Hưởng]: Tấn công đơn mục tiêu.

	Gây sát thương vật lý tương đương 150% lượng sát thương tính toán cơ bản.

	Args:
		target (Entity): Mục tiêu chịu đòn.
	"""
	print(entity_name, " ngân lên [Tuyệt Âm Phân Rã]!")
	var raw_dmg = DamageCalculator.calculate_damage(self , target)
	var scaled_dmg = int(raw_dmg * 1.5)
	target.take_damage(scaled_dmg)

func soundless_voice(target: Entity):
	"""
	[Giọng Ca Vô Thanh]: Tấn công và gây khống chế.

	Gây sát thương vật lý và áp dụng trạng thái Choáng (Stun) trong 1 lượt.

	Args:
		target (Entity): Mục tiêu chịu đòn.
	"""
	print(entity_name, " bóp nghẹt bằng [Giọng Ca Vô Thanh]...")
	var dmg = DamageCalculator.calculate_damage(self , target)
	target.take_damage(dmg)
	target.add_status({"type": "Stun", "duration": 1})

func salvation_song(target: Entity):
	"""
	[Khúc Ca Cứu Rỗi]: Tuyệt kỹ khống chế diện rộng của Kanade.

	Gây sát thương thuần (Pure Damage) cực lớn (350% ATK) và áp dụng 
	trạng thái Choáng (Stun) trong 2 lượt.

	Args:
		target (Entity): Mục tiêu chịu đòn.
	"""
	print(entity_name, " bùng nổ với [Final Requiem]!")
	var multiplier = TypeChart.get_multiplier(self.type, target.type)
	var massive_dmg = int(self.atk * 3.5 * multiplier)
	
	target.take_damage(massive_dmg, "pure")
	target.add_status({"type": "Stun", "duration": 2})

func take_damage(amount: int, damage_type: String = "physical") -> bool:
	"""
	Xử lý nhận sát thương với cơ chế Chuyển hướng (Deflect).

	Kanade có 20% tỷ lệ chuyển 50% lượng sát thương nhận vào sang cho 
	một đồng minh ngẫu nhiên còn sống. Nếu không có đồng minh nào, 
	cô chỉ nhận 50% sát thương.

	Args:
		amount (int): Lượng sát thương gốc.
		damage_type (String): Loại sát thương.

	Returns:
		bool: True nếu Kanade bị hạ gục, ngược lại False.
	"""
	if randf() < 0.20:
		print("[DEFLECT] Kanade bẻ cong đường tấn công!")
		var halved_dmg = int(amount * 0.5)
		var alive_allies = allies.filter(func(a): return a != self and a.current_hp > 0)
		if not alive_allies.is_empty():
			var transfer_target = alive_allies[randi() % alive_allies.size()]
			transfer_target.take_damage(halved_dmg, damage_type)
			return super.take_damage(0, damage_type)
		else:
			return super.take_damage(halved_dmg, damage_type)
	
	return super.take_damage(amount, damage_type)
