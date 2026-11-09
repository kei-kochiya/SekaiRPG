extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Trạng thái phiên chơi. Thoát về menu / chơi mới / vào Sandbox phải dọn trạng thái tạm của lượt trước (cờ Holo-Sim, luyện tập,
hội thoại đang mở), và DialogueManager không được kẹt khi có lựa chọn đang mở.
"""

func _line() -> Dictionary:
	return {"text": "x", "type": "dialogue", "name": "A", "speaker": "left", "color": Color.WHITE}

func test_clear_transient_state_resets_every_battle_mode():
	GameManager.reset_game()
	HoloSimManager.is_sim_active = true
	GameManager.is_training_mode = true
	GameManager.is_tutorial = true
	GameManager.is_sandbox = true
	GameManager.is_scripted_battle = true
	GameManager.scripted_battle_id = "x"
	DialogueManager.show_choice(["a", "b"])
	GameManager.clear_transient_state()
	assert_false(HoloSimManager.is_sim_active, "Holo-Sim không còn hoạt động")
	assert_false(GameManager.is_training_mode, "Hết chế độ luyện tập")
	assert_false(GameManager.is_tutorial, "Hết hướng dẫn")
	assert_false(GameManager.is_sandbox, "Hết Sandbox")
	assert_false(GameManager.is_scripted_battle, "Hết trận kịch bản")
	assert_eq(GameManager.scripted_battle_id, "", "Xóa mã trận kịch bản")
	assert_false(DialogueManager._in_choice, "Lựa chọn đang mở bị đóng")
	assert_false(GameManager.is_in_dialogue, "Không còn khóa hội thoại")
	GameManager.reset_game()

# Quit-to-menu từ Holo-Sim rồi vào Sandbox từng làm trận Sandbox biến thành trận Holo-Sim (BattleInitializer xét cờ sim trước)
func test_start_menu_clears_leftover_holosim_state():
	GameManager.reset_game()
	HoloSimManager.is_sim_active = true
	GameManager.is_training_mode = true
	var root: Node = (Engine.get_main_loop() as SceneTree).current_scene
	var menu: Node = load(MapPaths.START_MENU).instantiate()
	root.add_child(menu) # _ready dọn trạng thái tạm
	assert_false(HoloSimManager.is_sim_active, "Về tới màn hình tiêu đề thì không còn cờ Holo-Sim")
	assert_false(GameManager.is_training_mode, "Không còn cờ luyện tập")
	root.remove_child(menu)
	menu.free()
	GameManager.reset_game()

func test_dialogue_reset_closes_without_running_the_callback():
	GameManager.reset_game()
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
	GameManager.reset_game()

# Gọi play_dialogue lúc lựa chọn đang mở từng làm giao diện kẹt vĩnh viễn (nút ẩn nhưng _in_choice còn true)
func test_dialogue_is_not_started_over_an_open_choice():
	GameManager.reset_game()
	DialogueManager.show_choice(["a", "b"])
	var fired := [0]
	DialogueManager.play_dialogue([_line()], func(): fired[0] += 1)
	assert_false(DialogueManager.active, "Không chen hội thoại lên lựa chọn đang mở")
	assert_true(DialogueManager._in_choice, "Lựa chọn vẫn còn đó để người chơi chọn")
	assert_eq(fired[0], 1, "Callback vẫn chạy để luồng cốt truyện không kẹt")
	DialogueManager._ui.choice_selected.emit(0)
	assert_false(DialogueManager._in_choice, "Chọn xong thì đóng lựa chọn")
	GameManager.reset_game()

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
	GameManager.reset_game()
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
	GameManager.reset_game()

# Hai lần ask() liên tiếp (lần sau gọi ngay trong lần chạy tiếp của lần trước) nhận đúng kết quả của từng lần
func test_back_to_back_asks_each_get_their_own_answer():
	GameManager.reset_game()
	var got := []
	var chain := func():
		got.append(await DialogueManager.ask(["a", "b", "c"]))
		got.append(await DialogueManager.ask(["x", "y"]))
	chain.call()
	DialogueManager._ui.choice_selected.emit(2)
	DialogueManager._ui.choice_selected.emit(1)
	assert_eq(got, [2, 1], "Mỗi lần hỏi nhận đúng lựa chọn của nó")
	GameManager.reset_game()
