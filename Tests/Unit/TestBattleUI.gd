extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Phần giao diện trận đấu mới sửa: số hồi máu nổi, thẻ hồi sinh hết bị làm mờ, banner thất bại đúng với từng trận kịch bản,
hit-stop trả lại tốc độ game cũ, nút giữ focus trong hộp thoại một nút.
"""

func _card(entity: Entity) -> CharacterCard:
	var card := CharacterCard.new()
	card.setup(entity, true)
	return card

func _floating_texts(overlay: Node) -> int:
	return overlay.get_children().filter(func(n): return n is FloatingText).size()

func test_heal_shows_a_floating_number_but_damage_and_setup_do_not():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	# Số nổi gắn vào nhóm "ui_overlay" nếu có (trong lúc chạy test, /root đang bận dựng nên không thêm con vào đó được)
	var overlay := Node.new()
	overlay.add_to_group("ui_overlay")
	root.add_child(overlay)
	var entity := Ichika.new()
	var card := _card(entity)
	root.add_child(card)
	assert_eq(_floating_texts(overlay), 0, "Dựng thẻ không sinh số nổi")
	entity.take_damage(50)
	assert_eq(_floating_texts(overlay), 1, "Mất máu: chỉ có số sát thương")
	entity.heal(20)
	assert_eq(_floating_texts(overlay), 2, "Hồi máu: có thêm một số nổi")
	root.remove_child(card)
	root.remove_child(overlay)
	card.free()
	overlay.free()
	entity.free()

func test_a_revived_card_is_no_longer_dimmed():
	var entity := Ichika.new()
	var card := _card(entity)
	entity.current_hp = 0
	entity.died.emit()
	assert_true(card.modulate.a < 1.0, "Gục thì thẻ bị làm mờ")
	entity.current_hp = 40
	entity.hp_changed.emit(entity.current_hp, entity.max_hp)
	assert_eq(card.modulate, Color.WHITE, "Hồi sinh (Dòng Máu Bất Tử...) thì hết mờ")
	card.free()
	entity.free()

# Kiểu kết cục mỗi trận kịch bản trong BattleInitializer: "retreat" về Safehouse, "harbor" về Bến Cảng, "continue" câu chuyện đi tiếp,
# "retry" đánh lại tại chỗ. Trận mới thêm vào registry phải được xếp vào đây (bài này lập danh sách các id đã biết).
const DEFEAT_KIND := {
	"ops_kanade": "retreat", "ops_ena": "retreat", "ops_ichika": "retreat", "ops_honami": "retreat", "pm_boss": "retreat",
	"harbor_boss": "harbor",
	"bounty_ambush": "continue", "mizuki_vs_ena_forced": "continue", "mizuki_vs_kanade": "continue", "ichika_vs_kanade_slow": "continue",
	"honami_spar": "continue", "ena_vs_mizuki": "continue", "ena_vs_thugs": "continue", "mizuki_vs_mafuyu": "continue", "street_survival": "continue",
	"prologue": "retry", "bounty_1": "retry", "bounty_2": "retry", "bounty_3": "retry", "mizuki_police_1": "retry", "mizuki_police_2": "retry",
	"final_mafuyu": "retry", "training_trial": "retry", "street_skirmish": "retry",
}

func test_defeat_banner_matches_what_happens_after_a_scripted_loss():
	var hud = load("res://UI/Battle/BattleHUD.gd").new()
	for id in DEFEAT_KIND:
		var text: String = hud._scripted_defeat_text(id)
		match DEFEAT_KIND[id]:
			"retreat": assert_true(text.contains("Safehouse"), "%s: rút về Safehouse" % id)
			"harbor": assert_true(text.contains("Bến Cảng"), "%s: quay lại Bến Cảng" % id)
			"continue": assert_eq(text, "KẾT THÚC TRẬN ĐẤU", "%s: câu chuyện đi tiếp" % id)
			"retry": assert_true(text.contains("thử lại"), "%s: đánh lại" % id)
	var known: Array = DEFEAT_KIND.keys()
	var registry: Array = BattleInitializer.scripted_battle_ids()
	known.sort()
	registry.sort()
	assert_eq(known, registry, "Mọi trận trong registry đều có kiểu kết cục trong bảng này (và ngược lại)")
	hud.free()

func test_hitstop_remembers_the_game_speed_it_found():
	GameManager.reduce_motion = false
	Engine.time_scale = 0.55 # vd. SlowStrikeScenario
	var shaker := ScreenShake.new()
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	root.add_child(shaker) # hitstop cần cây để đặt hẹn giờ
	shaker.hitstop(0.1)
	assert_eq(shaker._scale_before_hitstop, 0.55, "Nhớ tốc độ trước hit-stop để trả lại đúng (không ép về 1.0)")
	assert_eq(Engine.time_scale, 0.05, "Trong hit-stop game gần như đứng")
	root.remove_child(shaker)
	shaker.free()
	Engine.time_scale = 1.0

func test_trap_focus_keeps_focus_on_a_single_button():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var holder := VBoxContainer.new()
	var other := Button.new() # điều khiển khác nằm sát bên: mũi tên/Tab trước đây nhảy sang đó
	var btn := Button.new()
	holder.add_child(other)
	holder.add_child(btn)
	root.add_child(holder)
	UITheme.trap_focus(btn)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		assert_eq(btn.find_valid_focus_neighbor(side), btn, "Mũi tên không nhảy khỏi nút")
	assert_eq(btn.find_next_valid_focus(), btn, "Tab không nhảy khỏi nút")
	assert_eq(btn.find_prev_valid_focus(), btn, "Shift+Tab không nhảy khỏi nút")
	root.remove_child(holder)
	holder.free()

# Bộ đếm lỗi script chỉ đếm lỗi VM GDScript, không đếm push_error (assert, GameLogger.error...) và các loại khác
func test_script_error_counter_only_counts_script_errors():
	var counter := ScriptErrorCounter.new()
	var before := ScriptErrorCounter.snapshot()
	counter._log_error("f", "x.gd", 1, "code", "lỗi", false, Logger.ERROR_TYPE_ERROR, [])
	counter._log_error("f", "x.gd", 1, "code", "cảnh báo", false, Logger.ERROR_TYPE_WARNING, [])
	assert_eq(ScriptErrorCounter.snapshot(), before, "Lỗi thường/cảnh báo không làm test thất bại")
	counter._log_error("f", "x.gd", 1, "code", "Invalid call", false, Logger.ERROR_TYPE_SCRIPT, [])
	assert_eq(ScriptErrorCounter.snapshot(), before + 1, "Lỗi script làm tăng bộ đếm")
	assert_true(ScriptErrorCounter.last_message.contains("Invalid call"), "Lưu lại nội dung lỗi gần nhất")
	ScriptErrorCounter.count = before # trả bộ đếm về như cũ để test này không tự làm hỏng test sau nó

func test_the_player_names_itself_and_can_skip_its_own_camera():
	var follower := OverworldPlayer.new()
	assert_eq(follower.name, "OverworldPlayer", "Tên node cố định mà InteractableZone/can_save_now tìm")
	assert_true(follower.follow_camera, "Mặc định camera bám theo người chơi")
	var fixed := OverworldPlayer.new()
	fixed.follow_camera = false
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	root.add_child(follower)
	root.add_child(fixed)
	var cams := func(n: Node) -> int: return n.get_children().filter(func(c): return c is Camera2D).size()
	assert_eq(cams.call(follower), 1, "Người chơi thường có một camera")
	assert_eq(cams.call(fixed), 0, "Map có camera cố định thì người chơi không giành quyền hiển thị")
	root.remove_child(follower)
	root.remove_child(fixed)
	follower.free()
	fixed.free()

func test_sandbox_menu_frees_the_previous_battles_player_copies():
	var stale := Ichika.new()
	GameManager.sandbox_player_team = [stale]
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var menu: Node = load(MapPaths.SANDBOX_MENU).instantiate()
	root.add_child(menu)
	assert_true(stale.is_queued_for_deletion(), "Bản nhân vật của trận trước bị giải phóng khi menu dựng lại")
	assert_eq(GameManager.sandbox_player_team.size(), 0, "Danh sách phe ta được làm sạch")
	root.remove_child(menu)
	menu.free()
	GameManager.reset_game()

# Hướng dẫn trận đầu nhả khóa modal NGAY khi đóng (không chờ queue_free cuối frame): lượt đầu bắt đầu trong cùng frame và menu lệnh
# không nhận focus bàn phím/tay cầm khi PauseMenu còn báo có modal
func test_the_tutorial_modal_can_be_released_before_its_canvas_is_freed():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var host := Node.new()
	root.add_child(host)
	var tutorial = load("res://Scripts/Battle/BattleTutorial.gd")
	var panel: Control = tutorial._build_tutorial_panel(host)
	assert_true(PauseMenu.is_modal_open(), "Đang hiện hướng dẫn: có modal")
	var scope = panel.get_parent().get_meta("modal_scope", null)
	assert_true(scope != null, "ModalScope được gắn vào lớp hướng dẫn")
	scope.exit()
	assert_false(PauseMenu.is_modal_open(), "Nhả khóa ngay, trước khi lớp bị xóa")
	root.remove_child(host)
	host.free() # tree_exiting gọi exit() lần nữa: phải vô hại (idempotent)
	assert_false(PauseMenu.is_modal_open(), "Không bị nhả hai lần làm lệch bộ đếm")

# Bước chọn mục tiêu có nút quay lại: bấm nhầm một kỹ năng dùng một lần vẫn rút lại được (kỹ năng chỉ tiêu hao khi lệnh được phát đi)
func test_command_menu_can_go_back_from_target_selection():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var menu := CommandMenu.new()
	root.add_child(menu)
	var ichika := Ichika.new()
	var guard := Guard.new()
	ichika.allies = [ichika]
	menu.show_for(ichika, [guard])
	var chosen: Array = []
	menu.command_chosen.connect(func(action, target): chosen.append(action))
	menu._on_action_picked("attack")
	assert_true(menu.target_container.visible, "Chọn Tấn công thì hiện danh sách mục tiêu")
	assert_false(menu.action_container.visible, "Danh sách lệnh được ẩn")
	var buttons := menu.target_container.get_children().filter(func(n): return n is Button)
	assert_eq(buttons.size(), 2, "Một mục tiêu cộng một nút quay lại")
	(buttons[-1] as Button).pressed.emit()
	assert_true(menu.action_container.visible, "Quay lại danh sách lệnh")
	assert_false(menu.target_container.visible, "Danh sách mục tiêu được ẩn")
	assert_eq(menu.chosen_action, "", "Lệnh đã chọn bị bỏ")
	assert_true(chosen.is_empty(), "Quay lại không phát lệnh nào")
	root.remove_child(menu)
	menu.free()
	ichika.free()
	guard.free()

