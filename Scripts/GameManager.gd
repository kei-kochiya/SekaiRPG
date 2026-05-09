extends Node

var current_map_file: String = "res://Scenes/PrologueMap.tscn"
var last_player_position: Vector2 = Vector2.ZERO

var prologue_phase: int = 0
var warehouse_wave: int = 1
var enemies_defeated: int = 0
var is_tutorial: bool = false
var is_in_dialogue: bool = false
var is_sandbox: bool = false
var sandbox_player_team: Array = []
var sandbox_enemy_team: Array = []

# Safehouse quest state
var safehouse_intro_done: bool = false
var npcs_greeted: Array = []
var intro_quest_done: bool = false
var warehouse_mission_accepted: bool = false

# Harbor / Post-Warehouse quest state
var talked_to_mafuyu_training: bool = false
var accepted_harbor_mission: bool = false
var harbor_mission_unlocked: bool = false
var harbor_mission_done: bool = false
var harbor_intro_done: bool = false

# Training state
var training_ichika_done: bool = false
var training_kanade_done: bool = false
var is_training_mode: bool = false
var training_participants: Array = []
var training_used_opponents: Array = []
var last_battle_max_lv: int = 1

var upgrade_tutorial_done: bool = false
var harbor_route: String = "" 
var guards_defeated: bool = false
var harbor_wave: int = 1
var harbor_guards_defeated: int = 0

var party: Dictionary = {}

func _ready():
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

func get_party_member(m_name: String) -> Entity:
	return party.get(m_name)

func start_dialogue():
	is_in_dialogue = true

func end_dialogue():
	is_in_dialogue = false

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
		victory = true # Treat as "finished" wave to continue loop

	if victory:
		enemies_defeated += count
		if current_map_file.contains("Warehouse"):
			warehouse_wave += 1
		if current_map_file == "res://Scenes/HarborMap.tscn":
			harbor_wave += 1
			
	get_tree().change_scene_to_file(current_map_file)
