extends Node

const QuestRegistryClass = preload("res://Quests/QuestRegistry.gd")

func _ready():
	print("--- Running Save System Verification Tests ---")
	
	# Clean test directory
	SaveManager.ensure_saves_dir()
	
	# Test 1: Save New File with metadata
	GameManager.current_map_file = "res://Maps/Warehouse/WarehouseMap.tscn"
	GameManager.story.set_flag("warehouse_mission_accepted", true)
	
	var save_ok = SaveManager.save_game("test_warehouse_save.json")
	print("[Test 1] Save file created: ", save_ok)
	assert(save_ok == true, "Save should succeed")
	
	var meta = SaveManager.get_save_metadata("test_warehouse_save.json")
	print("[Test 1.1] Metadata read: ", meta)
	assert(meta.has("quest_name"), "Metadata must have quest_name")
	assert(meta.has("map_name"), "Metadata must have map_name")
	assert(meta.has("timestamp"), "Metadata must have timestamp")
	assert(meta["map_name"] == "Nhà kho cũ", "Expected map name 'Nhà kho cũ'")
	
	# Test 2: Quick Save & Auto Save
	var qs_ok = GameManager.quick_save()
	print("[Test 2] Quick save: ", qs_ok)
	assert(qs_ok == true, "Quick save should succeed")
	assert(FileAccess.file_exists(SaveManager.QUICK_SAVE_PATH), "Quick save file must exist")
	
	var as_ok = GameManager.auto_save()
	print("[Test 2.1] Auto save: ", as_ok)
	assert(as_ok == true, "Auto save should succeed")
	assert(FileAccess.file_exists(SaveManager.AUTOSAVE_PATH), "Auto save file must exist")
	
	# Test 3: Get All Save Slots
	var all_slots = SaveManager.get_all_save_slots()
	print("[Test 3] Total save slots found: ", all_slots.size())
	assert(all_slots.size() >= 3, "Expected at least 3 save slots")
	
	var latest = SaveManager.get_latest_save_path()
	print("[Test 3.1] Latest save path: ", latest)
	assert(latest != "", "Latest save path should not be empty")
	
	# Test 4: Delete Save File
	var del_ok = SaveManager.delete_save("test_warehouse_save.json")
	print("[Test 4] Delete save: ", del_ok)
	assert(del_ok == true, "Delete should succeed")
	assert(not FileAccess.file_exists("user://saves/test_warehouse_save.json"), "Deleted file should no longer exist")
	
	# Test 5: Clean Load Game Test
	var load_ok = GameManager.load_game(SaveManager.QUICK_SAVE_PATH)
	print("[Test 5] Load game: ", load_ok)
	assert(load_ok == true, "Load should succeed")
	
	print("--- ALL SAVE SYSTEM VERIFICATION TESTS PASSED SUCCESSFULLY! ---")
	get_tree().quit(0)
