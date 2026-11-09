extends ScriptedBattleScenario
class_name ConvoyWavesScenario

"""
ConvoyWavesScenario: Ena hộ tống đoàn xe chở bom trên cầu gần Vịnh Tokyo (truyện, chương 9).

Ena một mình đấu hai đợt khủng bố (WAVE_SIZE tên mỗi đợt). Hạ hết đợt 1 thì đợt 2 xông tới, mạnh hơn
WAVE_TWO_LEVEL_BONUS cấp; hạ hết đợt 2 là thắng. Ena gục là thua (map phát lại / về căn cứ như các trận Tác chiến khác).
"""

const WAVE_SIZE := 4
const WAVE_TWO_LEVEL_BONUS := 3

var _wave: int = 1
var _spawn_counter: int = 0
var _wave_two_bark_pending: bool = false

func on_start(main: Node):
	_spawn_counter = main.enemy_team.size()
	main.run_battle()

# Đợt 1 hết thì thả đợt 2 tại đây (do vòng lặp trận gọi), không làm trong tín hiệu died khi kỹ năng còn đang chạy
func check_battle_end(main: Node) -> bool:
	var players_alive := not AIManager.get_alive_targets(main.player_team).is_empty()
	if _wave == 1 and AIManager.get_alive_targets(main.enemy_team).is_empty() and players_alive:
		_wave = 2
		_start_wave_two(main)
		return false
	return super.check_battle_end(main)

func _start_wave_two(main: Node):
	var level: int = BattleInitializer.OPS_ENA_LEVEL
	if not main.enemy_team.is_empty():
		level = main.enemy_team[0].level
	level += WAVE_TWO_LEVEL_BONUS
	
	# Dọn đợt 1 (đã chết hết) rồi thả đợt 2
	for dead in main.enemy_team.duplicate():
		main.enemy_team.erase(dead)
		main.all_entities.erase(dead)
		dead.queue_free()
	for i in WAVE_SIZE:
		_spawn_counter += 1
		main.add_combatant(BattleInitializer.create_enemy("terrorist", level, "Khủng Bố " + str(_spawn_counter)))
	main.refresh_battle_state()
	main.hud.show_announcement("ĐỢT 2!", UITheme.ENEMY)
	_wave_two_bark_pending = true

func on_before_action(_main: Node, _actor: Entity):
	if _wave_two_bark_pending:
		_wave_two_bark_pending = false
		await say_lines("ops_ena_mid")
