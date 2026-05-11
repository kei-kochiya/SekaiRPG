extends Node
class_name Entity

"""
Entity: Lớp cơ sở cho toàn bộ các nhân vật và kẻ địch trong game.

Lớp này quản lý các chỉ số cơ bản (HP, ATK, DEF...), trạng thái (Status Effects),
hệ thống kỹ năng và logic chiến đấu cốt lõi như nhận sát thương, hồi máu.
Mọi thực thể tham gia chiến đấu đều phải kế thừa từ lớp này.
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

# ── Tham chiếu ngữ cảnh chiến đấu ───────────────────────────────────────────
var allies: Array = []
var enemies: Array = []

# ── Kỹ năng & Trạng thái ────────────────────────────────────────────────────
var skills: Array = []
var active_statuses: Array = []
var cooldowns: Dictionary = {}
var stat_caps: Dictionary = {
	"max_hp": 30000,
	"atk": 15000,
	"defense": 8000,
	"spd": 2000
}

# ── Phương thức chiến đấu cốt lõi ───────────────────────────────────────────

func take_damage(amount: int, damage_type: String = "physical") -> bool:
	"""
	Xử lý logic khi thực thể nhận sát thương từ các nguồn.

	Args:
		amount (int): Lượng sát thương nhận vào.
		damage_type (String): Loại sát thương (ví dụ: 'physical', 'pure', 'dot').

	Returns:
		bool: True nếu thực thể bị hạ gục (HP về 0), ngược lại False.
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
	Hồi phục máu cho thực thể. 

	Hàm này đảm bảo không hồi máu vượt quá max_hp và chỉ có tác dụng 
	khi thực thể còn sống.

	Args:
		amount (int): Lượng máu muốn hồi phục.
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
	Áp dụng một hiệu ứng trạng thái mới lên thực thể.

	Args:
		status (Dictionary): Chứa thông tin hiệu ứng (type, duration, percent...).
	"""
	active_statuses.append(status)
	status_changed.emit(active_statuses.duplicate())

func remove_statuses(to_remove: Array):
	"""
	Loại bỏ danh sách các hiệu ứng trạng thái khỏi thực thể.

	Args:
		to_remove (Array): Danh sách các Dictionary hiệu ứng cần loại bỏ.
	"""
	for s in to_remove:
		active_statuses.erase(s)
	if not to_remove.is_empty():
		status_changed.emit(active_statuses.duplicate())

# ── Kiểm tra khả năng sử dụng kỹ năng ───────────────────────────────────────

func can_use_skill(skill_name: String) -> bool:
	"""
	Kiểm tra xem một kỹ năng cụ thể có đang trong thời gian hồi chiêu hay không.

	Args:
		skill_name (String): Tên định danh (method) của kỹ năng cần kiểm tra.

	Returns:
		bool: True nếu kỹ năng sẵn sàng sử dụng, ngược lại False.
	"""
	return CooldownManager.is_skill_ready(self, skill_name)
