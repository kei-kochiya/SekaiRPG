extends CanvasLayer
class_name BattleHUD

## Master UI layer: assembles CharacterCards, ActionGauge, CommandMenu, and overlay.
## Renders on top of the game scene via CanvasLayer.

var player_cards: Dictionary = {}   # entity_name -> CharacterCard
var enemy_cards: Dictionary = {}
var action_gauge: ActionGauge
var command_menu: CommandMenu
var turn_label: Label
var overlay: Control                # floating text spawns here
var result_label: Label

func build(player_team: Array, enemy_team: Array):
	layer = 10
	
	# Clear old UI if rebuilding (reinforcements)
	for child in get_children():
		child.queue_free()
	player_cards.clear()
	enemy_cards.clear()
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	
	# --- Dark background fill ---
	var bg = ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.08, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	
	# --- Left column: Action Gauge ---
	var left_panel = PanelContainer.new()
	left_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left_panel.offset_right = 150
	var lps = StyleBoxFlat.new()
	lps.bg_color = Color(0.07, 0.07, 0.09, 0.9)
	lps.border_color = Color(0.15, 0.15, 0.15)
	lps.border_width_right = 1
	lps.set_content_margin_all(6)
	left_panel.add_theme_stylebox_override("panel", lps)
	left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left_panel)
	
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_panel.add_child(scroll)
	
	action_gauge = ActionGauge.new()
	scroll.add_child(action_gauge)
	
	# --- Top area: Character Cards ---
	# Player cards: Left Column
	var player_col = VBoxContainer.new()
	player_col.name = "PlayerColumn"
	player_col.position = Vector2(200, 80)
	player_col.add_theme_constant_override("separation", 10)
	root.add_child(player_col)
	
	for entity in player_team:
		var card = CharacterCard.new()
		card.setup(entity, true)
		player_col.add_child(card)
		player_cards[entity.entity_name] = card
	
	# Enemy cards: Right Column
	var enemy_col = VBoxContainer.new()
	enemy_col.name = "EnemyColumn"
	enemy_col.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	enemy_col.position = Vector2(-300, 80)
	enemy_col.add_theme_constant_override("separation", 10)
	root.add_child(enemy_col)
	
	for entity in enemy_team:
		var card = CharacterCard.new()
		card.setup(entity, false)
		enemy_col.add_child(card)
		enemy_cards[entity.entity_name] = card
	
	# --- Turn indicator (above command menu) ---
	turn_label = Label.new()
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	turn_label.offset_top = -320
	turn_label.offset_bottom = -240
	turn_label.offset_left = -150
	turn_label.offset_right = 150
	turn_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	turn_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	turn_label.add_theme_font_size_override("font_size", 18)
	
	var tb = StyleBoxTexture.new()
	tb.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/banner_modern.svg")
	tb.texture_margin_left = 20
	tb.texture_margin_right = 20
	tb.texture_margin_top = 20
	tb.texture_margin_bottom = 20
	turn_label.add_theme_stylebox_override("normal", tb)
	
	turn_label.visible = false
	root.add_child(turn_label)
	
	# --- Bottom center: Command Menu ---
	command_menu = CommandMenu.new()
	command_menu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	command_menu.offset_top = -20
	command_menu.offset_bottom = -20
	command_menu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	command_menu.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(command_menu)
	
	# --- Floating Text Overlay ---
	overlay = Control.new()
	overlay.name = "FloatingTextOverlay"
	overlay.add_to_group("ui_overlay")
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)
	
	# --- Result label (hidden until battle ends) ---
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.set_anchors_preset(Control.PRESET_CENTER)
	result_label.offset_left = -200
	result_label.offset_right = 200
	result_label.offset_top = -50
	result_label.offset_bottom = 50
	result_label.add_theme_font_size_override("font_size", 36)
	
	var rb = StyleBoxTexture.new()
	rb.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/banner_hanging.svg")
	rb.texture_margin_left = 32
	rb.texture_margin_right = 32
	rb.texture_margin_top = 32
	rb.texture_margin_bottom = 32
	result_label.add_theme_stylebox_override("normal", rb)
	
	result_label.visible = false
	root.add_child(result_label)

func show_turn_indicator(entity_name: String, is_player: bool):
	var color = Color(0.1, 0.2, 0.2) if is_player else Color(0.2, 0.1, 0.05)
	turn_label.text = "%s'S TURN" % entity_name.to_upper()
	turn_label.add_theme_color_override("font_color", color)
	turn_label.visible = true

func hide_turn_indicator():
	turn_label.visible = false

func show_result(text: String, color: Color):
	hide_turn_indicator()
	result_label.text = text
	result_label.add_theme_color_override("font_color", color)
	result_label.visible = true
	
	# Fade in
	result_label.modulate.a = 0.0
	var tween = result_label.create_tween()
	tween.tween_property(result_label, "modulate:a", 1.0, 0.6)
