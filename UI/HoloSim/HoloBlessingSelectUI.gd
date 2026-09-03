extends CanvasLayer
class_name HoloBlessingSelectUI

"""
Tóm tắt: HoloBlessingSelectUI hiển thị giao diện chọn 1 trong 3 Phước Lành Roguelite sau mỗi tầng thắng.
"""

signal blessing_chosen(blessing_id: String)

var cards_container: HBoxContainer

func _ready():
	layer = 150
	_build_ui()

func setup_options(options: Array):
	for c in cards_container.get_children():
		c.queue_free()
		
	for opt in options:
		var card = _create_blessing_card(opt)
		cards_container.add_child(card)

func _build_ui():
	# Nền tối mờ
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.05, 0.05, 0.1, 0.85)
	add_child(dimmer)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(800, 380)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.add_theme_constant_override("separation", 24)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "CHỌN PHƯỚC LÀNH (BLESSING)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Chọn 1 sức mạnh bị động để cường hóa đội hình trong suốt phần còn lại của lượt leo tháp."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	vbox.add_child(subtitle)
	
	cards_container = HBoxContainer.new()
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 24)
	vbox.add_child(cards_container)

func _create_blessing_card(data: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 240)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.14, 0.22, 0.95)
	sb.border_width_left = 2; sb.border_width_right = 2
	sb.border_width_top = 2; sb.border_width_bottom = 2
	sb.border_color = Color(0.3, 0.6, 1.0)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	var icon_lbl = Label.new()
	icon_lbl.text = data.get("icon", "⭐")
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 36)
	vbox.add_child(icon_lbl)
	
	var name_lbl = Label.new()
	name_lbl.text = data.get("name", "Phước Lành")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	vbox.add_child(name_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = data.get("desc", "")
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	vbox.add_child(desc_lbl)
	
	var btn = Button.new()
	btn.text = "CHỌN NÀY"
	btn.custom_minimum_size = Vector2(0, 36)
	btn.pressed.connect(func():
		blessing_chosen.emit(data["id"])
		queue_free()
	)
	vbox.add_child(btn)
	
	return panel
