extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Kiểm tra các lỗi tìm thấy khi chơi thử tự động toàn bộ game: EXP và chỉ số của luyện tập, đội hình gục sau trận,
hồi máu khi rời Holo-Sim, HP và kỷ lục lưu trong save, tên map, gợi ý "Nói chuyện 4 lần" và cảnh Mizuki ăn vặt.
"""

const BASE_SCENE = "res://Maps/Base/BaseMap.tscn"

# ── Luyện tập ───────────────────────────────────────────────────────────────

func test_training_clone_has_the_real_characters_upgrades():
	var real: Entity = GameManager.get_party_member("Ichika")
	real.max_hp += 900
	real.atk += 120
	real.defense += 40
	real.spd += 10
	GameManager.begin_training(["Ichika"])
	var clone: Entity = BattleInitializer._setup_training_battle()["player_team"][0]
	assert_true(clone != real, "Luyện tập đánh bằng bản sao, không phải nhân vật thật")
	assert_eq(clone.max_hp, real.max_hp, "Bản sao có đủ HP đã nâng")
	assert_eq(clone.atk, real.atk, "Bản sao có đủ ATK đã nâng")
	assert_eq(clone.defense, real.defense, "Bản sao có đủ DEF đã nâng")
	assert_eq(clone.spd, real.spd, "Bản sao có đủ SPD đã nâng")
	assert_eq(clone.current_hp, clone.max_hp, "Bản sao luôn vào trận đầy máu")
	GameManager.end_training()

func test_training_exp_is_collected_for_the_real_party_not_the_clone():
	var main = load("res://Scripts/Battle/Main.gd").new()
	var clone := Ichika.new()
	main.player_team = [clone]
	GameManager.begin_training(["Ichika"])

	var robot := Guard.new()
	LevelManager.set_initial_level(robot, 10)
	main._on_entity_died(robot)
	assert_eq(GameManager.training_exp_earned, LevelManager.get_exp_reward(10), "Hạ địch khi luyện tập gom EXP")
	assert_eq(clone.current_exp, 0, "EXP không cộng vào bản sao (sẽ mất khi hết trận)")

	# Đối thủ là thành viên trong nhóm vẫn cho EXP khi luyện tập (trước đây 70% trận luyện tập không cho gì)
	var foe := Kanade.new()
	LevelManager.set_initial_level(foe, 12)
	main._on_entity_died(foe)
	assert_eq(GameManager.training_exp_earned, LevelManager.get_exp_reward(10) + LevelManager.get_exp_reward(12), "Đối thủ là nhân vật cũng cho EXP")

	# Bản sao phe ta gục không được tính như hạ địch
	var before := GameManager.training_exp_earned
	main._on_entity_died(clone)
	assert_eq(GameManager.training_exp_earned, before, "Phe ta gục không sinh EXP")

	# Ngoài luyện tập: nhân vật làm địch vẫn không cho EXP, quái thường cho EXP trực tiếp
	GameManager.end_training()
	main._on_entity_died(Kanade.new())
	assert_eq(clone.current_exp, 0, "Ngoài luyện tập, nhân vật làm địch không cho EXP")
	main._on_entity_died(robot)
	assert_gt(clone.current_exp, 0, "Ngoài luyện tập, quái thường cho EXP trực tiếp")
	main.free()

func test_training_win_grants_exp_to_the_real_character():
	var ichika: Entity = GameManager.get_party_member("Ichika")
	var kanade: Entity = GameManager.get_party_member("Kanade")
	var exp_before := ichika.current_exp
	var kanade_exp := kanade.current_exp
	GameManager.begin_training(["Ichika"])
	GameManager.training_exp_earned = 40
	GameManager._apply_victory_rewards()
	assert_eq(ichika.current_exp, exp_before + 40, "Thắng luyện tập cộng EXP cho nhân vật thật")
	assert_eq(kanade.current_exp, kanade_exp, "Người không tham gia không nhận EXP")
	assert_eq(GameManager.training_exp_earned, 0, "Bộ đếm EXP được xóa sau khi trao")
	GameManager.end_training()

# ── Đội hình gục sau trận ───────────────────────────────────────────────────

func test_downed_members_start_story_battles_revived():
	var ena: Entity = GameManager.get_party_member("Ena")
	ena.current_hp = 0
	GameManager.is_scripted_battle = true
	GameManager.scripted_battle_id = "bounty_1"
	var data = BattleInitializer.setup_battle()
	assert_eq(data["player_team"][0], ena, "Hợp đồng 1 do Ena đánh một mình")
	assert_eq(ena.current_hp, int(ena.max_hp * 0.5), "Ena gục từ trận trước vào trận với 50% HP, không thua ngay lượt 0")

	# Người chỉ bị thương không bị đụng tới (các trận cốt truyện có thể cố ý bắt đầu với đội yếu)
	ena.current_hp = 10
	BattleInitializer.setup_battle()
	assert_eq(ena.current_hp, 10, "Chỉ người đã gục mới được hồi")

func test_sandbox_and_training_teams_are_not_touched_by_revive():
	var fresh := Ichika.new()
	fresh.current_hp = 0
	GameManager.is_sandbox = true
	GameManager.sandbox_player_team = [fresh]
	GameManager.sandbox_enemy_team = [Guard.new()]
	BattleInitializer.setup_battle()
	assert_eq(fresh.current_hp, 0, "Sandbox giữ nguyên đội do người chơi dựng")

func test_leaving_holosim_heals_the_whole_party():
	for p in GameManager.party.values():
		p.current_hp = 0
	HoloSimManager.start_new_run()
	HoloSimManager.end_run()
	assert_false(HoloSimManager.is_sim_active, "end_run kết thúc phiên Holo-Sim")
	for p in GameManager.party.values():
		assert_eq(p.current_hp, p.max_hp, "%s đầy máu khi rời tháp" % p.entity_name)

func test_battle_exit_clears_untargetable():
	var main = load("res://Scripts/Battle/Main.gd").new()
	var ichika: Entity = GameManager.get_party_member("Ichika")
	ichika.untargetable = true
	main.all_entities = [ichika]
	main._exit_tree()
	assert_false(ichika.untargetable, "Cờ bất khả nhắm của kịch bản không rò sang ngoài trận")
	main.free()

# ── Save ────────────────────────────────────────────────────────────────────

func _saved_game_state(slot: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SaveManager.SAVES_DIR + slot + ".json"))

func test_save_keeps_hp_and_the_holosim_record():
	var slot := "unit_test_hp_slot"
	var ichika: Entity = GameManager.get_party_member("Ichika")
	ichika.current_hp = 7
	GameManager.get_party_member("Kanade").current_hp = 0
	HoloSimManager.high_score_floor = 6
	assert_true(SaveManager.save_game(slot), "lưu slot thử nghiệm")
	var data := _saved_game_state(slot)

	ichika.current_hp = ichika.max_hp
	HoloSimManager.high_score_floor = 0
	SaveManager._commit_save_data(SaveManager._parse_save_data(data))
	assert_eq(ichika.current_hp, 7, "HP được khôi phục từ save (nạp game không còn là hồi máu miễn phí)")
	assert_eq(GameManager.get_party_member("Kanade").current_hp, 0, "Người gục vẫn gục sau khi nạp")
	assert_eq(HoloSimManager.high_score_floor, 6, "Kỷ lục Holo-Sim được khôi phục")

	# Save cũ chưa có HP -> đầy máu; HP lạc ngoài khoảng bị kẹp lại
	var party: Dictionary = data["game_state"]["party"]
	party["Ichika"].erase("hp")
	party["Kanade"]["hp"] = 999999
	party["Mafuyu"]["hp"] = -50
	data["game_state"].erase("holosim_high_floor")
	var parsed := SaveManager._parse_save_data(data)
	assert_eq(parsed["party"]["Ichika"]["hp"], parsed["party"]["Ichika"]["max_hp"], "Save cũ thiếu hp -> đầy máu")
	assert_eq(parsed["party"]["Kanade"]["hp"], parsed["party"]["Kanade"]["max_hp"], "hp quá lớn bị kẹp về max_hp")
	assert_eq(parsed["party"]["Mafuyu"]["hp"], 0, "hp âm bị kẹp về 0")
	assert_eq(parsed["holosim_high_floor"], 0, "Save cũ thiếu kỷ lục -> 0")
	SaveManager.delete_save(slot)

func test_new_game_clears_the_holosim_record():
	HoloSimManager.high_score_floor = 9
	GameManager.reset_game()
	assert_eq(HoloSimManager.high_score_floor, 0, "Chơi mới bắt đầu lại kỷ lục")

func test_every_map_scene_has_a_save_slot_name():
	for dir_name in DirAccess.get_directories_at("res://Maps"):
		for file_name in DirAccess.get_files_at("res://Maps/" + dir_name):
			if file_name.ends_with(".tscn"):
				var path := "res://Maps/%s/%s" % [dir_name, file_name]
				assert_true(MapPaths.NAMES.has(path), "Ô save có tên đọc được cho " + path)

# ── Cảnh ở căn cứ ───────────────────────────────────────────────────────────

func _post_harbor_morning_base() -> Node:
	GameManager.reset_game()
	for k in ["safehouse_intro_done", "intro_quest_done", "warehouse_mission_accepted", "harbor_mission_done", "mizuki_report_done", "post_harbor_morning_done", "ena_released"]:
		GameManager.set_flag(k, true)
	var base = load(BASE_SCENE).instantiate()
	base._init_stage()
	return base

func test_four_talks_trigger_ena_in_the_same_scene():
	var base = _post_harbor_morning_base()
	var stage = base.current_stage
	assert_eq(stage.get_script().resource_path.get_file(), "PostHarborMorningStage.gd", "Đúng Stage sau buổi sáng")
	for i in 3:
		stage.handle_npc_interaction("Ena")
		_drain_dialogue()
	assert_false(GameManager.get_flag("ena_control_phase"), "Mới nói chuyện 3 lần: chưa tới lượt Ena")
	stage.handle_npc_interaction("Ena")
	_drain_dialogue()
	assert_eq(GameManager.get_flag("interaction_count", 0), 4, "Đã đếm đủ 4 lần nói chuyện")
	assert_true(GameManager.get_flag("ena_control_phase"), "Lần thứ 4: Ena chán và nhận quyền điều khiển ngay, không cần vào lại căn cứ")
	base.free()

func test_ena_trigger_waits_for_open_choice_menus():
	var base = _post_harbor_morning_base()
	var stage = base.current_stage
	GameManager.set_flag("interaction_count", 4)
	DialogueManager.show_choice(["a", "b"])
	stage._on_talk_finished()
	assert_false(DialogueManager.active, "Không chen hội thoại mới lên khi lựa chọn đang mở")
	assert_false(GameManager.get_flag("ena_control_phase"), "Chờ người chơi chọn xong")
	DialogueManager._ui.choice_selected.emit(0)
	base.free()

# Giai đoạn của PostHarborStage do cờ mafuyu_honami_talked quyết định (trước đây là harbor_wave > 5)
func test_post_harbor_phase_follows_the_honami_talk_flag():
	var base = load(BASE_SCENE).instantiate()
	var stage = load("res://Maps/Base/Stages/PostHarborStage.gd").new()
	base.add_child(stage)
	stage.setup(base)
	stage.on_stage_start() # chưa nói chuyện với Mafuyu về Honami: buổi họp đầu
	assert_true(DialogueManager.active, "Chưa nói về Honami thì phát buổi họp đầu")
	_drain_dialogue()
	assert_true(GameManager.get_flag("harbor_meeting_p1_done"), "Buổi họp đầu chỉ phát một lần")
	assert_false(GameManager.get_flag("harbor_mizuki_snack_done"), "Chưa tới cảnh ăn vặt")
	stage.on_stage_start()
	assert_false(DialogueManager.active, "Họp xong rồi thì vào lại căn cứ không phát lại")
	GameManager.set_flag("mafuyu_honami_talked", true) # đã nói về Honami: sang cảnh Mizuki ăn vặt
	stage.on_stage_start()
	assert_true(DialogueManager.active, "Đã nói về Honami thì phát cảnh Mizuki ăn vặt")
	_drain_dialogue()
	assert_true(GameManager.get_flag("harbor_mizuki_snack_done"), "Cảnh ăn vặt đã xem")
	stage.on_stage_start()
	assert_false(DialogueManager.active, "Xem rồi thì không phát lại")
	base.free()

func test_alleyway_monologue_follows_the_honami_talk_flag():
	var alley = load("res://Maps/Alleyway/AlleywayMap.gd").new()
	assert_eq(alley._dialogue_key(), "honami_alleyway", "Chưa nói chuyện với Mafuyu: phần 1")
	GameManager.set_flag("mafuyu_honami_talked", true)
	assert_eq(alley._dialogue_key(), "honami_alleyway_p2", "Đã nói chuyện: phần 2")
	assert_true(DialogueLoader.get_lines("honami_alleyway").size() > 0 and DialogueLoader.get_lines("honami_alleyway_p2").size() > 0, "Cả hai đoạn hội thoại đều có")
	alley.free()

func test_mizuki_snack_scene_plays_only_once():
	GameManager.set_flag("mafuyu_honami_talked", true)
	var base = load(BASE_SCENE).instantiate()
	var stage = load("res://Maps/Base/Stages/PostHarborStage.gd").new()
	base.add_child(stage)
	stage.setup(base)
	assert_false(GameManager.get_flag("harbor_mizuki_snack_done"), "Chưa xem cảnh ăn vặt")
	stage._play_mizuki_snack_sequence()
	_drain_dialogue()
	assert_true(GameManager.get_flag("harbor_mizuki_snack_done"), "Xem xong thì đánh dấu để vào lại căn cứ không phát lại")
	assert_true(GameManager.get_flag("mizuki_control_phase"), "Chuyển sang điều khiển Mizuki")
	base.free()

# ── Thua màn Tác chiến / Thủ Tướng: về căn cứ để luyện tập thêm ──────────────

func test_losing_a_finale_fight_retreats_to_base_and_reopens_training():
	for id in ["ops_kanade", "ops_ichika", "ops_honami", "pm_boss"]:
		assert_true(id in ScriptedBattleOutcomes.RETREAT_ON_LOSS, "%s: thua thì rút về căn cứ" % id)
	for id in ["bounty_ambush", "mizuki_vs_mafuyu", "final_mafuyu", "street_skirmish"]:
		assert_false(id in ScriptedBattleOutcomes.RETREAT_ON_LOSS, "%s giữ cách xử lý thua riêng" % id)

	for flag in GameManager.TRAINING_DONE_FLAGS:
		GameManager.set_flag(flag, true)
	GameManager.current_map_file = "res://Maps/Highway/HighwayMap.tscn"
	GameManager.last_player_position = Vector2(50, 50)
	GameManager._retreat_to_base()
	assert_eq(GameManager.current_map_file, "res://Maps/Base/BaseMap.tscn", "Thua thì quay lại căn cứ, không đánh lại ngay tại bản đồ trận")
	assert_eq(GameManager.last_player_position, Vector2.ZERO, "Đứng ở vị trí mặc định trong căn cứ")
	assert_true(GameManager.get_flag("finale_retreated"), "Đánh dấu để căn cứ giải thích vì sao quay về")
	for flag in GameManager.TRAINING_DONE_FLAGS:
		assert_false(GameManager.get_flag(flag), "%s được mở lại để luyện tập thêm" % flag)

func test_wave_mission_loss_also_reopens_training():
	GameManager.set_flag("training_ichika_done", true)
	GameManager.set_flag("training_kanade_done", true)
	GameManager.reset_training_progress()
	assert_false(GameManager.get_flag("training_ichika_done"), "Ichika tập lại được")
	assert_false(GameManager.get_flag("training_kanade_done"), "Kanade tập lại được")

func _finale_stage_base() -> Node:
	GameManager.reset_game()
	for k in ["honami_house_unlocked", "honami_unlocked_intro_done", "pm_arc_started", "ops_intro_done"]:
		GameManager.set_flag(k, true)
	var base = load(BASE_SCENE).instantiate()
	base._init_stage()
	return base

func test_base_explains_the_retreat_once():
	var base = _finale_stage_base()
	var stage = base.current_stage
	assert_eq(stage.get_script().resource_path.get_file(), "HonamiHouseUnlockedStage.gd", "Giữa màn Tác chiến vẫn dùng Stage nhà Honami")
	GameManager.set_flag("finale_retreated", true)
	stage.on_stage_start()
	assert_true(DialogueManager.active, "Có lời giải thích khi về căn cứ sau trận thua")
	assert_false(GameManager.get_flag("finale_retreated"), "Chỉ giải thích một lần")
	_drain_dialogue()
	base.free()

func test_mafuyu_lets_the_player_resume_the_mission_or_train():
	var base = _finale_stage_base()
	var stage = base.current_stage
	assert_true(stage.get_quest_text().contains("tiếp tục nhiệm vụ"), "HUD nhắc quay lại nhiệm vụ")
	stage.handle_npc_interaction("Mafuyu")
	_drain_dialogue()
	assert_true(DialogueManager._in_choice, "Mafuyu mở menu lựa chọn")
	var labels: Array = DialogueManager._ui.choice_box.get_children().filter(func(n): return n is Button).map(func(b): return b.text)
	assert_true("[Tiếp tục nhiệm vụ]" in labels, "Có lựa chọn tiếp tục nhiệm vụ (trước đây không còn đường nào quay lại)")
	assert_true("[Tập luyện]" in labels, "Vẫn có tập luyện")
	DialogueManager._ui.choice_selected.emit(labels.size() - 1)
	base.free()

# Lên cấp giữa trận khi đang có buff tạm: chỉ số tăng theo giá trị gốc, buff gỡ xong không để lại phần thừa
func test_level_up_under_a_temp_buff_leaves_no_permanent_extra():
	var buffed := Ichika.new()
	var plain := Ichika.new()
	LevelManager.set_initial_level(buffed, 5)
	LevelManager.set_initial_level(plain, 5)
	buffed.add_temp_mod("spd", 40)
	buffed.add_temp_mod("atk", 100)
	LevelManager.process_level_up(buffed)
	LevelManager.process_level_up(plain)
	assert_eq(buffed.spd, plain.spd + 40, "the buff is still applied after the level-up")
	buffed.clear_temp_mods()
	assert_eq(buffed.spd, plain.spd, "spd is back to the plain level-up value once the buff is removed")
	assert_eq(buffed.atk, plain.atk, "atk is back to the plain level-up value once the buff is removed")
	buffed.free()
	plain.free()

func test_clearing_a_max_hp_buff_never_leaves_hp_above_max():
	var e := Ichika.new()
	var base_max := e.max_hp
	e.add_temp_mod("max_hp", 500)
	e.current_hp = e.max_hp
	e.clear_temp_mods()
	assert_eq(e.max_hp, base_max, "max HP back to normal")
	assert_eq(e.current_hp, base_max, "current HP is clamped to the restored max")
	e.free()
