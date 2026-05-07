extends Node
class_name ScreenShake

## Provides screen shake and hitstop (time-scale freeze) for impact moments.

var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	set_process(false)

func shake(intensity: float = 5.0, duration: float = 0.2):
	shake_intensity = intensity
	shake_timer = duration
	set_process(true)

func hitstop(duration: float = 0.1):
	Engine.time_scale = 0.05
	# ignore_time_scale = true so the timer counts real seconds
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func _process(delta):
	var parent = get_parent()
	if not parent:
		set_process(false)
		return
	
	if shake_timer > 0:
		shake_timer -= delta
		parent.position = original_offset + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
	else:
		parent.position = original_offset
		set_process(false)

