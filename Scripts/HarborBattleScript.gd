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
	
	# --- IMMEDIATE STATE UPDATE for Phase 2 ---
	var mafuyu = GameManager.get_party_member("Mafuyu")
	mafuyu.current_hp = mafuyu.max_hp 
	for s in mafuyu.skills:
		if s.name == "Lost World": s.cooldown_turns = 5
	
	var boss = main._get_entity("Đội Trưởng")
	if boss:
		boss.atk = 150
		boss.defense = 80
		boss.current_hp = boss.max_hp
	
	main.player_team = [mafuyu]
	main.enemy_team = [boss] if boss else []
	_sync_battle_state(main)
	
	# Dialogue follows
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_boss_mid_fight"), func():
		DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_mafuyu_reinforcement"), func():
			main.is_scripting = false 
		)
	)

static func check_transitions(main: Node):
	if main.is_scripting: return
	
	var boss = main._get_entity("Đội Trưởng")
	var boss_dead = (boss == null or boss.current_hp <= 0)
	
	if main.harbor_boss_phase == 1:
		if boss_dead:
			_revive_boss_p1(main)
	elif main.harbor_boss_phase == 2:
		if boss_dead:
			_trigger_phase_3(main)

static func _revive_boss_p1(main: Node):
	var boss = main._get_entity("Đội Trưởng")
	if not boss: return
	
	main.is_scripting = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_boss_revive_p1"), func():
		boss.current_hp = int(boss.max_hp * 0.5)
		_sync_battle_state(main)
		main.is_scripting = false
	)

static func _trigger_phase_3(main: Node):
	if main.harbor_boss_phase == 3: return 
	
	main.is_scripting = true
	main.harbor_boss_phase = 3
	main.turns_in_phase = 0
	
	# --- IMMEDIATE STATE UPDATE for Phase 3 ---
	var honami = Honami.new()
	honami.is_harbor = true
	var boss = main._get_entity("Đội Trưởng")
	var ichika = GameManager.get_party_member("Ichika")
	var ena = GameManager.get_party_member("Ena")
	
	if ichika.current_hp <= 0: ichika.current_hp = int(ichika.max_hp * 0.5)
	if ena.current_hp <= 0: ena.current_hp = int(ena.max_hp * 0.5)
	
	main.player_team = [ichika, ena, main.player_team[0]] # [Ichika, Ena, Mafuyu]
	if boss:
		boss.max_hp = 5000
		boss.current_hp = 5000
	main.enemy_team = [boss, honami] if boss else [honami]
	
	_sync_battle_state(main)
	
	# Dialogue follows
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_honami_arrival"), func():
		main.is_scripting = false 
	)

static func _sync_battle_state(main: Node):
	main.all_entities = main.player_team + main.enemy_team
	main._refresh_team_context()
	
	# Connect signals for new members
	for e in main.all_entities:
		if not e.died.is_connected(main._on_entity_died):
			e.died.connect(main._on_entity_died.bind(e))
	
	# Rebuild UI and Timeline
	main.hud.build(main.player_team, main.enemy_team)
	main._update_gauge_player_names()
	main._update_gauge_display()
	main._regenerate_timeline()
