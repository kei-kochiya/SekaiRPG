extends Entity
class_name Honami

"""
Honami: Nhân vật hệ Pure, chuyên về hỗ trợ hồi phục và thanh tẩy trạng thái xấu.

Lối chơi của Honami tập trung hoàn toàn vào việc duy trì sự sống cho đội hình. 
Cô sở hữu khả năng hồi phục mạnh mẽ cho cả đơn mục tiêu và diện rộng, 
đồng thời có khả năng thanh tẩy các hiệu ứng bất lợi.
"""

@export var is_harbor: bool = false

func _init():
	entity_name = "Honami"
	max_hp = 400
	current_hp = 400
	atk = 110
	defense = 120
	res = 40
	spd = 95
	type = "Pure"
	is_character = true
	
	skills = [
		{"name": "Nhát Chém Dịu Dàng", "method": "gentle_strike", "cooldown_turns": 2, "target": "enemy", "details": "Gây sát thương vật lý mạnh.\nTỷ lệ: 150% ATK."},
		{"name": "Làn Gió Thanh Tẩy", "method": "cleansing_breeze", "cooldown_turns": 3, "target": "ally", "details": "Hồi máu cho một đồng đội và xóa bỏ một hiệu ứng xấu ngẫu nhiên.\nTỷ lệ: 100% ATK."},
		{"name": "Giai Điệu Hồi Phục", "method": "healing_harmony", "cooldown_turns": 4, "target": "all_allies", "details": "Hồi máu cho toàn bộ đồng đội.\nTỷ lệ: 120% ATK."},
	]

func take_damage(amount: int, damage_type: String = "physical") -> bool:
	"""
	Xử lý nhận sát thương với cơ chế Bất tử (Invulnerability) theo kịch bản.

	Trong sự kiện tại Cảng (Harbor), Honami sẽ không nhận bất kỳ sát thương nào 
	để đảm bảo tiến trình kịch bản.

	Args:
		amount (int): Lượng sát thương gốc.
		damage_type (String): Loại sát thương.

	Returns:
		bool: Luôn trả về False nếu đang trong trạng thái bất tử.
	"""
	if is_harbor:
		damage_received.emit(0, damage_type)
		return false
	return super.take_damage(amount, damage_type)

func gentle_strike(target: Entity):
	"""
	[Nhát Chém Dịu Dàng]: Tấn công đơn mục tiêu cơ bản.

	Gây sát thương vật lý tương đương 150% lượng sát thương tính toán cơ bản.

	Args:
		target (Entity): Mục tiêu chịu đòn.
	"""
	print(entity_name, " sử dụng [Nhát Chém Dịu Dàng]!")
	var raw_dmg = DamageCalculator.calculate_damage(self, target)
	var scaled_dmg = int(raw_dmg * 1.5)
	target.take_damage(scaled_dmg)

func cleansing_breeze(target: Entity):
	"""
	[Làn Gió Thanh Tẩy]: Hồi phục và thanh tẩy đơn mục tiêu.

	Hồi phục máu tương đương 100% ATK và tự động xóa bỏ một 
	hiệu ứng trạng thái xấu ngẫu nhiên trên mục tiêu.

	Args:
		target (Entity): Đồng minh cần hỗ trợ.
	"""
	print(entity_name, " sử dụng [Làn Gió Thanh Tẩy]!")
	var heal_amount = int(self.atk * 1.0)
	target.heal(heal_amount)
	
	if not target.active_statuses.is_empty():
		var status = target.active_statuses.pick_random()
		target.remove_statuses([status])

func healing_harmony(_target: Entity):
	"""
	[Giai Điệu Hồi Phục]: Tuyệt kỹ hồi phục diện rộng của Honami.

	Hồi phục máu cho toàn bộ đồng minh còn sống một lượng tương đương 120% ATK.

	Args:
		_target (Entity): Tham số không sử dụng (tác động toàn đội ta).
	"""
	print(entity_name, " sử dụng [Giai Điệu Hồi Phục]!")
	var heal_amount = int(self.atk * 1.2)
	for ally in allies:
		if ally.current_hp > 0:
			ally.heal(heal_amount)
