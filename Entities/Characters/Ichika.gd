extends Entity
class_name Ichika

"""
Ichika: Nhân vật hệ Cool, thiên hướng sát thương vật lý mạnh và kỹ năng tự tổn hại.

Lối chơi của Ichika tập trung vào việc gây sát thương lớn và áp dụng hiệu ứng 
Chảy máu (Bleed). Tuyệt kỹ của cô có khả năng bỏ qua phòng thủ nhưng đổi lại 
bằng việc tiêu tốn sinh lực của bản thân.
"""

func _init():
	entity_name = "Ichika"
	max_hp = 175
	current_hp = 175
	atk = 150
	defense = 80
	res = 20
	spd = 100
	type = "Cool"
	is_character = true
	
	skills = [
		{"name": "Chém Kim Loại", "method": "metal_cut", "cooldown_turns": 2, "target": "enemy", "details": "Gây sát thương vật lý mạnh lên một mục tiêu.\nTỷ lệ: 150% ATK."},
		{"name": "Lưỡi Đao Rỉ Máu", "method": "bleeding_edge", "cooldown_turns": 3, "target": "enemy", "details": "Gây sát thương và áp dụng trạng thái Chảy máu (Bleed) trong 3 lượt.\nTỷ lệ: 100% ATK."},
		{"name": "Ảnh Kiếm", "method": "shadow_blade", "initial_cooldown": 5, "once_per_battle": true, "target": "enemy", "details": "Sát thương bỏ qua phòng thủ (Pure DMG).\nTiêu tốn 15% HP hiện tại. Tỷ lệ: 300% ATK."},
	]

func can_use_skill(skill_name: String) -> bool:
	"""
	Kiểm tra điều kiện đặc biệt để sử dụng kỹ năng của Ichika.

	Ngoài thời gian hồi chiêu, kỹ năng [Ảnh Kiếm] yêu cầu Ichika phải 
	còn nhiều hơn 1 HP để kích hoạt.

	Args:
		skill_name (String): Tên định danh kỹ năng.

	Returns:
		bool: True nếu đủ điều kiện sử dụng, ngược lại False.
	"""
	if not CooldownManager.is_skill_ready(self , skill_name):
		return false
	if skill_name == "shadow_blade" and current_hp <= 1:
		return false
	return true

func metal_cut(target: Entity):
	"""
	[Chém Kim Loại]: Kỹ năng tấn công đơn mục tiêu mạnh.

	Gây sát thương vật lý tương đương 150% lượng sát thương tính toán cơ bản.

	Args:
		target (Entity): Mục tiêu chịu đòn.
	"""
	print(entity_name, " sử dụng [Chém Kim Loại]!")
	var raw_dmg = DamageCalculator.calculate_damage(self , target)
	var scaled_dmg = int(raw_dmg * 1.5)
	target.take_damage(scaled_dmg)

func bleeding_edge(target: Entity):
	"""
	[Lưỡi Đao Rỉ Máu]: Tấn công và gây hiệu ứng xấu.

	Gây sát thương vật lý và áp dụng trạng thái Chảy máu (Bleed) 
	lên mục tiêu trong 3 lượt.

	Args:
		target (Entity): Mục tiêu chịu đòn.
	"""
	print(entity_name, " sử dụng [Lưỡi Đao Rỉ Máu]!")
	var dmg = DamageCalculator.calculate_damage(self , target)
	target.take_damage(dmg)
	target.add_status({"type": "Bleed", "duration": 3})

func shadow_blade(target: Entity):
	"""
	[Ảnh Kiếm]: Tuyệt kỹ cực hạn của Ichika.

	Giải phóng đòn tấn công cực mạnh gây sát thương thuần (Pure Damage) 
	bằng 300% ATK, bỏ qua DEF và RES. Đổi lại, Ichika tự gây sát thương 
	lên bản thân bằng 15% HP hiện tại (không gây chết người).

	Args:
		target (Entity): Mục tiêu chịu đòn.
	"""
	if current_hp <= 1:
		return
	
	print(entity_name, " giải phóng [Ảnh Kiếm] cực hạn!")
	var massive_dmg = self.atk * 3
	var self_dmg = int(self.current_hp * 0.15)
	self_dmg = min(self_dmg, current_hp - 1)
	
	target.take_damage(massive_dmg, "pure")
	self.take_damage(self_dmg, "pure")
