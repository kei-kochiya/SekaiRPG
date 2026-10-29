extends ScriptedBattleScenario
class_name SlowStrikeScenario

"""
SlowStrikeScenario: thời gian chậm lại; Ichika chỉ còn một lựa chọn là tuyệt kỹ Ảnh Sát và hạ gục đối thủ ngay.

Kanade đã chảy máu sẵn (đòn cuối của Mizuki) nên Ảnh Sát kích nổ đủ MAX_BLEED stack Chảy máu; nếu vì lý do nào đó
đòn chưa đủ chí mạng thì vẫn kết liễu để cảnh phim không bị kẹt.
"""

const STRIKE = "shadow_strike"
const SLOW_TIME_SCALE = 0.55
const MAX_BLEED = 5

func on_start(main: Node):
	for p in main.player_team:
		if p.entity_name == "Ichika":
			p.cooldowns.erase(STRIKE) # bỏ hồi chiêu khởi đầu của tuyệt kỹ
			p.action_gauge = 10000.0 # Ichika ra đòn trước
	for e in main.enemy_team:
		for i in range(MAX_BLEED):
			e.add_status({"type": "Bleed", "duration": 3})
	Engine.time_scale = SLOW_TIME_SCALE # Main._exit_tree sẽ khôi phục
	main.hud.show_announcement("Thời gian như chậm lại...", UITheme.ACCENT)
	super.on_start(main)

func get_allowed_actions(_main: Node, _actor: Entity) -> Array:
	return [STRIKE]

func on_action_executed(main: Node, _actor: Entity, action: String, target: Entity):
	if action == STRIKE and target and target.current_hp > 0:
		target.take_damage(target.current_hp, "pure") # đòn chí tử, không còn đường lui
		if main.shaker:
			main.shaker.hitstop(0.5)

func check_battle_end(main: Node) -> bool:
	if AIManager.get_alive_targets(main.enemy_team).is_empty():
		main.battle_over = true
		return true
	return super.check_battle_end(main)
