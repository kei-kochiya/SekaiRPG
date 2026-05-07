extends Node
class_name UpgradeManager

# Chi phí SP cho 1 lần nâng cấp
const UPGRADE_COST = 1

# Lượng chỉ số tăng thêm mỗi lần bấm nâng cấp
const UPGRADE_AMOUNTS = {
	"max_hp": 50,
	"atk": 10,
	"defense": 5,
	"spd": 2
}

# Hàm thực hiện nâng cấp
static func upgrade_stat(entity: Entity, stat_name: String) -> bool:
	# 1. Kiểm tra xem chỉ số này có nằm trong danh sách được phép nâng không (Loại trừ RES, Cooldown)
	if not UPGRADE_AMOUNTS.has(stat_name):
		print("[Lỗi] Không thể nâng cấp chỉ số: ", stat_name)
		return false
		
	# 2. Kiểm tra Skill Points
	if entity.skill_points < UPGRADE_COST:
		print("[Từ chối] ", entity.entity_name, " không đủ Skill Points. Hiện có: ", entity.skill_points)
		return false
		
	# 3. Lấy giá trị hiện tại và kiểm tra Hard Cap
	var current_val = entity.get(stat_name)
	var cap_val = entity.stat_caps.get(stat_name, 9999) # Nếu không cài cap, mặc định là 9999
	var increment = UPGRADE_AMOUNTS[stat_name]

	# Chặn nếu chỉ số đã đạt hoặc vượt giới hạn (có thể do level-up đẩy vượt)
	if current_val >= cap_val:
		print("[Từ chối] Chỉ số ", stat_name, " của ", entity.entity_name, " đã đạt giới hạn tối đa (", cap_val, ")!")
		return false

	# Clamp increment: chỉ tăng đến đúng giới hạn, không vượt qua
	var actual_increment = min(increment, cap_val - current_val)

	# 4. Tiến hành nâng cấp (Dùng hàm set/get mặc định của Godot)
	entity.set(stat_name, current_val + actual_increment)
	entity.skill_points -= UPGRADE_COST

	# Xử lý đặc biệt: Nếu nâng Max HP, hồi HP tương ứng, clamp để không vượt max
	if stat_name == "max_hp":
		entity.current_hp = min(entity.current_hp + actual_increment, entity.max_hp)
		
	print("[Thành công] ", entity.entity_name, " đã nâng ", stat_name, " lên ", entity.get(stat_name), " (Còn ", entity.skill_points, " SP)")
	return true
