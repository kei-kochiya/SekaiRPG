extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Kiểm tra tĩnh trên mã nguồn: gõ sai tên cờ cốt truyện hoặc khóa hội thoại sẽ không gây lỗi mà lặng lẽ đọc ra
false / bỏ qua cảnh, nên quét mọi script và bắt các tên không tồn tại. Cùng với đó là kiểm tra lưu/đọc tùy chọn người chơi.
"""

const SKIP_DIRS := ["addons", "tools", "Export", ".godot", "screenshots", "Playthrough"]

func _gd_files(dir_path: String = "res://") -> Array:
	var out := []
	for sub in DirAccess.get_directories_at(dir_path):
		if sub in SKIP_DIRS or sub.begins_with("."):
			continue
		out.append_array(_gd_files(dir_path.path_join(sub)))
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".gd"):
			out.append(dir_path.path_join(file))
	return out

# Mọi lần gọi `fn("literal"` trong mã game: {literal: [file, ...]}
func _literals(fn_names: Array) -> Dictionary:
	# \x22 là dấu nháy kép (tránh phải escape dấu nháy trong chuỗi GDScript)
	var re := RegEx.create_from_string(r"\b(?:%s)\(\s*\x22([A-Za-z0-9_]+)\x22\s*[,)]" % "|".join(fn_names))
	var out := {}
	for path in _gd_files():
		if path.begins_with("res://Tests/"):
			continue
		var text := FileAccess.get_file_as_string(path)
		for m in re.search_all(text):
			var key := m.get_string(1)
			if not out.has(key):
				out[key] = []
			out[key].append(path)
	return out

func test_every_story_flag_in_code_is_declared():
	var found := _literals(["get_flag", "set_flag"])
	assert_gt(found.size(), 50, "Found the story flags used by the code")
	for flag in found:
		assert_true(StoryState.DEFAULT_FLAGS.has(flag), "flag '%s' (%s) is declared in StoryState.DEFAULT_FLAGS" % [flag, found[flag][0]])

func test_every_literal_dialogue_key_in_code_exists():
	var found := _literals(["get_lines", "say_lines", "_say"]) # _say: lối tắt thoại của BountyMap/InterrogationMap
	assert_gt(found.size(), 80, "Found the dialogue keys used by the code")
	for key in found:
		assert_gt(DialogueLoader.get_lines(key).size(), 0, "dialogue key '%s' (%s) exists" % [key, found[key][0]])

# Một id trận gõ sai ở nơi gọi cho ra đội hình rỗng, tức là thắng ngay mà không ai hay: mọi id ghi thẳng trong mã phải có trong registry
func test_every_scripted_battle_id_in_code_is_registered():
	var found := _literals(["start_scripted_battle", "_start_battle", "_battle"])
	assert_gt(found.size(), 12, "Tìm thấy các id trận kịch bản được gọi trong mã")
	var registry: Array = BattleInitializer.scripted_battle_ids()
	for id in found:
		assert_true(id in registry, "trận '%s' (%s) có trong BattleInitializer registry" % [id, found[id][0]])

# Cờ chỉ ghi mà không ai đọc (hay ngược lại) là dấu hiệu đoạn mã đọc đã bị xóa mà cờ còn sót, như harbor_boss_defeated từng bị
func test_every_story_flag_is_both_written_and_read_somewhere():
	var written := _literals(["set_flag"])
	var read := _literals(["get_flag"])
	# Các cờ đặt/đọc bằng tên dựng động hoặc bảng dữ liệu: training_*_done (GameManager.TRAINING_DONE_FLAGS), bounty_N_done, các cờ trong bảng kết quả trận
	for flag in ScriptedBattleOutcomes.FATED.values() + ScriptedBattleOutcomes.WIN_FLAG.values():
		written[flag] = ["ScriptedBattleOutcomes"]
	for flag in GameManager.TRAINING_DONE_FLAGS:
		written[flag] = ["GameManager.TRAINING_DONE_FLAGS"]
		read[flag] = ["GameManager.TRAINING_DONE_FLAGS"]
	for i in range(1, 4):
		read["bounty_%d_done" % i] = ["BountyMap (khóa dựng bằng \"bounty_%d_done\")"] # đọc bằng tên dựng động
	var problems: Array = []
	for flag in StoryState.DEFAULT_FLAGS:
		if not written.has(flag):
			problems.append("%s: không nơi nào ghi" % flag)
		if not read.has(flag):
			problems.append("%s: không nơi nào đọc" % flag)
	assert_eq(problems, [], "Mọi cờ trong DEFAULT_FLAGS vừa được ghi vừa được đọc")

func test_settings_survive_a_save_and_load():
	var had_file := FileAccess.file_exists(GameSettings.PATH)
	var old_bytes := FileAccess.get_file_as_bytes(GameSettings.PATH) if had_file else PackedByteArray()
	var old := [GameManager.battle_speed, GameManager.master_volume, GameManager.reduce_motion,
		GameManager.skip_battle_unlocked, GameManager.skip_battle_enabled]
	
	GameManager.battle_speed = GameManager.BATTLE_SPEED_FAST
	GameManager.master_volume = 0.35
	GameManager.reduce_motion = true
	GameManager.skip_battle_unlocked = true
	GameManager.skip_battle_enabled = true
	GameManager.save_settings()
	GameManager.battle_speed = GameManager.BATTLE_SPEED_NORMAL
	GameManager.master_volume = 1.0
	GameManager.reduce_motion = false
	GameManager.skip_battle_unlocked = false
	GameManager.skip_battle_enabled = false
	GameManager.load_settings()
	assert_eq(GameManager.battle_speed, GameManager.BATTLE_SPEED_FAST, "battle speed is restored")
	assert_true(absf(GameManager.master_volume - 0.35) < 0.001, "volume is restored")
	assert_true(GameManager.reduce_motion, "reduce_motion is restored")
	assert_true(GameManager.skip_battle_unlocked and GameManager.skip_battle_enabled, "skip-battle unlock is restored")
	
	# Trả lại file và giá trị như cũ để không làm bẩn tùy chọn thật của người chơi
	if had_file:
		var f := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
		f.store_buffer(old_bytes)
		f.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	GameManager.battle_speed = old[0]
	GameManager.master_volume = old[1]
	GameManager.reduce_motion = old[2]
	GameManager.skip_battle_unlocked = old[3]
	GameManager.skip_battle_enabled = old[4]
