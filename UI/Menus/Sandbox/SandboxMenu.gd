extends Control

"""
SandboxMenu: Menu chế độ Sandbox cho phép tùy chỉnh trận đấu tự do.

- Chọn nhân vật phe ta (tối đa 4) độc lập, không làm biến đổi dữ liệu Party cốt truyện chính.
- Chọn kẻ địch (tối đa 5) kèm nút xóa từng con hoặc xóa hết.
- Tùy chỉnh cấp độ riêng cho từng phe.
- Tích hợp UpgradeUI phân bổ SP giữ nguyên chỉ số khi vào trận.
- Giao diện góc cạnh tone nâu / espresso cổ điển với viền vàng kim.
"""

var selected_players: Array = []
var selected_enemies: Array = []
var sandbox_player_instances: Dictionary = {}

var player_lv_spin: SpinBox
var enemy_lv_spin: SpinBox
var status_label: Label
var selected_enemy_container: VBoxContainer
var clear_enemy_btn: Button

@onready var player_side: VBoxContainer = $HBox/PlayerPanel/PlayerSide
@onready var enemy_side: VBoxContainer = $HBox/EnemyPanel/EnemySide
@onready var controls_side: VBoxContainer = $HBox/Controls

func _ready():
	_apply_modern_theme()
	_build_lists()
	_setup_controls()
	ScreenFade.fade_in(0.5)

func _style_button(btn: Button, normal_svg: String, hover_svg: String, font_color: Color):
	var ns = StyleBoxTexture.new()
	ns.texture = load(normal_svg)
	ns.texture_margin_left = 8
	ns.texture_margin_right = 8
	ns.texture_margin_top = 8
	ns.texture_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", ns)
	
	if hover_svg != "":
		var hs = StyleBoxTexture.new()
		hs.texture = load(hover_svg)
		hs.texture_margin_left = 8
		hs.texture_margin_right = 8
		hs.texture_margin_top = 8
		hs.texture_margin_bottom = 12
		btn.add_theme_stylebox_override("hover", hs)
		btn.add_theme_stylebox_override("focus", hs)
	else:
		btn.add_theme_stylebox_override("hover", ns)
		btn.add_theme_stylebox_override("focus", ns)
		
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.5, 0.45))

func _apply_modern_theme():
	$BG.color = Color(0.09, 0.07, 0.06, 1.0)
	
	var panel_sb = StyleBoxTexture.new()
	panel_sb.texture = load("res://Assets/UI/panel_angular_brown.svg")
	panel_sb.texture_margin_left = 16
	panel_sb.texture_margin_right = 16
	panel_sb.texture_margin_top = 16
	panel_sb.texture_margin_bottom = 16
	panel_sb.content_margin_left = 20
	panel_sb.content_margin_right = 20
	panel_sb.content_margin_top = 20
	panel_sb.content_margin_bottom = 20
	
	$HBox/PlayerPanel.add_theme_stylebox_override("panel", panel_sb)
	$HBox/EnemyPanel.add_theme_stylebox_override("panel", panel_sb)
	
	# Style buttons with sharp angular brown theme
	_style_button(player_side.get_node("UpgradeBtn"), "res://Assets/UI/btn_angular_brown.svg", "res://Assets/UI/btn_angular_brown_hover.svg", Color(0.96, 0.92, 0.85))
	_style_button(controls_side.get_node("StartBtn"), "res://Assets/UI/btn_angular_amber.svg", "res://Assets/UI/btn_angular_amber_hover.svg", Color(0.98, 0.90, 0.75))
	_style_button(controls_side.get_node("BackBtn"), "res://Assets/UI/btn_angular_red.svg", "", Color(1.0, 0.88, 0.88))

func _setup_controls():
	player_side.get_node("UpgradeBtn").pressed.connect(_on_upgrade)
	controls_side.get_node("StartBtn").pressed.connect(_on_start)
	controls_side.get_node("BackBtn").pressed.connect(_on_back)
	
	# Status warning label
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.custom_minimum_size = Vector2(160, 40)
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.text = ""
	controls_side.add_child(status_label)

func _show_status(msg: String, color: Color = Color.WHITE):
	if status_label:
		status_label.text = msg
		status_label.add_theme_color_override("font_color", color)

func _build_lists():
	# ── Phe Ta ──
	player_side.get_node("Label").add_theme_color_override("font_color", Color(0.96, 0.85, 0.62))
	for c_name in GameManager.available_sandbox_chars:
		var btn = CheckBox.new()
		btn.text = c_name
		btn.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82))
		btn.toggled.connect(func(is_on): _on_player_toggled(is_on, c_name, btn))
		player_side.get_node("Scroll/CharList").add_child(btn)
	
	var pl_box = HBoxContainer.new()
	var pl_lbl = Label.new()
	pl_lbl.text = "Level Phe Ta: "
	pl_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82))
	pl_box.add_child(pl_lbl)
	player_lv_spin = SpinBox.new()
	player_lv_spin.min_value = 1
	player_lv_spin.max_value = 100
	player_lv_spin.value = 10
	player_lv_spin.value_changed.connect(_on_player_lv_changed)
	pl_box.add_child(player_lv_spin)
	player_side.add_child(pl_box)
	player_side.move_child(pl_box, 2)
	_update_player_display()
	
	# ── Phe Địch ──
	enemy_side.get_node("Label").add_theme_color_override("font_color", Color(0.92, 0.70, 0.60))
	var all_enemies = GameManager.available_sandbox_chars + GameManager.available_sandbox_monsters
	
	var el_box = HBoxContainer.new()
	var el_lbl = Label.new()
	el_lbl.text = "Level Phe Địch: "
	el_lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82))
	el_box.add_child(el_lbl)
	enemy_lv_spin = SpinBox.new()
	enemy_lv_spin.min_value = 1
	enemy_lv_spin.max_value = 100
	enemy_lv_spin.value = 10
	el_box.add_child(enemy_lv_spin)
	enemy_side.add_child(el_box)
	enemy_side.move_child(el_box, 2)
	
	for e_name in all_enemies:
		var row = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = e_name
		lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		
		var add_btn = Button.new()
		add_btn.text = " + "
		_style_button(add_btn, "res://Assets/UI/btn_angular_brown.svg", "res://Assets/UI/btn_angular_brown_hover.svg", Color(0.96, 0.92, 0.85))
		add_btn.pressed.connect(_on_enemy_added.bind(e_name))
		row.add_child(add_btn)
		
		enemy_side.get_node("Scroll/EnemyList").add_child(row)
		
	# Container hiển thị danh sách địch đã chọn
	selected_enemy_container = VBoxContainer.new()
	enemy_side.add_child(selected_enemy_container)
	
	clear_enemy_btn = Button.new()
	clear_enemy_btn.text = "Xóa hết địch"
	_style_button(clear_enemy_btn, "res://Assets/UI/btn_angular_red.svg", "", Color(1.0, 0.88, 0.88))
	clear_enemy_btn.pressed.connect(func():
		selected_enemies.clear()
		_update_enemy_display()
	)
	enemy_side.add_child(clear_enemy_btn)
	clear_enemy_btn.visible = false
	
	_update_enemy_display()


func _on_player_lv_changed(new_lv: float):
	var lv = int(new_lv)
	for c_name in sandbox_player_instances.keys():
		var p = sandbox_player_instances[c_name]
		LevelManager.set_initial_level(p, lv)

func _on_player_toggled(is_on: bool, c_name: String, chk: CheckBox):
	if is_on:
		if selected_players.size() >= 4:
			chk.set_pressed_no_signal(false)
			_show_status("Phe ta tối đa 4 nhân vật!", Color(1.0, 0.4, 0.4))
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
	player_side.get_node("SelectedLabel").text = "Đã chọn: %d/4 (%s)" % [selected_players.size(), ", ".join(selected_players)]
	player_side.get_node("SelectedLabel").add_theme_color_override("font_color", Color(0.85, 0.78, 0.68))
	_show_status("")

func _on_enemy_added(e_name: String):
	if selected_enemies.size() >= 5:
		_show_status("Phe địch tối đa 5 đơn vị!", Color(1.0, 0.4, 0.4))
		return
	selected_enemies.append(e_name)
	_update_enemy_display()

func _update_enemy_display():
	enemy_side.get_node("SelectedLabel").text = "Đã chọn: %d/5" % selected_enemies.size()
	enemy_side.get_node("SelectedLabel").add_theme_color_override("font_color", Color(0.85, 0.78, 0.68))
	
	for child in selected_enemy_container.get_children():
		child.queue_free()
		
	for i in range(selected_enemies.size()):
		var e_name = selected_enemies[i]
		var chip = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = "%d. %s" % [i + 1, e_name]
		lbl.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82))
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.add_child(lbl)
		
		var rm_btn = Button.new()
		rm_btn.text = " x "
		_style_button(rm_btn, "res://Assets/UI/btn_angular_red.svg", "", Color(1.0, 0.9, 0.92))
		var idx = i
		rm_btn.pressed.connect(func():
			selected_enemies.remove_at(idx)
			_update_enemy_display()
		)
		chip.add_child(rm_btn)
		selected_enemy_container.add_child(chip)
		
	clear_enemy_btn.visible = not selected_enemies.is_empty()
	_show_status("")

func _on_upgrade():
	if selected_players.is_empty():
		_show_status("Hãy chọn nhân vật trước khi nâng cấp!", Color(1.0, 0.7, 0.3))
		return
	
	var entities: Array[Entity] = []
	for p_name in selected_players:
		var p = sandbox_player_instances.get(p_name)
		if p:
			entities.append(p)
	
	UpgradeUI.show_ui(entities)

func _on_start():
	if selected_players.is_empty():
		_show_status("Vui lòng chọn ít nhất 1 nhân vật phe ta!", Color(1.0, 0.4, 0.4))
		return
		
	if selected_enemies.is_empty():
		_show_status("Vui lòng chọn ít nhất 1 kẻ địch!", Color(1.0, 0.4, 0.4))
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
