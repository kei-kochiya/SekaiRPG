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
