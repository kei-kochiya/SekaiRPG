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

# ── StoryState ─────────────────────────────────────────────────────────────

func test_storystate_reset_handles_float_flags():
	# JSON luôn trả số dạng float; reset() trước đây chỉ đặt lại cờ kiểu int
	var story = StoryState.new()
	story.set_flag("prologue_phase", 1.0)
	story.set_flag("interaction_count", 3.0)
	story.set_flag("npcs_greeted", ["Mafuyu"])
	story.set_flag("custom_extra_flag", true)
	story.warehouse_wave = 4
	story.training_wave = 3
	story.reset()
	assert_eq(story.get_flag("prologue_phase"), 0, "reset() đặt lại prologue_phase dạng float")
	assert_true(story.get_flag("prologue_phase") is int, "prologue_phase sau reset là int")
	assert_eq(story.get_flag("interaction_count"), 0, "reset() đặt lại interaction_count dạng float")
	assert_eq(story.get_flag("npcs_greeted").size(), 0, "reset() làm rỗng npcs_greeted")
	assert_false(story.get_flag("custom_extra_flag", false), "reset() bỏ cờ ngoài DEFAULT_FLAGS")
	assert_eq(story.warehouse_wave, 1, "reset() đặt warehouse_wave = 1")
	assert_eq(story.training_wave, 0, "reset() đặt training_wave = 0")

func test_storystate_deserialize_starts_from_defaults():
	var story = StoryState.new()
	story.set_flag("finale_done", true)
	# Save cũ: thiếu gần hết khóa, số dạng float
	story.deserialize({"flags": {"prologue_phase": 2.0}})
	assert_eq(story.get_flag("prologue_phase"), 2, "deserialize giữ cờ đã lưu")
	assert_true(story.get_flag("prologue_phase") is int, "cờ int nạp từ float được ép về int")
	assert_false(story.get_flag("finale_done"), "cờ không có trong save quay về mặc định")
	for key in StoryState.DEFAULT_FLAGS:
		assert_true(story.flags.has(key), "deserialize luôn có khóa mặc định: " + key)
	assert_eq(story.training_wave, 0, "save cũ thiếu training_wave -> 0")
	assert_eq(story.warehouse_wave, 1, "save cũ thiếu warehouse_wave -> 1")

func test_storystate_json_roundtrip_types():
	var src = StoryState.new()
	src.set_flag("prologue_phase", 3)
	src.warehouse_wave = 4
	src.training_wave = 2
	var loaded = JSON.parse_string(JSON.stringify(src.serialize()))
	var dst = StoryState.new()
	dst.deserialize(loaded)
	assert_eq(dst.get_flag("prologue_phase"), 3, "prologue_phase qua JSON")
	assert_true(dst.get_flag("prologue_phase", 0) >= 1, "so sánh prologue_phase >= 1 hợp lệ")
	assert_eq(dst.warehouse_wave, 4, "warehouse_wave qua JSON")
	assert_eq(dst.training_wave, 2, "training_wave qua JSON")
	dst.reset()
	assert_eq(dst.get_flag("prologue_phase"), 0, "reset sau khi nạp từ JSON")

# ── GameManager: trạng thái tạm & luyện tập ────────────────────────────────

func test_training_wave_separate_from_warehouse_wave():
	var old_wave = GameManager.warehouse_wave
	var old_map = GameManager.current_map_file
	var old_defeated = GameManager.enemies_defeated
	GameManager.warehouse_wave = 3
	GameManager.training_used_opponents = ["Kanade"]
	GameManager.begin_training(["Ichika"])
	assert_true(GameManager.is_training_mode, "begin_training bật chế độ luyện tập")
	assert_eq(GameManager.training_wave, 1, "begin_training đặt training_wave = 1")
	assert_eq(GameManager.warehouse_wave, 3, "begin_training không đụng warehouse_wave")
	assert_eq(GameManager.training_used_opponents.size(), 0, "begin_training xóa training_used_opponents")

	GameManager.current_map_file = "res://Maps/Warehouse/TrainingWarehouseMap.tscn"
	GameManager._apply_victory_rewards(1)
	assert_eq(GameManager.training_wave, 2, "thắng khi luyện tập tăng training_wave")
	assert_eq(GameManager.warehouse_wave, 3, "thắng khi luyện tập không tăng warehouse_wave")

	GameManager.training_used_opponents = ["Mafuyu"]
	GameManager.end_training()
	assert_false(GameManager.is_training_mode, "end_training tắt chế độ luyện tập")
	assert_eq(GameManager.training_wave, 0, "end_training đặt training_wave = 0")
	assert_eq(GameManager.training_used_opponents.size(), 0, "end_training xóa training_used_opponents")

	GameManager.warehouse_wave = old_wave
	GameManager.current_map_file = old_map
	GameManager.enemies_defeated = old_defeated

func test_clear_transient_state():
	GameManager.begin_training(["Ichika"])
	GameManager.training_used_opponents = ["Kanade"]
	GameManager.is_scripted_battle = true
	GameManager.scripted_battle_id = "pm_boss"
	GameManager.is_sandbox = true
	GameManager.sandbox_player_team = ["x"]
	GameManager.sandbox_enemy_team = ["y"]
	GameManager.is_in_dialogue = true
	HoloSimManager.is_sim_active = true

	GameManager.clear_transient_state()
	assert_false(GameManager.is_training_mode, "clear: is_training_mode")
	assert_eq(GameManager.training_participants.size(), 0, "clear: training_participants")
	assert_eq(GameManager.training_used_opponents.size(), 0, "clear: training_used_opponents")
	assert_eq(GameManager.training_wave, 0, "clear: training_wave")
	assert_false(GameManager.is_scripted_battle, "clear: is_scripted_battle")
	assert_eq(GameManager.scripted_battle_id, "", "clear: scripted_battle_id")
	assert_false(GameManager.is_sandbox, "clear: is_sandbox")
	assert_eq(GameManager.sandbox_player_team.size(), 0, "clear: sandbox_player_team")
	assert_eq(GameManager.sandbox_enemy_team.size(), 0, "clear: sandbox_enemy_team")
	assert_false(GameManager.is_in_dialogue, "clear: is_in_dialogue")
	assert_false(HoloSimManager.is_sim_active, "clear: HoloSimManager.is_sim_active")

func test_reset_game_resets_economy_and_transient_state():
	GameManager.credits = 9999
	GameManager.inventory = {"potion": 77}
	GameManager.opened_chests = ["unit_test_chest_reset"]
	GameManager.is_training_mode = true
	GameManager.is_scripted_battle = true
	GameManager.reset_game()
	assert_eq(GameManager.credits, GameManager.DEFAULT_CREDITS, "reset_game đặt lại credits")
	assert_eq(GameManager.inventory, GameManager.DEFAULT_INVENTORY, "reset_game đặt lại inventory")
	assert_eq(GameManager.opened_chests.size(), 0, "reset_game xóa opened_chests")
	assert_false(GameManager.is_training_mode, "reset_game xóa is_training_mode")
	assert_false(GameManager.is_scripted_battle, "reset_game xóa is_scripted_battle")
	# Sửa inventory không được làm hỏng hằng số mặc định
	GameManager.add_item("potion", 5)
	assert_eq(GameManager.DEFAULT_INVENTORY["potion"], 2, "DEFAULT_INVENTORY không bị thay đổi")
	GameManager.reset_game()

# ── SaveManager ────────────────────────────────────────────────────────────

func test_save_name_sanitising():
	assert_eq(SaveManager.sanitize_save_name("  my save  "), "my save", "cắt khoảng trắng đầu/cuối")
	assert_eq(SaveManager.sanitize_save_name("slot.json"), "slot", "bỏ đuôi .json")
	assert_eq(SaveManager.sanitize_save_name("../../evil"), "evil", "bỏ phần đường dẫn")
	assert_eq(SaveManager.sanitize_save_name("a:b*c"), "a_b_c", "thay ký tự cấm bằng _")
	assert_eq(SaveManager.sanitize_save_name(""), "", "tên rỗng bị từ chối")
	assert_eq(SaveManager.sanitize_save_name("   "), "", "tên toàn khoảng trắng bị từ chối")
	assert_eq(SaveManager.sanitize_save_name(".."), "", "tên .. bị từ chối")
	assert_eq(SaveManager.sanitize_save_name("QuickSave"), "", "tên dành riêng quicksave bị từ chối")
	assert_eq(SaveManager.sanitize_save_name("autosave.json"), "", "tên dành riêng autosave bị từ chối")

func test_save_game_rejects_invalid_names():
	assert_false(SaveManager.save_game("quicksave"), "không cho lưu tay đè slot quicksave")
	assert_ne(SaveManager.last_error, "", "last_error được điền khi từ chối")
	assert_false(SaveManager.save_game("AutoSave.json"), "không cho lưu tay đè slot autosave")
	assert_false(SaveManager.save_game(""), "tên rỗng bị từ chối")
	assert_false(SaveManager.save_game(".."), "tên .. bị từ chối")
	assert_false(SaveManager.save_game("user://elsewhere/x.json"), "đường dẫn ngoài user://saves/ bị từ chối")
	var wrapped = GameManager.save_game("")
	assert_false(wrapped, "GameManager.save_game trả về false khi tên không hợp lệ")
	assert_ne(GameManager.last_save_error, "", "GameManager.last_save_error được điền")

func test_save_game_sanitises_typed_name_and_writes_atomically():
	var typed = "../unit_test_sanitised:slot"
	var clean = "unit_test_sanitised_slot"
	assert_true(SaveManager.save_game(typed), "lưu với tên đã làm sạch")
	assert_eq(SaveManager.last_error, "", "last_error rỗng khi lưu thành công")
	assert_true(FileAccess.file_exists(SaveManager.SAVES_DIR + clean + ".json"), "file được tạo với tên đã làm sạch")
	assert_false(FileAccess.file_exists(SaveManager.SAVES_DIR + clean + ".json.tmp"), "không còn file .tmp sau khi ghi")
	var meta = SaveManager.get_save_metadata(clean)
	assert_eq(meta.get("version"), SaveManager.SAVE_VERSION, "metadata ghi đúng SAVE_VERSION")
	assert_true(SaveManager.delete_save(clean), "dọn file save thử nghiệm")

func test_save_roundtrip_next_level_exp():
	var slot = "unit_test_roundtrip_slot"
	var ichika = GameManager.get_party_member("Ichika")
	var original_next = ichika.next_level_exp
	ichika.next_level_exp = 777
	assert_true(SaveManager.save_game(slot), "lưu slot thử nghiệm")

	var raw = FileAccess.get_file_as_string(SaveManager.SAVES_DIR + slot + ".json")
	var data = JSON.parse_string(raw)
	assert_true(data is Dictionary, "file save là JSON hợp lệ")
	var saved_party = data["game_state"]["party"]["Ichika"]
	assert_eq(int(saved_party.get("next_level_exp", -1)), 777, "next_level_exp được ghi vào save")

	# Nạp: giá trị hiện tại bị đổi rồi phải được khôi phục từ save
	var parsed = SaveManager._parse_save_data(data)
	assert_false(parsed.is_empty(), "save hợp lệ được phân tích")
	ichika.next_level_exp = 5
	SaveManager._commit_save_data(parsed)
	assert_eq(ichika.next_level_exp, 777, "next_level_exp được khôi phục khi nạp")

	# Save cũ thiếu next_level_exp: tính lại theo level thay vì giữ giá trị lệch
	saved_party.erase("next_level_exp")
	var old_style = SaveManager._parse_save_data(data)
	assert_eq(old_style["party"]["Ichika"]["next_level_exp"], LevelManager.exp_needed_for_level(ichika.level), "save cũ: tính lại next_level_exp theo level")

	ichika.next_level_exp = original_next
	SaveManager.delete_save(slot)

func test_exp_needed_for_level_matches_level_up_curve():
	var e = Ichika.new()
	LevelManager.set_initial_level(e, 12)
	assert_eq(LevelManager.exp_needed_for_level(12), e.next_level_exp, "exp_needed_for_level khớp đường cong lên cấp (Lv12)")
	assert_eq(LevelManager.exp_needed_for_level(1), 100, "Lv1 cần 100 EXP")

func test_load_game_failure_does_not_mutate_state():
	var slot = "unit_test_corrupt_slot"
	var path = SaveManager.SAVES_DIR + slot + ".json"
	SaveManager.ensure_saves_dir()
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string('{"metadata": {}, "game_state": 5}')
	f.close()

	var credits_before = GameManager.credits
	var map_before = GameManager.current_map_file
	var story_before = GameManager.story.serialize()

	assert_false(GameManager.load_game(slot), "save hỏng (game_state sai kiểu) bị từ chối")
	assert_ne(GameManager.last_load_error, "", "last_load_error được điền")
	assert_eq(GameManager.credits, credits_before, "credits không đổi khi tải thất bại")
	assert_eq(GameManager.current_map_file, map_before, "current_map_file không đổi khi tải thất bại")
	assert_eq(GameManager.story.serialize(), story_before, "story không đổi khi tải thất bại")

	var g = FileAccess.open(path, FileAccess.WRITE)
	g.store_string("this is not json")
	g.close()
	assert_false(GameManager.load_game(slot), "file không phải JSON bị từ chối")
	assert_false(GameManager.load_game("unit_test_missing_slot"), "file không tồn tại bị từ chối")
	SaveManager.delete_save(slot)

func test_parse_save_data_tolerates_missing_parts():
	# player_pos null, map không tồn tại, thiếu party/inventory: vẫn hợp lệ với giá trị dự phòng
	var parsed = SaveManager._parse_save_data({"game_state": {"current_map": "res://Maps/KhongTonTai.tscn", "player_pos": null}})
	assert_false(parsed.is_empty(), "save thiếu nhiều mục vẫn được chấp nhận")
	assert_eq(parsed["map"], SaveManager.FALLBACK_MAP, "map không tồn tại -> về Base")
	assert_eq(parsed["pos"], Vector2.ZERO, "player_pos null -> Vector2.ZERO")
	assert_eq(parsed["credits"], GameManager.DEFAULT_CREDITS, "thiếu credits -> mặc định")
	assert_eq(parsed["inventory"], GameManager.DEFAULT_INVENTORY, "thiếu inventory -> mặc định")
	assert_true(SaveManager._parse_save_data({"metadata": {}}).is_empty(), "thiếu game_state bị từ chối")
