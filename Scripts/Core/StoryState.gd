extends Node
class_name StoryState

"""
Tóm tắt: StoryState là vùng nhớ chuyên dụng lưu trữ toàn bộ tiến trình và sự kiện cốt truyện.

Chức năng chính:
- Lưu trữ bộ từ điển `flags` chứa các biến boolean/int để theo dõi trạng thái nhiệm vụ, đối thoại và mở khóa.
- Lưu trữ biến đếm (wave, kẻ địch tiêu diệt) cho các nhiệm vụ cày cuốc (Warehouse, Harbor).
- Cung cấp API để `GameManager` dễ dàng thiết lập (set), đọc (get) và khôi phục (reset) trạng thái.
- Hỗ trợ Serialize/Deserialize dữ liệu sang JSON để phục vụ việc Save/Load Game.
"""

# ── Dữ Liệu Cờ Trạng Thái (Flags) ──────────────────────────────────────────

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
	"training_ena_done": false,
	"training_mizuki_done": false,
	"post_harbor_training_reset": false,
	"ena_control_phase": false,
	"ena_cafe_unlocked": false,
	"ena_cafe_done": false,
	"ena_vs_mizuki_done": false,
	"ena_vs_mizuki_won": false,
	"ena_vs_thugs_done": false,
	"ena_vs_thugs_won": false,
	"interaction_count": 0,
	"harbor_meeting_p1_done": false,
	"mafuyu_honami_talked": false,
	"mizuki_control_phase": false,
	"harbor_mizuki_snack_done": false,
	"mizuki_vs_mafuyu_done": false,
	"mizuki_report_done": false,
	"post_harbor_morning_done": false,
	"ena_released": false
}

var warehouse_wave: int = 1
var harbor_wave: int = 1
var enemies_defeated: int = 0
var harbor_guards_defeated: int = 0
var harbor_route: String = ""

# ── API Quản Lý Trạng Thái ─────────────────────────────────────────────────

# Thiết lập giá trị cho một cờ trạng thái cụ thể.
func set_flag(id: String, value: Variant):
	flags[id] = value

# Lấy giá trị của một cờ trạng thái từ bộ nhớ.
func get_flag(id: String, default: Variant = false) -> Variant:
	return flags.get(id, default)

func reset():
	"""
	Khôi phục toàn bộ tiến trình và dữ liệu nhiệm vụ về trạng thái mặc định.
	
	Args: Không có
	Returns: Không có
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

# ── API Tuần Tự Hóa (Serialize/Deserialize) ────────────────────────────────

func serialize() -> Dictionary:
	"""
	Chuyển đổi toàn bộ dữ liệu trạng thái sang định dạng Dictionary.
	
	Args: Không có
	Returns:
		Dictionary: Chứa dữ liệu toàn bộ state để lưu.
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
		data (Dictionary): Dữ liệu trạng thái đã lưu.
	Returns: Không có
	"""
	flags = data.get("flags", flags.duplicate())
	warehouse_wave = data.get("warehouse_wave", 1)
	harbor_wave = data.get("harbor_wave", 1)
	enemies_defeated = data.get("enemies_defeated", 0)
	harbor_guards_defeated = data.get("harbor_guards_defeated", 0)
	harbor_route = data.get("harbor_route", "")
