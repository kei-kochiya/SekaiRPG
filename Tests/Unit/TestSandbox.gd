class_name TestSandbox
extends BaseTest

"""
TestSandbox: Kiểm thử toàn diện logic chế độ Sandbox.
- Đảm bảo phe ta giới hạn tối đa 4 nhân vật.
- Đảm bảo thực thể trong Sandbox độc lập hoàn toàn với Party của phần chơi Campaign.
- Đảm bảo thêm/xóa kẻ địch (tối đa 5) hoạt động chính xác.
- Đảm bảo cấu hình trận đấu Sandbox (BattleInitializer) khởi tạo đúng DefaultScenario và giữ nguyên chỉ số nâng cấp.
"""

func test_sandbox_player_isolation():
	
	# Lấy nhân vật gốc từ campaign party
	var original_ichika = GameManager.get_party_member("Ichika")
	var orig_hp = original_ichika.max_hp
	var orig_lv = original_ichika.level
	
	# Tạo nhân vật Sandbox và nâng cấp lên level 50
	var sandbox_ichika = EntityFactory.create("Ichika")
	LevelManager.set_initial_level(sandbox_ichika, 50)
	
	assert_ne(sandbox_ichika, original_ichika, "Sandbox entity must be a separate instance")
	assert_eq(sandbox_ichika.level, 50, "Sandbox Ichika should be level 50")
	assert_gt(sandbox_ichika.max_hp, orig_hp, "Sandbox Ichika HP should scale up")
	
	# Campaign party member must remain untouched
	assert_eq(original_ichika.level, orig_lv, "Campaign party member level must not be modified")
	assert_eq(original_ichika.max_hp, orig_hp, "Campaign party member HP must not be modified")

func test_sandbox_enemy_creation_and_bosses():
	
	var mob = EntityFactory.create("Lính Cảng")
	assert_true(mob != null, "Should create mob Guard")
	assert_eq(mob.entity_name, "Lính Cảng", "Mob entity_name should match")
	
	var boss = EntityFactory.create("Đội Trưởng (BOSS)")
	assert_true(boss != null, "Should create boss Captain")
	assert_eq(boss.entity_name, "Đội Trưởng", "Boss entity_name should match")
	
	LevelManager.set_initial_level(boss, 30)
	assert_eq(boss.level, 30, "Boss level should scale to 30")

func test_sandbox_battle_initializer():
	
	# Giả lập thiết lập Sandbox
	GameManager.is_sandbox = true
	GameManager.sandbox_player_team.clear()
	GameManager.sandbox_enemy_team.clear()
	
	var p1 = EntityFactory.create("Kanade")
	LevelManager.set_initial_level(p1, 20)
	UpgradeManager.upgrade_stat(p1, "atk") # Nâng cấp 1 lần ATK
	var p1_atk = p1.atk
	GameManager.sandbox_player_team.append(p1)
	
	var e1 = EntityFactory.create("Thủ Tướng (FINAL BOSS)")
	LevelManager.set_initial_level(e1, 25)
	GameManager.sandbox_enemy_team.append(e1)
	
	var battle_data = BattleInitializer.setup_battle()
	assert_eq(battle_data["player_team"].size(), 1, "Player team count should be 1")
	assert_eq(battle_data["enemy_team"].size(), 1, "Enemy team count should be 1")
	assert_true(battle_data["scenario"] is DefaultScenario, "Sandbox should use DefaultScenario")
	
	# Kiểm tra thực thể trong trận đấu giữ nguyên chỉ số nâng cấp
	var battle_p1 = battle_data["player_team"][0]
	assert_eq(battle_p1.atk, p1_atk, "Upgraded ATK must be preserved in battle")
	
	# Dọn dẹp state
	GameManager.is_sandbox = false
	GameManager.sandbox_player_team.clear()
	GameManager.sandbox_enemy_team.clear()

func test_sandbox_enemy_limit():
	
	var menu_script = load("res://UI/Menus/Sandbox/SandboxMenu.gd")
	assert_eq(menu_script.ENEMY_LIMIT, 5, "Sandbox allows at most 5 enemies")
	assert_eq(menu_script.PLAYER_LIMIT, 4, "Sandbox allows at most 4 player characters")
	# Giới hạn phải được áp dụng thật, không chỉ khai báo hằng số
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var menu: Node = load(MapPaths.SANDBOX_MENU).instantiate()
	root.add_child(menu)
	for i in 8:
		menu._on_enemy_added("Lính Cảng")
	assert_eq(menu.selected_enemies.size(), 5, "Thêm quá 5 kẻ địch thì bị từ chối")
	for member in ["Ichika", "Kanade", "Ena", "Mizuki", "Mafuyu"]:
		var box := CheckBox.new()
		menu._on_player_toggled(true, member, box)
		box.free()
	assert_eq(menu.selected_players.size(), 4, "Chọn quá 4 nhân vật phe ta thì bị từ chối")
	root.remove_child(menu)
	menu.free()

# Hạ ô Level phải hạ cả nhân vật đã chọn (set_initial_level chỉ biết nâng): trước đây ô hiện Lv.20 nhưng trận vẫn đánh ở Lv.50
func test_lowering_the_level_spinner_lowers_selected_players():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var menu: Node = load(MapPaths.SANDBOX_MENU).instantiate()
	root.add_child(menu)
	var box := CheckBox.new()
	menu._on_player_toggled(true, "Ichika", box)
	box.free()
	menu._on_player_lv_changed(50.0)
	var high_hp: int = menu.sandbox_player_instances["Ichika"].max_hp
	assert_eq(menu.sandbox_player_instances["Ichika"].level, 50, "Nâng lên Lv.50")
	menu._on_player_lv_changed(20.0)
	var low = menu.sandbox_player_instances["Ichika"]
	assert_eq(low.level, 20, "Hạ xuống Lv.20 thì nhân vật cũng về Lv.20")
	assert_lt(low.max_hp, high_hp, "Chỉ số giảm theo cấp")
	assert_eq(low.skill_points, 20 * 3, "SP tính lại theo cấp mới")
	menu._on_player_lv_changed(35.0)
	assert_eq(menu.sandbox_player_instances["Ichika"].level, 35, "Nâng lại vẫn đúng")
	root.remove_child(menu)
	menu.free()

# Bấm "Bắt đầu" xong là đội đã chuyển cho GameManager: kéo ô Level lúc đang fade không được free các bản sao đó (trận sẽ cầm đối tượng đã bị xóa)
func test_lowering_the_level_while_the_battle_is_starting_leaves_the_copies_alone():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var menu: Node = load(MapPaths.SANDBOX_MENU).instantiate()
	root.add_child(menu)
	var box := CheckBox.new()
	menu._on_player_toggled(true, "Ichika", box)
	box.free()
	menu._on_player_lv_changed(40.0)
	var before = menu.sandbox_player_instances["Ichika"]
	menu._busy = true
	menu._on_player_lv_changed(10.0)
	assert_true(is_instance_valid(before), "Bản sao đang được trận giữ vẫn còn")
	assert_true(menu.sandbox_player_instances["Ichika"] == before, "Không bị dựng lại khi đang vào trận")
	assert_eq(before.level, 40, "Level giữ nguyên")
	menu._busy = false
	root.remove_child(menu)
	menu.free()

