class_name FakeBattleMain
extends Node

"""
FakeBattleMain: giả lập tối thiểu những gì một BattleScenario đọc/gọi trên Main (đội hình, HUD, banner kết quả, vòng lặp)
để test kịch bản mà không cần dựng cả BattleScene.
"""

class FakeHud extends RefCounted:
	var announcements: Array = []
	var results: Array = []
	func show_announcement(text: String, _color: Color = Color.WHITE): announcements.append(text)
	func show_victory(): results.append(true)
	func show_defeat(): results.append(false)

var player_team: Array
var enemy_team: Array
var all_entities: Array = []
var hud := FakeHud.new()
var battle_over: bool = false
var is_scripting: bool = false
var ran: bool = false
var shaker = null

func _init(players: Array, enemies: Array):
	player_team = players
	enemy_team = enemies
	all_entities = players + enemies

func run_battle(): ran = true
func _regenerate_timeline(): pass
func prepare_entity(e: Entity): e.reset_battle_state()
func _connect_combatant(_e: Entity): pass
func refresh_battle_state(): pass

func add_combatant(e: Entity, on_player_side: bool = false):
	(player_team if on_player_side else enemy_team).append(e)
	all_entities.append(e)

# Giống Main.end_battle: banner hiện đúng một lần
func end_battle(victory: bool):
	if hud.results.is_empty():
		if victory:
			hud.show_victory()
		else:
			hud.show_defeat()
	battle_over = true
