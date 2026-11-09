extends ScriptedBattleScenario
class_name SparringScenario

"""
SparringScenario: Honami thử phản xạ của Ichika trong căn phòng trống dưới phòng khám (truyện, chương 11).

Honami chỉ PHÒNG THỦ: không ra đòn và không nhận sát thương (is_harbor). Ichika tự chọn FREE_TURNS lượt đầu,
đến lượt kế tiếp đòn Ảnh Sát được tung ra (ép) và bị Honami chặn đứng, rồi buổi tập kết thúc.
Không thể thắng; kết quả luôn là cờ honami_spar_done (ScriptedBattleOutcomes.FATED), cả đội được hồi đầy máu.
"""

const FREE_TURNS := 3

var _player_turns: int = 0
var _blocked: bool = false

func _honami(main: Node) -> Entity:
	for e in main.enemy_team:
		if e.entity_name == "Honami":
			return e
	return null

func on_start(main: Node):
	var h := _honami(main)
	if h:
		h.is_harbor = true # miễn nhiễm mọi sát thương: Honami chỉ đỡ đòn
	main.run_battle()

func on_turn_start(main: Node, actor: Entity):
	if main.player_team.has(actor):
		_player_turns += 1

func skips_turn(main: Node, actor: Entity) -> bool:
	return main.enemy_team.has(actor)

func on_turn_skipped(main: Node, _actor: Entity):
	main.hud.show_announcement("Honami giữ thế thủ...", UITheme.TEXT_MUTED)

func get_forced_action(main: Node, actor: Entity) -> Dictionary:
	if not main.player_team.has(actor) or _player_turns <= FREE_TURNS:
		return {}
	var h := _honami(main)
	if h == null:
		return {}
	return {"action": "shadow_strike", "target": h}

func on_action_executed(_main: Node, actor: Entity, action: String, _target: Entity):
	if actor.entity_name == "Ichika" and action == "shadow_strike":
		_blocked = true

func check_battle_end(main: Node) -> bool:
	if _blocked:
		main.hud.show_announcement("Ảnh Sát bị chặn đứng!", UITheme.TEXT_MUTED)
		main.battle_over = true
		return true
	return false

func get_victory_status(_main: Node) -> bool:
	return false

func on_battle_completed(_main: Node, _is_victory: bool):
	await say_lines("honami_spar_bark")
	GameManager.finish_battle(false, 0)
