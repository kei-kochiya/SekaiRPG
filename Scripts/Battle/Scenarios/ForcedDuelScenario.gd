extends ScriptedBattleScenario
class_name ForcedDuelScenario

"""
ForcedDuelScenario: Mizuki bị Kanade dùng từ trường điều khiển phải tấn công Ena; Ena không chống cự và phải thua.

- Lệnh của Mizuki bị ép thành "attack" lên Ena (không hiện menu).
- Ena bỏ qua mọi lượt. Sau HITS_TO_FINISH đòn, Ena gục dù còn máu.
- Giữa trận chèn các đoạn thoại forced_duel_line_1..3.
"""

const HITS_TO_FINISH = 3

var _mizuki_actions: int = 0

func _is_mizuki(actor: Entity) -> bool:
	return actor.entity_name == "Mizuki"

func on_before_action(_main: Node, actor: Entity):
	if _is_mizuki(actor) and _mizuki_actions < HITS_TO_FINISH:
		await say_lines("forced_duel_line_%d" % (_mizuki_actions + 1))

func get_forced_action(main: Node, actor: Entity) -> Dictionary:
	if not _is_mizuki(actor):
		return {}
	var targets = AIManager.get_alive_targets(main.enemy_team)
	if targets.is_empty():
		return {}
	return {"action": "attack", "target": targets[0]}

func skips_turn(main: Node, actor: Entity) -> bool:
	return main.enemy_team.has(actor)

func on_turn_skipped(main: Node, _actor: Entity):
	main.hud.show_announcement("Ena không chống cự...", UITheme.TEXT_MUTED)

func on_action_executed(main: Node, actor: Entity, _action: String, target: Entity):
	if not _is_mizuki(actor):
		return
	_mizuki_actions += 1
	if _mizuki_actions >= HITS_TO_FINISH and target and target.current_hp > 0:
		target.take_damage(target.current_hp, "pure")

func check_battle_end(main: Node) -> bool:
	if AIManager.get_alive_targets(main.enemy_team).is_empty():
		main.hud.show_announcement("Ena gục xuống.", UITheme.TEXT_MUTED)
		main.battle_over = true
		return true
	return super.check_battle_end(main)
