class_name QuestHUDBuilder
extends RefCounted

static func build(parent: Node2D) -> Dictionary:
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	parent.add_child(canvas)
	
	var quest_panel = PanelContainer.new()
	quest_panel.position = Vector2(20, 20)
	canvas.add_child(quest_panel)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.6)
	sb.border_width_left = 4
	sb.border_color = Color(0.4, 0.7, 1.0)
	sb.set_content_margin_all(10)
	quest_panel.add_theme_stylebox_override("panel", sb)
	
	var quest_label = Label.new()
	quest_label.add_theme_font_size_override("font_size", 16)
	quest_panel.add_child(quest_label)
	
	return {
		"panel": quest_panel,
		"label": quest_label
	}
