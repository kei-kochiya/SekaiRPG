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
