## ScreenFade — Autoload
## Persistent black overlay for scene transitions.
## Usage:  await ScreenFade.fade_out()
##         get_tree().change_scene_to_file(...)
##         # new scene calls:  await ScreenFade.fade_in()
extends CanvasLayer

var _rect: ColorRect

func _ready() -> void:
	layer = 200
	_rect = ColorRect.new()
	_rect.color = Color.BLACK
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)

func fade_out(duration: float = 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 1.0, duration)
	await tw.finished

func fade_in(duration: float = 0.5) -> void:
	_rect.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_property(_rect, "modulate:a", 0.0, duration)
	await tw.finished
