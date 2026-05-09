extends Node

## Central state management.
## Holds persistent game flags, party data, and mission status.

var current_map_file: String = "res://Scenes/PrologueMap.tscn"
var last_player_position: Vector2 = Vector2.ZERO

# Persistent Game Flags (Quests, Unlocks, Progress)
var flags: Dictionary = {
	"prologue_phase": 0,
	"safehouse_intro_done": false,
	"intro_quest_done": false,
	"npcs_greeted": [],
	"warehouse_mission_accepted": false,
	"talked_to_mafuyu_training": false,
	"accepted_harbor_mission": false,
	"harbor_mission_unlocked": false,
	"harbor_mission_done": false,
	"harbor_intro_done": false,
	"upgrade_tutorial_done": false,
	"guards_defeated": false,
	"training_ichika_done": false,
	"training_kanade_done": false
}

# Mission State (Volatile, resets often)
var warehouse_wave: int = 1
var harbor_wave: int = 1
var enemies_defeated: int = 0
var harbor_guards_defeated: int = 0

# Training State
var is_training_mode: bool = false
var training_participants: Array = []
var training_used_opponents: Array = []
var last_battle_max_lv: int = 1

# System State
var is_in_dialogue: bool = false
var is_tutorial: bool = false
var is_sandbox: bool = false
var sandbox_player_team: Array = []
var sandbox_enemy_team: Array = []
var harbor_route: String = "" 

var party: Dictionary = {}

func _ready():
	_init_party()

func _init_party():
	party["Ichika"] = Ichika.new()
	party["Kanade"] = Kanade.new()
	party["Mafuyu"] = Mafuyu.new()
	party["Ena"]    = Ena.new()
	party["Mizuki"] = Mizuki.new()
	
	LevelManager.set_initial_level(party["Ichika"], 1)
	LevelManager.set_initial_level(party["Kanade"], 5)
	LevelManager.set_initial_level(party["Mafuyu"], 8)
	LevelManager.set_initial_level(party["Ena"],    8)
	LevelManager.set_initial_level(party["Mizuki"], 10)

# Flag Helpers
func set_flag(id: String, value: Variant):
	flags[id] = value

func get_flag(id: String, default: Variant = false) -> Variant:
	return flags.get(id, default)

# Property passthrough for backward compatibility (optional but helpful)
var prologue_phase: int:
	get: return flags.get("prologue_phase", 0)
	set(v): flags["prologue_phase"] = v

var safehouse_intro_done: bool:
	get: return flags.get("safehouse_intro_done", false)
	set(v): flags["safehouse_intro_done"] = v

var intro_quest_done: bool:
	get: return flags.get("intro_quest_done", false)
	set(v): flags["intro_quest_done"] = v

var npcs_greeted: Array:
	get: return flags.get("npcs_greeted", [])
	set(v): flags["npcs_greeted"] = v

var harbor_mission_unlocked: bool:
	get: return flags.get("harbor_mission_unlocked", false)
	set(v): flags["harbor_mission_unlocked"] = v

var warehouse_mission_accepted: bool:
	get: return flags.get("warehouse_mission_accepted", false)
	set(v): flags["warehouse_mission_accepted"] = v

var accepted_harbor_mission: bool:
	get: return flags.get("accepted_harbor_mission", false)
	set(v): flags["accepted_harbor_mission"] = v

var harbor_mission_done: bool:
	get: return flags.get("harbor_mission_done", false)
	set(v): flags["harbor_mission_done"] = v

var harbor_intro_done: bool:
	get: return flags.get("harbor_intro_done", false)
	set(v): flags["harbor_intro_done"] = v

var talked_to_mafuyu_training: bool:
	get: return flags.get("talked_to_mafuyu_training", false)
	set(v): flags["talked_to_mafuyu_training"] = v

var training_ichika_done: bool:
	get: return flags.get("training_ichika_done", false)
	set(v): flags["training_ichika_done"] = v

var training_kanade_done: bool:
	get: return flags.get("training_kanade_done", false)
	set(v): flags["training_kanade_done"] = v

var guards_defeated: bool:
	get: return flags.get("guards_defeated", false)
	set(v): flags["guards_defeated"] = v

# Logic
func get_party_member(m_name: String) -> Entity:
	return party.get(m_name)

func start_dialogue():
	is_in_dialogue = true

func end_dialogue():
	is_in_dialogue = false

const SAVE_PATH = "user://sekai_save.json"

func save_game():
	var save_data = {
		"current_map": current_map_file,
		"player_pos": {"x": last_player_position.x, "y": last_player_position.y},
		"flags": flags,
		"mission_state": {
			"warehouse_wave": warehouse_wave,
			"harbor_wave": harbor_wave,
			"enemies_defeated": enemies_defeated
		},
		"party": {}
	}
	
	for p_name in party:
		var e = party[p_name]
		save_data["party"][p_name] = {
			"level": e.level,
			"exp": e.current_exp,
			"skill_points": e.skill_points,
			"atk": e.atk,
			"defense": e.defense,
			"spd": e.spd,
			"max_hp": e.max_hp
		}
	
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(save_data))
	f.close()
	print("[GameManager] Game Saved to ", SAVE_PATH)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	
	if not data is Dictionary: return false
	
	current_map_file = data.get("current_map", "res://Scenes/BaseMap.tscn")
	var pos = data.get("player_pos", {"x": 0, "y": 0})
	last_player_position = Vector2(pos.x, pos.y)
	
	flags = data.get("flags", flags.duplicate())
	
	var m_state = data.get("mission_state", {})
	warehouse_wave = m_state.get("warehouse_wave", 1)
	harbor_wave = m_state.get("harbor_wave", 1)
	enemies_defeated = m_state.get("enemies_defeated", 0)
	
	var p_data = data.get("party", {})
	for p_name in p_data:
		if party.has(p_name):
			var e = party[p_name]
			var d = p_data[p_name]
			e.level = d.get("level", 1)
			e.current_exp = d.get("exp", 0)
			e.skill_points = d.get("skill_points", 0)
			e.atk = d.get("atk", e.atk)
			e.defense = d.get("defense", e.defense)
			e.spd = d.get("spd", e.spd)
			e.max_hp = d.get("max_hp", e.max_hp)
			e.current_hp = e.max_hp
	
	print("[GameManager] Game Loaded from ", SAVE_PATH)
	get_tree().change_scene_to_file(current_map_file)
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func reset_game():
	# Reset flags to default
	for key in flags:
		if flags[key] is bool: flags[key] = false
		elif flags[key] is int: flags[key] = 0
		elif flags[key] is Array: flags[key] = []
	
	warehouse_wave = 1
	harbor_wave = 1
	enemies_defeated = 0
	last_player_position = Vector2.ZERO
	current_map_file = "res://Scenes/PrologueMap.tscn"
	_init_party()

func store_map_state(map_path: String, player_pos: Vector2):
	current_map_file = map_path
	last_player_position = player_pos

func reset_mission_stats():
	enemies_defeated = 0

func trigger_battle():
	get_tree().change_scene_to_file("res://Scenes/BattleScene.tscn")

func finish_battle(victory: bool, count: int = 1):
	if is_sandbox:
		get_tree().change_scene_to_file("res://Scenes/SandboxMenu.tscn")
		return

	if not victory and is_training_mode:
		var bonus_exp = int(last_battle_max_lv * 5)
		print("[TRAINING] Thua cuộc! Nhận được ", bonus_exp, " EXP an ủi.")
		for p_name in training_participants:
			var entity = get_party_member(p_name)
			if entity: LevelManager.gain_exp(entity, bonus_exp)
		victory = true 

	if victory:
		enemies_defeated += count
		if current_map_file.contains("Warehouse"):
			warehouse_wave += 1
		if current_map_file == "res://Scenes/HarborMap.tscn":
			harbor_wave += 1
			
	get_tree().change_scene_to_file(current_map_file)
