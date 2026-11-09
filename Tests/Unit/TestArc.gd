extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Kiểm tra logic chiến đấu và trạng thái của hồi kết 2 (Nightcord sụp đổ): trận kịch bản, hook kịch bản,
Mafuyu phản chiếu, thành viên đã chết và bộ lọc đối thủ luyện tập.
"""

func test_fated_and_win_flags_exist_in_story_state():
	for id in ScriptedBattleOutcomes.FATED:
		assert_true(StoryState.DEFAULT_FLAGS.has(ScriptedBattleOutcomes.FATED[id]), "Flag exists for fated battle " + id)
	for id in ScriptedBattleOutcomes.WIN_FLAG:
		assert_true(StoryState.DEFAULT_FLAGS.has(ScriptedBattleOutcomes.WIN_FLAG[id]), "Flag exists for win-flag battle " + id)
	for id in ["mizuki_police_done", "last_scripted_win", "last_scripted_loss"]:
		assert_true(StoryState.DEFAULT_FLAGS.has(id), "Default flag " + id)

func test_members_die_in_story_but_stay_in_sandbox_data():
	for n in ["Ichika", "Honami", "Ena", "Mizuki", "Kanade", "Mafuyu"]:
		assert_true(GameManager.is_member_alive_in_story(n), n + " alive by default")
	GameManager.story.set_flag("ena_killed", true)
	GameManager.story.set_flag("mizuki_killed", true)
	GameManager.story.set_flag("kanade_killed", true)
	GameManager.story.set_flag("final_mafuyu_defeated", true)
	for n in ["Ena", "Mizuki", "Kanade", "Mafuyu"]:
		assert_false(GameManager.is_member_alive_in_story(n), n + " gone after the arc")
		assert_true(GameManager.get_party_member(n) != null, n + " data stays for Holo-Sim and Sandbox")
	assert_true(GameManager.is_member_alive_in_story("Ichika"), "Ichika survives")
	assert_true(GameManager.is_member_alive_in_story("Honami"), "Honami survives")

func test_training_never_picks_dead_members():
	GameManager.story.set_flag("ena_killed", true)
	GameManager.story.set_flag("mizuki_killed", true)
	GameManager.story.set_flag("kanade_killed", true)
	GameManager.story.set_flag("final_mafuyu_defeated", true)
	for i in range(60):
		GameManager.begin_training(["Ichika", "Honami"])
		var data = BattleInitializer._setup_training_battle()
		for e in data["enemy_team"]:
			assert_false(e.entity_name in ["Ena", "Mizuki", "Kanade", "Mafuyu"], "Training opponent is not a dead member: " + e.entity_name)
	GameManager.end_training()

func test_final_mafuyu_mirrors_upgrades_with_a_floor():
	var mafuyu = GameManager.get_party_member("Mafuyu")
	var base_atk = mafuyu.atk
	var base_hp = mafuyu.max_hp
	var boss = BattleInitializer.build_final_mafuyu()
	assert_gt(boss.level, 0, "Boss has a level")
	assert_eq(boss.current_hp, boss.max_hp, "Boss starts at full HP")
	var floor_ref = Mafuyu.new()
	LevelManager.set_initial_level(floor_ref, BattleInitializer.FINAL_BOSS_FLOOR_LEVEL)
	assert_true(boss.atk >= floor_ref.atk, "Boss is never weaker than the floor level")

	# Dồn thật nhiều điểm vào Mafuyu đồng đội: boss phải mạnh lên theo
	mafuyu.atk += 5000
	mafuyu.max_hp += 20000
	var boss_upgraded = BattleInitializer.build_final_mafuyu()
	assert_gt(boss_upgraded.atk, boss.atk, "Upgrading Mafuyu makes the final boss hit harder")
	assert_gt(boss_upgraded.max_hp, boss.max_hp, "Upgrading Mafuyu makes the final boss tankier")
	assert_true(boss_upgraded.atk >= int((base_atk + 5000) * BattleInitializer.FINAL_BOSS_MIRROR["atk"]), "Boss ATK reflects the party Mafuyu")
	mafuyu.atk = base_atk
	mafuyu.max_hp = base_hp

func test_untargetable_entities_are_skipped_by_ai():
	var kanade = Kanade.new()
	var mizuki = Mizuki.new()
	var ichika = Ichika.new()
	ichika.untargetable = true
	for i in range(40):
		assert_eq(AIManager.pick_target(kanade, [mizuki, ichika], []), mizuki, "AI ignores the frozen ally")
	ichika.reset_battle_state()
	assert_false(ichika.untargetable, "Battle reset clears untargetable")

func test_forced_duel_overrides_mizuki_and_skips_ena():
	var scenario = ForcedDuelScenario.new()
	var mizuki = Mizuki.new()
	var ena = Ena.new()
	var fake = FakeBattleMain.new([mizuki], [ena])
	assert_eq(scenario.get_forced_action(fake, mizuki)["action"], "attack", "Mizuki's command is forced to attack")
	assert_eq(scenario.get_forced_action(fake, mizuki)["target"], ena, "Mizuki is forced onto Ena")
	assert_true(scenario.skips_turn(fake, ena), "Ena never fights back")
	assert_false(scenario.skips_turn(fake, mizuki), "Mizuki still takes her turns")
	assert_true(scenario.get_forced_action(fake, ena).is_empty(), "Enemies are never forced")
	# Sau đủ số đòn, Ena gục dù còn máu
	ena.max_hp = 100000
	ena.current_hp = 100000
	for i in range(ForcedDuelScenario.HITS_TO_FINISH):
		scenario.on_action_executed(fake, mizuki, "attack", ena)
	assert_eq(ena.current_hp, 0, "Ena falls after the scripted number of hits")
	fake.free()

func test_slow_strike_restricts_actions_and_finishes():
	var scenario = SlowStrikeScenario.new()
	var ichika = Ichika.new()
	var kanade = Kanade.new()
	var fake = FakeBattleMain.new([ichika], [kanade])
	assert_eq(scenario.get_allowed_actions(fake, ichika), ["shadow_strike"], "Only Ảnh Sát is available")
	kanade.max_hp = 5000
	kanade.current_hp = 5000
	scenario.on_action_executed(fake, ichika, "shadow_strike", kanade)
	assert_eq(kanade.current_hp, 0, "Ảnh Sát finishes the duel")
	Engine.time_scale = 1.0
	fake.free()

func test_forced_loss_ends_after_a_few_turns():
	var scenario = ForcedLossScenario.new()
	var ena = Ena.new()
	var fake = FakeBattleMain.new([ena], [PoliceOfficer.new()])
	for i in range(ForcedLossScenario.MAX_PLAYER_TURNS):
		scenario.on_turn_start(fake, ena)
	assert_false(scenario._overwhelmed, "Ena still fights during her allotted turns")
	scenario.on_turn_start(fake, ena)
	assert_true(scenario._overwhelmed, "After the allotted turns the ambush overwhelms her")
	fake.free()

# ── BaseMap: chọn Stage và điều hướng theo cờ ───────────────────────────────

func _base_with(flags: Dictionary):
	GameManager.reset_game()
	for k in flags:
		GameManager.story.set_flag(k, flags[k])
	return load("res://Maps/Base/BaseMap.tscn").instantiate()

func _stage_name(flags: Dictionary) -> String:
	var m = _base_with(flags)
	m._init_stage()
	var stage_name: String = m.current_stage.get_script().resource_path.get_file().get_basename()
	m.free()
	return stage_name

func _redirect(flags: Dictionary) -> String:
	var m = _base_with(flags)
	var target: String = m._arc2_redirect_target()
	m.free()
	return target

func test_base_picks_the_right_arc_stage():
	assert_eq(_stage_name({"pm_boss_defeated": true}), "FinaleStage", "PM dead -> celebration and the next-PM talk")
	assert_eq(_stage_name({"interrogation_seen": true}), "OrdersStage", "After the torture scene -> Mafuyu's orders")
	assert_eq(_stage_name({"kanade_killed": true}), "RevealStage", "Kanade dead -> Mafuyu's reveal")
	assert_eq(_stage_name({"final_confront_started": true}), "FinalStage", "Confronting Mafuyu happens in the base")
	assert_eq(_stage_name({"game_completed": true, "final_confront_started": true}), "EpilogueStage", "Epilogue wins over the final stage")

func test_base_redirects_away_when_the_arc_lives_elsewhere():
	assert_eq(_redirect({}), "", "Normal play stays in the base")
	assert_eq(_redirect({"ena_left_nightcord": true}), "res://Maps/Bounty/BountyMap.tscn", "Ena's bounty hunt")
	assert_eq(_redirect({"ena_left_nightcord": true, "interrogation_seen": true}), "", "Orders happen in the base")
	assert_eq(_redirect({"ena_left_nightcord": true, "interrogation_seen": true, "ena_kill_ordered": true}), "res://Maps/Interrogation/InterrogationMap.tscn", "Warehouse sequence")
	assert_eq(_redirect({"ena_left_nightcord": true, "kanade_killed": true, "interrogation_seen": true, "ena_kill_ordered": true}), "", "Reveal happens in the base")
	assert_eq(_redirect({"ena_left_nightcord": true, "honami_rescue_done": true}), "res://Maps/HonamiHouse/HonamiHouseMap.tscn", "After the rescue the player lives at Honami's house")
	assert_eq(_redirect({"ena_left_nightcord": true, "honami_rescue_done": true, "final_confront_started": true}), "", "The final stage is in the base")
	assert_eq(_redirect({"ena_left_nightcord": true, "game_completed": true}), "", "Epilogue stays in the base")

# ── Hội thoại ───────────────────────────────────────────────────────────────
