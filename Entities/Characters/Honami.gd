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
	max_hp = 600 # HP cao
	current_hp = 600
	atk = 90 # DMG thấp
	defense = 140
	res = 50
	spd = 90
	type = "Pure"
	is_character = true
	
	skills = [
		{"name": "Vệt Cắt Xót Thương", "method": "merciful_cleave", "cooldown_turns": 2, "target": "all_enemies", "details": "Vung vũ khí hình bán nguyệt, gây sát thương AoE lên toàn bộ kẻ địch."},
		{"name": "Điểm Tựa Vững Chắc", "method": "rearguard_stance", "cooldown_turns": 3, "target": "ally", "details": "Xóa toàn bộ debuff cho bản thân và 1 đồng minh, sau đó hồi máu cho cả hai."},
		{"name": "Án Tử Bình Yên", "method": "painless_execution", "initial_cooldown": 5, "once_per_battle": true, "target": "enemy", "details": "Đập tan mục tiêu, bỏ qua 50% DEF. Hồi máu toàn đội dựa trên kết quả."},
	]

func take_damage(amount: int, damage_type: String = "physical") -> bool:
	if is_harbor:
		damage_received.emit(0, damage_type)
		return false
	return super.take_damage(amount, damage_type)

func merciful_cleave(_target: Entity):
	"""
	[Vệt Cắt Xót Thương]: Sát thương AoE.
	"""
	print(entity_name, " vung vũ khí: [Vệt Cắt Xót Thương]!")
	for enemy in enemies:
		if enemy.current_hp > 0:
			var dmg = DamageCalculator.calculate_damage(self , enemy)
			enemy.take_damage(int(dmg * 0.8)) # Giảm chút dmg vì là AoE

func rearguard_stance(target: Entity):
	"""
	[Điểm Tựa Vững Chắc]: Xóa debuff và hồi máu.
	"""
	print(entity_name, " thiết lập [Điểm Tựa Vững Chắc] cho ", target.entity_name)
	
	# Xóa debuff cho bản thân và đồng minh
	self.clear_all_debuffs()
	target.clear_all_debuffs()
	
	# Hồi máu (30% HP tối đa của Honami)
	var heal_amount = int(self.max_hp * 0.3)
	self.heal(heal_amount)
	target.heal(heal_amount)

func painless_execution(target: Entity):
	"""
	[Án Tử Bình Yên]: Sát thương xuyên giáp và hồi máu toàn đội.
	"""
	print(entity_name, " giáng xuống [Án Tử Bình Yên]!")
	
	# Tính toán sát thương bỏ qua 50% DEF
	var original_def = target.defense
	target.defense = int(target.defense * 0.5)
	var dmg = DamageCalculator.calculate_damage(self , target)
	target.defense = original_def # Trả lại DEF
	
	var killed = target.take_damage(dmg)
	
	if killed:
		print("Kẻ địch gục ngã! Hồi 50% HP toàn đội.")
		for ally in allies:
			ally.heal(int(self.max_hp * 0.5))
	else:
		print("Kẻ địch còn sống. Gây Stun và hồi 25% HP toàn đội.")
		target.add_status({"type": "Stun", "duration": 1})
		for ally in allies:
			ally.heal(int(self.max_hp * 0.25))
