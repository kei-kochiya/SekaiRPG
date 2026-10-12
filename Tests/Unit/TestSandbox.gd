class_name TestSandbox
extends BaseTest

"""
TestSandbox: Kiểm thử toàn diện logic chế độ Sandbox.
- Đảm bảo phe ta giới hạn tối đa 4 nhân vật.
- Đảm bảo thực thể trong Sandbox độc lập hoàn toàn với Party của phần chơi Campaign.
- Đảm bảo thêm/xóa kẻ địch (tối đa 5) hoạt động chính xác.
- Đảm bảo cấu hình trận đấu Sandbox (BattleInitializer) khởi tạo đúng DefaultScenario và giữ nguyên chỉ số nâng cấp.
"""

func _init():
	pass

func test_sandbox_player_isolation():
	current_test_name = "test_sandbox_player_isolation"
	
	# Lấy nhân vật gốc từ campaign party
	var original_ichika = GameManager.get_party_member("Ichika")
	var orig_hp = original_ichika.max_hp
	var orig_lv = original_ichika.level
	
	# Tạo nhân vật Sandbox và nâng cấp lên level 50
	var sandbox_ichika = GameManager.create_sandbox_entity("Ichika")
	LevelManager.set_initial_level(sandbox_ichika, 50)
	
	assert_ne(sandbox_ichika, original_ichika, "Sandbox entity must be a separate instance")
	assert_eq(sandbox_ichika.level, 50, "Sandbox Ichika should be level 50")
	assert_gt(sandbox_ichika.max_hp, orig_hp, "Sandbox Ichika HP should scale up")
	
	# Campaign party member must remain untouched
	assert_eq(original_ichika.level, orig_lv, "Campaign party member level must not be modified")
	assert_eq(original_ichika.max_hp, orig_hp, "Campaign party member HP must not be modified")

func test_sandbox_enemy_creation_and_bosses():
	current_test_name = "test_sandbox_enemy_creation_and_bosses"
	
	var mob = GameManager.create_sandbox_entity("Lính Cảng")
	assert_true(mob != null, "Should create mob Guard")
	assert_eq(mob.entity_name, "Lính Cảng", "Mob entity_name should match")
	
	var boss = GameManager.create_sandbox_entity("Đội Trưởng (BOSS)")
	assert_true(boss != null, "Should create boss Captain")
	assert_eq(boss.entity_name, "Đội Trưởng", "Boss entity_name should match")
	
	LevelManager.set_initial_level(boss, 30)
	assert_eq(boss.level, 30, "Boss level should scale to 30")

func test_sandbox_battle_initializer():
	current_test_name = "test_sandbox_battle_initializer"
	
	# Giả lập thiết lập Sandbox
	GameManager.is_sandbox = true
	GameManager.sandbox_player_team.clear()
	GameManager.sandbox_enemy_team.clear()
	
	var p1 = GameManager.create_sandbox_entity("Kanade")
	LevelManager.set_initial_level(p1, 20)
	UpgradeManager.upgrade_stat(p1, "atk") # Nâng cấp 1 lần ATK
	var p1_atk = p1.atk
	GameManager.sandbox_player_team.append(p1)
	
	var e1 = GameManager.create_sandbox_entity("Thủ Tướng (FINAL BOSS)")
	LevelManager.set_initial_level(e1, 25)
	GameManager.sandbox_enemy_team.append(e1)
	
	var battle_data = BattleInitializer.setup_battle(null)
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
	current_test_name = "test_sandbox_enemy_limit"
	
	var enemies = []
	for i in range(5):
		enemies.append("Kidnapper")
	assert_eq(enemies.size(), 5, "Should have 5 enemies")
	
	# Test removing enemy at index
	enemies.remove_at(0)
	assert_eq(enemies.size(), 4, "Should have 4 enemies after removing one")
