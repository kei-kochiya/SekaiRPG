extends Node
class_name LevelManager

"""
Tóm tắt: LevelManager là lớp tĩnh (Static Class) chuyên trách tính toán kinh nghiệm và thăng cấp nhân vật.

Chức năng chính:
- Xử lý việc cấp và cộng dồn điểm kinh nghiệm (EXP) thông qua hàm `gain_exp()`.
- Tự động tính toán số cấp thăng lên nếu điểm EXP vượt mức, xử lý chuỗi lên cấp liên tục.
- Cung cấp thuật toán gia tăng chỉ số gốc dựa trên tỷ lệ % (Growth Rate) và áp dụng cơ chế Soft Cap/Hard Cap.
- Tự động phân bổ Điểm Kỹ Năng (SP) ngẫu nhiên cho hệ thống quái vật để tạo độ khó biến thiên.
"""

# ── Hằng Số Cấp Độ ─────────────────────────────────────────────────────────

const SOFT_CAP_LEVEL = 50
const MAX_LEVEL = 100

# ── Xử Lý Kinh Nghiệm ──────────────────────────────────────────────────────

# Tính toán lượng kinh nghiệm nhận được dựa trên cấp độ kẻ địch
static func get_exp_reward(enemy_level: int) -> int:
	return enemy_level * 75

static func gain_exp(entity: Entity, amount: int):
	"""
	Cấp kinh nghiệm cho một thực thể và kiểm tra điều kiện lên cấp.
	
	Args:
		entity (Entity): Thực thể nhận kinh nghiệm.
		amount (int): Lượng kinh nghiệm nhận được.
	Returns: Không có
	"""
	if entity == null or entity.level >= MAX_LEVEL:
		return
		
	entity.current_exp += amount
	
	while entity.current_exp >= entity.next_level_exp and entity.level < MAX_LEVEL:
		entity.current_exp -= entity.next_level_exp
		process_level_up(entity)

# ── Xử Lý Lên Cấp ──────────────────────────────────────────────────────────

static func process_level_up(entity: Entity):
	"""
	Thực hiện các thay đổi chỉ số khi thực thể lên một cấp độ mới.
	
	Args:
		entity (Entity): Thực thể vừa được lên cấp.
	Returns: Không có
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
	Thiết lập cấp độ ban đầu cho một thực thể bằng cách lặp vòng lên cấp ảo.
	
	Args:
		entity (Entity): Thực thể cần thiết lập.
		target_level (int): Cấp độ đích muốn đạt tới.
	Returns: Không có
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

# ── Nâng Cấp Tự Động ───────────────────────────────────────────────────────

# Tự động phân bổ ngẫu nhiên điểm kỹ năng (SP) cho quái vật
static func _auto_upgrade_monster(entity: Entity):
	var stats = UpgradeManager.UPGRADE_AMOUNTS.keys()
	var attempts = 0
	while entity.skill_points >= UpgradeManager.UPGRADE_COST and attempts < 100:
		attempts += 1
		var stat = stats[randi() % stats.size()]
		if not UpgradeManager.upgrade_stat(entity, stat):
			continue
