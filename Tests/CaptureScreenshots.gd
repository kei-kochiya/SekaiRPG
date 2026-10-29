extends Node

"""
CaptureScreenshots: chụp ảnh các màn hình UI để kiểm tra bằng mắt.

Chạy (cần cửa sổ, không dùng --headless):
	godot --path . res://Tests/CaptureScreenshotsScene.tscn -- start_menu battle

Shot hợp lệ: start_menu | sandbox | sandbox_sel | upgrade | battle | cards | dialogue | narrator | pause | options | guide
	| saveload | saveload_title | saveload_confirm | saveload_error | shop | blessing | skilldetail | entities | tutorial | <res://đường/dẫn/scene.tscn>
Hội thoại / Overworld / phím ảo: choices | dialogue_long | narrator_long | dialogue_xl | narrator_xl | quest_hud | prompt | mobile | floating
Kiểm tra logic (in [Check] PASS/FAIL): pause_flow | fx_check
Ảnh lưu vào screenshots/ (đã gitignore).
"""

const OUT_DIR = "res://screenshots/"
const SETTLE_FRAMES = 20

func _ready():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var shots := OS.get_cmdline_user_args()
	if shots.is_empty():
		shots = PackedStringArray(["start_menu", "sandbox", "upgrade", "battle", "cards"])
	for shot in shots:
		await _capture(shot)
	get_tree().quit(0)

func _reset_overlays():
	# Autoload giữ trạng thái giữa các shot trong cùng một lần chạy nên phải dọn trước mỗi shot.
	PauseMenu.visible = false
	get_tree().paused = false
	DialogueManager.active = false
	DialogueManager.visible = false
	GameManager.end_dialogue()

func _capture(shot: String):
	_reset_overlays()
	var root: Node = null
	match shot:
		"start_menu": root = load("res://UI/Menus/Start/StartMenu.tscn").instantiate()
		"sandbox": root = _build_sandbox(false)
		"upgrade": root = _build_upgrade()
		"sandbox_sel": root = _build_sandbox(true)
		"saveload": root = _build_saveload(false, "")
		"saveload_title": root = _build_saveload(true, "")
		"saveload_confirm": root = _build_saveload(false, "confirm")
		"saveload_error": root = _build_saveload(false, "error")
		"shop": root = _build_shop()
		"blessing": root = _build_blessing()
		"skilldetail": root = _build_skill_detail()
		"entities": root = _build_entities()
		"tutorial": root = _build_tutorial()
		"cards": root = _build_cards()
		"battle": root = _build_battle()
		"dialogue": root = _build_dialogue(4)
		"narrator": root = _build_dialogue(1)
		"pause": root = _build_pause()
		"options": root = _build_options()
		"guide": root = _build_guide()
		"choices": root = _build_choices()
		"dialogue_long": root = _build_dialogue_longest("honami_house_intro", false)
		"narrator_long": root = _build_dialogue_longest("street_honami_encounter", true)
		"quest_hud": root = _build_quest_hud()
		"prompt": root = _build_prompt()
		"mobile": root = _build_mobile()
		"floating": root = _build_floating()
		"pause_flow": root = _build_pause_flow()
		"fx_check": root = await _build_fx_check()
		"dialogue_xl": root = _build_dialogue_xl(false)
		"narrator_xl": root = _build_dialogue_xl(true)
		_:
			if shot.begins_with("res://") and ResourceLoader.exists(shot):
				root = load(shot).instantiate()
	if root == null:
		printerr("[Capture] Shot không hợp lệ: " + shot)
		return
	add_child(root)
	await _settle()
	var img := get_viewport().get_texture().get_image()
	var file := shot.get_file().get_basename() + ".png"
	img.save_png(OUT_DIR + file)
	print("[Capture] Saved " + OUT_DIR + file)
	root.queue_free()
	await get_tree().process_frame

func _settle():
	for i in range(SETTLE_FRAMES):
		if ScreenFade and ScreenFade._rect:
			ScreenFade._rect.modulate.a = 0.0
		await get_tree().process_frame
	await RenderingServer.frame_post_draw

func _build_upgrade() -> Node:
	_force_720()
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	var party: Array[Entity] = []
	for e in [Ichika.new(), Kanade.new(), Mafuyu.new()]:
		e.skill_points = 8
		party.append(e)
	UpgradeUI.show_ui(party)
	holder.tree_exiting.connect(UpgradeUI.close_ui)
	return holder

# ── Shot màn hình menu / hộp thoại modal ───────────────────────────────────

# Sandbox; `selected` = đã chọn 3 nhân vật, 3 kẻ địch và đang hiện cảnh báo
func _build_sandbox(selected: bool) -> Node:
	_force_720()
	var menu = load("res://UI/Menus/Sandbox/SandboxMenu.tscn").instantiate()
	if not selected:
		return menu
	menu.ready.connect(func():
		var boxes = menu.player_side.get_node("Scroll/CharList").get_children()
		for i in 3:
			boxes[i].button_pressed = true
		for n in ["Kidnapper", "Kidnapper", "Khủng Bố"]:
			menu._on_enemy_added(n)
		menu._show_status("Hãy chọn nhân vật trước khi nâng cấp!", UITheme.WARNING))
	return menu

# Ghi vài file save giả (tiền tố zz_capture_) để thấy danh sách có dữ liệu; xóa lại khi shot kết thúc
func _write_temp_saves() -> Array:
	SaveManager.ensure_saves_dir()
	var now := Time.get_unix_time_from_system()
	var metas := [
		{"file_name": "autosave.json", "quest_name": "Điều tra nhà kho cũ", "map_name": "Nhà kho cũ", "timestamp": "12/03/2026 21:45:10", "unix_time": now},
		{"file_name": "quicksave.json", "quest_name": "Truy đuổi tên thủ lĩnh băng đảng qua khu cảng phía Đông thành phố", "map_name": "Bến cảng thành phố", "timestamp": "12/03/2026 21:30:02", "unix_time": now - 900},
		{"file_name": "chuong_2_truoc_boss.json", "quest_name": "Phòng thủ căn cứ", "map_name": "Căn cứ Nightcord (Safehouse)", "timestamp": "11/03/2026 18:05:44", "unix_time": now - 90000},
	]
	var paths := []
	for i in metas.size():
		var path := "user://saves/zz_capture_%d.json" % i
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string(JSON.stringify({"metadata": metas[i], "game_state": {}}))
		f.close()
		paths.append(path)
	return paths

func _remove_temp_saves(paths: Array):
	for path in paths:
		SaveManager.delete_save(path)

# Hộp thoại Lưu/Tải; `title_mode` giả lập mở từ StartMenu; `extra` = "confirm" | "error"
func _build_saveload(title_mode: bool, extra: String) -> Node:
	_clear_systems()
	var paths := _write_temp_saves()
	var scene := get_tree().current_scene
	var scene_name := scene.name
	if title_mode:
		scene.name = "StartMenu"
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(UITheme.backdrop())
	var menu = load("res://UI/Menus/SaveLoad/SaveLoadMenu.tscn").instantiate()
	holder.add_child(menu)
	match extra:
		"confirm": menu.ready.connect(func(): menu._confirm_delete(paths[1]))
		"error": menu.ready.connect(func(): menu._set_status("Không thể tải file save.", UITheme.DANGER_TEXT))
	holder.tree_exiting.connect(func():
		scene.name = scene_name
		_remove_temp_saves(paths))
	return holder

func _build_shop() -> Node:
	_clear_systems()
	GameManager.credits = 90
	GameManager.inventory = {"potion": 2, "energy_drink": 1}
	return ShopMenu.new()

func _build_blessing() -> Node:
	_clear_systems()
	var ui := HoloBlessingSelectUI.new()
	ui.ready.connect(func():
		ui.setup_options([
			HoloBlessing.BLESSING_CATALOG["blessing_bleed"],
			HoloBlessing.BLESSING_CATALOG["blessing_cooldown"],
			HoloBlessing.BLESSING_CATALOG["blessing_undying"],
		]))
	return ui

func _build_skill_detail() -> Node:
	_clear_systems()
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(UITheme.backdrop())
	var popup := SkillDetailPopup.new()
	holder.add_child(popup)
	popup.display_entity_skills(Ichika.new())
	return holder

# Bảng chi tiết: có người hạ gục, kỹ năng đang hồi và kỹ năng đã dùng hết
func _build_entities() -> Node:
	_clear_systems()
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(UITheme.backdrop())
	var players: Array = [Ichika.new(), Kanade.new(), Mafuyu.new(), Ena.new()]
	var foes: Array = [Captain.new(), Terrorist.new(), CyborgEnforcer.new()]
	players[0].cooldowns["piercing_chord"] = 2
	players[0].cooldowns["shadow_strike"] = 99
	players[1].current_hp = 40
	foes[1].current_hp = 0
	var panel := EntityDetailPanel.new()
	holder.add_child(panel)
	panel.show_entities(players, foes)
	return holder

func _build_tutorial() -> Node:
	_clear_systems()
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(UITheme.backdrop())
	var panel := BattleTutorial._build_tutorial_panel(holder)
	var step: Array = BattleTutorial.STEPS[3]
	BattleTutorial._show_tutorial_step(holder, panel.get_child(0), step[0], step[1])
	return holder

func _build_cards() -> Node:
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.add_theme_constant_override("separation", 16)
	var CharacterCardClass = load("res://UI/Battle/CharacterCard.gd")
	var entities := [[Ichika.new(), true], [Captain.new(), false], [Terrorist.new(), false], [CyborgEnforcer.new(), false]]
	for pair in entities:
		var card = CharacterCardClass.new()
		row.add_child(card)
		card.setup(pair[0], pair[1])
	return row

func _build_battle() -> Node:
	GameManager.is_sandbox = true
	GameManager.sandbox_player_team.clear()
	GameManager.sandbox_enemy_team.clear()
	for n in ["Ichika", "Kanade", "Mafuyu", "Ena"]:
		GameManager.sandbox_player_team.append(GameManager.create_sandbox_entity(n))
	for n in ["Kidnapper", "Khủng Bố", "Vệ Binh Cơ Giới"]:
		var enemy = GameManager.create_sandbox_entity(n)
		LevelManager.set_initial_level(enemy, 5)
		GameManager.sandbox_enemy_team.append(enemy)
	return load("res://Scripts/Battle/BattleScene.tscn").instantiate()

func _build_dialogue(line_index: int) -> Node:
	DialogueManager.play_dialogue(DialogueLoader.get_lines("prologue_phase0"))
	DialogueManager.index = line_index
	DialogueManager._show_current_line()
	return Control.new()

func _build_pause() -> Node:
	PauseMenu._reset_views()
	PauseMenu.visible = true
	PauseMenu._panel.visible = true
	return Control.new()

func _build_options() -> Node:
	PauseMenu.show_options(true)
	return Control.new()

func _build_guide() -> Node:
	PauseMenu._reset_views()
	PauseMenu.visible = true
	PauseMenu._panel.visible = false
	PauseMenu._on_guide()
	return Control.new()

# ── Shot hệ thống (hội thoại / pause / phím ảo) và Overworld ──────────────

# Đưa các autoload UI về trạng thái nghỉ để shot trước không dính sang shot sau
func _clear_systems():
	_force_720()
	PauseMenu._reset_views()
	PauseMenu.visible = false
	get_tree().paused = false
	GameManager.end_dialogue()
	DialogueManager.active = false
	DialogueManager._in_choice = false
	DialogueManager._ui.clear()
	DialogueManager.visible = false

# Nền màu giả lập mặt bản đồ để thử độ tương phản của HUD bán trong suốt
func _backdrop(color: Color) -> ColorRect:
	var bg := ColorRect.new()
	bg.color = color
	bg.size = Vector2(2560, 1440)
	return bg

# Cửa sổ đúng 1280x720 (kích thước thiết kế, trường hợp hẹp nhất) thay vì bị phóng to tối đa
func _force_720():
	var w := get_window()
	w.mode = Window.MODE_WINDOWED
	w.size = Vector2i(1280, 720)

func _build_choices() -> Node:
	_clear_systems()
	# Mở hai menu liên tiếp: focus phải rơi vào nút mới đầu tiên, không phải nút cũ
	DialogueManager.show_choice(["[Đến nhà Honami]", "[Đi dạo (Khu phố)]", "[Hủy]"])
	DialogueManager.show_choice(["[Hất tay ra] Xê ra! Tụi này tao cân hết!", "[Nổi cáu] Mày cản tao? Muốn ăn đòn à?!", "Đá khỏi giường"])
	var check := func():
		for i in 3:
			await get_tree().process_frame
		var f := get_viewport().gui_get_focus_owner()
		var first: Node = DialogueManager._ui.choice_box.get_child(0)
		print("[Check] choices focus ok=", f == first, " children=", DialogueManager._ui.choice_box.get_child_count())
	check.call()
	return Control.new()

# Dòng thoại dài nhất của một đoạn hội thoại (theo loại thoại/tường thuật) để kiểm tra chữ không bị cắt
func _build_dialogue_longest(key: String, narrator: bool) -> Node:
	_clear_systems()
	var lines: Array = DialogueLoader.get_lines(key)
	var best := 0
	var best_len := -1
	for i in lines.size():
		var is_narr: bool = lines[i]["type"] == "narrator"
		var n: int = str(lines[i]["text"]).length()
		if is_narr == narrator and n > best_len:
			best = i
			best_len = n
	DialogueManager.play_dialogue(lines)
	DialogueManager.index = best
	DialogueManager._show_current_line()
	return Control.new()

# Câu thoại dài gấp ba dòng dài nhất: hộp phải tự cao thêm (lên trên / ra hai phía), chữ không bị cắt
func _build_dialogue_xl(narrator: bool) -> Node:
	_clear_systems()
	var text := "Bọn băng đảng sẵn sàng trả hàng đống tiền để mua mạng sống. Tôi lấy tiền của bọn chúng để mua thuốc cho những người không có khả năng chi trả. "
	DialogueManager.play_dialogue([{"type": "narrator" if narrator else "dialogue", "name": "Mafuyu", "speaker": "left", "color": Color("#665588"), "text": text.repeat(3)}])
	return Control.new()

func _build_quest_hud() -> Node:
	_clear_systems()
	var holder := Node2D.new()
	holder.add_child(_backdrop(Color.DARK_OLIVE_GREEN))
	var hud := QuestHUDBuilder.build(holder)
	hud["label"].text = "MỤC TIÊU: Tự do khám phá (Nói chuyện 4 lần hoặc Đi tập luyện để tiếp tục)"
	return holder

func _build_prompt() -> Node:
	_clear_systems()
	var holder := Node2D.new()
	holder.add_child(_backdrop(Color.DARK_OLIVE_GREEN))
	var texts := ["Mở rương", "Nhấn ENTER để bắt đầu lượt tập (Wave 3)", "Press ENTER"]
	for i in texts.size():
		var marker := ColorRect.new()
		marker.color = UITheme.PLAYER
		marker.size = Vector2(32, 32)
		marker.position = Vector2(284 + i * 380, 368)
		holder.add_child(marker)
		var zone := InteractableZone.new()
		zone.position = Vector2(300 + i * 380, 400)
		zone.prompt_text = texts[i]
		holder.add_child(zone)
		zone.is_player_inside = true
	# Đổi text sau khi vùng đã dựng (như TreasureChest sau khi mở): nhãn phải cập nhật
	(holder.get_child(2) as InteractableZone).prompt_text = "Rương trống"
	return holder

# Phím ảo chỉ bật trên mobile thật: ép bật ngay trong shot, không động tới script
func _build_mobile() -> Node:
	_clear_systems()
	var mc = get_node("/root/MobileControls")
	mc._is_mobile = true
	mc.process_mode = Node.PROCESS_MODE_ALWAYS
	mc.layer = 120
	mc.visible = true
	if mc._root == null:
		mc._setup_ui()
	mc.set_interact_visible(true)
	# Hai ngón: ngón 0 giữ joystick, ngón 1 chạm rồi thả chỗ khác không được làm joystick reset
	var base: Vector2 = mc._joystick_base.global_position
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.pressed = true
	down.position = base + Vector2(30, 0)
	mc._input(down)
	var other := InputEventScreenTouch.new()
	other.index = 1
	other.pressed = false
	other.position = Vector2(900, 300)
	mc._input(other)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = base + Vector2(60, -35)
	mc._input(drag)
	print("[Check] mobile joystick_touch=", mc._joystick_touch, " (mong đợi 0), dir=", mc._current_dir)
	var holder := Control.new()
	holder.add_child(_backdrop(Color.DARK_OLIVE_GREEN))
	holder.tree_exiting.connect(func():
		mc._reset_joystick()
		mc._is_mobile = false
		mc.visible = false)
	return holder

# Số sát thương nổi phải nằm trên thẻ HUD (lớp "ui_overlay")
func _build_floating() -> Node:
	_clear_systems()
	var battle := _build_battle()
	battle.ready.connect(func():
		for i in 6:
			await get_tree().process_frame # chờ bố cục thẻ xong để số nổi lên đúng chỗ
		var foes: Array = battle.enemy_team
		foes[0].take_damage(37)
		foes[1].set_meta("was_crit", true)
		foes[1].take_damage(88, "physical", true)
		foes[2].set_meta("was_broken", true)
		foes[2].take_damage(54)
		battle.player_team[0].take_damage(21, "dot"))
	return battle

# Kiểm tra luồng PauseMenu: Cài đặt từ StartMenu -> Đóng -> ESC trong game, ESC theo lớp, scene bị chặn, failsafe và modal
func _build_pause_flow() -> Node:
	_clear_systems()
	var ok := true
	PauseMenu.show_options(true)
	ok = ok and PauseMenu.visible and not get_tree().paused and PauseMenu._options_panel.visible
	PauseMenu._close_options()
	ok = ok and not PauseMenu.visible and not get_tree().paused and PauseMenu._root.visible and PauseMenu._panel.visible
	PauseMenu.toggle()
	ok = ok and PauseMenu.visible and get_tree().paused and PauseMenu._panel.visible and not PauseMenu._options_panel.visible
	ok = ok and not PauseMenu._btn_quick_save.visible
	PauseMenu._on_options()
	_press_esc()
	ok = ok and PauseMenu.visible and PauseMenu._panel.visible and not PauseMenu._options_panel.visible
	_press_esc()
	ok = ok and not PauseMenu.visible and not get_tree().paused
	var scene := get_tree().current_scene
	var scene_name := scene.name
	scene.name = "StartMenu"
	_press_esc()
	ok = ok and not PauseMenu.visible
	scene.name = scene_name
	GameManager.start_dialogue()
	PauseMenu.push_modal()
	_press_esc()
	ok = ok and not PauseMenu.visible and GameManager.is_in_dialogue
	PauseMenu.pop_modal()
	_press_esc()
	ok = ok and PauseMenu.visible and not GameManager.is_in_dialogue
	print("[Check] pause_flow ", "PASS" if ok else "FAIL")
	var holder := Control.new()
	holder.tree_exiting.connect(func():
		if PauseMenu.visible:
			PauseMenu.toggle())
	return holder

# Kiểm tra ScreenFade (fade mới thay fade cũ, không coroutine nào bị treo, busy về false) và ScreenShake (time_scale về 1.0 khi bị gỡ giữa hitstop)
func _build_fx_check() -> Node:
	var ok := true
	var state := {"a": false, "b": false}
	var run_a := func():
		await ScreenFade.fade_out(0.3)
		state["a"] = true
	var run_b := func():
		await get_tree().create_timer(0.1).timeout
		await ScreenFade.fade_in(0.2)
		state["b"] = true
	run_a.call()
	run_b.call()
	ok = ok and ScreenFade.busy
	await get_tree().create_timer(0.8).timeout
	ok = ok and state["a"] and state["b"] and not ScreenFade.busy and ScreenFade._rect.modulate.a == 0.0
	var shake := ScreenShake.new()
	add_child(shake)
	shake.hitstop(0.5)
	ok = ok and Engine.time_scale < 0.1
	shake.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	ok = ok and Engine.time_scale == 1.0
	print("[Check] fx ", "PASS" if ok else "FAIL", " ", state, " busy=", ScreenFade.busy, " scale=", Engine.time_scale)
	return Control.new()

func _press_esc():
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	PauseMenu._input(ev)
