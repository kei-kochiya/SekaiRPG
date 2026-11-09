extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Kiểm tra các tiện ích dùng chung của Stage ở căn cứ: dòng thoại say(), menu luyện tập offer_training(),
khoá cảnh/cửa ra, đặt người chơi, bảng màu nhân vật duy nhất và hai bệ tương tác (cửa hàng, Holo-Sim).
"""

const BASE_SCENE = "res://Maps/Base/BaseMap.tscn"

# Dựng BaseMap như lúc vào căn cứ ở một giai đoạn cốt truyện (các cờ cho trước) và gắn vào cây; _drop_base gỡ ra rồi giải phóng
func _spawn_base(flags: Array = []) -> Node:
	GameManager.reset_game()
	for flag in flags:
		GameManager.set_flag(flag, true)
	var base = load(BASE_SCENE).instantiate()
	(Engine.get_main_loop() as SceneTree).current_scene.add_child(base) # _ready dựng map, NPC và người chơi; cảnh mở đầu chờ fade nên không chạy trong test
	return base

func _drop_base(base: Node) -> void:
	base.get_parent().remove_child(base)
	base.free()

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

# ── Cảnh tự chạy và cửa ra ─────────────────────────────────────────────────

# Nối dây thật: vùng tương tác của NPC do BaseMap dựng phải đi qua talk_to_npc (nơi có chốt cảnh tự chạy)
func test_npc_zone_routes_through_the_cutscene_guard():
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

# ── Bố cục NPC ─────────────────────────────────────────────────────────────

# Cờ dẫn tới từng Stage của Base (khớp BaseMap._init_stage)
const STAGE_FLAGS := {
	"intro": [], "post_warehouse": ["harbor_mission_unlocked"], "post_harbor": ["harbor_mission_done"],
	"post_harbor_control": ["harbor_mission_done", "mizuki_control_phase"], "post_harbor_morning": ["mizuki_report_done"],
	"post_cafe": ["ena_cafe_done"], "post_street": ["street_mission_fully_done"], "honami_unlocked": ["honami_house_unlocked"],
	"finale": ["pm_boss_defeated"], "orders": ["interrogation_seen"], "reveal": ["kanade_killed"],
	"final": ["final_confront_started"], "epilogue": ["game_completed"],
}
# Stage mà BaseMap._init_stage phải chọn cho từng bộ cờ ở trên: nếu thang cốt truyện đổi, bài kiểm tra bố cục không được âm thầm kiểm tra nhầm Stage
const STAGE_SCRIPTS := {
	"intro": "IntroStage.gd", "post_warehouse": "PostWarehouseStage.gd", "post_harbor": "PostHarborStage.gd",
	"post_harbor_control": "PostHarborStage.gd", "post_harbor_morning": "PostHarborMorningStage.gd",
	"post_cafe": "PostCafeStreetMissionStage.gd", "post_street": "PostStreetStage.gd", "honami_unlocked": "HonamiHouseUnlockedStage.gd",
	"finale": "FinaleStage.gd", "orders": "OrdersStage.gd", "reveal": "RevealStage.gd", "final": "FinalStage.gd", "epilogue": "EpilogueStage.gd",
}
const DOORWAYS := [Vector2(24, 10), Vector2(24, 20), Vector2(17, 15), Vector2(31, 15)]
const TERMINALS := [Vector2(16, 15), Vector2(20, 15)]
# Kanade nằm trên giường ở Khu Nghỉ Ngơi sau chuyến Bến Cảng (chủ ý của cốt truyện)
const ALLOWED_ON_BLOCKED := {"post_harbor": ["Kanade"], "post_harbor_control": ["Kanade"]}

# Không NPC nào đứng trong tường/đồ đạc, chắn ô cửa, hay có vùng nói chuyện chồng lên bệ cửa hàng/Holo-Sim
func test_no_base_npc_stands_in_a_wall_a_doorway_or_on_a_terminal():
	var problems: Array = []
	for stage_name in STAGE_FLAGS:
		var base = _spawn_base(STAGE_FLAGS[stage_name])
		var blocked := {}
		var npcs := {}
		for c in base.get_children():
			if c is StaticBody2D and c.get_child_count() > 0:
				blocked[(c.position / base.TILE_SIZE).round()] = true
			elif c.has_meta("is_npc") and not c.is_queued_for_deletion():
				npcs[c.get_meta("npc_name")] = c.position
		assert_eq(base.current_stage.get_script().resource_path.get_file(), STAGE_SCRIPTS[stage_name], "%s: bộ cờ chọn đúng Stage" % stage_name)
		assert_gt(npcs.size(), 0, "%s: có NPC" % stage_name)
		for npc in npcs:
			var tile: Vector2 = (npcs[npc] / base.TILE_SIZE).round()
			if blocked.has(tile) and not (npc in ALLOWED_ON_BLOCKED.get(stage_name, [])):
				problems.append("%s/%s đứng trên ô bị chặn %s" % [stage_name, npc, tile])
			for door in DOORWAYS:
				if absf(tile.x - door.x) <= 0.5 and absf(tile.y - door.y) <= 1.0:
					problems.append("%s/%s chắn cửa %s" % [stage_name, npc, door])
			for terminal in TERMINALS:
				if npcs[npc].distance_to(terminal * base.TILE_SIZE) < 80.0:
					problems.append("%s/%s chồng lên bệ %s" % [stage_name, npc, terminal])
		_drop_base(base)
	assert_eq(problems, [], "Bố cục NPC hợp lệ ở mọi Stage")

# ── Sảnh dùng chung ────────────────────────────────────────────────────────

# PostStreetStage và HonamiHouseUnlockedStage dùng chung bố cục sảnh: đổi một chỗ phải đổi cả hai
func test_lobby_stages_share_one_hall_layout():
	var base = load(BASE_SCENE).instantiate()
	var tiles := {"Ena": Vector2(28, 13), "Kanade": Vector2(23, 13), "Mizuki": Vector2(19, 12), "Mafuyu": Vector2(25, 12)}
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

func test_training_menu_hides_members_who_already_trained_only_when_asked():
	GameManager.set_flag("training_ichika_done", true)
	var stage := BaseMapStage.new()
	var out := _open_training_menu(stage, ["Ichika", "Kanade"], true)
	assert_eq(out["labels"], ["Kanade (5 Waves)", "Để sau."], "Ichika đã tập xong thì ẩn đi, giữ thứ tự còn lại")
	assert_eq(out["started"], false, "Chọn \"Để sau.\" thì không vào luyện tập")
	assert_false(GameManager.is_training_mode, "Chưa bắt đầu luyện tập")
	out = _open_training_menu(stage, ["Ichika", "Kanade"])
	assert_eq(out["labels"], ["Ichika (5 Waves)", "Kanade (5 Waves)", "Để sau."], "Không bật hide_done thì hiện đủ")
	stage.free()

func test_training_menu_cancel_does_not_run_the_before_start_hook():
	var fired := [0]
	var stage := BaseMapStage.new()
	var out := _open_training_menu(stage, ["Ichika"], false, false, "", func(): fired[0] += 1)
	assert_eq(out["labels"], ["Ichika (5 Waves)", "Để sau."], "Một người thì không có mục cả nhóm")
	assert_eq(fired[0], 0, "Chọn \"Để sau.\" thì không chạy before_start (cờ/khoá cảnh chỉ đặt khi thật sự vào luyện tập)")
	stage.free()

func test_training_menu_skips_the_dead_and_offers_the_group_option():
	var stage := BaseMapStage.new()
	var out := _open_training_menu(stage, ["Ichika", "Honami"], false, true, "Cả hai (10 Waves)")
	assert_eq(out["labels"], ["Ichika (5 Waves)", "Honami (5 Waves)", "Cả hai (10 Waves)", "Để sau."], "Hai người thì có thêm mục cả nhóm")
	GameManager.set_flag("ena_killed", true)
	out = _open_training_menu(stage, ["Ichika", "Ena"], false, true, "Cả hai (10 Waves)")
	assert_eq(out["labels"], ["Ichika (5 Waves)", "Để sau."], "Người đã chết bị bỏ, còn một người thì không có mục cả nhóm")
	stage.free()

# ── Đặt người chơi và bệ tương tác của BaseMap ─────────────────────────────

func test_base_map_sets_and_places_the_player():
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

# ── Cảnh tự chạy phải khoá người chơi ──────────────────────────────────────

# Cảnh tự chạy chỉ chặn NPC (_cutscene_active) mà không đóng băng người chơi từng cho phép bấm ENTER ở bệ Holo-Sim giữa lúc chờ,
# rồi hội thoại của cảnh chen lên lựa chọn đang mở làm kẹt giao diện. lock_scene() đóng băng người chơi nên cả hai đều không xảy ra.
func test_autoplaying_base_cutscenes_freeze_the_player():
	var cases := {
		"post_cafe": ["ena_cafe_done"],
		"post_street_invasion": ["street_mission_fully_done", "post_street_trained_once"],
		"honami_unlocked_intro": ["honami_house_unlocked"],
		"epilogue_intro": ["game_completed"],
		"post_harbor_morning": ["mizuki_report_done"],
		"post_harbor_report": ["harbor_mission_done", "mizuki_vs_mafuyu_done"],
		"orders": ["interrogation_seen"],
		"reveal": ["kanade_killed"],
		"final": ["final_confront_started"],
		"finale": ["pm_boss_defeated"],
	}
	for case_name in cases:
		var base = _spawn_base(cases[case_name]) # on_stage_start chờ fade nên tự gọi bên dưới
		var player: Node = base.get_node("OverworldPlayer")
		assert_true(player.is_physics_processing(), "%s: người chơi đi lại được trước cảnh" % case_name)
		base.current_stage.on_stage_start()
		assert_false(player.is_physics_processing(), "%s: cảnh tự chạy đóng băng người chơi" % case_name)
		assert_true(base.current_stage._cutscene_active, "%s: và chặn NPC" % case_name)
		DialogueManager.reset()
		_drop_base(base)

# Bến Cảng chỉ mở sau khi Ena giao nhiệm vụ (cảnh harbor_arrival giả định cô ấy đã giao việc)
func test_harbor_exit_needs_the_briefing_from_ena():
	var base = _spawn_base(["harbor_mission_unlocked"])
	assert_eq(base.current_stage.get_script().resource_path.get_file(), "PostWarehouseStage.gd", "Đúng Stage sau Nhà kho")
	base._on_exit_interacted()
	assert_true(DialogueManager.active, "Chưa gặp Ena: chỉ có lời nhắc, không đi Bến Cảng")
	assert_false(base._leaving, "Không bị kẹt ở trạng thái đang rời đi")
	DialogueManager.reset()
	_drop_base(base)

# BaseMap._spawn_player chạy trước on_stage_start: cờ điều khiển Mizuki còn bật từ cảnh trước thì người chơi hiện ra là Mizuki chồng lên NPC
func test_morning_after_the_report_spawns_ichika_not_mizuki():
	var base = _spawn_base(["mizuki_report_done", "mizuki_control_phase"])
	assert_eq((base.get_node("OverworldPlayer") as OverworldPlayer).character_name, "Ichika", "Người chơi là Ichika ngay từ lúc xuất hiện")
	assert_false(GameManager.get_flag("mizuki_control_phase"), "Cờ điều khiển Mizuki đã được tắt trước khi dựng người chơi")
	_drop_base(base)

# Cờ npcs_greeted phải được ghi bằng set_flag chứ không dựa vào mảng sống phía sau getter
func test_greeting_an_intro_npc_is_recorded_in_the_story_flags():
	var base = _spawn_base()
	assert_eq(base.current_stage.get_script().resource_path.get_file(), "IntroStage.gd", "Đúng Stage mở đầu")
	base.current_stage._quest_phase_interact("Kanade")
	_drain_dialogue()
	assert_true("Kanade" in GameManager.get_flag("npcs_greeted"), "Lời chào được ghi vào cờ")
	base.current_stage._quest_phase_interact("Kanade")
	_drain_dialogue()
	assert_eq(GameManager.get_flag("npcs_greeted").count("Kanade"), 1, "Chào lần hai không ghi trùng")
	_drop_base(base)

# Ai cũng đã tập xong thì nói một câu thay vì mở menu chỉ có nút "Để sau."
func test_training_with_everyone_done_says_so_instead_of_opening_an_empty_menu():
	for member in ["Ichika", "Kanade"]:
		GameManager.set_flag("training_%s_done" % member.to_lower(), true)
	var stage := BaseMapStage.new()
	var started = await stage.offer_training(["Ichika", "Kanade"], true)
	assert_eq(started, false, "Không có ai để luyện tập")
	assert_true(DialogueManager.active, "Có một dòng dẫn truyện thay cho menu")
	assert_false(DialogueManager._in_choice, "Không mở lựa chọn chỉ có \"Để sau.\"")
	_drain_dialogue()
	stage.free()

# NPC chưa có gì để nói vẫn phải đáp lại: ở bước Kanade nằm giường và lúc chuẩn bị lại bài kiểm tra, bấm ENTER không được im lặng
func test_npcs_with_nothing_to_say_still_answer():
	var harbor = load("res://Maps/Base/Stages/PostHarborStage.gd").new()
	GameManager.set_flag("mizuki_control_phase", true)
	harbor.handle_npc_interaction("Kanade")
	assert_true(DialogueManager.active, "Kanade (Mizuki điều khiển) đáp một dòng")
	_drain_dialogue()
	harbor.free()
	GameManager.set_flag("mizuki_control_phase", false)
	var finale = load("res://Maps/Base/Stages/FinaleStage.gd").new()
	finale._prep_mode = true
	for npc in ["Ena", "Kanade", "Mizuki"]:
		finale.handle_npc_interaction(npc)
		assert_true(DialogueManager.active, "%s lúc chuẩn bị lại đáp một dòng" % npc)
		_drain_dialogue()
	finale.free()

# FinaleStage tách base_celebration ở dòng bắt đầu bằng "RẦM!" (tiếng sập cửa): sửa chữ trong JSON mà quên chỗ này thì phần sau
# cú sập rỗng và Mafuyu nói "để cô ta nguội" khi Ena vẫn còn trong phòng
func test_base_celebration_still_has_the_door_slam_line_the_finale_splits_on():
	var lines: Array = DialogueLoader.get_lines("base_celebration")
	var slam := lines.filter(func(l): return str(l.get("text", "")).begins_with("RẦM!"))
	assert_eq(slam.size(), 1, "Đúng một dòng bắt đầu bằng RẦM!")
	assert_gt(lines.find(slam[0]), 0, "Có thoại trước tiếng sập cửa")
	assert_lt(lines.find(slam[0]), lines.size() - 1, "Có thoại sau tiếng sập cửa")
