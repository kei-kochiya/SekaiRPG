extends Node
class_name StoryState

"""
StoryState: Quản lý toàn bộ tiến trình cốt truyện, nhiệm vụ và các biến cờ (flags).

Lớp này đóng vai trò là một kho chứa dữ liệu tập trung cho trạng thái trò chơi, 
tách biệt khỏi logic điều phối của GameManager. Hỗ trợ việc lưu trữ bền vững (persistence) 
cho các sự kiện quan trọng trong thế giới Sekai.
"""

# ── Cờ Trạng thái Cốt truyện (Persistent Flags) ──────────────────────────────
var flags: Dictionary = {
	"prologue_phase": 0,
	"safehouse_intro_done": false,
	"intro_quest_done": false,
	"npcs_greeted": [],
	"warehouse_mission_accepted": false,
	"talked_to_mafuyu_training": false,
	"accepted_harbor_mission": false,
	"harbor_mission_unlocked": false,
	"harbor_mission_done": false,
	"harbor_intro_done": false,
	"upgrade_tutorial_done": false,
	"guards_defeated": false,
	"training_ichika_done": false,
	"training_kanade_done": false,
	"harbor_meeting_p1_done": false,
	"mafuyu_honami_talked": false,
	"mizuki_control_phase": false,
	"harbor_mizuki_snack_done": false,
	"mizuki_vs_mafuyu_done": false
}

# ── Tiến độ Nhiệm vụ Hiện tại (Volatile/Persistent) ─────────────────────────
var warehouse_wave: int = 1
var harbor_wave: int = 1
var enemies_defeated: int = 0
var harbor_guards_defeated: int = 0
var harbor_route: String = ""

func set_flag(id: String, value: Variant):
	"""
	Thiết lập giá trị cho một cờ trạng thái cụ thể.
	
	Args:
		id (String): Tên định danh của cờ (key).
		value (Variant): Giá trị cần lưu trữ.
	"""
	flags[id] = value

func get_flag(id: String, default: Variant = false) -> Variant:
	"""
	Lấy giá trị của một cờ trạng thái từ bộ nhớ.
	
	Args:
		id (String): Tên định danh của cờ cần tìm.
		default (Variant): Giá trị trả về nếu không tìm thấy ID.
		
	Returns:
		Variant: Giá trị hiện tại của cờ hoặc giá trị mặc định.
	"""
	return flags.get(id, default)

func reset():
	"""
	Khôi phục toàn bộ tiến trình và dữ liệu nhiệm vụ về trạng thái mặc định.
	
	Dùng khi người chơi bắt đầu lại từ đầu hoặc reset màn chơi.
	"""
	for key in flags:
		if flags[key] is bool: flags[key] = false
		elif flags[key] is int: flags[key] = 0
		elif flags[key] is Array: flags[key] = []
		
	warehouse_wave = 1
	harbor_wave = 1
	enemies_defeated = 0
	harbor_guards_defeated = 0
	harbor_route = ""

func serialize() -> Dictionary:
	"""
	Chuyển đổi toàn bộ dữ liệu trạng thái sang định dạng Dictionary.
	
	Phục vụ cho việc mã hóa JSON trong hệ thống lưu trữ (Save system).
	
	Returns:
		Dictionary: Một bản đồ chứa toàn bộ thông tin story và flags.
	"""
	return {
		"flags": flags,
		"warehouse_wave": warehouse_wave,
		"harbor_wave": harbor_wave,
		"enemies_defeated": enemies_defeated,
		"harbor_guards_defeated": harbor_guards_defeated,
		"harbor_route": harbor_route
	}

func deserialize(data: Dictionary):
	"""
	Khôi phục trạng thái từ dữ liệu đã được nạp (deserialize).
	
	Args:
		data (Dictionary): Dữ liệu thô từ file save đã được giải mã JSON.
	"""
	flags = data.get("flags", flags.duplicate())
	warehouse_wave = data.get("warehouse_wave", 1)
	harbor_wave = data.get("harbor_wave", 1)
	enemies_defeated = data.get("enemies_defeated", 0)
	harbor_guards_defeated = data.get("harbor_guards_defeated", 0)
	harbor_route = data.get("harbor_route", "")
