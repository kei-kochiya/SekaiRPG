extends DefaultScenario
class_name PrologueScenario

func on_start(main: Node):
	# Prologue Fix: Đảm bảo Ichika luôn đi đầu
	for p in main.player_team:
		if p.entity_name == "Ichika":
			p.action_gauge = 10000.0
	
	main._regenerate_timeline()
	main.run_battle()

func on_battle_completed(main: Node, is_victory: bool):
	if is_victory:
		GameManager.prologue_phase = 1
	super.on_battle_completed(main, is_victory)
