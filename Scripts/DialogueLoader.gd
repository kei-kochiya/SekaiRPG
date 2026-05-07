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
	var path = "res://Data/"
	var dir = DirAccess.open(path)
	if not dir:
		push_error("DialogueLoader: cannot open " + path)
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_load_single_file(path + file_name)
		file_name = dir.get_next()

func _load_single_file(file_path: String) -> void:
	var f := FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		push_error("DialogueLoader: cannot open " + file_path)
		return
	var text := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("DialogueLoader: JSON parse failed in " + file_path)
		return
	if not parsed is Dictionary:
		push_error("DialogueLoader: JSON root in " + file_path + " is not a Dictionary")
		return

	# Merge into _data
	var new_data: Dictionary = parsed as Dictionary
	for key in new_data:
		_data[key] = new_data[key]
	
	print("DialogueLoader: Loaded ", file_path)

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
