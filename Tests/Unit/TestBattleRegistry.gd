extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Khóa cấu hình của các trận kịch bản hiện có (đội hình phe ta, số lượng và cấp kẻ địch, kịch bản dùng).
Đây là độ khó đã được chỉnh tay: đổi các con số này phải là chủ ý (sửa bảng dưới đây), không phải hệ quả của một lần dọn code.
"""

# id -> [đội phe ta, số kẻ địch, cấp kẻ địch đầu tiên, class kịch bản, class kẻ địch đầu tiên]
var EXPECTED := {
	"prologue": [["Ichika"], 3, 1, PrologueScenario, "Kidnapper"],
	"ena_vs_thugs": [["Ena"], 3, 25, ScriptedBattleScenario, "Thug"],
	"harbor_boss": [["Ichika", "Ena"], 1, 25, HarborBossScenario, "Captain"],
	"mizuki_vs_mafuyu": [["Mizuki"], 1, 100, ScriptedBattleScenario, "Mafuyu"],
	"ops_kanade": [["Kanade"], 2, 35, ScriptedBattleScenario, "Terrorist"],
	"ops_ichika": [["Ichika"], 2, 35, ScriptedBattleScenario, "Terrorist"],
	"ops_honami": [["Honami"], 3, 35, ScriptedBattleScenario, "Terrorist"],
	"pm_boss": [["Mafuyu", "Ena", "Mizuki"], 1, 50, PrimeMinisterBossScenario, "PrimeMinister"],
	"bounty_1": [["Ena"], 2, 22, ScriptedBattleScenario, "WarehouseWorker"],
	"bounty_2": [["Ena"], 2, 22, ScriptedBattleScenario, "Terrorist"],
	"bounty_3": [["Ena"], 1, 27, ScriptedBattleScenario, "Guard"],
	"bounty_ambush": [["Ena"], 4, 27, ForcedLossScenario, "PoliceOfficer"],
	"mizuki_police_1": [["Mizuki"], 2, 20, ScriptedBattleScenario, "PoliceOfficer"],
	"mizuki_police_2": [["Mizuki"], 3, 22, ScriptedBattleScenario, "PoliceOfficer"],
	"mizuki_vs_kanade": [["Mizuki", "Ichika"], 1, 100, FrozenAllyScenario, "Kanade"],
	"ichika_vs_kanade_slow": [["Ichika"], 1, 60, SlowStrikeScenario, "Kanade"],
	"street_skirmish": [["Ichika", "Mizuki"], 3, 20, DefaultScenario, "Terrorist"],
	"street_survival": [["Ichika", "Mizuki"], 3, 20, StreetSurvivalScenario, "Terrorist"],
}

func test_scripted_battle_setups_are_unchanged():
	GameManager.reset_game()
	for id in EXPECTED:
		var want: Array = EXPECTED[id]
		var data := BattleInitializer._setup_scripted_battle(id)
		var names: Array = data["player_team"].map(func(e): return e.entity_name)
		assert_eq(names, want[0], "%s party" % id)
		assert_eq(data["enemy_team"].size(), want[1], "%s enemy count" % id)
		assert_eq(data["enemy_team"][0].level, want[2], "%s enemy level" % id)
		assert_true(is_instance_of(data["scenario"], want[3]), "%s scenario class" % id)
		assert_eq(data["enemy_team"][0].get_script().get_global_name(), want[4], "%s enemy class" % id)

func test_party_enemies_that_mirror_members_follow_the_real_level():
	GameManager.reset_game()
	LevelManager.set_initial_level(GameManager.get_party_member("Mizuki"), 31)
	LevelManager.set_initial_level(GameManager.get_party_member("Ena"), 29)
	var ena_vs_mizuki := BattleInitializer._setup_scripted_battle("ena_vs_mizuki")
	assert_eq(ena_vs_mizuki["enemy_team"][0].level, 31, "the Mizuki opponent has the real Mizuki's level")
	var forced := BattleInitializer._setup_scripted_battle("mizuki_vs_ena_forced")
	var ena: Entity = forced["enemy_team"][0]
	assert_eq(ena.level, 29, "the Ena opponent has the real Ena's level")
	assert_eq(ena.current_hp, int(ena.max_hp * 0.4), "she starts at 40% HP after days of torture")

func test_final_mafuyu_keeps_her_mirror_and_floor():
	GameManager.reset_game()
	var boss := BattleInitializer.build_final_mafuyu()
	assert_true(boss.level >= BattleInitializer.FINAL_BOSS_FLOOR_LEVEL, "never below the floor level")
	assert_eq(boss.current_hp, boss.max_hp, "full HP at the start")
	assert_eq(boss.max_break_gauge, 400, "break gauge 400")
	boss.free()

func test_every_registry_battle_builds_non_empty_teams():
	# Mọi id kịch bản được map gán phải có trong bảng (nếu không trận sẽ rỗng và thắng ngay).
	var ids: Array = EXPECTED.keys() + ["ena_vs_mizuki", "mizuki_vs_ena_forced", "bounty_ambush", "final_mafuyu", "training_trial", "ops_ena", "honami_spar"]
	GameManager.reset_game()
	for id in ids:
		var data := BattleInitializer._setup_scripted_battle(id)
		assert_gt(data["player_team"].size(), 0, "%s has players" % id)
		assert_gt(data["enemy_team"].size(), 0, "%s has enemies" % id)
