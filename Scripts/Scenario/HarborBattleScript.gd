extends Node
class_name HarborBattleScript

"""
HarborBattleScript: Quản lý các sự kiện kịch bản trong trận đấu Boss tại Cảng (Harbor).

Lớp này xử lý việc triệu hồi viện binh, chuyển đổi các giai đoạn (phase) của Boss,
hồi sinh Boss, và điều phối các đoạn hội thoại giữa trận đấu để tạo trải nghiệm
điện ảnh và thử thách cho người chơi.
"""

static func run_intro(main: Node, callback: Callable):
	"""
	Chạy đoạn giới thiệu đầu trận đấu Boss.

	Tạm dừng vòng lặp chiến đấu để chạy hội thoại, sau đó chuyển sang Phase 1.

	Args:
		main (Node): Tham chiếu đến BattleManager.
		callback (Callable): Hàm sẽ được gọi sau khi kết thúc hội thoại để bắt đầu trận đấu.
	"""
	if main == null:
		print("[HarborBattleScript] Lỗi: main là null trong run_intro.")
		return
		
	main.is_scripting = true
	main._regenerate_timeline()
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_boss_intro"), func():
		main.harbor_boss_phase = 1
		main.is_scripting = false
		callback.call()
	)

static func handle_loss(main: Node):
	"""
	Xử lý tình huống người chơi thua cuộc ở Phase 1 (Sự kiện kịch bản).

	Thay vì kết thúc game, sự kiện này sẽ triệu hồi Mafuyu đến cứu viện,
	hồi phục trạng thái và chuyển sang Phase 2.

	Args:
		main (Node): Tham chiếu đến BattleManager.
	"""
	if main == null: return
	
	main.is_scripting = true
	main.harbor_boss_phase = 2 
	main.turns_in_phase = 0
	
	# --- Cập nhật trạng thái cho Phase 2 ---
	var mafuyu = GameManager.get_party_member("Mafuyu")
	if mafuyu == null:
		print("[HarborBattleScript] Lỗi nghiêm trọng: Không tìm thấy Mafuyu trong party.")
		return
		
	mafuyu.current_hp = mafuyu.max_hp 
	for s in mafuyu.skills:
		if s.name == "Lost World": s.cooldown_turns = 5
	
	var boss = main._get_entity("Đội Trưởng")
	if boss:
		boss.atk = 150
		boss.defense = 80
		boss.current_hp = boss.max_hp
	
	main.player_team = [mafuyu]
	main.enemy_team = [boss] if boss else []
	_sync_battle_state(main)
	
	# Chạy hội thoại cứu viện
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_boss_mid_fight"), func():
		DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_mafuyu_reinforcement"), func():
			main.is_scripting = false 
		)
	)

static func check_transitions(main: Node):
	"""
	Kiểm tra điều kiện chuyển đổi giữa các Phase dựa trên trạng thái của Boss.

	Args:
		main (Node): Tham chiếu đến BattleManager.
	"""
	if main == null or main.is_scripting: return
	
	var boss = main._get_entity("Đội Trưởng")
	var boss_dead = (boss == null or boss.current_hp <= 0)
	
	if main.harbor_boss_phase == 1:
		if boss_dead:
			_revive_boss_p1(main)
	elif main.harbor_boss_phase == 2:
		if boss_dead:
			_trigger_phase_3(main)

static func _revive_boss_p1(main: Node):
	"""
	Hồi sinh Boss lần đầu (Phase 1 → Phase 1.5).

	Args:
		main (Node): Tham chiếu đến BattleManager.
	"""
	var boss = main._get_entity("Đội Trưởng")
	if not boss: 
		print("[HarborBattleScript] Cảnh báo: Không tìm thấy Boss để hồi sinh.")
		return
	
	main.is_scripting = true
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_boss_revive_p1"), func():
		boss.current_hp = int(boss.max_hp * 0.5)
		_sync_battle_state(main)
		main.is_scripting = false
	)

static func _trigger_phase_3(main: Node):
	"""
	Kích hoạt giai đoạn cuối (Phase 3) khi Honami xuất hiện.

	Args:
		main (Node): Tham chiếu đến BattleManager.
	"""
	if main == null or main.harbor_boss_phase == 3: return 
	
	main.is_scripting = true
	main.harbor_boss_phase = 3
	main.turns_in_phase = 0
	
	# --- Cập nhật trạng thái cho Phase 3 ---
	var honami = Honami.new()
	honami.is_harbor = true
	var boss = main._get_entity("Đội Trưởng")
	var ichika = GameManager.get_party_member("Ichika")
	var ena = GameManager.get_party_member("Ena")
	
	if ichika == null or ena == null:
		print("[HarborBattleScript] Lỗi: Thiếu thành viên Ichika hoặc Ena cho Phase 3.")
		return
		
	if ichika.current_hp <= 0: ichika.current_hp = int(ichika.max_hp * 0.5)
	if ena.current_hp <= 0: ena.current_hp = int(ena.max_hp * 0.5)
	
	main.player_team = [ichika, ena, main.player_team[0]] # [Ichika, Ena, Mafuyu]
	if boss:
		boss.max_hp = 5000
		boss.current_hp = 5000
	main.enemy_team = [boss, honami] if boss else [honami]
	
	_sync_battle_state(main)
	
	# Hội thoại kết thúc
	DialogueManager.play_dialogue(DialogueLoader.get_lines("harbor_honami_arrival"), func():
		main.is_scripting = false 
	)

static func _sync_battle_state(main: Node):
	"""
	Đồng bộ hóa dữ liệu trận đấu và cập nhật giao diện (HUD).

	Dùng khi có sự thay đổi về đội hình (thêm/bớt thành viên) giữa trận đấu.

	Args:
		main (Node): Tham chiếu đến BattleManager.
	"""
	if main == null: return
	
	main.all_entities = main.player_team + main.enemy_team
	main._refresh_team_context()
	
	# Kết nối tín hiệu cho thành viên mới
	for e in main.all_entities:
		if not e.died.is_connected(main._on_entity_died):
			e.died.connect(main._on_entity_died.bind(e))
	
	# Xây dựng lại UI và Timeline
	main.hud.setup(main.player_team, main.enemy_team)
	main._setup_gauge_teams()
	main._regenerate_timeline()
