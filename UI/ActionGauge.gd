extends VBoxContainer
class_name ActionGauge

## Vertical timeline showing the next N turns.
## Player entries are teal, enemy entries are orange-red.

const PLAYER_COLOR = Color(0.29, 0.62, 0.62)
const ENEMY_COLOR  = Color(0.72, 0.38, 0.16)
const BG_COLOR     = Color(0.08, 0.08, 0.08, 0.85)

var player_names: Array[String] = []

func _ready():
	add_theme_constant_override("separation", 2)
	custom_minimum_size = Vector2(140, 0)

func set_player_names(names: Array[String]):
	player_names = names

func refresh(timeline: Array):
	# Clear old entries
	for c in get_children():
		c.queue_free()
	
	# Header
	var header = Label.new()
	header.text = "TURN ORDER"
	header.add_theme_font_size_override("font_size", 11)
	header.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(header)
	
	var sep = HSeparator.new()
	sep.add_theme_constant_override("separation", 4)
	add_child(sep)
	
	# Turn entries
	for i in range(timeline.size()):
		var entry_name = timeline[i]["name"]
		var is_player = player_names.has(entry_name)
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		
		# Turn number
		var num = Label.new()
		num.text = "%d." % (i + 1)
		num.add_theme_font_size_override("font_size", 11)
		num.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
		num.custom_minimum_size = Vector2(22, 0)
		row.add_child(num)
		
		# Colored square (portrait placeholder)
		var icon = ColorRect.new()
		icon.custom_minimum_size = Vector2(14, 14)
		icon.color = PLAYER_COLOR if is_player else ENEMY_COLOR
		row.add_child(icon)
		
		# Name
		var lbl = Label.new()
		lbl.text = entry_name
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color",
			PLAYER_COLOR if is_player else ENEMY_COLOR)
		row.add_child(lbl)
		
		add_child(row)
