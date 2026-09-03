extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho Hệ thống Nhiệm vụ (QuestRegistry, QuestDefinition, Stage Progression).
"""

func test_quest_registry_loading():
	var quests = QuestRegistry.get_all_quests()
	assert_eq(quests.size(), 10, "QuestRegistry loaded exactly 10 quests")
	
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
