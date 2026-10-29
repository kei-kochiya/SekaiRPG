extends Control

"""
SandboxMenu: Menu chế độ Sandbox cho phép tùy chỉnh trận đấu tự do.

- Chọn nhân vật phe ta (tối đa 4) độc lập, không làm biến đổi dữ liệu Party cốt truyện chính.
- Chọn kẻ địch (tối đa 5) bằng nút +/- cho từng loại, kèm nút xóa hết.
- Tùy chỉnh cấp độ riêng cho từng phe.
- Tích hợp UpgradeUI phân bổ SP giữ nguyên chỉ số khi vào trận.
- Giao diện dùng UITheme: ba cột (phe ta, phe địch, điều khiển) trên nền backdrop; "Bắt đầu" là hành động chính.
"""

const PLAYER_LIMIT = 4
const ENEMY_LIMIT = 5
const PLAYER_PANEL_WIDTH = 340
const CONTROLS_WIDTH = 288

var selected_players: Array = []
var selected_enemies: Array = []
var sandbox_player_instances: Dictionary = {}

var player_lv_spin: SpinBox
var enemy_lv_spin: SpinBox
var status_label: Label
var clear_enemy_btn: Button

var _enemy_rows: Dictionary = {}
var _enemy_count_label: Label

@onready var player_side: VBoxContainer = $HBox/PlayerPanel/PlayerSide
@onready var enemy_side: VBoxContainer = $HBox/EnemyPanel/EnemySide
@onready var controls_side: VBoxContainer = $HBox/Controls

func _ready():
	_apply_theme()
	_build_lists()
	_setup_controls()
	ScreenFade.fade_in(0.5)
	player_side.get_node("Scroll/CharList").get_child(0).call_deferred("grab_focus")

# ── Giao diện ──────────────────────────────────────────────────────────────

func _apply_theme():
	var backdrop = UITheme.backdrop()
	add_child(backdrop)
	move_child(backdrop, 0)

	var hbox: HBoxContainer = $HBox
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, UITheme.SP_8)
	hbox.add_theme_constant_override("separation", UITheme.SP_6)

	var player_panel: PanelContainer = $HBox/PlayerPanel
	player_panel.custom_minimum_size.x = PLAYER_PANEL_WIDTH
	_style_side(player_panel, player_side, UITheme.PLAYER)

	var enemy_panel: PanelContainer = $HBox/EnemyPanel
	enemy_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_side(enemy_panel, enemy_side, UITheme.ENEMY)

	controls_side.custom_minimum_size.x = CONTROLS_WIDTH
	controls_side.add_theme_constant_override("separation", UITheme.SP_3)

# Khung chung của một cột: viền màu phe, tiêu đề, danh sách cuộn và nhãn đếm
func _style_side(panel: PanelContainer, side: VBoxContainer, accent: Color):
	panel.add_theme_stylebox_override("panel", UITheme.panel(UITheme.INK_800, UITheme.INK_600, accent, UITheme.SP_6))
	side.add_theme_constant_override("separation", UITheme.SP_3)
	UITheme.style_title(side.get_node("Label"), UITheme.FS_HEADING, accent)

	var scroll: ScrollContainer = side.get_node("Scroll")
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 200
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true

	var count: Label = side.get_node("SelectedLabel")
	UITheme.style_label(count, UITheme.FS_BODY, UITheme.TEXT_MUTED)
	count.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _setup_controls():
	var upgrade_btn: Button = player_side.get_node("UpgradeBtn")
	UITheme.style_button(upgrade_btn, UITheme.Kind.SECONDARY)
	upgrade_btn.pressed.connect(_on_upgrade)

	var start_btn: Button = controls_side.get_node("StartBtn")
	UITheme.style_button(start_btn, UITheme.Kind.PRIMARY, UITheme.FS_HEADING)
	start_btn.custom_minimum_size.y = UITheme.MIN_TOUCH + UITheme.SP_2
	start_btn.pressed.connect(_on_start)

	var back_btn: Button = controls_side.get_node("BackBtn")
	UITheme.style_button(back_btn, UITheme.Kind.GHOST)
	back_btn.pressed.connect(_on_back)

	var title = Label.new()
	title.text = "Sandbox"
	UITheme.style_title(title, UITheme.FS_TITLE, UITheme.ACCENT)
	controls_side.add_child(title)
	controls_side.move_child(title, 0)

	var desc = UITheme.make_label("Tùy chỉnh trận đấu tự do: chọn đội hình hai phe rồi bắt đầu.", UITheme.FS_BODY, UITheme.TEXT_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_side.add_child(desc)
	controls_side.move_child(desc, 1)

	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_side.add_child(spacer)
	controls_side.move_child(spacer, 2)

	# Dòng báo lỗi/nhắc việc, chừa sẵn chỗ cho 3 dòng để bố cục không nhảy
	status_label = UITheme.make_label("", UITheme.FS_BODY, UITheme.TEXT)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 72
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	controls_side.add_child(status_label)
	controls_side.move_child(status_label, 3)

func _show_status(msg: String, color: Color = UITheme.TEXT):
	if status_label:
		status_label.text = msg
		status_label.add_theme_color_override("font_color", color)

# Hàng "Cấp độ" + ô nhập số, đặt ngay dưới tiêu đề cột
func _add_level_row(side: VBoxContainer) -> SpinBox:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SP_3)
	var lbl = UITheme.make_label("Cấp độ", UITheme.FS_LABEL, UITheme.TEXT)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var spin = SpinBox.new()
	spin.min_value = 1
	spin.max_value = 100
	spin.value = 10
	spin.custom_minimum_size = Vector2(144, UITheme.MIN_TOUCH)
	spin.get_line_edit().add_theme_font_size_override("font_size", UITheme.FS_LABEL)
	row.add_child(spin)

	side.add_child(row)
	side.move_child(row, 1)
	return spin

func _make_step_button(text: String, tip: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.tooltip_text = tip
	UITheme.style_button(btn, UITheme.Kind.SECONDARY, UITheme.FS_HEADING)
	btn.custom_minimum_size.x = UITheme.MIN_TOUCH
	return btn

func _build_lists():
	# ── Phe Ta ──
	player_lv_spin = _add_level_row(player_side)
	player_lv_spin.value_changed.connect(_on_player_lv_changed)

	var hover_row = UITheme.box(UITheme.INK_700, Color.TRANSPARENT, UITheme.RADIUS_SM, UITheme.SP_1, UITheme.SP_1)
	var char_list = player_side.get_node("Scroll/CharList")
	char_list.add_theme_constant_override("separation", UITheme.SP_1)
	for c_name in GameManager.available_sandbox_chars:
		var btn = CheckBox.new()
		btn.text = c_name
		btn.custom_minimum_size.y = UITheme.MIN_TOUCH
		btn.add_theme_font_size_override("font_size", UITheme.FS_LABEL)
		btn.add_theme_stylebox_override("hover", hover_row)
		btn.add_theme_stylebox_override("hover_pressed", hover_row)
		btn.toggled.connect(func(is_on): _on_player_toggled(is_on, c_name, btn))
		char_list.add_child(btn)
	_update_player_display()


	# ── Phe Địch ──
	enemy_lv_spin = _add_level_row(enemy_side)

	var enemy_list = enemy_side.get_node("Scroll/EnemyList")
	enemy_list.add_theme_constant_override("separation", UITheme.SP_1)
	var all_enemies = GameManager.available_sandbox_chars + GameManager.available_sandbox_monsters
	for e_name in all_enemies:
		_add_enemy_row(enemy_list, e_name)

	clear_enemy_btn = Button.new()
	clear_enemy_btn.text = "Xóa hết địch"
	UITheme.style_button(clear_enemy_btn, UITheme.Kind.GHOST, UITheme.FS_BODY)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		clear_enemy_btn.add_theme_color_override(color_name, UITheme.DANGER_TEXT)
	clear_enemy_btn.pressed.connect(_on_clear_enemies)
	_enemy_count_label = enemy_side.get_node("SelectedLabel")
	var enemy_footer = _make_footer(enemy_side, _enemy_count_label)
	enemy_footer.add_child(clear_enemy_btn)

	_update_enemy_display()

# Gộp nhãn đếm vào một hàng cuối cột để nút kèm theo nằm cùng dòng
func _make_footer(side: VBoxContainer, count_label: Label) -> HBoxContainer:
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", UITheme.SP_3)
	side.add_child(footer)
	count_label.reparent(footer)
	count_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return footer

func _add_enemy_row(parent: Control, e_name: String):
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SP_2)
	parent.add_child(row)

	var lbl = UITheme.make_label(e_name, UITheme.FS_LABEL, UITheme.TEXT)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl.clip_text = true
	lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(lbl)

	var minus = _make_step_button("-", "Bớt 1 " + e_name)
	minus.pressed.connect(_on_enemy_removed.bind(e_name))
	row.add_child(minus)

	var count = UITheme.make_label("0", UITheme.FS_LABEL, UITheme.TEXT_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	count.custom_minimum_size.x = 32
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(count)

	var plus = _make_step_button("+", "Thêm 1 " + e_name)
	plus.pressed.connect(_on_enemy_added.bind(e_name))
	row.add_child(plus)

	_enemy_rows[e_name] = {"count": count, "minus": minus, "plus": plus}

# ── Phe Ta ─────────────────────────────────────────────────────────────────

func _on_player_lv_changed(new_lv: float):
	var lv = int(new_lv)
	for c_name in sandbox_player_instances.keys():
		var p = sandbox_player_instances[c_name]
		LevelManager.set_initial_level(p, lv)

func _on_player_toggled(is_on: bool, c_name: String, chk: CheckBox):
	if is_on:
		if selected_players.size() >= PLAYER_LIMIT:
			chk.set_pressed_no_signal(false)
			_show_status("Phe ta tối đa %d nhân vật!" % PLAYER_LIMIT, UITheme.DANGER_TEXT)
			return
		if not selected_players.has(c_name):
			selected_players.append(c_name)
			if not sandbox_player_instances.has(c_name):
				var p = GameManager.create_sandbox_entity(c_name)
				LevelManager.set_initial_level(p, int(player_lv_spin.value))
				sandbox_player_instances[c_name] = p
	else:
		selected_players.erase(c_name)

	_update_player_display()

func _update_player_display():
	var text = "Đã chọn: %d/%d" % [selected_players.size(), PLAYER_LIMIT]
	if not selected_players.is_empty():
		text += " (%s)" % ", ".join(selected_players)
	player_side.get_node("SelectedLabel").text = text
	_show_status("")

# ── Phe Địch ───────────────────────────────────────────────────────────────

func _on_enemy_added(e_name: String):
	if selected_enemies.size() >= ENEMY_LIMIT:
		_show_status("Phe địch tối đa %d đơn vị!" % ENEMY_LIMIT, UITheme.DANGER_TEXT)
		return
	selected_enemies.append(e_name)
	_update_enemy_display()

func _on_enemy_removed(e_name: String):
	var idx = selected_enemies.rfind(e_name)
	if idx >= 0:
		selected_enemies.remove_at(idx)
	_update_enemy_display()
	# Nút "-" vừa hết lượt bấm: chuyển focus sang "+" cùng hàng
	var ref: Dictionary = _enemy_rows.get(e_name, {})
	if not ref.is_empty() and ref["minus"].disabled and ref["minus"].has_focus():
		ref["plus"].grab_focus()

func _on_clear_enemies():
	selected_enemies.clear()
	_update_enemy_display()
	if not _enemy_rows.is_empty():
		_enemy_rows.values()[0]["plus"].grab_focus()

func _update_enemy_display():
	var counts := {}
	for e_name in selected_enemies:
		counts[e_name] = counts.get(e_name, 0) + 1

	for e_name in _enemy_rows:
		var n: int = counts.get(e_name, 0)
		var ref: Dictionary = _enemy_rows[e_name]
		ref["count"].text = str(n)
		ref["count"].add_theme_color_override("font_color", UITheme.ACCENT if n > 0 else UITheme.TEXT_MUTED)
		ref["minus"].disabled = (n == 0)

	_enemy_count_label.text = "Đã chọn: %d/%d" % [selected_enemies.size(), ENEMY_LIMIT]
	clear_enemy_btn.disabled = selected_enemies.is_empty()
	_show_status("")

# ── Điều Khiển ─────────────────────────────────────────────────────────────

func _on_upgrade():
	if selected_players.is_empty():
		_show_status("Hãy chọn nhân vật trước khi nâng cấp!", UITheme.WARNING)
		return

	var entities: Array[Entity] = []
	for p_name in selected_players:
		var p = sandbox_player_instances.get(p_name)
		if p:
			entities.append(p)

	UpgradeUI.show_ui(entities)

func _on_start():
	if selected_players.is_empty():
		_show_status("Vui lòng chọn ít nhất 1 nhân vật phe ta!", UITheme.DANGER_TEXT)
		return

	if selected_enemies.is_empty():
		_show_status("Vui lòng chọn ít nhất 1 kẻ địch!", UITheme.DANGER_TEXT)
		return

	GameManager.is_sandbox = true
	GameManager.sandbox_player_team.clear()
	GameManager.sandbox_enemy_team.clear()

	# Nạp các nhân vật phe ta độc lập (đã qua nâng cấp SP)
	for p_name in selected_players:
		var p = sandbox_player_instances[p_name]
		GameManager.sandbox_player_team.append(p)

	# Khởi tạo phe địch
	var e_lv = int(enemy_lv_spin.value)
	for e_name in selected_enemies:
		var enemy = GameManager.create_sandbox_entity(e_name)
		LevelManager.set_initial_level(enemy, e_lv)
		GameManager.sandbox_enemy_team.append(enemy)

	await ScreenFade.fade_out(0.5)
	GameManager.trigger_battle()

func _on_back():
	GameManager.is_sandbox = false
	GameManager.sandbox_player_team.clear()
	GameManager.sandbox_enemy_team.clear()
	await ScreenFade.fade_out(0.5)
	get_tree().change_scene_to_file("res://UI/Menus/Start/StartMenu.tscn")
