extends BattleScenario
class_name HarborBossScenario

var phase: int = 0
var turns_in_phase: int = 0

func on_start(main: Node):
	main.is_scripting = true
	main._regenerate_timeline()
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_boss_intro"), func():
		phase = 1
		main.is_scripting = false
		main.run_battle()
	)

func on_turn_start(main: Node, _actor: Entity):
	_check_transitions(main)
	turns_in_phase += 1

func on_entity_died(main: Node, _entity: Entity):
	_check_transitions(main)

func check_battle_end(main: Node) -> bool:
	if main.is_scripting: return false # Block end check while scripting
	
	var boss = main._get_entity("Đội Trưởng")
	var boss_dead = (boss == null or boss.current_hp <= 0)
	
	# Win condition: Boss dead in Phase 3
	if boss_dead and phase >= 3:
		main.hud.show_victory()
		main.battle_over = true
		return true
		
	# Special case for Phase 1 loss
	if AIManager.get_alive_targets(main.player_team).is_empty():
		if phase == 1:
			_handle_loss_p1(main)
			return false # Chuyển sang Phase 2, không kết thúc trận đấu
		else:
			main.hud.show_defeat()
			main.battle_over = true
			return true
			
	return false

func get_victory_status(main: Node) -> bool:
	var boss = main._get_entity("Đội Trưởng")
	return boss == null or boss.current_hp <= 0

func on_battle_completed(main: Node, is_victory: bool):
	var enemy_count = main.enemy_team.size()
	if is_victory:
		DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_victory"), func():
			GameManager.harbor_mission_done = true
			GameManager.finish_battle(is_victory, enemy_count)
		)
	else:
		GameManager.finish_battle(is_victory, enemy_count)

# --- Internal Harbor Logic ---

func _check_transitions(main: Node):
	if main.is_scripting: return
	
	var boss = main._get_entity("Đội Trưởng")
	var boss_dead = (boss == null or boss.current_hp <= 0)
	
	if phase == 1 and boss_dead:
		_revive_boss_p1(main)
	elif phase == 2 and boss_dead:
		_trigger_phase_3(main)

func _handle_loss_p1(main: Node):
	main.is_scripting = true
	phase = 2 
	turns_in_phase = 0
	
	var mafuyu = GameManager.get_party_member("Mafuyu")
	if mafuyu:
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
	
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_boss_mid_fight"), func():
		DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_mafuyu_reinforcement"), func():
			main.is_scripting = false 
		)
	)

func _revive_boss_p1(main: Node):
	var boss = main._get_entity("Đội Trưởng")
	if not boss: return
	
	main.is_scripting = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_boss_revive_p1"), func():
		boss.current_hp = int(boss.max_hp * 0.5)
		_sync_battle_state(main)
		main.is_scripting = false
	)

func _trigger_phase_3(main: Node):
	main.is_scripting = true
	phase = 3
	turns_in_phase = 0
	
	var honami = Honami.new()
	honami.is_harbor = true
	var boss = main._get_entity("Đội Trưởng")
	var ichika = GameManager.get_party_member("Ichika")
	var ena = GameManager.get_party_member("Ena")
	
	if ichika and ena:
		if ichika.current_hp <= 0: ichika.current_hp = int(ichika.max_hp * 0.5)
		if ena.current_hp <= 0: ena.current_hp = int(ena.max_hp * 0.5)
		main.player_team = [ichika, ena, main.player_team[0]]
		
	if boss:
		boss.max_hp = 5000
		boss.current_hp = 5000
	main.enemy_team = [boss, honami] if boss else [honami]
	
	_sync_battle_state(main)
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_honami_arrival"), func():
		main.is_scripting = false 
	)

func _sync_battle_state(main: Node):
	main.all_entities = main.player_team + main.enemy_team
	main._refresh_team_context()
	for e in main.all_entities:
		if not e.died.is_connected(main._on_entity_died):
			e.died.connect(main._on_entity_died.bind(e))
	main.hud.setup(main.player_team, main.enemy_team)
	main._setup_gauge_teams()
	main._regenerate_timeline()
