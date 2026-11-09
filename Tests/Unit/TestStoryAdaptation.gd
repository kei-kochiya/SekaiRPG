extends "res://Tests/Unit/BaseTest.gd"

"""
Tóm tắt: Bảo vệ phần cốt truyện đưa từ truyện "Giao ước lúc 25h" vào game: mọi hội thoại đúng định dạng, các khóa
hội thoại mới có mặt và kịch bản của ba trận mới (bài kiểm tra huấn luyện, Ena hộ tống, buổi thử phản xạ của Honami)
chạy đúng luật. Đội hình của chúng được TestBattleRegistry khóa.
"""

const STORY_DIR := "res://Data/storyline/"
const MAX_TEXT_LEN := 260

# Các khóa hội thoại mới, kèm nơi code gọi chúng
const NEW_KEYS := [
	"training_week_intro", "training_week_drills", "training_trial_pre", "training_trial_retry",
	"training_trial_bark_1", "training_trial_bark_2", "training_trial_bark_3", "training_trial_post", "training_welcome",
	"ops_ena_pre", "ops_ena_mid", "ops_ena_post",
	"honami_spar_pre", "honami_spar_bark", "honami_spar_post",
	"street_car_ride", "harbor_gate_firefight",
	"epilogue_bar_invite", "epilogue_bar_shiho",
]

# Khóa hội thoại của hồi kết 2 (Nightcord sụp đổ), gồm cả khóa ghép tên động (forced_duel_line_N...) mà quét literal không thấy
const ARC_KEYS = [
	"base_celebration", "ena_leaves_aftermath",
	"bounty_intro", "bounty_1_pre", "bounty_1_post", "bounty_2_pre", "bounty_2_post", "bounty_3_pre", "bounty_3_post",
	"bounty_ambush_mid", "bounty_ambush_end",
	"interrogation_torture_1", "interrogation_torture_2", "orders_mafuyu", "warehouse_mizuki_arrive",
	"mizuki_police_1_pre", "mizuki_police_2_pre", "mizuki_police_done", "warehouse_mafuyu_arrive",
	"forced_duel_pre", "forced_duel_line_1", "forced_duel_line_2", "forced_duel_line_3", "forced_duel_post", "kanade_dossier",
	"kanade_confront_pre", "ichika_freeze_line", "mizuki_dies", "kanade_slow_pre", "kanade_death", "reveal_mafuyu", "honami_rescue",
	"honami_options_intro", "honami_menu_prompt", "honami_training_offer_arc2", "honami_upgrade_offer",
	"final_mafuyu_pre", "final_mafuyu_lose", "final_mafuyu_post", "ending_honami_offer", "ending_narration",
	"epilogue_base_intro", "epilogue_honami_talk", "epilogue_honami_idle",
]

func _all_dialogue() -> Dictionary:
	var out := {}
	var dir := DirAccess.open(STORY_DIR)
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(STORY_DIR + f))
		if parsed is Dictionary:
			for k in parsed:
				out[k] = {"file": f, "lines": parsed[k]}
	return out

func test_every_dialogue_file_parses_and_has_unique_keys():
	var seen := {}
	var dir := DirAccess.open(STORY_DIR)
	for f in dir.get_files():
		if not f.ends_with(".json"):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(STORY_DIR + f))
		assert_true(parsed is Dictionary, "%s parses as an object" % f)
		if not parsed is Dictionary:
			continue
		for k in parsed:
			assert_false(seen.has(k), "dialogue key '%s' is defined once (%s)" % [k, f])
			seen[k] = f

func test_every_dialogue_entry_is_well_formed():
	var all := _all_dialogue()
	for key in all:
		var info: Dictionary = all[key]
		var lines: Array = info["lines"]
		assert_gt(lines.size(), 0, "%s has lines" % key)
		for i in lines.size():
			var e: Dictionary = lines[i]
			var where := "%s[%d] in %s" % [key, i, info["file"]]
			var t: String = e.get("type", "")
			assert_true(t in ["dialogue", "narrator", "action"], where + " has a valid type")
			var text: String = e.get("text", "")
			assert_gt(text.length(), 0, where + " has text")
			assert_true(text.length() <= MAX_TEXT_LEN, where + " fits a dialogue box (%d chars)" % text.length())
			if t != "narrator":
				assert_true(str(e.get("name", "")) != "", where + " names its speaker")
				assert_true(e.get("speaker", "") in ["left", "right"], where + " has a portrait side")
				assert_true(str(e.get("color", "")).is_valid_html_color(), where + " has a valid colour")

func test_new_dialogue_keys_exist():
	for key in NEW_KEYS + ARC_KEYS:
		assert_gt(DialogueLoader.get_lines(key).size(), 0, "dialogue key exists: " + key)

# Cờ của các cảnh mới đã được TestStaticChecks bảo vệ (mọi cờ literal trong code phải khai báo trong DEFAULT_FLAGS); ở đây chỉ ghim luật kết cục
func test_new_battles_have_their_outcome_rules():
	assert_eq(ScriptedBattleOutcomes.FATED.get("honami_spar"), "honami_spar_done", "spar sets its flag win or lose")
	assert_eq(ScriptedBattleOutcomes.WIN_FLAG.get("training_trial"), "training_trial_won", "trial sets its flag on a win")
	assert_true("ops_ena" in ScriptedBattleOutcomes.RETREAT_ON_LOSS, "losing the convoy fight retreats like the other ops")

func test_trial_opponents_mirror_the_real_party_members():
	var ena: Entity = GameManager.get_party_member("Ena")
	LevelManager.set_initial_level(ena, 20)
	var data = BattleInitializer._setup_scripted_battle("training_trial")
	var clone: Entity = data["enemy_team"][0]
	assert_eq(clone.entity_name, "Ena", "first opponent is Ena")
	assert_eq(clone.level, 20, "the clone has the same level as the real Ena")
	assert_eq(clone.max_hp, int(ena.max_hp * BattleInitializer.TRAINING_TRIAL_MIRROR["max_hp"]), "max HP follows the mirror factor")
	assert_eq(clone.current_hp, clone.max_hp, "the clone starts at full HP")

func test_training_trial_is_won_by_surviving_until_the_bell():
	var data = BattleInitializer._setup_scripted_battle("training_trial")
	var main := FakeBattleMain.new(data["player_team"], data["enemy_team"])
	var sc: TrainingTrialScenario = data["scenario"]
	assert_false(sc.check_battle_end(main), "not over at the start")
	for i in TrainingTrialScenario.ENEMY_ACTIONS_TO_SURVIVE:
		sc.on_turn_start(main, main.enemy_team[i % 2])
	assert_false(sc.check_battle_end(main), "not over right before the bell")
	sc.on_turn_start(main, main.enemy_team[0])
	assert_true(sc.check_battle_end(main), "the bell ends the trial")
	assert_true(sc.get_victory_status(main), "surviving until the bell is a win")
	main.free()

func test_training_trial_is_lost_when_ichika_falls():
	var data = BattleInitializer._setup_scripted_battle("training_trial")
	var main := FakeBattleMain.new(data["player_team"], data["enemy_team"])
	var sc: TrainingTrialScenario = data["scenario"]
	main.player_team[0].current_hp = 0
	assert_true(sc.check_battle_end(main), "the trial ends when Ichika is down")
	assert_false(sc.get_victory_status(main), "and it is a loss")
	main.free()

func test_sparring_honami_cannot_be_hurt_and_ends_on_a_forced_shadow_strike():
	var data = BattleInitializer._setup_scripted_battle("honami_spar")
	var main := FakeBattleMain.new(data["player_team"], data["enemy_team"])
	var sc: SparringScenario = data["scenario"]
	var honami: Honami = main.enemy_team[0]
	sc.on_start(main)
	assert_true(main.ran, "the battle loop starts")
	assert_true(honami.is_harbor, "Honami is immune while sparring")
	var before := honami.current_hp
	honami.take_damage(99999)
	assert_eq(honami.current_hp, before, "no damage gets through")
	assert_true(sc.skips_turn(main, honami), "Honami never attacks")
	var ichika: Entity = main.player_team[0]
	for i in SparringScenario.FREE_TURNS:
		sc.on_turn_start(main, ichika)
		assert_true(sc.get_forced_action(main, ichika).is_empty(), "turn %d is the player's own" % (i + 1))
	sc.on_turn_start(main, ichika)
	var forced := sc.get_forced_action(main, ichika)
	assert_eq(forced.get("action"), "shadow_strike", "the next turn is a forced Shadow Strike")
	assert_false(sc.check_battle_end(main), "the spar is not over before the strike lands")
	sc.on_action_executed(main, ichika, "shadow_strike", honami)
	assert_true(sc.check_battle_end(main), "the spar ends once the strike is blocked")
	assert_false(sc.get_victory_status(main), "sparring is never a win")
	main.free()
