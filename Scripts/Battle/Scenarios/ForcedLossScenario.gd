extends ScriptedBattleScenario
class_name ForcedLossScenario

"""
ForcedLossScenario: trận kịch bản người chơi KHÔNG thể thắng (vd. Ena bị Cảnh sát Quốc tế phục kích).

Người chơi có MAX_PLAYER_TURNS lượt hành động; sau đó đội hình bị áp đảo và trận kết thúc bằng thất bại.
"""

const MAX_PLAYER_TURNS = 3

var _player_turns: int = 0
var _overwhelmed: bool = false

func on_turn_start(main: Node, actor: Entity):
	if main.player_team.has(actor):
		_player_turns += 1
		if _player_turns > MAX_PLAYER_TURNS:
			_overwhelmed = true

func check_battle_end(main: Node) -> bool:
	if not _overwhelmed:
		return super.check_battle_end(main)
	
	main.hud.show_announcement("Bị áp đảo...", UITheme.DANGER_TEXT)
	for p in main.player_team:
		if p.current_hp > 0:
			p.take_damage(p.current_hp, "pure")
	main.battle_over = true
	return true
