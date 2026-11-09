extends DefaultScenario
class_name ScriptedBattleScenario

func check_battle_end(main: Node) -> bool:
	if AIManager.get_alive_targets(main.player_team).is_empty():
		# Có banner (BattleHUD._scripted_defeat_text); trước đây chỉ đặt battle_over nên im lặng 2 giây rồi đổi cảnh. Cả hai phe cùng gục
		# thì get_victory_status báo thắng, nên banner cũng phải là thắng.
		main.end_battle(AIManager.get_alive_targets(main.enemy_team).is_empty())
		return true
		
	return super.check_battle_end(main)

