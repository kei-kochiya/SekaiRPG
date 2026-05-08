extends CanvasLayer

# ── Nodes ──────────────────────────────────────────────────────────────────
var _root: Control
var _dialogue_layer: Control
var _narrator_layer: Control

var panel: PanelContainer
var rich_text: RichTextLabel
var left_portrait: TextureRect
var right_portrait: TextureRect

var _narrator_panel: PanelContainer
var _narrator_label: RichTextLabel

# Choice UI
var _choice_panel: PanelContainer
var _choice_vbox: VBoxContainer
var _in_choice: bool = false
signal choice_made(index: int)

# ── State ──────────────────────────────────────────────────────────────────
var current_dialogue: Array = []
var index: int   = 0
var active: bool = false
var _callback: Callable

# ── Setup ──────────────────────────────────────────────────────────────────
func _ready() -> void:
	layer = 100
	visible = false

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_narrator_layer()
	_build_dialogue_layer()

func _build_narrator_layer() -> void:
	_narrator_layer = Control.new()
	_narrator_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_narrator_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_narrator_layer)

	_narrator_panel = PanelContainer.new()
	_narrator_panel.set_anchors_preset(Control.PRESET_CENTER)
	_narrator_panel.offset_left   = -480
	_narrator_panel.offset_right  =  480
	_narrator_panel.offset_top    = -54
	_narrator_panel.offset_bottom =  54
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0, 0, 0, 0.82)
	s.set_content_margin_all(20)
	_narrator_panel.add_theme_stylebox_override("panel", s)
	_narrator_layer.add_child(_narrator_panel)

	_narrator_label = RichTextLabel.new()
	_narrator_label.bbcode_enabled = true
	_narrator_label.fit_content = true
	_narrator_label.add_theme_font_size_override("normal_font_size", 18)
	_narrator_panel.add_child(_narrator_label)
	_narrator_layer.visible = false

func _build_dialogue_layer() -> void:
	_dialogue_layer = Control.new()
	_dialogue_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialogue_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_dialogue_layer)

	# Portraits
	left_portrait = TextureRect.new()
	left_portrait.custom_minimum_size = Vector2(256, 256)
	left_portrait.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	left_portrait.offset_left   = 80
	left_portrait.offset_top    = -456 # 256 (height) + 200 (box height)
	left_portrait.pivot_offset  = Vector2(128, 256)
	left_portrait.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
	left_portrait.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_layer.add_child(left_portrait)

	right_portrait = TextureRect.new()
	right_portrait.custom_minimum_size = Vector2(256, 256)
	right_portrait.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	right_portrait.offset_right  = -80
	right_portrait.offset_left   = -336 # -80 - 256
	right_portrait.offset_top    = -456
	right_portrait.pivot_offset  = Vector2(128, 256)
	right_portrait.stretch_mode  = TextureRect.STRETCH_KEEP_ASPECT
	right_portrait.expand_mode   = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_layer.add_child(right_portrait)

	# Text box
	panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top    = -200
	panel.offset_bottom = -30
	panel.offset_left   =  100
	panel.offset_right  = -100
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_color = Color(0.3, 0.3, 0.3)
	style.set_border_width_all(2)
	style.set_content_margin_all(25)
	panel.add_theme_stylebox_override("panel", style)
	_dialogue_layer.add_child(panel)

	rich_text = RichTextLabel.new()
	rich_text.bbcode_enabled = true
	rich_text.add_theme_font_size_override("normal_font_size", 20)
	panel.add_child(rich_text)

	# ── Choice panel (sits above the text box) ──
	_choice_panel = PanelContainer.new()
	_choice_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_choice_panel.offset_top    = -390
	_choice_panel.offset_bottom = -215
	_choice_panel.offset_left   =  200
	_choice_panel.offset_right  = -200
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.08, 0.08, 0.14, 0.97)
	cs.border_color = Color(0.4, 0.5, 0.8)
	cs.set_border_width_all(2)
	cs.corner_radius_top_left     = 6
	cs.corner_radius_top_right    = 6
	cs.corner_radius_bottom_left  = 6
	cs.corner_radius_bottom_right = 6
	cs.set_content_margin_all(16)
	_choice_panel.add_theme_stylebox_override("panel", cs)

	_choice_vbox = VBoxContainer.new()
	_choice_vbox.add_theme_constant_override("separation", 8)
	_choice_panel.add_child(_choice_vbox)
	_dialogue_layer.add_child(_choice_panel)
	_choice_panel.visible = false

	_dialogue_layer.visible = false

# ── Public API ─────────────────────────────────────────────────────────────
func play_dialogue(lines: Array, on_complete: Callable = Callable()) -> void:
	if active or lines.is_empty():
		if lines.is_empty():
			print("[DialogueManager] WARNING: Attempted to play empty dialogue!")
			if on_complete.is_valid(): on_complete.call()
		return
	
	_clear_portraits()
	current_dialogue = lines
	_callback = on_complete
	index = 0
	active = true
	GameManager.start_dialogue()
	visible = true
	_show_current_line()

## Show a choice menu and emit choice_made(index) when the player picks.
## Caller should:  DialogueManager.show_choice([...])
##                 var idx = await DialogueManager.choice_made
func show_choice(options: Array) -> void:
	visible = true
	_dialogue_layer.visible = true
	_choice_panel.visible = true
	_in_choice = true
	GameManager.start_dialogue()
	_clear_portraits()

	# Clear old buttons
	for c in _choice_vbox.get_children():
		c.queue_free()
	await get_tree().process_frame

	for i in options.size():
		var btn := Button.new()
		btn.text = options[i]
		btn.flat = false
		var bs := StyleBoxFlat.new()
		bs.bg_color = Color(0.12, 0.12, 0.22)
		bs.border_color = Color(0.35, 0.45, 0.75)
		bs.set_border_width_all(1)
		bs.set_content_margin_all(10)
		bs.corner_radius_top_left     = 4
		bs.corner_radius_top_right    = 4
		bs.corner_radius_bottom_left  = 4
		bs.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", bs)
		var bh := bs.duplicate() as StyleBoxFlat
		bh.bg_color = Color(0.22, 0.28, 0.55)
		btn.add_theme_stylebox_override("hover", bh)
		btn.add_theme_stylebox_override("focus", bh)
		btn.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
		btn.add_theme_font_size_override("font_size", 17)
		btn.pressed.connect(_on_choice_selected.bind(i))
		_choice_vbox.add_child(btn)

	# Focus first option for keyboard nav
	if _choice_vbox.get_child_count() > 0:
		_choice_vbox.get_child(0).grab_focus()

func _on_choice_selected(idx: int) -> void:
	_choice_panel.visible = false
	_in_choice = false
	# Hide whole overlay if nothing else is active
	if not active:
		_clear_portraits()
		visible = false
		GameManager.end_dialogue()
	choice_made.emit(idx)

# ── Input ──────────────────────────────────────────────────────────────────
func _process(_delta) -> void:
	if _in_choice or not active:
		return
	if Input.is_action_just_pressed("ui_accept"):
		index += 1
		if index < current_dialogue.size():
			_show_current_line()
		else:
			_end_dialogue()

func _end_dialogue() -> void:
	active = false
	visible = false
	_dialogue_layer.visible = false
	_narrator_layer.visible = false
	_clear_portraits()
	await get_tree().process_frame
	GameManager.end_dialogue()
	if _callback.is_valid():
		_callback.call()

# ── Rendering ──────────────────────────────────────────────────────────────
func _clear_portraits():
	left_portrait.texture = null
	right_portrait.texture = null
	left_portrait.modulate = Color.WHITE
	right_portrait.modulate = Color.WHITE
	left_portrait.scale = Vector2.ONE
	right_portrait.scale = Vector2.ONE

func _show_current_line() -> void:
	var line: Dictionary = current_dialogue[index]
	var kind:     String = line.get("type",    "dialogue")
	var speaker:  String = line.get("speaker", "left")
	var name_tag: String = line.get("name",    "")
	var color:    Color  = line.get("color",   Color.WHITE)
	var text:     String = line.get("text",    "")

	match kind:
		"narrator":
			_show_narrator(text)
		"action":
			_show_dialogue(speaker, name_tag, color, "[i]" + text + "[/i]")
		_:
			_show_dialogue(speaker, name_tag, color, text)

func _show_narrator(text: String) -> void:
	_narrator_layer.visible = true
	_dialogue_layer.visible = false
	_narrator_label.text = "[center][color=#ddddcc]" + text + "[/color][/center]"
	_narrator_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_narrator_panel, "modulate:a", 1.0, 0.35)

func _show_dialogue(speaker: String, name_tag: String, color: Color, text: String) -> void:
	_narrator_layer.visible = false
	_dialogue_layer.visible = true

	rich_text.text = "[color=#%s]%s:[/color]\n\n%s" % [
		color.to_html(false), name_tag, text
	]

	var portrait_path := "res://Art/Portraits/%s.png" % name_tag.to_lower()
	var tex: Texture2D = null
	if ResourceLoader.exists(portrait_path):
		tex = load(portrait_path) as Texture2D
	
	if speaker == "left":
		# If this character was on the right, clear the right
		if right_portrait.texture == tex: right_portrait.texture = null
		left_portrait.texture = tex
	else:
		# If this character was on the left, clear the left
		if left_portrait.texture == tex: left_portrait.texture = null
		right_portrait.texture = tex

	var tw := create_tween()
	tw.set_parallel(true)
	if speaker == "left":
		tw.tween_property(left_portrait,  "scale",    Vector2(1.05, 1.05), 0.15)
		tw.tween_property(left_portrait,  "modulate", Color(1, 1, 1, 1),             0.15)
		tw.tween_property(right_portrait, "scale",    Vector2(0.9, 0.9),   0.15)
		tw.tween_property(right_portrait, "modulate", Color(0.35, 0.35, 0.35, 1),    0.15)
	else:
		tw.tween_property(right_portrait, "scale",    Vector2(1.05, 1.05), 0.15)
		tw.tween_property(right_portrait, "modulate", Color(1, 1, 1, 1),             0.15)
		tw.tween_property(left_portrait,  "scale",    Vector2(0.9, 0.9),   0.15)
		tw.tween_property(left_portrait,  "modulate", Color(0.35, 0.35, 0.35, 1),    0.15)
