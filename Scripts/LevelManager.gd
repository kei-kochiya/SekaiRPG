extends Node
class_name LevelManager

const SOFT_CAP_LEVEL = 50
const MAX_LEVEL = 100

static func get_exp_reward(enemy_level: int) -> int:
	# Base 40 + 20 per level. (e.g. Lv 5 = 140 EXP)
	return 40 + (enemy_level * 20)

# Hàm nhận EXP sau trận đấu
static func gain_exp(entity: Entity, amount: int):
	if entity.level >= MAX_LEVEL:
		return
		
	entity.current_exp += amount
	print(entity.entity_name, " nhận ", amount, " EXP.")
	
	# Vòng lặp xử lý việc nhận quá nhiều EXP và lên nhiều cấp cùng lúc
	while entity.current_exp >= entity.next_level_exp and entity.level < MAX_LEVEL:
		entity.current_exp -= entity.next_level_exp
		process_level_up(entity)

# Hàm xử lý logic lên 1 cấp
static func process_level_up(entity: Entity):
	entity.level += 1
	
	# Nhận Skill Points (SP)
	if entity.is_character:
		entity.skill_points += 3 # Công thức Level * 2 + bonus
	else:
		entity.skill_points += 2 # Quái SP = Level * 2
	
	# Xử lý Soft Cap cho chỉ số
	var growth_rate = 0.05
	if entity.level > SOFT_CAP_LEVEL:
		growth_rate = 0.02 
		
	entity.max_hp += int(entity.max_hp * growth_rate)
	entity.atk += int(entity.atk * growth_rate)
	entity.defense += int(entity.defense * growth_rate)
	entity.spd += int(entity.spd * growth_rate)

	# Clamp theo Hard Cap
	entity.max_hp = min(entity.max_hp, entity.stat_caps.get("max_hp", 9999))
	entity.atk = min(entity.atk, entity.stat_caps.get("atk", 9999))
	entity.defense = min(entity.defense, entity.stat_caps.get("defense", 9999))
	entity.spd = min(entity.spd, entity.stat_caps.get("spd", 9999))

	entity.current_hp = entity.max_hp
	entity.hp_changed.emit(entity.current_hp, entity.max_hp)
	entity.level_changed.emit(entity.level)
	
	var exp_curve = 1.2
	if entity.level >= SOFT_CAP_LEVEL:
		exp_curve = 1.5
	entity.next_level_exp = int(entity.next_level_exp * exp_curve)
	
	# Nếu là quái, tự động dùng SP để nâng cấp ngẫu nhiên
	if not entity.is_character:
		_auto_upgrade_monster(entity)
	
	print(">>> ", entity.entity_name, " đạt Cấp ", entity.level, "! <<<")

# Hàm Setup nhanh cho Kẻ địch (Gọi lúc mới spawn)
static func set_initial_level(entity: Entity, target_level: int):
	if target_level <= 1: 
		# Đảm bảo quái Level 1 cũng có SP ban đầu
		if not entity.is_character:
			entity.skill_points = target_level * 2
			_auto_upgrade_monster(entity)
		return
	
	target_level = clamp(target_level, 1, MAX_LEVEL)
	
	var levels_to_gain = target_level - entity.level
	for i in range(levels_to_gain):
		process_level_up(entity)
	
	# Đảm bảo SP khớp với Level * 2 cho quái
	if not entity.is_character:
		entity.skill_points = target_level * 2
		_auto_upgrade_monster(entity)
		
	entity.current_exp = 0

static func _auto_upgrade_monster(entity: Entity):
	var stats = UpgradeManager.UPGRADE_AMOUNTS.keys()
	var attempts = 0
	while entity.skill_points >= UpgradeManager.UPGRADE_COST and attempts < 100:
		attempts += 1
		var stat = stats[randi() % stats.size()]
		if not UpgradeManager.upgrade_stat(entity, stat):
			# Nếu không nâng được (đạt cap), thử stat khác
			continue
