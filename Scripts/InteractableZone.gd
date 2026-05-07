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
	prompt_label.position = Vector2(-40, -40)
	prompt_label.add_theme_font_size_override("font_size", 12)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	# If player is in zone, dialogue isn't playing, and presses Accept
	if is_player_inside and Input.is_action_just_pressed("ui_accept"):
		if not GameManager.is_in_dialogue:
			interacted.emit()
