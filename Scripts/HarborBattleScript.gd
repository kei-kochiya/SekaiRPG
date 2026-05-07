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
	main.harbor_boss_phase = 2 
	main.turns_in_phase = 0
	
	# 1. Dialogue: Boss taunts
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_boss_mid_fight"), func():
		# --- Phase 2: Mafuyu Solo vs Nerfed Boss ---
		var mafuyu = Mafuyu.new()
		for s in mafuyu.skills:
			if s.name == "Lost World": s.cooldown_turns = 5
		
		var boss = main.enemy_team[0]
		boss.atk = 150
		boss.defense = 80
		boss.current_hp = boss.max_hp
		
		main.player_team = [mafuyu]
		main.enemy_team = [boss]
		
		_sync_battle_state(main)
		
		DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_mafuyu_reinforcement"), func():
			main.is_scripting = false # Player starts Phase 2
		)
	)

static func check_transitions(main: Node):
	if main.harbor_boss_phase == 2 and main.turns_in_phase > 5:
		_trigger_phase_3(main)

static func _trigger_phase_3(main: Node):
	main.is_scripting = true
	main.harbor_boss_phase = 3
	main.turns_in_phase = 0
	
	var honami = Honami.new()
	var boss = main.enemy_team[0]
	
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_honami_arrival"), func():
		# --- Phase 3: Team Battle ---
		var ichika = Ichika.new()
		var ena = Ena.new()
		ichika.current_hp = ichika.max_hp
		ena.current_hp = ena.max_hp
		
		# Current player team should have mafuyu already
		main.player_team = [ichika, ena, main.player_team[0]]
		
		boss.max_hp = 5000
		boss.current_hp = 5000
		main.enemy_team = [boss, honami]
		
		_sync_battle_state(main)
		main.is_scripting = false 
	)

static func _sync_battle_state(main: Node):
	main.all_entities = main.player_team + main.enemy_team
	main._refresh_team_context()
	main._update_gauge_player_names()
	
	# Connect signals for new members
	for e in main.all_entities:
		if not e.died.is_connected(main._on_entity_died):
			e.died.connect(main._on_entity_died.bind(e))
	
	# Rebuild UI and Timeline
	main.hud.build(main.player_team, main.enemy_team)
	main._update_gauge_display()
	main._regenerate_timeline()
