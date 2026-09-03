extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho Core Autoloads (GameManager, StoryState, LevelManager, SaveManager).
"""

func test_gamemanager_flags():
	GameManager.set_flag("test_flag_unit", 123)
	assert_eq(GameManager.get_flag("test_flag_unit"), 123, "GameManager get/set flag")
	assert_eq(GameManager.get_flag("nonexistent_flag", 999), 999, "GameManager default flag fallback")

func test_storystate_serialization():
	var story = StoryState.new()
	story.set_flag("prologue_phase", 2)
	story.warehouse_wave = 3
	story.set_flag("custom_quest_unlocked", true)
	
	var data = story.serialize()
	assert_eq(data.get("warehouse_wave"), 3, "StoryState serialized warehouse_wave")
	assert_eq(data.get("flags", {}).get("prologue_phase"), 2, "StoryState serialized prologue_phase flag")
	
	var new_story = StoryState.new()
	new_story.deserialize(data)
	assert_eq(new_story.get_flag("prologue_phase"), 2, "StoryState deserialized prologue_phase")
	assert_eq(new_story.warehouse_wave, 3, "StoryState deserialized warehouse_wave")
	assert_true(new_story.get_flag("custom_quest_unlocked"), "StoryState deserialized custom flag")

func test_level_manager():
	var ichika = Ichika.new()
	LevelManager.set_initial_level(ichika, 5)
	assert_eq(ichika.level, 5, "LevelManager initial level")
	assert_gt(ichika.max_hp, 100, "LevelManager scales max_hp with level")
	assert_gt(ichika.atk, 10, "LevelManager scales atk with level")
	
	var old_level = ichika.level
	LevelManager.gain_exp(ichika, 99999)
	assert_gt(ichika.level, old_level, "LevelManager gain_exp triggers level up")

func test_save_manager_crud():
	var test_slot = "unit_test_core_save.json"
	var save_res = SaveManager.save_game(test_slot)
	assert_true(save_res, "SaveManager save_game creates file")
	
	var meta = SaveManager.get_save_metadata(test_slot)
	assert_true(not meta.is_empty(), "SaveManager read preview metadata")
	assert_true(meta.has("timestamp"), "Save metadata has timestamp")
	
	var del_res = SaveManager.delete_save(test_slot)
	assert_true(del_res, "SaveManager delete_save removes file")
	var meta_after = SaveManager.get_save_metadata(test_slot)
	assert_true(meta_after.is_empty(), "SaveManager metadata is empty after delete")
