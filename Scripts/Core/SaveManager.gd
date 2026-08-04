class_name SaveManager

const SAVE_PATH = "user://sekai_save.json"

static func save_game(path: String = SAVE_PATH):
	var save_data = {
		"current_map": GameManager.current_map_file,
		"player_pos": {"x": GameManager.last_player_position.x, "y": GameManager.last_player_position.y},
		"story": GameManager.story.serialize(),
		"party": {}
	}
	
	for p_name in GameManager.party:
		var e = GameManager.party[p_name]
		save_data["party"][p_name] = {
			"level": e.level, "exp": e.current_exp, "skill_points": e.skill_points,
			"atk": e.atk, "defense": e.defense, "spd": e.spd, "max_hp": e.max_hp
		}
	
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("[SaveManager] Lỗi: Không thể lưu file tại ", path)
		return
	f.store_string(JSON.stringify(save_data))
	f.close()
	print("[SaveManager] Game đã được lưu tại: ", path)

static func get_current_save_path() -> String:
	var map_name = GameManager.current_map_file.get_file().get_basename()
	return "user://" + map_name + ".json"

static func load_game(path: String = SAVE_PATH) -> bool:
	if not FileAccess.file_exists(path):
		print("[SaveManager] Lỗi: Không tìm thấy file tại ", path)
		return false
	
	var f = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	
	if not data is Dictionary: return false
	
	GameManager.current_map_file = data.get("current_map", "res://Maps/Base/BaseMap.tscn")
	var pos = data.get("player_pos", {"x": 0, "y": 0})
	GameManager.last_player_position = Vector2(pos.x, pos.y)
	
	if data.has("story"):
		GameManager.story.deserialize(data["story"])
	else:
		GameManager.story.flags = data.get("flags", GameManager.story.flags.duplicate())
		var m_state = data.get("mission_state", {})
		GameManager.story.warehouse_wave = m_state.get("warehouse_wave", 1)
		GameManager.story.harbor_wave = m_state.get("harbor_wave", 1)
		GameManager.story.enemies_defeated = m_state.get("enemies_defeated", 0)
	
	var p_data = data.get("party", {})
	for p_name in p_data:
		if GameManager.party.has(p_name):
			var e = GameManager.party[p_name]; var d = p_data[p_name]
			e.level = d.get("level", 1); e.current_exp = d.get("exp", 0)
			e.skill_points = d.get("skill_points", 0); e.atk = d.get("atk", e.atk)
			e.defense = d.get("defense", e.defense); e.spd = d.get("spd", e.spd)
			e.max_hp = d.get("max_hp", e.max_hp); e.current_hp = e.max_hp
	
	print("[SaveManager] Game đã tải thành công từ: ", path)
	GameManager.get_tree().change_scene_to_file(GameManager.current_map_file)
	return true

static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)

static func get_save_files() -> Array:
	var saves = []
	var dir = DirAccess.open("user://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				saves.append("user://" + file_name)
			file_name = dir.get_next()
	return saves
