extends Node

var current_map_file: String = "res://Scenes/PrologueMap.tscn"
var last_player_position: Vector2 = Vector2.ZERO

var prologue_phase: int = 0
var warehouse_wave: int = 1
var enemies_defeated: int = 0
var is_tutorial: bool = false
var is_in_dialogue: bool = false

# Safehouse quest state
var safehouse_intro_done: bool = false
var npcs_greeted: Array = []          # filled by BaseMap as player meets each NPC
var intro_quest_done: bool = false    # true once all 4 NPCs have been greeted
var harbor_mission_unlocked: bool = false
var harbor_mission_done: bool = false
var upgrade_tutorial_done: bool = false
var harbor_route: String = "" # "guards" or "boss"
var guards_defeated: bool = false


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
	if victory:
		enemies_defeated += count
		# Every 5 enemies defeated = wave clear
		if enemies_defeated % 5 == 0:
			warehouse_wave += 1
			
	get_tree().change_scene_to_file(current_map_file)
