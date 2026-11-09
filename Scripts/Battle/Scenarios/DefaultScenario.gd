extends BattleScenario
class_name DefaultScenario

func on_start(main: Node):
	main.run_battle()


func check_battle_end(main: Node) -> bool:
	# Thắng nếu toàn bộ kẻ địch bị hạ gục
	if AIManager.get_alive_targets(main.enemy_team).is_empty():
		main.end_battle(true)
		return true
		
	# Thua nếu toàn bộ phe ta bị hạ gục
	if AIManager.get_alive_targets(main.player_team).is_empty():
		main.end_battle(false)
		return true
		
	return false

func get_victory_status(main: Node) -> bool:
	return AIManager.get_alive_targets(main.enemy_team).is_empty()

func on_battle_completed(_main: Node, is_victory: bool):
	GameManager.finish_battle(is_victory)
