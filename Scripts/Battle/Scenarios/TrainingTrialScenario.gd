extends ScriptedBattleScenario
class_name TrainingTrialScenario

"""
TrainingTrialScenario: bài kiểm tra ngày thứ bảy của "Khóa huấn luyện sinh tử" (truyện, chương 10).

Ichika một mình đối đầu Ena và Kanade, mạnh đúng bằng bản đồng đội của họ (kể cả mọi điểm nâng cấp).
- Thắng: hạ cả hai, HOẶC cầm cự cho tới khi chuông của Mafuyu rung (sau ENEMY_ACTIONS_TO_SURVIVE lượt hành động của hai kẻ địch).
- Thua: Ichika gục. Thua thì được thử lại (xem FinaleStage).
- Giữa trận chèn các đoạn thoại training_trial_bark_1..3 (đầu trận, giữa chừng và chặng cuối).
"""

const ENEMY_ACTIONS_TO_SURVIVE := 8

var _enemy_actions: int = 0
var _bell: bool = false
var _said_half: bool = false
var _said_last: bool = false

func on_start(main: Node):
	main.is_scripting = true
	main._regenerate_timeline()
	await say_lines("training_trial_bark_1")
	main.is_scripting = false
	main.run_battle()

func on_turn_start(main: Node, actor: Entity):
	if not main.enemy_team.has(actor):
		return
	_enemy_actions += 1
	if _enemy_actions > ENEMY_ACTIONS_TO_SURVIVE:
		_bell = true

func on_before_action(main: Node, actor: Entity):
	if not main.enemy_team.has(actor):
		return
	if not _said_half and _enemy_actions >= ENEMY_ACTIONS_TO_SURVIVE / 2:
		_said_half = true
		await say_lines("training_trial_bark_2")
	elif not _said_last and _enemy_actions >= ENEMY_ACTIONS_TO_SURVIVE - 1:
		_said_last = true
		await say_lines("training_trial_bark_3")

func check_battle_end(main: Node) -> bool:
	if _bell and not AIManager.get_alive_targets(main.player_team).is_empty():
		main.hud.show_announcement("CHUÔNG RUNG!", UITheme.PLAYER)
		main.end_battle(true)
		return true
	return super.check_battle_end(main)

func get_victory_status(main: Node) -> bool:
	if AIManager.get_alive_targets(main.player_team).is_empty():
		return false
	return _bell or AIManager.get_alive_targets(main.enemy_team).is_empty()
