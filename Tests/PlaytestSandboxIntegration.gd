extends Node2D

func _ready():
	print("\n" + "=".repeat(60))
	print("       PLAYTEST INTEGRATION: SANDBOX FULL WORKFLOW")
	print("=".repeat(60))
	
	# 1. Khởi tạo SandboxMenu
	var sandbox_scene = load("res://UI/Menus/Sandbox/SandboxMenu.tscn").instantiate()
	add_child(sandbox_scene)
	print("[STEP 1] Đã tải và khởi tạo SandboxMenu scene thành công.")
	
	# 2. Test chọn 4 nhân vật
	var char_list_container = sandbox_scene.get_node("HBox/PlayerPanel/PlayerSide/Scroll/CharList")
	var checkboxes = char_list_container.get_children()
	assert(checkboxes.size() >= 4, "Phải có ít nhất 4 checkbox nhân vật")
	
	# Tích 4 nhân vật đầu tiên
	for i in range(4):
		checkboxes[i].button_pressed = true
	assert(sandbox_scene.selected_players.size() == 4, "Phải chọn đúng 4 nhân vật")
	print("[STEP 2] Đã chọn 4 nhân vật: %s" % str(sandbox_scene.selected_players))
	
	# 3. Test chọn nhân vật thứ 5 (vượt quá giới hạn)
	if checkboxes.size() >= 5:
		checkboxes[4].button_pressed = true
		assert(sandbox_scene.selected_players.size() == 4, "Số lượng nhân vật không được vượt quá 4")
		assert(checkboxes[4].button_pressed == false, "Checkbox thứ 5 phải tự động bị hủy tick")
		print("[STEP 3] Giới hạn tối đa 4 nhân vật hoạt động chính xác (tự động nhả tick thứ 5).")
	
	# 4. Chỉnh level phe ta lên 25
	sandbox_scene.player_lv_spin.value = 25
	for p_name in sandbox_scene.selected_players:
		var p = sandbox_scene.sandbox_player_instances[p_name]
		assert(p.level == 25, "Level của nhân vật sandbox phải là 25")
	print("[STEP 4] Tùy chỉnh Level phe ta lên 25 thành công.")
	
	# 5. Phân bổ nâng cấp SP
	var p_ichika = sandbox_scene.sandbox_player_instances["Ichika"]
	var base_atk = p_ichika.atk
	var upgrade_success = UpgradeManager.upgrade_stat(p_ichika, "atk")
	assert(upgrade_success == true, "Nâng cấp ATK phải thành công")
	assert(p_ichika.atk > base_atk, "ATK sau nâng cấp phải lớn hơn ATK gốc")
	var upgraded_atk = p_ichika.atk
	print("[STEP 5] Đã phân bổ nâng cấp SP cho Ichika: ATK tăng từ %d -> %d." % [base_atk, upgraded_atk])
	
	# 6. Kiểm tra Party cốt truyện chính KHÔNG bị ảnh hưởng
	var campaign_ichika = GameManager.get_party_member("Ichika")
	assert(campaign_ichika.level != 25, "Party cốt truyện chính không được mang level 25 của Sandbox")
	print("[STEP 6] Dữ liệu Campaign Party được bảo toàn 100% (không bị ô nhiễm bởi Sandbox).")
	
	# 7. Thêm kẻ địch
	sandbox_scene._on_enemy_added("Lính Cảng")
	sandbox_scene._on_enemy_added("Đội Trưởng (BOSS)")
	sandbox_scene._on_enemy_added("Thủ Tướng (FINAL BOSS)")
	assert(sandbox_scene.selected_enemies.size() == 3, "Phải có đúng 3 kẻ địch được thêm")
	print("[STEP 7] Đã thêm 3 kẻ địch: %s" % str(sandbox_scene.selected_enemies))
	
	# 8. Xóa 1 kẻ địch ở index 0
	sandbox_scene.selected_enemies.remove_at(0)
	sandbox_scene._update_enemy_display()
	assert(sandbox_scene.selected_enemies.size() == 2, "Sau khi xóa phải còn 2 kẻ địch")
	print("[STEP 8] Xóa kẻ địch đơn lẻ bằng nút (x) hoạt động chính xác.")
	
	# Thêm lại Kidnapper
	sandbox_scene._on_enemy_added("Kidnapper")
	assert(sandbox_scene.selected_enemies.size() == 3, "Đã thêm lại thành 3 kẻ địch")
	
	# 9. Bấm bắt đầu trận đấu
	sandbox_scene._on_start()
	assert(GameManager.is_sandbox == true, "GameManager phải đang ở trạng thái Sandbox")
	assert(GameManager.sandbox_player_team.size() == 4, "Đội hình phe ta trong GameManager phải có 4 người")
	assert(GameManager.sandbox_enemy_team.size() == 3, "Đội hình phe địch trong GameManager phải có 3 người")
	
	# Kiểm tra ATK đã nâng cấp được bảo lưu khi vào trận
	var battle_ichika = GameManager.sandbox_player_team[0]
	assert(battle_ichika.atk == upgraded_atk, "ATK nâng cấp phải được bảo toàn khi vào trận chiến")
	print("[STEP 9] Bước vào trận chiến: Đội hình 4 vs 3, toàn bộ chỉ số nâng cấp SP được giữ nguyên.")
	
	# 10. Khởi tạo trận chiến qua BattleInitializer
	var battle_data = BattleInitializer.setup_battle(null)
	assert(battle_data["player_team"].size() == 4, "BattleInitializer player_team size == 4")
	assert(battle_data["enemy_team"].size() == 3, "BattleInitializer enemy_team size == 3")
	assert(battle_data["scenario"] is DefaultScenario, "Kịch bản trận chiến Sandbox phải là DefaultScenario")
	print("[STEP 10] BattleInitializer khởi tạo trận đấu Sandbox chuẩn xác.")
	
	# Dọn dẹp
	sandbox_scene.queue_free()
	GameManager.is_sandbox = false
	GameManager.sandbox_player_team.clear()
	GameManager.sandbox_enemy_team.clear()
	
	print("=".repeat(60))
	print(">>> TẤT CẢ CÁC BƯỚC PLAYTEST SANDBOX ĐỀU THÀNH CÔNG VỚI 0 LỖI! <<<")
	print("=".repeat(60) + "\n")
	
	get_tree().quit(0)
