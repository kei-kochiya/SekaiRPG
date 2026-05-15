extends BattleScenario
class_name DefaultScenario

func on_start(main: Node):
	main.run_battle()


func check_battle_end(main: Node) -> bool:
	# Thắng nếu toàn bộ kẻ địch bị hạ gục
	if AIManager.get_alive_targets(main.enemy_team).is_empty():
		main.hud.show_victory()
		main.battle_over = true
		return true
		
	# Thua nếu toàn bộ phe ta bị hạ gục
	if AIManager.get_alive_targets(main.player_team).is_empty():
		main.hud.show_defeat()
		main.battle_over = true
		return true
		
	return false

func get_victory_status(main: Node) -> bool:
	return AIManager.get_alive_targets(main.enemy_team).is_empty()

func on_battle_completed(main: Node, is_victory: bool):
	var enemy_count = main.enemy_team.size()
	
	if is_victory:
		if GameManager.current_map_file == "res://Maps/Harbor/HarborMap.tscn" and GameManager.harbor_route == "guards":
			GameManager.guards_defeated = true
			
	if is_victory and GameManager.prologue_phase == 0:
		GameManager.prologue_phase = 1
		
	GameManager.finish_battle(is_victory, enemy_count)
