class_name QuestRegistry
extends RefCounted

const QuestDef = preload("res://Quests/QuestDefinition.gd")

"""
Tóm tắt: QuestRegistry là hệ thống tra cứu và quản lý danh sách siêu dữ liệu Quest toàn cục.

Chức năng:
- Tự động nạp hoặc truy xuất danh sách 16 Quest được định nghĩa trong Quests/Definitions/.
- Cung cấp API tìm kiếm Quest theo ID: `get_quest(quest_id)`.
- Cung cấp API lấy danh sách toàn bộ nhiệm vụ: `get_all_quests()`.
- Cung cấp API xác định nhiệm vụ hiện tại dựa theo cờ StoryState: `get_current_quest()`.
"""

const QUEST_DIR = "res://Quests/Definitions/"

const QUEST_FILES = [
	"Q01_Prologue.tres",
	"Q02_SafehouseIntro.tres",
	"Q03_WarehouseCleanup.tres",
	"Q04_PostWarehouse.tres",
	"Q05_HarborInfiltration.tres",
	"Q06_PostHarborReport.tres",
	"Q07_MorningAndCafe.tres",
	"Q08_StreetAmbush.tres",
	"Q09_HonamiClinic.tres",
	"Q10_FinaleOperations.tres",
	"Q11_NextPrimeMinister.tres",
	"Q12_Bounty.tres",
	"Q13_Interrogation.tres",
	"Q14_Mole.tres",
	"Q15_LastNocturne.tres",
	"Q16_NewNightcord.tres"
]

static var _cached_quests: Dictionary = {}

static func get_all_quests() -> Array[QuestDef]:
	var list: Array[QuestDef] = []
	for file in QUEST_FILES:
		var path = QUEST_DIR + file
		if ResourceLoader.exists(path):
			var res = load(path) as QuestDef
			if res:
				list.append(res)
				_cached_quests[res.quest_id] = res
	return list

static func get_quest(quest_id: String) -> QuestDef:
	if _cached_quests.has(quest_id):
		return _cached_quests[quest_id]
	
	for file in QUEST_FILES:
		var path = QUEST_DIR + file
		if ResourceLoader.exists(path):
			var res = load(path) as QuestDef
			if res and res.quest_id == quest_id:
				_cached_quests[quest_id] = res
				return res
	return null

static func get_current_quest() -> QuestDef:
	"""
	Xác định Quest đang hoạt động dựa trên các mốc cờ StoryState hiện tại.
	"""
	# Hồi kết 2 (sau khi Thủ Tướng chết): xét từ mốc muộn nhất về trước
	if GameManager.story.get_flag("game_completed"):
		return get_quest("quest_16_new_nightcord")
	elif GameManager.story.get_flag("honami_rescue_done"):
		return get_quest("quest_15_last_nocturne")
	elif GameManager.story.get_flag("kanade_unmasked"):
		return get_quest("quest_14_mole")
	elif GameManager.story.get_flag("ena_captured"):
		return get_quest("quest_13_interrogation")
	elif GameManager.story.get_flag("ena_left_nightcord"):
		return get_quest("quest_12_bounty")
	elif GameManager.story.get_flag("pm_boss_defeated"):
		return get_quest("quest_11_next_pm")
	elif GameManager.story.get_flag("finale_done") or GameManager.story.get_flag("pm_arc_started"):
		return get_quest("quest_10_finale")
	elif GameManager.story.get_flag("honami_house_unlocked") or GameManager.story.get_flag("street_mission_fully_done"):
		return get_quest("quest_09_honami_clinic")
	elif GameManager.story.get_flag("ena_cafe_done"):
		return get_quest("quest_08_street_ambush")
	elif GameManager.story.get_flag("mizuki_report_done"):
		return get_quest("quest_07_morning_cafe")
	elif GameManager.story.get_flag("harbor_mission_done"):
		return get_quest("quest_06_post_harbor")
	elif GameManager.story.get_flag("accepted_harbor_mission") or GameManager.story.get_flag("harbor_mission_unlocked"):
		return get_quest("quest_05_harbor")
	elif GameManager.warehouse_wave > 5:
		return get_quest("quest_04_post_warehouse")
	elif GameManager.story.get_flag("warehouse_mission_accepted"):
		return get_quest("quest_03_warehouse")
	elif GameManager.story.get_flag("prologue_phase", 0) >= 1:
		return get_quest("quest_02_safehouse_intro")
	else:
		return get_quest("quest_01_prologue")
