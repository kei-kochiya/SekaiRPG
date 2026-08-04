extends Node
class_name Entity

"""
Tóm tắt: Entity là lớp cơ sở (Base Class) cho mọi thực thể tham gia chiến đấu (Nhân vật và Kẻ địch).

Chức năng chính:
- Định nghĩa toàn bộ chỉ số cốt lõi (HP, ATK, DEF, SPD, Type) và các biến hỗ trợ thăng cấp.
- Quản lý thanh hành động (Action Gauge) để sắp xếp thứ tự đánh trong lượt.
- Quản lý danh sách các hiệu ứng trạng thái (Status Effects) như Poison, Bleed, Stun và thời gian hồi chiêu (Cooldown).
- Cung cấp các phương thức chiến đấu tiêu chuẩn: nhận sát thương (take_damage), hồi máu (heal) và xử lý hiệu ứng.
"""

# ── Tín hiệu (Signals) ─────────────────────────────────────────────────────
signal hp_changed(new_hp: int, max_hp: int)
signal died()
@warning_ignore("unused_signal")
signal cooldown_updated(skill_name: String, turns_left: int)
signal status_changed(statuses: Array)
signal damage_received(amount: int, damage_type: String)
@warning_ignore("unused_signal")
signal level_changed(new_level: int)

# ── Chỉ số cơ bản ──────────────────────────────────────────────────────────
@export var entity_name: String = "Unknown"
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var atk: int = 10
@export var defense: int = 10
@export var res: int = 10
@export var spd: int = 10
@export var type: String = "None"
@export var skill_points: int = 0
@export var level: int = 1
@export var is_character: bool = false
@export var current_exp: int = 0
@export var next_level_exp: int = 100

# ── Cơ chế lượt đi ─────────────────────────────────────────────────────────
var action_gauge: float = 0.0 # Thanh hành động (0 - 10000)

# ── Tham chiếu ngữ cảnh chiến đấu ───────────────────────────────────────────
var allies: Array = []
var enemies: Array = []

# ── Kỹ năng & Trạng thái ────────────────────────────────────────────────────
var skills: Array = []
var active_statuses: Array = []
var cooldowns: Dictionary = {}
var skills_disabled: bool = false
var gives_exp: bool = true
var stat_caps: Dictionary = {
	"max_hp": 30000,
	"atk": 15000,
	"defense": 8000,
	"spd": 2000
}

# ── Phương thức chiến đấu cốt lõi ───────────────────────────────────────────

func take_damage(amount: int, damage_type: String = "physical") -> bool:
	"""
	Xử lý việc thực thể nhận sát thương và kiểm tra trạng thái sống còn.
	
	Args:
		amount (int): Lượng sát thương nhận vào.
		damage_type (String): Loại sát thương (physical, pure, dot).
	Returns: 
		bool: True nếu thực thể chết (HP = 0), ngược lại False.
	"""
	current_hp -= amount
	current_hp = clamp(current_hp, 0, max_hp)
	
	hp_changed.emit(current_hp, max_hp)
	damage_received.emit(amount, damage_type)
	
	if current_hp == 0:
		died.emit()
		return true
	return false

func heal(amount: int):
	"""
	Hồi phục HP cho thực thể nếu còn sống.
	
	Args:
		amount (int): Lượng máu hồi phục.
	Returns: Không có
	"""
	if current_hp <= 0: return
	var actual = min(amount, max_hp - current_hp)
	if actual > 0:
		current_hp += actual
		hp_changed.emit(current_hp, max_hp)
		damage_received.emit(actual, "heal")

# ── Quản lý Trạng thái (Status) ─────────────────────────────────────────────

func add_status(status: Dictionary):
	"""
	Thêm hiệu ứng trạng thái mới và xử lý logic cộng dồn/ghi đè.
	
	Args:
		status (Dictionary): Dictionary chứa thông tin hiệu ứng (type, duration...).
	Returns: Không có
	"""
	var type_name = status.get("type", "Unknown")
	
	if type_name == "Poison":
		for s in active_statuses:
			if s["type"] == "Poison":
				s["duration"] = status["duration"]
				status_changed.emit(active_statuses.duplicate())
				return
	
	if type_name == "Bleed":
		var bleed_count = get_status_count("Bleed")
		if bleed_count >= 5:
			return
			
	active_statuses.append(status)
	status_changed.emit(active_statuses.duplicate())

func remove_statuses(to_remove: Array):
	# Xóa danh sách các hiệu ứng trạng thái khỏi thực thể.
	for s in to_remove:
		active_statuses.erase(s)
	if not to_remove.is_empty():
		status_changed.emit(active_statuses.duplicate())

func get_status_count(type_name: String) -> int:
	# Trả về số lượng stack hiện có của một loại trạng thái.
	var count = 0
	for s in active_statuses:
		if s["type"] == type_name:
			count += 1
	return count

func remove_all_status_type(type_name: String):
	# Xóa sạch toàn bộ các stack của một loại trạng thái cụ thể.
	var to_remove = []
	for s in active_statuses:
		if s["type"] == type_name:
			to_remove.append(s)
	remove_statuses(to_remove)

func clear_all_debuffs():
	# Thanh tẩy toàn bộ các hiệu ứng xấu (Bleed, Poison, Stun, Slow).
	var debuffs = ["Bleed", "Poison", "Stun", "Slow"]
	var to_remove = []
	for s in active_statuses:
		if s["type"] in debuffs:
			to_remove.append(s)
	remove_statuses(to_remove)

func refresh_status_duration(type_name: String, new_duration: int):
	"""
	Cập nhật thời gian tồn tại cho tất cả các stack của một loại trạng thái.
	
	Args:
		type_name (String): Tên loại trạng thái.
		new_duration (int): Thời gian mới (tính theo lượt).
	Returns: Không có
	"""
	var changed = false
	for s in active_statuses:
		if s["type"] == type_name:
			s["duration"] = new_duration
			changed = true
	if changed:
		status_changed.emit(active_statuses.duplicate())

# ── Kiểm tra khả năng sử dụng kỹ năng ───────────────────────────────────────

func can_use_skill(skill_name: String) -> bool:
	"""
	Kiểm tra kỹ năng có sẵn sàng để sử dụng hay không.
	
	Args:
		skill_name (String): Tên kỹ năng cần kiểm tra.
	Returns: 
		bool: True nếu dùng được, ngược lại False.
	"""
	if skills_disabled: return false
	return cooldowns.get(skill_name, 0) <= 0

func get_portrait_path() -> String:
	return "res://Art/Portraits/%s.png" % entity_name.to_lower()
