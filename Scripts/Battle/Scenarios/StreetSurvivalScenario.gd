extends BattleScenario
class_name StreetSurvivalScenario

"""
StreetSurvivalScenario: Kịch bản trận chiến sinh tồn và cứu viện đặc biệt.
- Ichika & Mizuki bị vô hiệu hóa kỹ năng.
- Quái Terrorist xuất hiện vô tận, cấp tăng dần từ MIN_LEVEL lên MAX_LEVEL.
- Khi cả hai bị đánh bại (HP = 0) hoặc cầm cự được MAX_SURVIVAL_TURNS lượt, Mafuyu xuất hiện cứu viện.
- Mafuyu diệt đủ RESCUE_KILLS tên khủng bố để giành chiến thắng.
"""

const MIN_LEVEL := 20
const MAX_LEVEL := 25
const MAX_SURVIVAL_TURNS := 10
const RESCUE_KILLS := 5

var spawn_counter: int = 3
var turns_elapsed: int = 0
var kill_count: int = 0
var is_rescue_phase: bool = false

func on_start(main: Node):
	print("[StreetSurvivalScenario] Khởi chạy trận chiến sinh tồn!")
	turns_elapsed = 0
	kill_count = 0
	is_rescue_phase = false

	# Vô hiệu hóa kỹ năng của Ichika và Mizuki
	for p in main.player_team:
		if p.entity_name in ["Ichika", "Mizuki"]:
			p.skills_disabled = true

	# Bảo đảm quái đầu trận có level 25
	for e in main.enemy_team:
		LevelManager.set_initial_level(e, MAX_LEVEL)

	main.run_battle()

# Cấp của quái mới/đang sống ở lượt hiện tại: tăng một bậc sau mỗi hai lượt, trong khoảng MIN..MAX
func _survival_level() -> int:
	return clampi(MIN_LEVEL + int(turns_elapsed / 2), MIN_LEVEL, MAX_LEVEL)

func on_turn_start(main: Node, _actor: Entity):
	if is_rescue_phase:
		return

	turns_elapsed += 1

	# Giới hạn số lượt sống sót tối đa (nếu quá trâu bò không chết thì tự động qua pha sau)
	if turns_elapsed >= MAX_SURVIVAL_TURNS:
		print("[StreetSurvivalScenario] Người chơi sống quá dai! Kích hoạt cứu viện tự động.")
		_trigger_rescue_phase(main)
		return

	# Tăng cấp cho kẻ địch đang hoạt động nếu level thấp hơn
	var current_level := _survival_level()
	for e in main.enemy_team:
		if e.current_hp > 0 and e.level < current_level:
			LevelManager.set_initial_level(e, current_level)
			print("[Level Scaling] Nâng cấp ", e.entity_name, " lên Level ", current_level)

func on_entity_died(main: Node, entity: Entity):
	if not main.enemy_team.has(entity):
		# Pha sinh tồn: kiểm tra nếu cả hai Ichika và Mizuki đều gục ngã thì cứu viện
		if not is_rescue_phase and AIManager.get_alive_targets(main.player_team).is_empty():
			_trigger_rescue_phase(main)
		return

	_remove_enemy(main, entity)
	if not is_rescue_phase:
		# Kẻ địch chết trong pha sinh tồn: lập tức spawn con mới thế chỗ
		_spawn_terrorist(main, _survival_level())
		print("[Infinite Spawn] Kẻ địch mới xuất hiện (Level ", _survival_level(), ")")
		if AIManager.get_alive_targets(main.player_team).is_empty():
			_trigger_rescue_phase(main)
		return

	# Pha cứu viện
	kill_count += 1
	print("[Rescue Phase] Mafuyu hạ gục tên khủng bố thứ ", kill_count, "/", RESCUE_KILLS)
	if kill_count < RESCUE_KILLS:
		_spawn_terrorist(main, MAX_LEVEL) # chưa đủ mạng: tiếp tục spawn quái level 25
	else:
		print("[StreetSurvivalScenario] Mafuyu dẹp sạch vòng vây! Chiến thắng!")
		main.end_battle(true)

func _remove_enemy(main: Node, entity: Entity):
	main.enemy_team.erase(entity)
	main.all_entities.erase(entity)
	entity.queue_free()

func _spawn_terrorist(main: Node, level: int, refresh: bool = true):
	spawn_counter += 1
	main.add_combatant(BattleInitializer.create_enemy("terrorist", level, "Khủng Bố " + str(spawn_counter)))
	if refresh:
		main.refresh_battle_state()

# Trả kỹ năng cho Ichika và Mizuki (cờ chỉ tồn tại trong trận này nhưng hai nhân vật là bản bền vững)
func _unlock_skills():
	for n in ["Ichika", "Mizuki"]:
		var member = GameManager.get_party_member(n)
		if member:
			member.skills_disabled = false

func _trigger_rescue_phase(main: Node):
	is_rescue_phase = true
	print("[StreetSurvivalScenario] Kích hoạt pha cứu viện từ Mafuyu!")

	# Giải phóng cờ vô hiệu hóa kỹ năng để sạch state sau trận
	_unlock_skills()

	# Lấy Mafuyu từ party
	var mafuyu = GameManager.get_party_member("Mafuyu")
	if not mafuyu:
		# Dự phòng nếu không tìm thấy trong party
		mafuyu = Mafuyu.new()
		LevelManager.set_initial_level(mafuyu, 30)

	# Hồi phục đầy máu cho Mafuyu
	mafuyu.current_hp = mafuyu.max_hp

	# Buff sức mạnh riêng cho Mafuyu ở pha này (+50% ATK & DEF)
	mafuyu.add_temp_mod("atk", int(mafuyu.atk * 0.5))
	mafuyu.add_temp_mod("defense", int(mafuyu.defense * 0.5))

	# Tráo đổi đội hình phe ta thành duy nhất Mafuyu; dọn kẻ địch cũ, tạo mới 3 tên Level 25
	main.player_team = [mafuyu]
	for e in main.enemy_team:
		e.queue_free() # quái còn sống của pha sinh tồn bị dọn: giải phóng thay vì bỏ mồ côi
	main.enemy_team.clear()
	main.all_entities.clear()
	main.all_entities.append_array(main.player_team)
	main._connect_combatant(mafuyu)
	main.prepare_entity(mafuyu) # Reset trạng thái để bắt đầu pha cứu viện công bằng
	for i in 3:
		_spawn_terrorist(main, MAX_LEVEL, false)
	main.refresh_battle_state()

	# Hiển thị Banner cứu viện
	main.hud.show_announcement("MAFUYU CỨU VIỆN!", UITheme.PLAYER)

func check_battle_end(main: Node) -> bool:
	if not is_rescue_phase:
		# Trong pha sinh tồn, không bao giờ thua (đợi trigger_rescue_phase)
		return false

	# Phe ta thua nếu Mafuyu gục ngã
	if AIManager.get_alive_targets(main.player_team).is_empty():
		main.end_battle(false)
		return true

	# Phe ta thắng nếu hạ đủ số quái
	if kill_count >= RESCUE_KILLS:
		main.end_battle(true)
		return true

	return false

func get_victory_status(_main: Node) -> bool:
	return kill_count >= RESCUE_KILLS

func on_battle_completed(_main: Node, is_victory: bool):
	# Buff của Mafuyu là chỉ số tạm thời: Main._exit_tree sẽ gỡ. Đảm bảo tắt cờ skills_disabled
	_unlock_skills()

	GameManager.finish_battle(is_victory)
