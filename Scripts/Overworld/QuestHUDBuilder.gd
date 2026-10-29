class_name QuestHUDBuilder
extends RefCounted

const WIDTH = 360

static func build(parent: Node2D) -> Dictionary:
	var canvas = CanvasLayer.new()
	canvas.layer = 10
	parent.add_child(canvas)
	
	var quest_panel = PanelContainer.new()
	quest_panel.position = Vector2(UITheme.SP_6, UITheme.SP_6)
	canvas.add_child(quest_panel)
	
	# Panel phẳng, một vạch nhấn hổ phách ở cạnh trái
	var sb := UITheme.box(UITheme.overlay_dim(0.88), UITheme.ACCENT, UITheme.RADIUS_SM, UITheme.SP_4, UITheme.SP_3)
	sb.set_border_width_all(0)
	sb.border_width_left = UITheme.SP_1
	quest_panel.add_theme_stylebox_override("panel", sb)
	
	var quest_label = UITheme.make_label("", UITheme.FS_BODY, UITheme.TEXT)
	quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quest_label.custom_minimum_size.x = WIDTH
	quest_panel.add_child(quest_label)
	
	return {
		"panel": quest_panel,
		"label": quest_label
	}
