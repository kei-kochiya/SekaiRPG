extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho Hệ thống Nhiệm vụ (QuestRegistry, QuestDefinition, Stage Progression).
"""

func test_quest_registry_loading():
	var quests = QuestRegistry.get_all_quests()
	assert_eq(quests.size(), 16, "QuestRegistry loaded exactly 16 quests")
	
	for q in quests:
		assert_ne(q.quest_id, "", "Quest has non-empty ID")
		assert_ne(q.quest_name, "", "Quest has non-empty Name")
		assert_ne(q.linked_map_scene, "", "Quest has non-empty Map Scene")

func test_quest_progression_chain():
	GameManager.reset_game()
	var initial = QuestRegistry.get_current_quest()
	assert_true(initial != null, "Initial quest is not null")
	assert_eq(initial.quest_id, "quest_01_prologue", "Initial quest is quest_01_prologue")
	
	# Transition to Safehouse intro
	GameManager.story.set_flag("prologue_phase", 1)
	var post_prologue = QuestRegistry.get_current_quest()
	assert_true(post_prologue != null, "Post prologue quest is not null")
	assert_eq(post_prologue.quest_id, "quest_02_safehouse_intro", "Prologue phase 1 maps to quest_02_safehouse_intro")

func test_quest_map_scenes_exist():
	for q in QuestRegistry.get_all_quests():
		assert_true(ResourceLoader.exists(q.linked_map_scene), "Map scene exists for %s: %s" % [q.quest_id, q.linked_map_scene])

func test_quest_registry_merged_branches():
	GameManager.reset_game()
	GameManager.story.set_flag("pm_arc_started", true)
	assert_eq(QuestRegistry.get_current_quest().quest_id, "quest_10_finale", "pm_arc_started -> quest_10_finale")
	GameManager.story.set_flag("pm_arc_started", false)
	GameManager.story.set_flag("finale_done", true)
	assert_eq(QuestRegistry.get_current_quest().quest_id, "quest_10_finale", "finale_done -> quest_10_finale")
	GameManager.story.set_flag("finale_done", false)
	GameManager.story.set_flag("honami_house_unlocked", true)
	assert_eq(QuestRegistry.get_current_quest().quest_id, "quest_09_honami_clinic", "honami_house_unlocked -> quest_09")
	GameManager.story.set_flag("honami_house_unlocked", false)
	GameManager.story.set_flag("street_mission_fully_done", true)
	assert_eq(QuestRegistry.get_current_quest().quest_id, "quest_09_honami_clinic", "street_mission_fully_done -> quest_09")
	GameManager.reset_game()

func test_quest_current_with_missing_flags_after_load():
	# Save cũ/rỗng: deserialize phải cấp đủ khóa mặc định để QuestRegistry không so sánh bool với int
	GameManager.reset_game()
	GameManager.story.deserialize({"flags": {}})
	var q = QuestRegistry.get_current_quest()
	assert_true(q != null, "Có quest hiện tại khi save thiếu cờ")
	assert_eq(q.quest_id, "quest_01_prologue", "Save không có cờ nào -> quest_01_prologue")
	GameManager.story.deserialize({"flags": {"prologue_phase": 1.0}})
	assert_eq(QuestRegistry.get_current_quest().quest_id, "quest_02_safehouse_intro", "prologue_phase dạng float vẫn >= 1")
	GameManager.reset_game()

func test_quest_ignores_training_wave():
	GameManager.reset_game()
	GameManager.warehouse_mission_accepted = true
	GameManager.begin_training(["Ichika"])
	GameManager.training_wave = 9
	assert_eq(QuestRegistry.get_current_quest().quest_id, "quest_03_warehouse", "training_wave không ảnh hưởng quest Nhà kho")
	GameManager.reset_game()

func test_arc2_quest_chain():
	# Hồi kết 2: mỗi mốc cờ phải trỏ tới đúng quest, mốc muộn nhất thắng
	GameManager.reset_game()
	var steps = [
		["pm_boss_defeated", "quest_11_next_pm"],
		["ena_left_nightcord", "quest_12_bounty"],
		["ena_captured", "quest_13_interrogation"],
		["kanade_unmasked", "quest_14_mole"],
		["honami_rescue_done", "quest_15_last_nocturne"],
		["game_completed", "quest_16_new_nightcord"],
	]
	for step in steps:
		GameManager.story.set_flag(step[0], true)
		assert_eq(QuestRegistry.get_current_quest().quest_id, step[1], "%s -> %s" % [step[0], step[1]])
	GameManager.reset_game()
