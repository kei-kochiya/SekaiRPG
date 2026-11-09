extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Trạng thái phiên chơi. Thoát về menu / chơi mới / vào Sandbox phải dọn trạng thái tạm của lượt trước (cờ Holo-Sim, luyện tập,
hội thoại đang mở), và DialogueManager không được kẹt khi có lựa chọn đang mở.
"""

func _line() -> Dictionary:
	return {"text": "x", "type": "dialogue", "name": "A", "speaker": "left", "color": Color.WHITE}

func test_clear_transient_state_resets_every_battle_mode():
	HoloSimManager.is_sim_active = true
	GameManager.begin_training(["Ichika"])
	GameManager.training_used_opponents = ["Kanade"]
	GameManager.is_tutorial = true
	GameManager.is_sandbox = true
	GameManager.sandbox_player_team = ["x"]
	GameManager.sandbox_enemy_team = ["y"]
	GameManager.is_scripted_battle = true
	GameManager.scripted_battle_id = "pm_boss"
	DialogueManager.show_choice(["a", "b"])
	GameManager.clear_transient_state()
	assert_false(HoloSimManager.is_sim_active, "Holo-Sim không còn hoạt động")
	assert_false(GameManager.is_training_mode, "Hết chế độ luyện tập")
	assert_eq(GameManager.training_participants.size(), 0, "Không còn người luyện tập")
	assert_eq(GameManager.training_used_opponents.size(), 0, "Không còn đối thủ đã dùng")
	assert_eq(GameManager.training_wave, 0, "training_wave về 0")
	assert_false(GameManager.is_tutorial, "Hết hướng dẫn")
	assert_false(GameManager.is_sandbox, "Hết Sandbox")
	assert_eq(GameManager.sandbox_player_team.size(), 0, "Đội Sandbox phe ta được xóa")
	assert_eq(GameManager.sandbox_enemy_team.size(), 0, "Đội Sandbox phe địch được xóa")
	assert_false(GameManager.is_scripted_battle, "Hết trận kịch bản")
	assert_eq(GameManager.scripted_battle_id, "", "Xóa mã trận kịch bản")
	assert_false(DialogueManager._in_choice, "Lựa chọn đang mở bị đóng")
	assert_false(GameManager.is_in_dialogue, "Không còn khóa hội thoại")

# Quit-to-menu từ Holo-Sim rồi vào Sandbox từng làm trận Sandbox biến thành trận Holo-Sim (BattleInitializer xét cờ sim trước)
func test_start_menu_clears_leftover_holosim_state():
	HoloSimManager.is_sim_active = true
	GameManager.is_training_mode = true
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var menu: Node = load(MapPaths.START_MENU).instantiate()
	root.add_child(menu) # _ready dọn trạng thái tạm
	assert_false(HoloSimManager.is_sim_active, "Về tới màn hình tiêu đề thì không còn cờ Holo-Sim")
	assert_false(GameManager.is_training_mode, "Không còn cờ luyện tập")
	root.remove_child(menu)
	menu.free()

func test_dialogue_reset_closes_without_running_the_callback():
	var fired := [0]
	DialogueManager.play_dialogue([_line()], func(): fired[0] += 1)
	assert_true(DialogueManager.active, "Hội thoại đang mở")
	DialogueManager.reset()
	assert_false(DialogueManager.active, "Đã đóng")
	assert_false(DialogueManager.visible, "Đã ẩn")
	assert_false(GameManager.is_in_dialogue, "Nhả khóa hội thoại")
	assert_eq(fired[0], 0, "Callback của cảnh cũ không được chạy")
	DialogueManager._advance_dialogue() # bấm tiếp sau khi đóng: không lỗi, không chạy callback
	assert_eq(fired[0], 0, "Vẫn không chạy callback")

# Gọi play_dialogue lúc lựa chọn đang mở từng làm giao diện kẹt vĩnh viễn (nút ẩn nhưng _in_choice còn true)
func test_dialogue_is_not_started_over_an_open_choice():
	DialogueManager.show_choice(["a", "b"])
	var fired := [0]
	DialogueManager.play_dialogue([_line()], func(): fired[0] += 1)
	assert_false(DialogueManager.active, "Không chen hội thoại lên lựa chọn đang mở")
	assert_true(DialogueManager._in_choice, "Lựa chọn vẫn còn đó để người chơi chọn")
	assert_eq(fired[0], 1, "Callback vẫn chạy để luồng cốt truyện không kẹt")
	DialogueManager._ui.choice_selected.emit(0)
	assert_false(DialogueManager._in_choice, "Chọn xong thì đóng lựa chọn")

func test_menu_scene_list_matches_the_scenes_that_exist():
	assert_true("StartMenu" in GameManager.MENU_SCENES and "SandboxMenu" in GameManager.MENU_SCENES, "Hai menu chính")
	assert_true("EndingCard" in GameManager.MENU_SCENES, "Màn kết không tạm dừng/hiện phím ảo")
	assert_false("SaveLoadMenu" in GameManager.MENU_SCENES, "SaveLoadMenu chỉ là lớp phủ, không bao giờ là scene gốc")
	for scene_path in [MapPaths.START_MENU, MapPaths.SANDBOX_MENU, MapPaths.ENDING_CARD]:
		var node: Node = load(scene_path).instantiate()
		assert_true(node.name in GameManager.MENU_SCENES, "Tên node gốc %s nằm trong danh sách menu" % scene_path.get_file())
		node.free()

# ask()/play_async() từng await trên tín hiệu dùng chung: sau reset() (thoát về menu giữa chừng) coroutine cũ bị đánh thức bởi lựa chọn đầu
# tiên của phiên sau rồi chạy tiếp mã của cảnh đã đóng. Mỗi lời gọi giờ có người chờ riêng nên coroutine cũ bị bỏ rơi.
func test_reset_abandons_pending_asks_instead_of_waking_them_later():
	var seen := [0, 0, 0]
	var first := func():
		await DialogueManager.ask(["a", "b"])
		seen[0] += 1
	first.call()
	DialogueManager.reset()
	var second := func():
		var idx: int = await DialogueManager.ask(["c", "d"])
		seen[1] = idx + 10
	second.call()
	DialogueManager._ui.choice_selected.emit(1)
	assert_eq(seen[0], 0, "Coroutine của phiên đã reset không bị đánh thức bởi lựa chọn của phiên sau")
	assert_eq(seen[1], 11, "Lời gọi hiện tại nhận đúng lựa chọn của mình")
	var third := func():
		await DialogueManager.play_async([_line()])
		seen[2] += 1
	third.call()
	DialogueManager.reset()
	DialogueManager.play_dialogue([_line()])
	DialogueManager._advance_dialogue()
	assert_eq(seen[2], 0, "play_async đã reset cũng không bị đánh thức bởi hội thoại sau")

# Hai lần ask() liên tiếp (lần sau gọi ngay trong lần chạy tiếp của lần trước) nhận đúng kết quả của từng lần
func test_back_to_back_asks_each_get_their_own_answer():
	var got := []
	var chain := func():
		got.append(await DialogueManager.ask(["a", "b", "c"]))
		got.append(await DialogueManager.ask(["x", "y"]))
	chain.call()
	DialogueManager._ui.choice_selected.emit(2)
	DialogueManager._ui.choice_selected.emit(1)
	assert_eq(got, [2, 1], "Mỗi lần hỏi nhận đúng lựa chọn của nó")

# Lời gọi đến muộn của map cũ (timer/coroutine) khi người chơi đã về menu không được kéo menu sang map đó
func test_change_map_and_scripted_battles_are_ignored_while_a_menu_is_current():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	_saved_root_name = root.name
	root.name = "StartMenu"
	GameManager.current_map_file = MapPaths.CAFE
	GameManager.change_map(MapPaths.HARBOR, 0.0)
	assert_eq(GameManager.current_map_file, MapPaths.CAFE, "change_map bị bỏ qua khi đang ở menu")
	GameManager.start_scripted_battle("ena_vs_thugs", MapPaths.CAFE, Vector2.ZERO, 0.0)
	assert_false(GameManager.is_scripted_battle, "start_scripted_battle bị bỏ qua khi đang ở menu")
	root.name = _saved_root_name

# "Tải game" xóa hết save rồi đóng: cột nút phải được dựng lại (trước đây "Tiếp tục" vẫn nằm đó và dẫn tới "Không tìm thấy file save")
func test_start_menu_rebuilds_its_buttons_when_the_save_list_changes():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var menu: Node = load("res://UI/Menus/Start/StartMenu.tscn").instantiate()
	root.add_child(menu)
	var count_buttons := func(): return menu.find_children("*", "Button", true, false).size()
	var before: int = count_buttons.call()
	var old_button: Button = menu.find_children("*", "Button", true, false)[0]
	menu._on_save_menu_closed()
	assert_true(old_button.is_inside_tree(), "Danh sách save không đổi thì giữ nguyên các nút")
	menu._built_with_save = not GameManager.has_save() # như thể danh sách save đã đổi lúc hộp "Tải game" đang mở
	menu._on_save_menu_closed()
	assert_false(old_button.is_inside_tree(), "Danh sách save đổi thì các nút cũ bị bỏ")
	assert_eq(count_buttons.call(), before, "Cột nút được dựng lại đủ, không nhân đôi")
	assert_eq(menu._built_with_save, GameManager.has_save(), "Trạng thái dựng khớp với danh sách save hiện tại")
	root.remove_child(menu)
	menu.free()

# Lưu game chỉ khi đang đi lại ngoài Overworld: không Sandbox/trận kịch bản/luyện tập/Holo-Sim, không ở menu/trận, và người chơi chưa bị khóa
func test_can_save_now_guards():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	assert_false(GameManager.can_save_now(), "Không có người chơi Overworld thì không lưu")
	var player := OverworldPlayer.new()
	root.add_child(player)
	assert_true(GameManager.can_save_now(), "Người chơi đang đi lại thì lưu được")
	player.set_physics_process(false) # cảnh tự chạy khóa người chơi
	assert_false(GameManager.can_save_now(), "Người chơi bị khóa (đang cảnh tự chạy) thì không lưu")
	player.set_physics_process(true)
	for guard in ["is_sandbox", "is_scripted_battle", "is_training_mode"]:
		GameManager.set(guard, true)
		assert_false(GameManager.can_save_now(), "%s chặn lưu" % guard)
		GameManager.set(guard, false)
	HoloSimManager.is_sim_active = true
	assert_false(GameManager.can_save_now(), "Holo-Sim chặn lưu")
	HoloSimManager.is_sim_active = false
	assert_true(GameManager.can_save_now(), "Hết các chốt chặn thì lưu lại được")
	root.remove_child(player)
	player.free()

# Đường dây thật: hộp "Tải game" rời cây (tree_exited) thì Start Menu tự dựng lại cột nút, không cần ai gọi tay
func test_start_menu_listens_for_the_load_dialog_closing():
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var menu: Node = load("res://UI/Menus/Start/StartMenu.tscn").instantiate()
	root.add_child(menu)
	var old_button: Button = menu.find_children("*", "Button", true, false)[0]
	menu._busy = false
	menu._on_load_menu()
	var overlay: Node = menu.get_child(menu.get_child_count() - 1)
	menu._built_with_save = not GameManager.has_save() # như thể danh sách save đã đổi lúc hộp đang mở
	menu.remove_child(overlay)
	assert_false(old_button.is_inside_tree(), "Hộp đóng lại thì cột nút cũ bị bỏ và dựng lại")
	assert_eq(menu._built_with_save, GameManager.has_save(), "Trạng thái dựng khớp với danh sách save")
	overlay.free()
	root.remove_child(menu)
	menu.free()

# Tên gốc của runner đổi sang "StartMenu" trong một test: trả lại ở after_each để một lỗi giữa chừng không làm các lời gọi change_map
# ở mọi test sau bị bỏ qua lặng lẽ
var _saved_root_name := ""

func after_each() -> void:
	if _saved_root_name != "":
		((Engine.get_main_loop() as SceneTree).current_scene).name = _saved_root_name
		_saved_root_name = ""
	super.after_each()

