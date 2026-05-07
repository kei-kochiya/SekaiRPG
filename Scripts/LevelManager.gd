extends Node
class_name LevelManager

const SOFT_CAP_LEVEL = 50
const MAX_LEVEL = 100

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
	entity.skill_points += 1 # Nhận 1 SP mỗi khi lên cấp
	
	# Xử lý Soft Cap cho chỉ số
	# Bình thường tăng 5% chỉ số gốc, sau Soft Cap (Lv 50) chỉ tăng 2%
	var growth_rate = 0.05
	if entity.level > SOFT_CAP_LEVEL:
		growth_rate = 0.02 
		
	# Tăng các chỉ số cơ bản (Bỏ qua RES và Cooldown)
	entity.max_hp += int(entity.max_hp * growth_rate)
	entity.atk += int(entity.atk * growth_rate)
	entity.defense += int(entity.defense * growth_rate)
	entity.spd += int(entity.spd * growth_rate)

	# Clamp theo Hard Cap (stat_caps định nghĩa trong Entity.gd)
	entity.max_hp = min(entity.max_hp, entity.stat_caps.get("max_hp", 9999))
	entity.atk = min(entity.atk, entity.stat_caps.get("atk", 9999))
	entity.defense = min(entity.defense, entity.stat_caps.get("defense", 9999))
	entity.spd = min(entity.spd, entity.stat_caps.get("spd", 9999))

	# Hồi đầy máu (Tùy chọn, thường RPG hay làm thế này)
	entity.current_hp = entity.max_hp
	
	# Xử lý Soft Cap cho EXP
	# Yêu cầu EXP tăng dần (1.2x mỗi cấp). Sau Soft Cap, cần cày cuốc cực khổ hơn (1.5x)
	var exp_curve = 1.2
	if entity.level >= SOFT_CAP_LEVEL:
		exp_curve = 1.5
		
	entity.next_level_exp = int(entity.next_level_exp * exp_curve)
	
	print(">>> ", entity.entity_name, " đạt Cấp ", entity.level, "! (+1 SP) <<<")

# Hàm Setup nhanh cho Kẻ địch (Gọi lúc mới spawn)
static func set_initial_level(entity: Entity, target_level: int):
	if target_level <= 1: 
		return
	
	target_level = clamp(target_level, 1, MAX_LEVEL)
	
	# Giả lập quá trình lên cấp để tự động cộng dồn chỉ số bằng vòng lặp
	var levels_to_gain = target_level - entity.level
	for i in range(levels_to_gain):
		process_level_up(entity)
		
	# Reset lại EXP hiện tại về 0 cho gọn gàng sau khi set level
	entity.current_exp = 0
