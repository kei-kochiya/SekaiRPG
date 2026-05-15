extends DefaultScenario
class_name ScriptedBattleScenario

func check_battle_end(main: Node) -> bool:
	if AIManager.get_alive_targets(main.player_team).is_empty():
		main.battle_over = true
		return true
		
	return super.check_battle_end(main)

func on_battle_completed(main: Node, is_victory: bool):
	var enemy_count = main.enemy_team.size()
	GameManager.finish_battle(is_victory, enemy_count)
