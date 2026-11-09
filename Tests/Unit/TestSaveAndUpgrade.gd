extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Hai phần logic rủi ro cao từng không có test: vòng lưu/nạp đầy đủ (credits, kho, rương, map, cờ, cấp và chỉ số nhân vật)
và UpgradeManager (chi phí SP, trần chỉ số, thành viên đang gục).
"""

const SLOT := "unit_test_full_roundtrip"

func test_a_full_save_and_load_restores_the_whole_game_state():
	GameManager.reset_game()
	GameManager.credits = 4321
	GameManager.inventory = {"potion": 7, "bandage": 2}
	GameManager.opened_chests = ["chest_a", "chest_b"]
	GameManager.current_map_file = MapPaths.CAFE
	GameManager.last_player_position = Vector2(96, 224)
	GameManager.set_flag("warehouse_mission_accepted", true)
	GameManager.set_flag("npcs_greeted", ["Kanade", "Ena"])
	GameManager.warehouse_wave = 4
	var ichika := GameManager.get_party_member("Ichika")
	LevelManager.set_initial_level(ichika, 9)
	ichika.current_exp = 35
	ichika.skill_points = 3
	ichika.atk += 40
	ichika.current_hp = 50
	assert_true(SaveManager.save_game(SLOT), "lưu thành công")

	# Làm hỏng mọi thứ rồi nạp lại: phải về đúng như lúc lưu
	GameManager.reset_game()
	assert_eq(GameManager.credits, GameManager.DEFAULT_CREDITS, "Trạng thái đã bị đặt lại trước khi nạp")
	assert_true(GameManager.load_game(SLOT), "nạp thành công")
	assert_eq(GameManager.credits, 4321, "credits")
	assert_eq(GameManager.inventory.get("potion", 0), 7, "vật phẩm")
	assert_eq(GameManager.inventory.get("bandage", 0), 2, "vật phẩm")
	assert_eq(GameManager.opened_chests, ["chest_a", "chest_b"], "rương đã mở")
	assert_eq(GameManager.current_map_file, MapPaths.CAFE, "map hiện tại")
	assert_true(GameManager.get_flag("warehouse_mission_accepted"), "cờ cốt truyện")
	assert_eq(GameManager.get_flag("npcs_greeted"), ["Kanade", "Ena"], "cờ dạng mảng")
	assert_eq(GameManager.warehouse_wave, 4, "bộ đếm wave")
	var restored := GameManager.get_party_member("Ichika")
	assert_eq(restored.level, 9, "cấp")
	assert_eq(restored.current_exp, 35, "kinh nghiệm")
	assert_eq(restored.skill_points, 3, "điểm kỹ năng")
	assert_eq(restored.atk, ichika.atk, "chỉ số đã nâng")
	assert_eq(restored.current_hp, 50, "máu hiện tại")
	SaveManager.delete_save(SLOT)
	GameManager.reset_game()

func test_saving_over_an_existing_slot_replaces_it():
	GameManager.reset_game()
	GameManager.credits = 111
	assert_true(SaveManager.save_game(SLOT), "lưu lần đầu")
	GameManager.credits = 222
	assert_true(SaveManager.save_game(SLOT), "lưu đè lên slot cũ")
	assert_false(FileAccess.file_exists(SaveManager.SAVES_DIR + SLOT + ".json.tmp"), "Không còn file tạm")
	GameManager.credits = 0
	assert_true(GameManager.load_game(SLOT), "nạp")
	assert_eq(GameManager.credits, 222, "Slot giữ bản lưu mới nhất")
	SaveManager.delete_save(SLOT)
	GameManager.reset_game()

# ── UpgradeManager ─────────────────────────────────────────────────────────

func test_upgrade_spends_one_sp_and_adds_the_listed_amount():
	var e := Ichika.new()
	e.skill_points = 2
	var atk_before := e.atk
	assert_true(UpgradeManager.upgrade_stat(e, "atk"), "Nâng ATK thành công")
	assert_eq(e.atk, atk_before + UpgradeManager.UPGRADE_AMOUNTS["atk"], "ATK tăng đúng mức")
	assert_eq(e.skill_points, 1, "Tốn đúng 1 SP")
	e.skill_points = 0
	assert_false(UpgradeManager.upgrade_stat(e, "atk"), "Hết SP thì không nâng được")
	assert_false(UpgradeManager.upgrade_stat(e, "no_such_stat"), "Chỉ số lạ bị từ chối")
	assert_false(UpgradeManager.upgrade_stat(null, "atk"), "Không có thực thể thì từ chối")
	e.free()

func test_upgrade_stops_at_the_stat_cap_with_a_partial_increment():
	var e := Ichika.new()
	e.skill_points = 5
	var cap: int = e.stat_caps.get("defense", 9999)
	e.defense = cap - 2 # còn 2 tới trần, mức tăng 5: chỉ cộng 2
	assert_true(UpgradeManager.upgrade_stat(e, "defense"), "Còn chỗ trước trần thì nâng được")
	assert_eq(e.defense, cap, "Chỉ tăng đúng phần còn lại tới trần")
	assert_eq(e.skill_points, 4, "Vẫn tốn 1 SP")
	assert_false(UpgradeManager.upgrade_stat(e, "defense"), "Đã chạm trần thì từ chối")
	assert_eq(e.skill_points, 4, "Bị từ chối thì không mất SP")
	e.free()

func test_a_downed_member_is_not_revived_by_an_hp_upgrade():
	var alive := Ichika.new()
	alive.skill_points = 1
	alive.current_hp = 100
	UpgradeManager.upgrade_stat(alive, "max_hp")
	assert_eq(alive.current_hp, 130, "Người còn sống được hồi đúng phần máu tối đa vừa thêm")
	var downed := Ichika.new()
	downed.skill_points = 1
	downed.current_hp = 0
	var max_before := downed.max_hp
	UpgradeManager.upgrade_stat(downed, "max_hp")
	assert_eq(downed.max_hp, max_before + 30, "Máu tối đa vẫn tăng")
	assert_eq(downed.current_hp, 0, "Người đang gục không được nâng cấp để sống lại với vài chục máu")
	alive.free()
	downed.free()

func test_bulk_upgrade_counts_successes_and_stops_when_sp_runs_out():
	var e := Ichika.new()
	e.skill_points = 3
	assert_eq(UpgradeManager.bulk_upgrade(e, "spd", 10), 3, "Nâng được đúng số lần SP cho phép")
	assert_eq(e.skill_points, 0, "Hết SP")
	assert_eq(UpgradeManager.bulk_upgrade(e, "spd", 10), 0, "Không còn SP thì không nâng thêm")
	e.free()

# ── Trận đánh theo wave dựng từ Data/battles/mission_battles.json ──────────

func test_warehouse_waves_come_from_the_json_and_scale_with_the_wave():
	GameManager.reset_game()
	GameManager.current_map_file = MapPaths.WAREHOUSE
	GameManager.warehouse_wave = 2
	var data := BattleInitializer.setup_battle()
	assert_eq(data["player_team"].map(func(e): return e.entity_name), ["Ichika", "Kanade"], "Đội hình Nhà kho")
	assert_eq(data["enemy_team"].size(), 5, "5 nhân viên kho")
	assert_eq(data["enemy_team"][0].level, 6, "Cấp = wave x 3")
	GameManager.warehouse_wave = 5
	assert_eq(BattleInitializer.setup_battle()["enemy_team"][0].level, 15, "Cấp tối đa 15")
	GameManager.warehouse_wave = 1
	assert_eq(BattleInitializer.setup_battle()["enemy_team"][0].level, 3, "Cấp tối thiểu 3")
	GameManager.reset_game()

func test_harbor_guard_waves_come_from_the_json_and_scale_with_the_wave():
	GameManager.reset_game()
	GameManager.current_map_file = MapPaths.HARBOR
	GameManager.harbor_wave = 2
	var data := BattleInitializer.setup_battle()
	assert_eq(data["player_team"].map(func(e): return e.entity_name), ["Ichika", "Ena"], "Đội hình Bến Cảng")
	assert_eq(data["enemy_team"].size(), 4, "4 lính gác")
	assert_eq(data["enemy_team"][0].level, 7, "Cấp = 5 + wave")
	GameManager.reset_game()

# RES giảm sát thương theo phần trăm; mọi test sát thương khác đặt RES = 0 nên công thức này từng không được ghim
func test_resistance_reduces_damage_by_its_percentage():
	var attacker := Ichika.new()
	attacker.atk = 100
	attacker.crit_rate = 0.0
	attacker.type = "Pure"
	var defender := Guard.new()
	defender.defense = 0
	defender.type = "Pure"
	defender.res = 0
	assert_eq(DamageCalculator.calculate_damage(attacker, defender, 1.0), 100, "Không kháng: nguyên sát thương")
	defender.res = 50
	assert_eq(DamageCalculator.calculate_damage(attacker, defender, 1.0), 50, "Kháng 50%: còn một nửa")
	defender.res = 100
	assert_eq(DamageCalculator.calculate_damage(attacker, defender, 1.0), 5, "Kháng 100%: chạm sàn 5% ATK")
	attacker.free()
	defender.free()

# ── Holo-Sim: sàn 30% máu được áp trước khi HUD dựng ───────────────────────

func test_holosim_floor_raises_low_hp_members_to_thirty_percent_before_the_hud():
	GameManager.reset_game()
	HoloSimManager.is_sim_active = true
	HoloSimManager.current_floor = 2
	var ichika := GameManager.get_party_member("Ichika")
	var kanade := GameManager.get_party_member("Kanade")
	var mafuyu := GameManager.get_party_member("Mafuyu")
	ichika.current_hp = int(ichika.max_hp * 0.1)
	kanade.current_hp = ceili(kanade.max_hp * 0.9)
	mafuyu.current_hp = 0
	var data := BattleInitializer.setup_battle()
	assert_eq(ichika.current_hp, int(ichika.max_hp * 0.3), "Người còn ít máu được nâng lên 30%")
	assert_eq(kanade.current_hp, ceili(kanade.max_hp * 0.9), "Người nhiều máu hơn 30% giữ nguyên")
	assert_gt(mafuyu.current_hp, 0, "Người đang gục được hồi (BattleInitializer._revive_downed) rồi mới tính sàn")
	assert_eq(data["player_team"].size(), 3, "Đội Holo-Sim gồm ba nhân vật")
	HoloSimManager.is_sim_active = false
	GameManager.reset_game()

