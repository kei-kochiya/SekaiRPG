extends Node
class_name HarborBattleScript

## Handles the scripted reinforcements and phase transitions for the Harbor Boss fight.

static func run_intro(main: Node, callback: Callable):
	main.is_scripting = true
	main._regenerate_timeline()
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_boss_intro"), func():
		main.harbor_boss_phase = 1
		main.is_scripting = false
		callback.call()
	)

static func handle_loss(main: Node):
	main.is_scripting = true
	main.harbor_boss_phase = 2 # Prevent re-triggering
	
	# 1. Dialogue: Boss taunts
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_boss_mid_fight"), func():
		# 2. Reinforcement: Mafuyu arrives
		var mafuyu = Mafuyu.new()
		main.player_team.append(mafuyu)
		
		# Restore players
		for p in main.player_team:
			if p.current_hp <= 0:
				p.current_hp = 100
				p.hp_changed.emit(p.current_hp, p.max_hp)
		
		DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_mafuyu_reinforcement"), func():
			# 3. Enemy: Honami arrives
			var honami = Honami.new()
			main.enemy_team.append(honami)
			
			DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_honami_arrival"), func():
				# Re-sync everything
				main.all_entities = main.player_team + main.enemy_team
				main._refresh_team_context()
				main._update_gauge_player_names()
				
				# Signals
				mafuyu.died.connect(main._on_entity_died.bind(mafuyu))
				honami.died.connect(main._on_entity_died.bind(honami))
				
				# Rebuild UI
				main.hud.build(main.player_team, main.enemy_team)
				main._update_gauge_display()
				main._regenerate_timeline()
				
				main.is_scripting = false # Resume battle
			)
		)
	)
