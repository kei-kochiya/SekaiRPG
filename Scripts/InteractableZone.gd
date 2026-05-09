extends Area2D
class_name InteractableZone

signal interacted

var prompt_label: Label
var is_player_inside: bool = false
@export var prompt_text: String = "Press ENTER"

func _ready():
	# Configure Area2D
	collision_layer = 0
	collision_mask = 1 # Assuming player is on layer 1
	
	prompt_label = Label.new()
	prompt_label.text = prompt_text
	prompt_label.visible = false
	prompt_label.position = Vector2(-60, -50)
	prompt_label.custom_minimum_size = Vector2(120, 40)
	prompt_label.add_theme_font_size_override("font_size", 12)
	prompt_label.add_theme_color_override("font_color", Color(0.2, 0.1, 0.05))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var pb = StyleBoxTexture.new()
	pb.texture = load("res://Assets/kenney_ui-pack-adventure/Vector/banner_modern.svg")
	pb.texture_margin_left = 10
	pb.texture_margin_right = 10
	pb.texture_margin_top = 10
	pb.texture_margin_bottom = 10
	prompt_label.add_theme_stylebox_override("normal", pb)
	
	add_child(prompt_label)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.name == "OverworldPlayer":
		is_player_inside = true
		prompt_label.visible = true

func _on_body_exited(body):
	if body.name == "OverworldPlayer":
		is_player_inside = false
		prompt_label.visible = false

func _process(_delta):
	# Hide prompt if dialogue or UI is active
	if GameManager.is_in_dialogue:
		prompt_label.visible = false
	elif is_player_inside:
		prompt_label.visible = true

	# If player is in zone, dialogue isn't playing, and presses Accept
	if is_player_inside and Input.is_action_just_pressed("ui_accept"):
		if not GameManager.is_in_dialogue:
			interacted.emit()
