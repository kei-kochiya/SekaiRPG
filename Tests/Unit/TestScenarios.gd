extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Kiểm tra luồng của các kịch bản trận có đổi đội hình giữa chừng (sinh quái, đợt hai, cứu viện, tiếp viện của boss),
dùng FakeBattleMain để không cần dựng cả BattleScene.
"""

func _setup(id: String) -> Array:
	GameManager.reset_game()
	var data := BattleInitializer._setup_scripted_battle(id)
	return [FakeBattleMain.new(data["player_team"], data["enemy_team"]), data["scenario"]]

func _kill(entity: Entity):
	entity.current_hp = 0

func test_convoy_second_wave_arrives_when_the_first_is_cleared():
	var s := _setup("ops_ena")
	var main: FakeBattleMain = s[0]
	var sc: ConvoyWavesScenario = s[1]
	sc.on_start(main)
	assert_true(main.ran, "the battle loop starts")
	assert_eq(main.enemy_team.size(), ConvoyWavesScenario.WAVE_SIZE, "wave 1 size")
	assert_false(sc.check_battle_end(main), "not over while wave 1 is alive")
	for e in main.enemy_team:
		_kill(e)
	assert_false(sc.check_battle_end(main), "clearing wave 1 starts wave 2 instead of ending the battle")
	assert_eq(main.enemy_team.size(), ConvoyWavesScenario.WAVE_SIZE, "wave 2 size")
	assert_eq(main.enemy_team[0].level, BattleInitializer.OPS_ENA_LEVEL + ConvoyWavesScenario.WAVE_TWO_LEVEL_BONUS, "wave 2 is stronger")
	assert_true(main.hud.announcements.has("ĐỢT 2!"), "wave 2 is announced")
	for e in main.enemy_team:
		_kill(e)
	assert_true(sc.check_battle_end(main), "clearing wave 2 ends the battle")
	assert_true(sc.get_victory_status(main), "and it is a win")
	main.free()

func test_street_survival_respawns_then_mafuyu_rescues_and_wins():
	var s := _setup("street_survival")
	var main: FakeBattleMain = s[0]
	var sc: StreetSurvivalScenario = s[1]
	sc.on_start(main)
	var ichika: Entity = main.player_team[0]
	assert_true(ichika.skills_disabled, "Ichika's skills are locked during the survival phase")
	
	var first: Entity = main.enemy_team[0]
	_kill(first)
	sc.on_entity_died(main, first)
	assert_eq(main.enemy_team.size(), 3, "a dead terrorist is replaced during survival")
	assert_false(main.enemy_team.has(first), "the dead one is gone from the team")
	assert_false(sc.is_rescue_phase, "still the survival phase")
	
	for p in main.player_team.duplicate():
		_kill(p)
	sc.on_entity_died(main, main.player_team[0])
	assert_true(sc.is_rescue_phase, "both fallen: Mafuyu steps in")
	assert_eq(main.player_team.size(), 1, "only Mafuyu fights now")
	assert_eq(main.player_team[0].entity_name, "Mafuyu", "the rescuer is Mafuyu")
	assert_eq(main.enemy_team.size(), 3, "three fresh terrorists")
	assert_false(ichika.skills_disabled, "Ichika's skills are unlocked again")
	assert_true(main.hud.announcements.has("MAFUYU CỨU VIỆN!"), "the rescue is announced")
	
	for i in StreetSurvivalScenario.RESCUE_KILLS:
		var e: Entity = main.enemy_team[0]
		_kill(e)
		sc.on_entity_died(main, e)
	assert_true(sc.check_battle_end(main), "enough kills end the battle")
	assert_true(sc.get_victory_status(main), "and it is a win")
	assert_eq(main.hud.results, [true], "the victory banner is shown exactly once")
	main.free()
	GameManager.reset_game() # trả buff tạm và HP của Mafuyu về như cũ

func test_prime_minister_calls_two_guards_once_below_half_hp():
	var s := _setup("pm_boss")
	var main: FakeBattleMain = s[0]
	var sc: PrimeMinisterBossScenario = s[1]
	var pm: Entity = main.enemy_team[0]
	sc.on_turn_start(main, pm)
	assert_eq(main.enemy_team.size(), 1, "no guards while the PM is healthy")
	pm.current_hp = int(pm.max_hp * 0.4)
	sc.on_turn_start(main, pm)
	assert_eq(main.enemy_team.size(), 3, "two guards arrive below 50% HP")
	assert_eq(main.enemy_team[1].entity_name, "Cảnh Vệ 1", "first guard name")
	assert_eq(main.enemy_team[2].entity_name, "Cảnh Vệ 2", "second guard name")
	assert_eq(main.enemy_team[1].level, PrimeMinisterBossScenario.GUARD_LEVEL, "guard level")
	sc.on_turn_start(main, pm)
	assert_eq(main.enemy_team.size(), 3, "the call for help happens only once")
	main.free()

# Trận kịch bản thường (không phải trận định mệnh) thua thì phải hiện banner thất bại, không im lặng
func test_a_scripted_battle_wipe_shows_the_defeat_banner_once():
	var ichika := Ichika.new()
	ichika.current_hp = 0
	var main := FakeBattleMain.new([ichika], [Guard.new()])
	var scenario := ScriptedBattleScenario.new()
	assert_true(scenario.check_battle_end(main), "Cả đội gục thì trận kết thúc")
	assert_eq(main.hud.results, [false], "Banner thất bại hiện đúng một lần")
	assert_true(main.battle_over, "battle_over được đặt")
	assert_true(scenario.check_battle_end(main), "Gọi lại vẫn kết thúc")
	assert_eq(main.hud.results.size(), 1, "Không hiện banner lần hai")
	ichika.free()
	main.free()

# Cả hai phe cùng gục: get_victory_status báo thắng nên banner cũng phải là thắng chứ không phải thất bại
func test_a_simultaneous_wipe_shows_victory_like_the_outcome_says():
	var ichika := Ichika.new()
	ichika.current_hp = 0
	var guard := Guard.new()
	guard.current_hp = 0
	var main := FakeBattleMain.new([ichika], [guard])
	var scenario := ScriptedBattleScenario.new()
	assert_true(scenario.check_battle_end(main), "Hai phe cùng gục thì trận kết thúc")
	assert_eq(main.hud.results, [true], "Banner thắng, khớp với get_victory_status")
	assert_true(scenario.get_victory_status(main), "Kết quả được ghi là thắng")
	main.free()
	ichika.free()
	guard.free()

# Main.end_battle thật (không phải bản giả của FakeBattleMain): banner chỉ hiện đúng một lần dù bị gọi hai lần
class CountingHud extends Node:
	var results: Array = []
	func show_victory(): results.append(true)
	func show_defeat(): results.append(false)

func test_real_main_shows_the_result_banner_only_once():
	var main = load("res://Scripts/Battle/Main.gd").new()
	var hud := CountingHud.new()
	main.hud = hud
	main.end_battle(false)
	main.end_battle(true)
	assert_eq(hud.results, [false], "Lần gọi đầu quyết định banner, lần hai bị bỏ qua")
	assert_true(main.battle_over, "battle_over được đặt")
	main.hud = null
	hud.free()
	main.free()

