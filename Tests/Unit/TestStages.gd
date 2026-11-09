extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Kiểm tra các tiện ích dùng chung của Stage ở căn cứ: dòng thoại say(), menu luyện tập offer_training(),
khoá cảnh/cửa ra, đặt người chơi, bảng màu nhân vật duy nhất và hai bệ tương tác (cửa hàng, Holo-Sim).
"""

const BASE_SCENE = "res://Maps/Base/BaseMap.tscn"

# Chạy hết hội thoại đang mở (kể cả hội thoại mới mở ra từ callback của hội thoại trước)
func _drain_dialogue() -> void:
	var guard := 0
	while DialogueManager.active and guard < 50:
		DialogueManager._advance_dialogue()
		guard += 1

# Mở menu luyện tập, đọc nhãn các nút rồi chọn nút cuối ("Để sau."): trả về {"labels": [...], "started": kết quả offer_training}
func _open_training_menu(stage: BaseMapStage, trainees: Array, hide_done: bool = false, alive_only: bool = false, group_label: String = "", before_start: Callable = Callable()) -> Dictionary:
	var out := {"labels": [], "started": null}
	var run := func():
		out["started"] = await stage.offer_training(trainees, hide_done, before_start, alive_only, group_label)
	run.call()
	out["labels"] = DialogueManager._ui.choice_box.get_children().filter(func(n): return n is Button).map(func(b): return b.text)
	DialogueManager._ui.choice_selected.emit(out["labels"].size() - 1)
	return out

# ── say() và bảng màu ──────────────────────────────────────────────────────

func test_say_builds_a_line_in_the_speakers_colour():
	GameManager.reset_game()
	var stage := BaseMapStage.new()
	var line := stage.say("Mafuyu", "Xin chào")
	assert_eq(line["text"], "Xin chào", "Giữ nguyên lời thoại")
	assert_eq(line["type"], "dialogue", "Là thoại nhân vật, không phải dẫn truyện")
	assert_eq(line["name"], "Mafuyu", "Tên người nói")
	assert_eq(line["color"], Color("#665588"), "Màu của Mafuyu")
	assert_false(line.has("speaker"), "Không đặt bên nói: DialogueUI mặc định là trái")
	assert_eq(stage.say("Ghost", "...")["color"], Color.WHITE, "Người lạ thì màu trắng")
	stage.free()

func test_speaker_colours_match_the_dialogue_files():
	var checked := 0
	var mismatches: Array = []
	for key in DialogueLoader._data:
		for line in DialogueLoader.get_lines(key):
			if BaseMapStage.SPEAKER_COLORS.has(line["name"]):
				checked += 1
				if line["color"] != BaseMapStage.SPEAKER_COLORS[line["name"]]:
					mismatches.append("%s/%s" % [key, line["name"]])
	assert_gt(checked, 100, "Có nhiều dòng thoại của sáu nhân vật chính để so")
	assert_eq(mismatches, [], "Bảng màu người nói khớp với JSON")

func test_every_character_colour_resolves_to_its_own_sprite():
	for char_name in MapUtils.CHARACTER_COLORS:
		var player := OverworldPlayer.new()
		player.character_color = MapUtils.CHARACTER_COLORS[char_name]
		assert_eq(player.character_name, char_name, "Màu của %s ra đúng sprite của %s" % [char_name, char_name])
		player.free()

# ── Cảnh tự chạy và cửa ra ─────────────────────────────────────────────────

func test_npc_talk_is_ignored_while_a_cutscene_runs():
	GameManager.reset_game()
	_drain_dialogue() # suite trước có thể để lại một hội thoại đang mở
	var stage := PostCafeStreetMissionStage.new()
	stage._cutscene_active = true
	stage.talk_to_npc("Ena")
	assert_false(DialogueManager.active, "Đang cảnh tự chạy thì chạm NPC không mở hội thoại")
	stage._cutscene_active = false
	stage.talk_to_npc("Ena")
	assert_true(DialogueManager.active, "Hết cảnh tự chạy thì NPC nói chuyện bình thường")
	_drain_dialogue()
	stage.free()

# Nối dây thật: vùng tương tác của NPC do BaseMap dựng phải đi qua talk_to_npc (nơi có chốt cảnh tự chạy)
func test_npc_zone_routes_through_the_cutscene_guard():
	GameManager.reset_game()
	_drain_dialogue()
	var base = load(BASE_SCENE).instantiate()
	var stage := PostCafeStreetMissionStage.new()
	base.current_stage = stage
	base._create_npc("Ena", Vector2.ZERO, Color.WHITE)
	var zone: InteractableZone = null
	for c in base.get_child(base.get_child_count() - 1).get_children():
		if c is InteractableZone:
			zone = c
	assert_true(zone != null, "NPC có vùng tương tác")
	stage._cutscene_active = true
	zone.interacted.emit()
	assert_false(DialogueManager.active, "Vùng tương tác của NPC cũng bị chốt khi đang cảnh tự chạy")
	stage._cutscene_active = false
	zone.interacted.emit()
	assert_true(DialogueManager.active, "Hết cảnh tự chạy thì chạm NPC mở hội thoại")
	_drain_dialogue()
	base.free()
	stage.free()

func test_arc2_cutscene_stages_keep_the_exit_shut():
	for file in ["OrdersStage", "RevealStage", "FinalStage", "FinaleStage"]:
		var stage: BaseMapStage = load("res://Maps/Base/Stages/%s.gd" % file).new()
		assert_true(stage.handle_exit(), "%s: cửa ra luôn bị khoá" % file)
		stage.free()
	var open_stage: BaseMapStage = load("res://Maps/Base/Stages/PostWarehouseStage.gd").new()
	assert_false(open_stage.handle_exit(), "Stage thường để BaseMap tự xử lý cửa ra")
	open_stage.free()

# ── Sảnh dùng chung ────────────────────────────────────────────────────────

# PostStreetStage và HonamiHouseUnlockedStage dùng chung bố cục sảnh: đổi một chỗ phải đổi cả hai
func test_lobby_stages_share_one_hall_layout():
	var base = load(BASE_SCENE).instantiate()
	var tiles := {"Ena": Vector2(17, 11), "Kanade": Vector2(23, 13), "Mizuki": Vector2(19, 12), "Mafuyu": Vector2(24, 11)}
	for file in ["PostStreetStage", "HonamiHouseUnlockedStage"]:
		var stage: BaseMapStage = load("res://Maps/Base/Stages/%s.gd" % file).new()
		stage.map = base
		assert_true(stage is LobbyStage, "%s dùng chung LobbyStage" % file)
		var positions: Dictionary = stage.get_npc_positions()
		assert_eq(positions.keys(), tiles.keys(), "%s: đúng bốn NPC theo thứ tự" % file)
		for npc in tiles:
			assert_eq(positions[npc], tiles[npc] * base.TILE_SIZE, "%s: vị trí của %s" % [file, npc])
		assert_eq(stage.get_scene_lighting(), Color(0.9, 0.9, 1.0), "%s: ánh sáng sảnh" % file)
		stage.free()
	assert_eq(LobbyStage.TRAINEES, ["Ichika", "Kanade", "Ena", "Mizuki", "Mafuyu"], "Năm người được Mafuyu cho luyện tập")
	base.free()

# ── Menu luyện tập ─────────────────────────────────────────────────────────

func test_training_menu_hides_members_who_already_trained():
	GameManager.reset_game()
	GameManager.set_flag("training_ichika_done", true)
	var stage := BaseMapStage.new()
	var out := _open_training_menu(stage, ["Ichika", "Kanade"], true)
	assert_eq(out["labels"], ["Kanade (5 Waves)", "Để sau."], "Ichika đã tập xong thì ẩn đi, giữ thứ tự còn lại")
	assert_eq(out["started"], false, "Chọn \"Để sau.\" thì không vào luyện tập")
	assert_false(GameManager.is_training_mode, "Chưa bắt đầu luyện tập")
	stage.free()
	GameManager.reset_game()

func test_training_menu_cancel_does_not_run_the_before_start_hook():
	GameManager.reset_game()
	var fired := [0]
	var stage := BaseMapStage.new()
	var out := _open_training_menu(stage, ["Ichika"], false, false, "", func(): fired[0] += 1)
	assert_eq(out["labels"], ["Ichika (5 Waves)", "Để sau."], "Một người thì không có mục cả nhóm")
	assert_eq(fired[0], 0, "Chọn \"Để sau.\" thì không chạy before_start (cờ/khoá cảnh chỉ đặt khi thật sự vào luyện tập)")
	stage.free()
	GameManager.reset_game()

func test_training_menu_keeps_everyone_unless_asked_to_hide():
	GameManager.reset_game()
	GameManager.set_flag("training_ichika_done", true)
	var stage := BaseMapStage.new()
	var out := _open_training_menu(stage, ["Ichika", "Kanade"])
	assert_eq(out["labels"], ["Ichika (5 Waves)", "Kanade (5 Waves)", "Để sau."], "Không bật hide_done thì hiện đủ")
	stage.free()
	GameManager.reset_game()

func test_training_menu_skips_the_dead_and_offers_the_group_option():
	GameManager.reset_game()
	var stage := BaseMapStage.new()
	var out := _open_training_menu(stage, ["Ichika", "Honami"], false, true, "Cả hai (10 Waves)")
	assert_eq(out["labels"], ["Ichika (5 Waves)", "Honami (5 Waves)", "Cả hai (10 Waves)", "Để sau."], "Hai người thì có thêm mục cả nhóm")
	GameManager.set_flag("ena_killed", true)
	out = _open_training_menu(stage, ["Ichika", "Ena"], false, true, "Cả hai (10 Waves)")
	assert_eq(out["labels"], ["Ichika (5 Waves)", "Để sau."], "Người đã chết bị bỏ, còn một người thì không có mục cả nhóm")
	stage.free()
	GameManager.reset_game()

# ── Đặt người chơi và bệ tương tác của BaseMap ─────────────────────────────

func test_base_map_sets_and_places_the_player():
	GameManager.reset_game()
	var base = load(BASE_SCENE).instantiate()
	base.set_player("Ena") # chưa có người chơi: không lỗi
	base.place_player(Vector2(3, 4))
	var player := OverworldPlayer.new()
	player.name = "OverworldPlayer"
	base.add_child(player)
	base.set_player("Ena")
	assert_eq(player.character_name, "Ena", "Đổi sang sprite của Ena")
	base.place_player(Vector2(3, 4), "left")
	assert_eq(player.position, Vector2(3 * base.TILE_SIZE, 4 * base.TILE_SIZE), "Vị trí tính theo ô lưới")
	assert_eq(player._facing, "left", "Hướng nhìn được đặt")
	base.free()

func test_shop_and_holo_sim_terminals_are_built_in_order():
	GameManager.reset_game()
	var base = load(BASE_SCENE).instantiate()
	base._spawn_shop_and_sim()
	var roots: Array = base.get_children()
	assert_eq(roots.size(), 2, "Hai bệ: cửa hàng rồi Holo-Sim")
	assert_eq(roots[0].position, Vector2(16 * base.TILE_SIZE, 15 * base.TILE_SIZE), "Cửa hàng ở ô (16, 15)")
	assert_eq(roots[1].position, Vector2(20 * base.TILE_SIZE, 15 * base.TILE_SIZE), "Holo-Sim ở ô (20, 15)")
	for root in roots:
		assert_eq(root.get_child_count(), 3, "Mỗi bệ có hình, nhãn và vùng tương tác")
		assert_true(root.get_child(2) is InteractableZone, "Nút cuối là vùng tương tác")
	assert_eq(roots[0].get_child(2).prompt_text, "Mở Cửa Hàng (Shop)", "Gợi ý của cửa hàng")
	assert_eq(roots[1].get_child(2).prompt_text, "Máy Mô Phỏng Holo-Sim", "Gợi ý của Holo-Sim")
	base.free()
