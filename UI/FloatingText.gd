extends Label
class_name FloatingText

## Damage number that floats upward and fades out, then self-destructs.

const COLORS = {
	"physical": Color(1.0, 0.3, 0.3),
	"pure":     Color(1.0, 1.0, 1.0),
	"dot":      Color(0.7, 0.3, 0.8),
	"heal":     Color(0.3, 1.0, 0.3),
}

var float_color: Color = Color.RED

func _ready():
	add_theme_color_override("font_color", float_color)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 4)
	add_theme_font_size_override("font_size", 24)
	
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	z_index = 100
	
	# Slight random horizontal scatter
	position.x += randf_range(-15, 15)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 60, 1.0) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.5)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

static func spawn(parent: Node, amount: int, damage_type: String, pos: Vector2):
	var ft = FloatingText.new()
	var prefix = "+" if damage_type == "heal" else "-"
	ft.text = "%s%d" % [prefix, amount]
	ft.float_color = COLORS.get(damage_type, Color.RED)
	ft.position = pos
	parent.add_child(ft)
