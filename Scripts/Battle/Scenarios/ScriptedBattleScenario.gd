extends DefaultScenario
class_name ScriptedBattleScenario

func check_battle_end(main: Node) -> bool:
	if AIManager.get_alive_targets(main.player_team).is_empty():
		main.battle_over = true
		return true
		
	return super.check_battle_end(main)

