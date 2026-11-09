extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Unit test cho Chế độ Mô phỏng Roguelite (HoloSimManager, HoloBlessing, HoloSimScenario).
"""

func test_holosim_floors():
	assert_eq(HoloSimManager.MAX_FLOORS, 10, "HoloSim has 10 floors")
	
	# Floor 1
	var f1 = HoloSimManager.get_floor_info(1)
	assert_false(f1["is_rest"], "Floor 1 is combat floor")
	assert_gt(f1["enemies"].size(), 0, "Floor 1 has enemies")
	
	# Rest Floors: 4 & 9
	assert_true(HoloSimManager.is_rest_floor(4), "Floor 4 is rest station")
	assert_true(HoloSimManager.is_rest_floor(9), "Floor 9 is rest station")
	
	# Boss Floor: 10
	var f10 = HoloSimManager.get_floor_info(10)
	assert_true(f10["enemies"].has("Đội Trưởng (BOSS)"), "Floor 10 has final boss")

func test_holosim_blessings():
	var catalog = HoloBlessing.BLESSING_CATALOG
	assert_eq(catalog.size(), 8, "HoloBlessing defines 8 unique blessings")
	
	var random_blessings = HoloBlessing.get_random_blessings(3, ["blessing_bleed"])
	assert_eq(random_blessings.size(), 3, "get_random_blessings returns requested count")
	for b in random_blessings:
		assert_ne(b["id"], "blessing_bleed", "Excluded blessings are not returned")

func test_holosim_scenario():
	HoloSimManager.start_new_run()
	assert_true(HoloSimManager.is_sim_active, "HoloSimManager start_new_run sets is_sim_active to true")
	assert_eq(HoloSimManager.current_floor, 1, "HoloSim starts at floor 1")
	
	HoloSimManager.add_blessing("blessing_speed")
	assert_true(HoloSimManager.has_blessing("blessing_speed"), "HoloSim records added blessing")
	
	var ichika = Ichika.new()
	var initial_spd = ichika.spd
	HoloSimManager.apply_blessings_to_team([ichika])
	assert_eq(ichika.spd, initial_spd + 35, "Speed blessing applies +35 SPD to team members")
	
	HoloSimManager.advance_floor()
	assert_eq(HoloSimManager.current_floor, 2, "advance_floor increments current floor")
	assert_gt(HoloSimManager.high_score_floor, 0, "High score floor updated")
	
	HoloSimManager.is_sim_active = false

func test_holosim_battle_setup():
	HoloSimManager.start_new_run()
	var battle_data = BattleInitializer.setup_battle()
	assert_gt(battle_data["enemy_team"].size(), 0, "HoloSim floor 1 spawns enemies")
	assert_true(battle_data["scenario"] is HoloSimScenario, "HoloSim uses HoloSimScenario")
	HoloSimManager.is_sim_active = false

func test_blessings_do_not_stack_across_floors():
	HoloSimManager.start_new_run()
	HoloSimManager.add_blessing("blessing_speed")
	HoloSimManager.add_blessing("blessing_crit")
	var ichika = Ichika.new()
	var base_spd = ichika.spd
	var base_crit = ichika.crit_rate
	for floor_run in range(3):
		HoloSimManager.apply_blessings_to_team([ichika])
		ichika.clear_temp_mods() # Main._exit_tree gỡ buff khi mỗi tầng kết thúc
	assert_eq(ichika.spd, base_spd, "Speed blessing leaves no permanent SPD on the party")
	assert_eq(ichika.crit_rate, base_crit, "Crit blessing leaves no permanent crit rate on the party")
	HoloSimManager.is_sim_active = false

func test_rest_floors_have_no_enemies():
	for f in [4, 9]:
		assert_true(HoloSimManager.is_rest_floor(f), "Floor %d is a rest floor" % f)
		assert_eq(HoloSimManager.get_floor_info(f)["enemies"].size(), 0, "Rest floor %d has no battle" % f)

# ── HoloSimScenario: các hook Phước Lành chạy trong trận ───────────────────

func _end_holosim_test(entities: Array) -> void:
	HoloSimManager.is_sim_active = false
	HoloSimManager.active_blessings.clear()
	for e in entities:
		e.free()

# Dòng Máu Bất Tử cứu đội đúng một lần mỗi trận: lần gục thứ hai là thua thật
func test_undying_blessing_saves_the_team_once():
	HoloSimManager.start_new_run()
	HoloSimManager.add_blessing("blessing_undying")
	var ichika := Ichika.new()
	var guard := Guard.new()
	var main := FakeBattleMain.new([ichika], [guard])
	var scenario := HoloSimScenario.new()
	ichika.current_hp = 0
	assert_false(scenario.check_battle_end(main), "Gục lần đầu: được cứu, trận tiếp tục")
	assert_eq(ichika.current_hp, int(ichika.max_hp * 0.4), "Hồi 40% HP")
	assert_true(main.hud.results.is_empty(), "Chưa có banner thua")
	ichika.current_hp = 0
	assert_true(scenario.check_battle_end(main), "Gục lần hai: thua thật")
	assert_eq(main.hud.results, [false], "Banner thua hiện đúng một lần")
	main.free()
	_end_holosim_test([ichika, guard])

# Hút Máu khi Hạ Địch: kẻ địch chết thì người đầu tiên còn sống hồi 25% máu tối đa; nhân vật chết thì không
func test_heal_on_kill_blessing_heals_the_first_living_member():
	HoloSimManager.start_new_run()
	HoloSimManager.add_blessing("blessing_heal_kill")
	var ichika := Ichika.new()
	var guard := Guard.new()
	var main := FakeBattleMain.new([ichika], [guard])
	var scenario := HoloSimScenario.new()
	ichika.current_hp = 10
	scenario.on_entity_died(main, guard)
	assert_eq(ichika.current_hp, 10 + int(ichika.max_hp * 0.25), "Hồi 25% máu tối đa")
	var after_kill: int = ichika.current_hp
	scenario.on_entity_died(main, ichika)
	assert_eq(ichika.current_hp, after_kill, "Đồng đội gục không kích hoạt hồi máu")
	main.free()
	_end_holosim_test([ichika, guard])

# Kích Nổ Năng Lượng: đòn chí mạng giảm 1 lượt hồi của kỹ năng đang hồi, cờ chí mạng được tiêu thụ
func test_cooldown_blessing_shaves_one_turn_after_a_crit():
	HoloSimManager.start_new_run()
	HoloSimManager.add_blessing("blessing_cooldown")
	var ichika := Ichika.new()
	var guard := Guard.new()
	var main := FakeBattleMain.new([ichika], [guard])
	var scenario := HoloSimScenario.new()
	CooldownManager.set_cooldown(ichika, "shadow_strike", 3)
	ichika.set_meta("last_hit_crit", true)
	scenario.on_action_executed(main, ichika, "attack", guard)
	assert_eq(ichika.cooldowns["shadow_strike"], 2, "Hồi chiêu giảm 1 lượt")
	assert_false(ichika.has_meta("last_hit_crit"), "Cờ chí mạng đã được tiêu thụ")
	scenario.on_action_executed(main, ichika, "attack", guard)
	assert_eq(ichika.cooldowns["shadow_strike"], 2, "Không chí mạng thì không giảm thêm")
	main.free()
	_end_holosim_test([ichika, guard])

# Phản Đòn: nối vào đội hình sống qua nhiều trận nên phải gỡ ra khi xong, không để lại hook cho trận sau
func test_thorn_blessing_reflects_and_unhooks_when_the_battle_ends():
	HoloSimManager.start_new_run()
	HoloSimManager.add_blessing("blessing_thorn")
	var ichika := Ichika.new()
	var guard := Guard.new()
	var main := FakeBattleMain.new([ichika], [guard])
	var scenario := HoloSimScenario.new()
	scenario.on_start(main)
	var guard_hp: int = guard.current_hp
	ichika.take_damage(100)
	assert_eq(guard.current_hp, guard_hp - 35, "Phản lại 35% sát thương nhận vào cho kẻ địch")
	scenario._disconnect_hooks()
	assert_eq(ichika.damage_received_detailed.get_connections().size(), 0, "Hook được gỡ khỏi đội hình bền vững")
	guard_hp = guard.current_hp
	ichika.take_damage(100)
	assert_eq(guard.current_hp, guard_hp, "Gỡ hook rồi thì không phản đòn nữa")
	main.free()
	_end_holosim_test([ichika, guard])

