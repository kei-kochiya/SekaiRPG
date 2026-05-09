extends CanvasLayer

## MobileControls: Refactored for better touch responsiveness.
## Uses TouchScreenButton for multi-touch support and larger hitboxes.

const ARROW_TEX = "res://Assets/kenney_ui-pack-adventure/Vector/minimap_arrow_a.svg"
const BUTTON_TEX = "res://Assets/kenney_ui-pack-adventure/Vector/button_brown.svg"

var _controls: Control

func _ready():
	# Visible on mobile or for testing
	var is_mobile = OS.has_feature("mobile") or OS.get_name() == "Android" or OS.get_name() == "iOS"
	visible = is_mobile
	if not visible: return
	
	layer = 120
	_build_ui()

func _build_ui():
	_controls = Control.new()
	_controls.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_controls)
	
	# ── D-Pad (Bottom Left) ──
	var dpad = Control.new()
	dpad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	dpad.offset_left = 60
	dpad.offset_top = -280
	_controls.add_child(dpad)
	
	_create_touch_btn(dpad, Vector2(100, 0),    0,   "ui_up")
	_create_touch_btn(dpad, Vector2(100, 200),  180, "ui_down")
	_create_touch_btn(dpad, Vector2(0, 100),   -90,  "ui_left")
	_create_touch_btn(dpad, Vector2(200, 100),  90,   "ui_right")
	
	# ── Action Buttons (Bottom Right) ──
	var actions = Control.new()
	actions.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	actions.offset_right = -80
	actions.offset_top = -220
	_controls.add_child(actions)
	
	# Interact Button (A) - Large circle or square
	_create_action_btn(actions, Vector2(-120, 0), "A", "ui_accept")
	
	# ── Pause Button (Top Right) ──
	var top_right = Control.new()
	top_right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	top_right.offset_right = -60
	top_right.offset_top = 60
	_controls.add_child(top_right)
	
	_create_action_btn(top_right, Vector2(-100, 0), "||", "ui_cancel")

func _create_touch_btn(parent: Control, pos: Vector2, rot: float, action: String):
	var btn = TouchScreenButton.new()
	btn.texture_normal = load(ARROW_TEX)
	btn.action = action
	btn.position = pos
	
	# Scaling the arrow up for mobile (original is small)
	btn.scale = Vector2(1.5, 1.5)
	
	# Set pivot and rotation
	# Note: TouchScreenButton rotates from top-left, so we offset the position to center it
	# Assuming 64x64 texture, 1.5 scale -> 96x96
	var offset = Vector2(48, 48)
	btn.position -= offset.rotated(deg_to_rad(rot)) - offset
	
	# Center of the 64x64 texture is 32x32
	# Actually, to make it easier, let's just use a Sprite2D inside if needed, 
	# but TouchScreenButton has its own transform.
	
	# Simple approach: apply rotation and modulate
	var rad = deg_to_rad(rot)
	# Transform math for rotation around center
	var pivot = Vector2(32, 32)
	btn.transform = btn.transform.translated(pivot).rotated(rad).translated(-pivot)
	
	btn.modulate = Color(1, 1, 1, 0.6)
	parent.add_child(btn)

func _create_action_btn(parent: Control, pos: Vector2, txt: String, action: String):
	# Using a regular button for the visual, but a TouchScreenButton for the actual input
	# because TouchScreenButton doesn't support easy Label centering.
	
	var visual = Button.new()
	visual.text = txt
	visual.custom_minimum_size = Vector2(100, 100)
	visual.position = pos
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE # Don't block the touch button
	
	var sb = StyleBoxTexture.new()
	sb.texture = load(BUTTON_TEX)
	sb.texture_margin_left = 12
	sb.texture_margin_right = 12
	sb.texture_margin_top = 12
	sb.texture_margin_bottom = 16
	visual.add_theme_stylebox_override("normal", sb)
	visual.add_theme_font_size_override("font_size", 32)
	visual.modulate = Color(1, 1, 1, 0.7)
	parent.add_child(visual)
	
	var tsb = TouchScreenButton.new()
	# Create a simple invisible rectangle for the hitbox
	var rect = RectangleShape2D.new()
	rect.size = Vector2(100, 100)
	tsb.shape = rect
	tsb.action = action
	tsb.position = pos + Vector2(50, 50) # Center the hitbox
	parent.add_child(tsb)
