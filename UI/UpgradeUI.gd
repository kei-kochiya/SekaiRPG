extends CanvasLayer

## UI for spending Skill Points (SP) on character stats.
## Displays character list and stat upgrade buttons.

signal closed

const THEME_COLOR = Color(0.2, 0.6, 0.8)
const BG_COLOR = Color(0.05, 0.05, 0.08, 0.9)

var characters: Array[Entity] = []
var selected_index: int = 0

var char_list: VBoxContainer
var stat_vbox: VBoxContainer
var sp_label: Label
var char_name_label: Label

func _ready():
	_build_ui()
	visible = false

func show_ui(chars: Array[Entity]):
	characters = chars
	selected_index = 0
	visible = true
	_refresh_all()

func _build_ui():
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 400)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = BG_COLOR
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = THEME_COLOR
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	
	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 20)
	panel.add_child(main_hbox)
	
	# -- Left: Character List --
	var left_vbox = VBoxContainer.new()
	left_vbox.custom_minimum_size = Vector2(150, 0)
	main_hbox.add_child(left_vbox)
	
	var list_title = Label.new()
	list_title.text = "NHÂN VẬT"
	list_title.add_theme_color_override("font_color", THEME_COLOR)
	left_vbox.add_child(list_title)
	
	char_list = VBoxContainer.new()
	char_list.name = "CharList"
	left_vbox.add_child(char_list)
	
	# -- Right: Stats & Upgrades --
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_vbox)
	
	char_name_label = Label.new()
	char_name_label.name = "CharNameLabel"
	char_name_label.text = "NAME"
	char_name_label.add_theme_font_size_override("font_size", 24)
	right_vbox.add_child(char_name_label)
	
	sp_label = Label.new()
	sp_label.name = "SPLabel"
	sp_label.text = "Skill Points: 0"
	sp_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	right_vbox.add_child(sp_label)
	
	var sep = ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color(0.3, 0.3, 0.3)
	right_vbox.add_child(sep)
	
	stat_vbox = VBoxContainer.new()
	stat_vbox.name = "StatVBox"
	stat_vbox.add_theme_constant_override("separation", 10)
	right_vbox.add_child(stat_vbox)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = " ĐÓNG "
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_btn.pressed.connect(func(): 
		visible = false
		closed.emit()
	)
	right_vbox.add_child(Control.new()) # spacer
	right_vbox.add_child(close_btn)

func _refresh_all():
	# Refresh character list
	for c in char_list.get_children(): c.queue_free()
	for i in range(characters.size()):
		var btn = Button.new()
		btn.text = characters[i].entity_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if i == selected_index:
			btn.modulate = Color(1.5, 1.5, 1.5)
		btn.pressed.connect(func():
			selected_index = i
			_refresh_all()
		)
		char_list.add_child(btn)
	
	var char = characters[selected_index]
	char_name_label.text = char.entity_name.to_upper() + " - Lv." + str(char.level)
	sp_label.text = "Skill Points: " + str(char.skill_points)
	
	# Refresh stats
	for c in stat_vbox.get_children(): c.queue_free()
	
	var stats_to_show = ["max_hp", "atk", "defense", "spd"]
	var labels = {
		"max_hp": "Máu (HP)",
		"atk": "Tấn công (ATK)",
		"defense": "Phòng thủ (DEF)",
		"spd": "Tốc độ (SPD)"
	}
	
	for stat in stats_to_show:
		var row = HBoxContainer.new()
		stat_vbox.add_child(row)
		
		var name_lbl = Label.new()
		name_lbl.text = labels[stat]
		name_lbl.custom_minimum_size = Vector2(120, 0)
		row.add_child(name_lbl)
		
		var val_lbl = Label.new()
		val_lbl.text = str(char.get(stat))
		val_lbl.custom_minimum_size = Vector2(60, 0)
		row.add_child(val_lbl)
		
		var plus_btn = Button.new()
		plus_btn.text = " + "
		plus_btn.disabled = char.skill_points < UpgradeManager.UPGRADE_COST
		plus_btn.pressed.connect(func():
			if UpgradeManager.upgrade_stat(char, stat):
				_refresh_all()
		)
		row.add_child(plus_btn)
		
		var inc_lbl = Label.new()
		inc_lbl.text = "(+%d)" % UpgradeManager.UPGRADE_AMOUNTS[stat]
		inc_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		inc_lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(inc_lbl)
