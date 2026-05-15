extends Control
class_name DialogueUI

"""
DialogueUI: Thành phần giao diện của hệ thống hội thoại.

Lớp này tách biệt hoàn toàn logic hiển thị (vẽ khung, chạy chữ, chân dung) 
khỏi logic điều phối của DialogueManager.
"""

signal line_completed
signal choice_selected(idx: int)

var dialogue_box: PanelContainer
var text_label: RichTextLabel
var left_portrait: TextureRect
var right_portrait: TextureRect
var narrator_box: PanelContainer
var narrator_label: RichTextLabel
var choice_box: VBoxContainer
var choice_panel: PanelContainer

func _ready():
	# Ensure the root Control is full screen
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0
	offset_right = 0
	offset_top = 0
	offset_bottom = 0
	_init_ui()

func _init_ui():
	# Cấu trúc UI được di chuyển từ DialogueManager sang đây
	var d_layer = Control.new()
	d_layer.name = "DialogueLayer"
	d_layer.anchor_right = 1.0
	d_layer.anchor_bottom = 1.0
	d_layer.offset_left = 0
	d_layer.offset_right = 0
	d_layer.offset_top = 0
	d_layer.offset_bottom = 0
	d_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(d_layer)

	narrator_box = PanelContainer.new()
	narrator_box.set_anchors_preset(Control.PRESET_CENTER)
	narrator_box.offset_left = -400; narrator_box.offset_right = 400
	narrator_box.offset_top = -40; narrator_box.offset_bottom = 40
	narrator_box.add_theme_stylebox_override("panel", _get_style("panel_brown_dark.svg", 12, 20))
	d_layer.add_child(narrator_box)
	
	narrator_label = RichTextLabel.new()
	narrator_label.bbcode_enabled = true
	narrator_label.fit_content = true
	narrator_label.add_theme_font_size_override("normal_font_size", 18)
	narrator_box.add_child(narrator_label)
	narrator_box.visible = false

	left_portrait = _create_portrait(Control.PRESET_BOTTOM_LEFT, 80, -456)
	right_portrait = _create_portrait(Control.PRESET_BOTTOM_RIGHT, -336, -456)
	d_layer.add_child(left_portrait)
	d_layer.add_child(right_portrait)

	dialogue_box = PanelContainer.new()
	dialogue_box.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_box.offset_top = -200; dialogue_box.offset_bottom = -30
	dialogue_box.offset_left = 100; dialogue_box.offset_right = -100
	dialogue_box.add_theme_stylebox_override("panel", _get_style("panel_brown.svg", 12, 25))
	d_layer.add_child(dialogue_box)

	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.add_theme_font_size_override("normal_font_size", 20)
	text_label.add_theme_color_override("default_color", Color(0.15, 0.08, 0.05))
	dialogue_box.add_child(text_label)

	choice_panel = PanelContainer.new()
	choice_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	choice_panel.offset_top = -390; choice_panel.offset_bottom = -215
	choice_panel.offset_left = 200; choice_panel.offset_right = -200
	choice_panel.add_theme_stylebox_override("panel", _get_style("panel_border_brown.svg", 32, 16))
	d_layer.add_child(choice_panel)
	
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 8)
	choice_panel.add_child(choice_box)
	choice_panel.visible = false

func display_line(line: Dictionary):
	var type = line.get("type", "dialogue")
	var text = line.get("text", "")
	var speaker_name = line.get("name", "")
	var speaker_side = line.get("speaker", "left")
	var color = line.get("color", Color.WHITE)

	narrator_box.visible = (type == "narrator")
	dialogue_box.visible = (type != "narrator")
	left_portrait.visible = (type != "narrator")
	right_portrait.visible = (type != "narrator")

	if type == "narrator":
		narrator_label.text = "[center][color=#ddddcc]%s[/color][/center]" % text
	else:
		var final_text = "[i]%s[/i]" % text if type == "action" else text
		text_label.text = "[color=#%s]%s:[/color]\n\n%s" % [color.to_html(false), speaker_name, final_text]
		_update_portraits(speaker_name, speaker_side)

func display_choices(options: Array):
	choice_panel.visible = true
	for c in choice_box.get_children(): c.queue_free()
	for i in options.size():
		var btn = Button.new()
		btn.text = options[i]
		btn.add_theme_stylebox_override("normal", _get_style("button_brown.svg", 10, 10))
		btn.add_theme_stylebox_override("hover", _get_style("button_grey.svg", 10, 10))
		btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
		btn.pressed.connect(func(): choice_selected.emit(i))
		choice_box.add_child(btn)
	
	if choice_box.get_child_count() > 0:
		choice_box.get_child(0).grab_focus()

func clear():
	left_portrait.texture = null
	right_portrait.texture = null
	text_label.text = ""
	narrator_label.text = ""
	narrator_box.visible = false
	dialogue_box.visible = false
	choice_panel.visible = false

func _update_portraits(character_name: String, side: String):
	var path = "res://Art/Portraits/%s.png" % character_name.to_lower()
	var tex = load(path) if ResourceLoader.exists(path) else null
	
	if side == "left":
		if right_portrait.texture == tex: right_portrait.texture = null
		left_portrait.texture = tex
	else:
		if left_portrait.texture == tex: left_portrait.texture = null
		right_portrait.texture = tex
	
	var tw = create_tween().set_parallel(true)
	var focus_l = (side == "left")
	tw.tween_property(left_portrait, "modulate", Color(1,1,1,1) if focus_l else Color(0.4,0.4,0.4,1), 0.2)
	tw.tween_property(left_portrait, "scale", Vector2(1.05, 1.05) if focus_l else Vector2(0.9, 0.9), 0.2)
	tw.tween_property(right_portrait, "modulate", Color(1,1,1,1) if not focus_l else Color(0.4,0.4,0.4,1), 0.2)
	tw.tween_property(right_portrait, "scale", Vector2(1.05, 1.05) if not focus_l else Vector2(0.9, 0.9), 0.2)

func _get_style(tex: String, margin: int, padding: int) -> StyleBoxTexture:
	var s = StyleBoxTexture.new()
	s.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/" + tex)
	s.texture_margin_left = margin; s.texture_margin_right = margin
	s.texture_margin_top = margin; s.texture_margin_bottom = margin
	s.set_content_margin_all(padding)
	return s

func _create_portrait(preset: int, x: int, y: int) -> TextureRect:
	var t = TextureRect.new()
	t.custom_minimum_size = Vector2(256, 256)
	t.set_anchors_preset(preset)
	t.offset_left = x; t.offset_right = x + 256
	t.offset_top = y; t.offset_bottom = y + 256
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.pivot_offset = Vector2(128, 256)
	return t
