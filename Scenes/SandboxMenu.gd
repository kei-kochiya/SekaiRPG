extends Control

var selected_players: Array = []
var selected_enemies: Array = []
var player_lv_spin: SpinBox
var enemy_lv_spin: SpinBox

var available_chars = ["Ichika", "Kanade", "Mafuyu", "Ena", "Mizuki", "Honami"]
var available_monsters = ["Lính Cảng", "Kidnapper", "Target", "Nhân Viên Kho", "Đội Trưởng (BOSS)"]

func _ready():
	_build_lists()
	_apply_kenney_styles()
	$HBox/PlayerSide/UpgradeBtn.pressed.connect(_on_upgrade)
	$HBox/Controls/StartBtn.pressed.connect(_on_start)
	$HBox/Controls/BackBtn.pressed.connect(_on_back)
	
	ScreenFade.fade_in(0.5)

func _apply_kenney_styles():
	for btn in [$HBox/PlayerSide/UpgradeBtn, $HBox/Controls/StartBtn, $HBox/Controls/BackBtn]:
		var ns = StyleBoxTexture.new()
		ns.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg")
		ns.texture_margin_left = 10
		ns.texture_margin_right = 10
		ns.texture_margin_top = 10
		ns.texture_margin_bottom = 14
		btn.add_theme_stylebox_override("normal", ns)
		btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))

func _build_lists():
	# Player list (Characters only)
	for c_name in available_chars:
		var btn = CheckBox.new()
		btn.text = c_name
		btn.toggled.connect(_on_player_toggled.bind(c_name))
		$HBox/PlayerSide/Scroll/CharList.add_child(btn)
	
	var pl_box = HBoxContainer.new()
	var pl_lbl = Label.new()
	pl_lbl.text = "Level Phe Ta: "
	pl_box.add_child(pl_lbl)
	player_lv_spin = SpinBox.new()
	player_lv_spin.min_value = 1; player_lv_spin.max_value = 100; player_lv_spin.value = 10
	pl_box.add_child(player_lv_spin)
	$HBox/PlayerSide.add_child(pl_box)
	$HBox/PlayerSide.move_child(pl_box, 2)
	
	# Enemy list (Characters + Monsters)
	var all_enemies = available_chars + available_monsters
	
	var el_box = HBoxContainer.new()
	var el_lbl = Label.new()
	el_lbl.text = "Level Phe Địch: "
	el_box.add_child(el_lbl)
	enemy_lv_spin = SpinBox.new()
	enemy_lv_spin.min_value = 1; enemy_lv_spin.max_value = 100; enemy_lv_spin.value = 10
	el_box.add_child(enemy_lv_spin)
	$HBox/EnemySide.add_child(el_box)
	$HBox/EnemySide.move_child(el_box, 2)
	for e_name in all_enemies:
		var row = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = e_name
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)
		
		var add_btn = Button.new()
		add_btn.text = " + "
		var ans = StyleBoxTexture.new()
		ans.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg")
		ans.texture_margin_left = 6
		ans.texture_margin_right = 6
		ans.texture_margin_top = 6
		ans.texture_margin_bottom = 10
		add_btn.add_theme_stylebox_override("normal", ans)
		add_btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
		add_btn.pressed.connect(_on_enemy_added.bind(e_name))
		row.add_child(add_btn)
		
		$HBox/EnemySide/Scroll/EnemyList.add_child(row)

func _on_player_toggled(is_on: bool, c_name: String):
	if is_on:
		if selected_players.size() < 4:
			selected_players.append(c_name)
		else:
			# Uncheck if full (visual only, logic below)
			pass
	else:
		selected_players.erase(c_name)
	
	$HBox/PlayerSide/SelectedLabel.text = "Đã chọn: %d/4" % selected_players.size()

func _on_enemy_added(e_name: String):
	if selected_enemies.size() < 5:
		selected_enemies.append(e_name)
		_update_enemy_display()

func _update_enemy_display():
	$HBox/EnemySide/SelectedLabel.text = "Đã chọn: %d/5 (%s)" % [selected_enemies.size(), ", ".join(selected_enemies)]
	# Simple clear/re-add or just label for now. 
	# Let's add a way to remove enemies.
	if $HBox/EnemySide/SelectedLabel.has_meta("clear_btn"):
		return
	
	var clear_btn = Button.new()
	clear_btn.text = "Xóa hết địch"
	var cns = StyleBoxTexture.new()
	cns.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/button_red.svg")
	cns.texture_margin_left = 10
	cns.texture_margin_right = 10
	cns.texture_margin_top = 10
	cns.texture_margin_bottom = 14
	clear_btn.add_theme_stylebox_override("normal", cns)
	clear_btn.pressed.connect(func(): 
		selected_enemies.clear()
		_update_enemy_display()
	)
	$HBox/EnemySide.add_child(clear_btn)
	$HBox/EnemySide/SelectedLabel.set_meta("clear_btn", true)

func _on_upgrade():
	if selected_players.is_empty():
		return
	
	var entities: Array[Entity] = []
	var target_lv = int(player_lv_spin.value)
	for p_name in selected_players:
		var p = GameManager.get_party_member(p_name)
		LevelManager.set_initial_level(p, target_lv)
		entities.append(p)
	
	UpgradeUI.show_ui(entities)

func _on_start():
	if selected_players.is_empty() or selected_enemies.is_empty():
		return
	
	GameManager.is_sandbox = true
	GameManager.sandbox_player_team.clear()
	GameManager.sandbox_enemy_team.clear()
	
	# Setup Players
	var p_lv = int(player_lv_spin.value)
	for p_name in selected_players:
		var p = GameManager.get_party_member(p_name)
		LevelManager.set_initial_level(p, p_lv)
		GameManager.sandbox_player_team.append(p)
	
	# Setup Enemies
	var e_lv = int(enemy_lv_spin.value)
	for e_name in selected_enemies:
		var enemy = _create_sandbox_entity(e_name)
		LevelManager.set_initial_level(enemy, e_lv)
		GameManager.sandbox_enemy_team.append(enemy)
	
	await ScreenFade.fade_out(0.5)
	GameManager.trigger_battle()

func _on_back():
	await ScreenFade.fade_out(0.5)
	get_tree().change_scene_to_file("res://Scenes/StartMenu.tscn")

func _create_sandbox_entity(e_name: String) -> Entity:
	# If it's a character name, create a NEW instance so it doesn't share state with party
	match e_name:
		"Ichika": return Ichika.new()
		"Kanade": return Kanade.new()
		"Mafuyu": return Mafuyu.new()
		"Ena": return Ena.new()
		"Mizuki": return Mizuki.new()
		"Honami": return Honami.new()
		"Lính Cảng":
			var g = Entity.new()
			g.entity_name = "Lính Cảng"
			g.max_hp = 250; g.current_hp = 250; g.atk = 75; g.defense = 40; g.spd = 95; g.type = "Hard"
			return g
		"Kidnapper":
			var k = Entity.new()
			k.entity_name = "Kidnapper"
			k.max_hp = 80; k.current_hp = 80; k.atk = 40; k.defense = 20; k.spd = 80; k.type = "None"
			k.skills = [{"name": "Shank", "method": "basic_attack", "cooldown_turns": 1}]
			return k
		"Target":
			var t = Entity.new()
			t.entity_name = "Target"
			t.max_hp = 100; t.current_hp = 100; t.atk = 45; t.defense = 25; t.spd = 90; t.type = "None"
			return t
		"Nhân Viên Kho":
			var w = WarehouseWorker.new()
			return w
		"Đội Trưởng (BOSS)":
			var b = Entity.new()
			b.entity_name = "Đội Trưởng"
			b.max_hp = 3500; b.current_hp = 3500; b.atk = 240; b.defense = 130; b.spd = 110; b.type = "Hard"
			b.skills = [{"name": "Execution", "method": "basic_attack", "cooldown_turns": 1}]
			return b
	return Entity.new()
