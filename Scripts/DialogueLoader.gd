## DialogueLoader — Autoload
## Reads Data/dialogue.json and provides typed line arrays
## that DialogueManager.play_dialogue() can consume.
##
## Usage:
##   DialogueManager.play_dialogue(DialogueLoader.get("prologue_phase0"))

extends Node

var _data: Dictionary = {}

func _ready() -> void:
	_load_json()

func _load_json() -> void:
	var f := FileAccess.open("res://Data/dialogue.json", FileAccess.READ)
	if f == null:
		push_error("DialogueLoader: cannot open res://Data/dialogue.json — error %d" % FileAccess.get_open_error())
		return
	var text := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("DialogueLoader: JSON parse failed")
		return
	if not parsed is Dictionary:
		push_error("DialogueLoader: JSON root is not a Dictionary")
		return

	_data = parsed as Dictionary

## Return the dialogue array for a given key (e.g. "prologue_phase0").
## Each element is a dict compatible with DialogueManager:
##   { type, speaker?, name?, color (Color), text }
func get_lines(key: String) -> Array:
	if not _data.has(key):
		push_warning("DialogueLoader: unknown key '%s'" % key)
		return []

	var raw: Array = _data[key]
	var out: Array = []
	for entry in raw:
		var line: Dictionary = {}
		line["type"]    = entry.get("type", "dialogue")
		line["text"]    = entry.get("text", "")
		line["name"]    = entry.get("name", "")
		line["speaker"] = entry.get("speaker", "left")
		# Convert hex color string → Color
		var hex: String = entry.get("color", "#ffffff")
		line["color"] = Color(hex)
		out.append(line)
	return out
