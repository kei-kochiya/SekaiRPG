extends RefCounted
class_name StoryState

"""
Tóm tắt: StoryState là vùng nhớ chuyên dụng lưu trữ toàn bộ tiến trình và sự kiện cốt truyện.

Chức năng chính:
- Lưu trữ bộ từ điển `flags` chứa các biến boolean/int để theo dõi trạng thái nhiệm vụ, đối thoại và mở khóa.
- Lưu trữ biến đếm (wave, kẻ địch tiêu diệt) cho các nhiệm vụ cày cuốc (Warehouse, Harbor) và chế độ luyện tập (training_wave).
- Cung cấp API để `GameManager` dễ dàng thiết lập (set), đọc (get) và khôi phục (reset) trạng thái.
- Hỗ trợ Serialize/Deserialize dữ liệu sang JSON để phục vụ việc Save/Load Game.
"""

# ── Dữ Liệu Cờ Trạng Thái (Flags) ──────────────────────────────────────────

# Giá trị mặc định của mọi cờ; reset() và deserialize() đều khởi đầu từ bảng này
# để không bao giờ thiếu khóa (và kiểu dữ liệu luôn đúng: bool/int/Array).
const DEFAULT_FLAGS := {
	"prologue_phase": 0,
	"safehouse_intro_done": false,
	"intro_quest_done": false,
	"npcs_greeted": [],
	"warehouse_mission_accepted": false,
	"talked_to_mafuyu_training": false,
	"accepted_harbor_mission": false,
	"harbor_mission_unlocked": false,
	"harbor_mission_done": false,
	"harbor_boss_defeated": false,
	"harbor_intro_done": false,
	"training_ichika_done": false,
	"training_kanade_done": false,
	"training_ena_done": false,
	"training_mizuki_done": false,
	"training_mafuyu_done": false,
	"training_honami_done": false,
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
	"ena_released": false,
	"street_mission_started": false,
	"street_mission_ready": false,
	"street_skirmish_done": false,
	"street_skirmish_won": false,
	"street_survival_done": false,
	"street_survival_won": false,
	"street_mission_fully_done": false,
	"post_street_trained_once": false,
	"honami_house_unlocked": false,
	"honami_house_intro_done": false,
	"honami_unlocked_intro_done": false,
	"pm_arc_started": false,
	"ops_intro_done": false,
	"ops_kanade_done": false,
	"ops_ichika_done": false,
	"ops_honami_done": false,
	"pm_car_scene_done": false,
	"pm_boss_defeated": false,
	"finale_done": false,
	# ── Hồi kết 2: Sự sụp đổ của Nightcord (sau khi Thủ Tướng chết) ──
	"ena_left_nightcord": false,
	"bounty_intro_done": false,
	"bounty_1_done": false,
	"bounty_2_done": false,
	"bounty_3_done": false,
	"ena_captured": false,
	"interrogation_seen": false,
	"ena_kill_ordered": false,
	"mizuki_police_done": false,
	"warehouse_arrival_done": false,
	"ena_killed": false,
	"kanade_fled": false,
	"kanade_unmasked": false,
	"mizuki_killed": false,
	"kanade_killed": false,
	"mafuyu_reveal_done": false,
	"honami_rescue_done": false,
	"honami_options_intro_done": false,
	"final_confront_started": false,
	"final_mafuyu_defeated": false,
	"game_completed": false,
	"epilogue_intro_done": false,
	# Tiến độ nội bộ của BountyMap / InterrogationMap (để hội thoại không phát lại khi tải save)
	"bounty_posts_played": 0,
	"mizuki_police_wins": 0,
	"warehouse_mizuki_arrive_seen": false,
	"kanade_confront_seen": false,
	"kanade_slow_pre_seen": false,
	# Kết quả trận kịch bản gần nhất (GameManager ghi, map đọc để biết thắng/thua); chuỗi rỗng = không có
	"last_scripted_win": "",
	"last_scripted_loss": ""
}

var flags: Dictionary = DEFAULT_FLAGS.duplicate(true)

var warehouse_wave: int = 1
var harbor_wave: int = 1
# Bộ đếm wave RIÊNG của chế độ luyện tập (0 = không luyện tập). Không dùng chung với warehouse_wave
# để việc thua/bỏ dở luyện tập không làm sai lệch tiến trình cốt truyện Nhà kho.
var training_wave: int = 0
var enemies_defeated: int = 0
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
	# Dựng lại từ DEFAULT_FLAGS (không dò kiểu từng giá trị) nên cờ int/float nạp từ JSON cũng được đặt lại.
	flags = DEFAULT_FLAGS.duplicate(true)

	warehouse_wave = 1
	harbor_wave = 1
	training_wave = 0
	enemies_defeated = 0
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
		"flags": flags.duplicate(true),
		"warehouse_wave": warehouse_wave,
		"harbor_wave": harbor_wave,
		"training_wave": training_wave,
		"enemies_defeated": enemies_defeated,
		"harbor_route": harbor_route
	}

func deserialize(data: Dictionary):
	"""
	Khôi phục trạng thái từ dữ liệu đã được nạp (deserialize).
	Bắt đầu từ DEFAULT_FLAGS rồi gộp cờ đã lưu lên trên, nên save cũ thiếu khóa vẫn có giá trị mặc định.

	Args:
		data (Dictionary): Dữ liệu trạng thái đã lưu.
	Returns: Không có
	"""
	flags = DEFAULT_FLAGS.duplicate(true)
	var saved_flags = data.get("flags", {})
	if saved_flags is Dictionary:
		for key in saved_flags:
			flags[key] = saved_flags[key]
	_normalize_flag_types()

	# JSON luôn trả số dạng float nên ép về int cho các bộ đếm
	warehouse_wave = int(data.get("warehouse_wave", 1))
	harbor_wave = int(data.get("harbor_wave", 1))
	training_wave = int(data.get("training_wave", 0))
	enemies_defeated = int(data.get("enemies_defeated", 0))
	harbor_route = str(data.get("harbor_route", ""))

# Ép các cờ mặc định kiểu int (JSON trả về float) về lại int để so sánh/hiển thị đúng.
func _normalize_flag_types():
	for key in DEFAULT_FLAGS:
		if DEFAULT_FLAGS[key] is int and flags[key] is float:
			flags[key] = int(flags[key])
