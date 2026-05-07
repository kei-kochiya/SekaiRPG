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


func start_dialogue():
	is_in_dialogue = true

func end_dialogue():
	is_in_dialogue = false

func store_map_state(map_path: String, player_pos: Vector2):
	current_map_file = map_path
	last_player_position = player_pos

func trigger_battle():
	get_tree().change_scene_to_file("res://Scenes/BattleScene.tscn")

func finish_battle(victory: bool):
	if victory:
		enemies_defeated += 1
		# Every 5 enemies defeated = wave clear
		if enemies_defeated % 5 == 0:
			warehouse_wave += 1
			
	get_tree().change_scene_to_file(current_map_file)
