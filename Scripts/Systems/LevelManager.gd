extends Node
class_name LevelManager

"""
LevelManager: Quản lý hệ thống cấp độ, kinh nghiệm và thăng tiến sức mạnh.

Lớp này xử lý việc tính toán phần thưởng kinh nghiệm, xử lý tiến trình lên cấp,
tự động nâng cấp chỉ số cho quái vật và áp dụng các giới hạn (Soft/Hard Cap).
"""

const SOFT_CAP_LEVEL = 50
const MAX_LEVEL = 100

static func get_exp_reward(enemy_level: int) -> int:
	"""
	Tính toán lượng kinh nghiệm (EXP) nhận được dựa trên cấp độ kẻ địch.
	
	Công thức: 40 + (enemy_level * 20).

	Args:
		enemy_level (int): Cấp độ của kẻ địch đã bị hạ gục.

	Returns:
		int: Tổng lượng EXP nhận được.
	"""
	return enemy_level * 75

static func gain_exp(entity: Entity, amount: int):
	"""
	Cấp kinh nghiệm cho một thực thể và kiểm tra điều kiện lên cấp.
	
	Nếu EXP tích lũy vượt quá mốc tiếp theo, thực thể sẽ tự động lên cấp 
	thông qua process_level_up.

	Args:
		entity (Entity): Thực thể nhận kinh nghiệm.
		amount (int): Lượng kinh nghiệm nhận được.
	"""
	if entity == null or entity.level >= MAX_LEVEL:
		return
		
	entity.current_exp += amount
	
	while entity.current_exp >= entity.next_level_exp and entity.level < MAX_LEVEL:
		entity.current_exp -= entity.next_level_exp
		process_level_up(entity)

static func process_level_up(entity: Entity):
	"""
	Thực hiện các thay đổi khi thực thể lên một cấp độ mới.

	Quy trình bao gồm:
	- Tăng Skill Points (3 cho Player, 2 cho Quái).
	- Tăng chỉ số cơ bản (5% growth, giảm còn 2% sau Soft Cap lv 50).
	- Áp dụng Hard Cap chỉ số từ định nghĩa trong Entity.
	- Hồi phục đầy HP và cập nhật EXP curve (1.2x hoặc 1.5x sau lv 50).
	- Tự động nâng cấp chỉ số cho quái vật.

	Args:
		entity (Entity): Thực thể lên cấp.
	"""
	if entity == null: return
	
	entity.level += 1
	
	if entity.is_character:
		entity.skill_points += 3
	else:
		entity.skill_points += 2
	
	var growth_rate = 0.05
	var spd_growth = 0.03
	
	if entity.level > SOFT_CAP_LEVEL:
		growth_rate = 0.02 
		spd_growth = 0.01
		
	entity.max_hp += int(entity.max_hp * growth_rate)
	entity.atk += int(entity.atk * growth_rate)
	entity.defense += int(entity.defense * growth_rate)
	entity.spd += int(entity.spd * spd_growth)

	entity.max_hp = min(entity.max_hp, entity.stat_caps.get("max_hp", 9999))
	entity.atk = min(entity.atk, entity.stat_caps.get("atk", 9999))
	entity.defense = min(entity.defense, entity.stat_caps.get("defense", 9999))
	entity.spd = min(entity.spd, entity.stat_caps.get("spd", 9999))

	if entity.current_hp > 0:
		entity.current_hp = entity.max_hp
		
	entity.hp_changed.emit(entity.current_hp, entity.max_hp)
	entity.level_changed.emit(entity.level)
	
	var exp_curve = 1.2
	if entity.level >= SOFT_CAP_LEVEL:
		exp_curve = 1.5
	entity.next_level_exp = int(entity.next_level_exp * exp_curve)
	
	if not entity.is_character:
		_auto_upgrade_monster(entity)

static func set_initial_level(entity: Entity, target_level: int):
	"""
	Thiết lập cấp độ ban đầu cho một thực thể (thường dùng khi spawn).

	Lên cấp hàng loạt cho đến khi đạt target_level và đảm bảo SP 
	được phân bổ chính xác cho quái vật.

	Args:
		entity (Entity): Thực thể cần thiết lập.
		target_level (int): Cấp độ đích muốn đạt tới.
	"""
	if entity == null:
		return
		
	if target_level <= 1: 
		entity.skill_points = target_level * (3 if entity.is_character else 2)
		if not entity.is_character:
			_auto_upgrade_monster(entity)
		return
	
	target_level = clamp(target_level, 1, MAX_LEVEL)
	
	var levels_to_gain = target_level - entity.level
	for i in range(levels_to_gain):
		process_level_up(entity)
	
	entity.skill_points = target_level * (3 if entity.is_character else 2)
	if not entity.is_character:
		_auto_upgrade_monster(entity)
		
	entity.current_exp = 0

static func _auto_upgrade_monster(entity: Entity):
	"""
	Tự động phân bổ điểm kỹ năng (SP) cho quái vật vào các chỉ số ngẫu nhiên.

	Args:
		entity (Entity): Thực thể quái vật.
	"""
	var stats = UpgradeManager.UPGRADE_AMOUNTS.keys()
	var attempts = 0
	while entity.skill_points >= UpgradeManager.UPGRADE_COST and attempts < 100:
		attempts += 1
		var stat = stats[randi() % stats.size()]
		if not UpgradeManager.upgrade_stat(entity, stat):
			continue
