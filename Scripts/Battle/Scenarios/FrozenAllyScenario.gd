extends ScriptedBattleScenario
class_name FrozenAllyScenario

"""
FrozenAllyScenario: Mizuki đấu Kanade trong khi Ichika chết lặng, không thể cử động (và không bị nhắm tới).

Trận không thể thắng: kết thúc khi Mizuki gục.
"""

var _freeze_line_shown: bool = false

func _is_frozen(actor: Entity) -> bool:
	return actor.entity_name == "Ichika"

func on_start(main: Node):
	for p in main.player_team:
		if _is_frozen(p):
			p.untargetable = true
	super.on_start(main)

func skips_turn(_main: Node, actor: Entity) -> bool:
	return _is_frozen(actor)

func on_turn_skipped(main: Node, _actor: Entity):
	if not _freeze_line_shown:
		_freeze_line_shown = true
		await say_lines("ichika_freeze_line")
	else:
		main.hud.show_announcement("Ichika đứng chết lặng...", UITheme.TEXT_MUTED)

func check_battle_end(main: Node) -> bool:
	for p in main.player_team:
		if p.entity_name == "Mizuki" and p.current_hp <= 0:
			main.hud.show_announcement("Mizuki gục ngã.", UITheme.DANGER_TEXT)
			main.battle_over = true
			return true
	return super.check_battle_end(main)
