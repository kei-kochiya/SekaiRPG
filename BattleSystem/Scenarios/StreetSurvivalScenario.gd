extends BattleScenario
class_name StreetSurvivalScenario

"""
StreetSurvivalScenario: Kịch bản trận chiến sinh tồn và cứu viện đặc biệt.
- Ichika & Mizuki bị vô hiệu hóa kỹ năng.
- Quái Terrorist xuất hiện vô tận, tăng cấp dần từ 25 lên 30.
- Khi cả hai bị đánh bại (HP = 0), Mafuyu sẽ xuất hiện cứu viện.
- Mafuyu diệt đủ 10 tên khủng bố để giành chiến thắng.
"""

var spawn_counter: int = 3
var turns_elapsed: int = 0
var kill_count: int = 0
var is_rescue_phase: bool = false

var original_mafuyu_atk: int = 0
var original_mafuyu_def: int = 0

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
		LevelManager.set_initial_level(e, 25)
		
	main.run_battle()

func on_turn_start(main: Node, actor: Entity):
	if is_rescue_phase:
		return
		
	turns_elapsed += 1
	var current_level = clamp(25 + int(turns_elapsed / 2), 25, 30)
	
	# Tăng cấp cho kẻ địch đang hoạt động nếu level thấp hơn
	for e in main.enemy_team:
		if e.current_hp > 0 and e.level < current_level:
			LevelManager.set_initial_level(e, current_level)
			print("[Level Scaling] Nâng cấp ", e.entity_name, " lên Level ", current_level)

func on_entity_died(main: Node, entity: Entity):
	if not is_rescue_phase:
		# Nếu là kẻ địch chết trong pha sinh tồn, lập tức spawn con mới thế chỗ
		if entity in main.enemy_team:
			spawn_counter += 1
			var current_level = clamp(25 + int(turns_elapsed / 2), 25, 30)
			var new_enemy = Terrorist.new()
			new_enemy.entity_name = "Khủng Bố " + str(spawn_counter)
			LevelManager.set_initial_level(new_enemy, current_level)
			
			main.enemy_team.append(new_enemy)
			main.all_entities.append(new_enemy)
			new_enemy.died.connect(main._on_entity_died.bind(new_enemy))
			
			main._refresh_team_context()
			main.hud.setup(main.player_team, main.enemy_team)
			main._setup_gauge_teams()
			main._regenerate_timeline()
			print("[Infinite Spawn] Kẻ địch mới xuất hiện: ", new_enemy.entity_name, " (Level ", current_level, ")")
			
		# Kiểm tra nếu cả hai Ichika và Mizuki đều gục ngã
		var alive_players = AIManager.get_alive_targets(main.player_team)
		if alive_players.is_empty():
			_trigger_rescue_phase(main)
	else:
		# Pha cứu viện:
		if entity in main.enemy_team:
			kill_count += 1
			print("[Rescue Phase] Mafuyu hạ gục tên khủng bố thứ ", kill_count, "/10")
			
			# Nếu chưa đủ 10 mạng, tiếp tục spawn quái level 30
			if kill_count < 10:
				spawn_counter += 1
				var new_enemy = Terrorist.new()
				new_enemy.entity_name = "Khủng Bố " + str(spawn_counter)
				LevelManager.set_initial_level(new_enemy, 30)
				
				main.enemy_team.append(new_enemy)
				main.all_entities.append(new_enemy)
				new_enemy.died.connect(main._on_entity_died.bind(new_enemy))
				
				main._refresh_team_context()
				main.hud.setup(main.player_team, main.enemy_team)
				main._setup_gauge_teams()
				main._regenerate_timeline()
			else:
				# Đã hạ gục 10 tên, chiến thắng!
				print("[StreetSurvivalScenario] Mafuyu dẹp sạch vòng vây! Chiến thắng!")
				main.hud.show_victory()
				main.battle_over = true

func _trigger_rescue_phase(main: Node):
	is_rescue_phase = true
	print("[StreetSurvivalScenario] Kích hoạt pha cứu viện từ Mafuyu!")
	
	# Giải phóng cờ vô hiệu hóa kỹ năng cho Ichika và Mizuki để sạch state sau trận
	var ichika = GameManager.get_party_member("Ichika")
	var mizuki = GameManager.get_party_member("Mizuki")
	if ichika: ichika.skills_disabled = false
	if mizuki: mizuki.skills_disabled = false
	
	# Lấy Mafuyu từ party
	var mafuyu = GameManager.get_party_member("Mafuyu")
	if not mafuyu:
		# Dự phòng nếu không tìm thấy trong party
		mafuyu = Mafuyu.new()
		LevelManager.set_initial_level(mafuyu, 30)
		
	# Hồi phục đầy máu cho Mafuyu
	mafuyu.current_hp = mafuyu.max_hp
	
	# Buff sức mạnh riêng cho Mafuyu ở pha này (+50% ATK & DEF)
	original_mafuyu_atk = mafuyu.atk
	original_mafuyu_def = mafuyu.defense
	mafuyu.atk = int(mafuyu.atk * 1.5)
	mafuyu.defense = int(mafuyu.defense * 1.5)
	
	# Tráo đổi đội hình phe ta thành duy nhất Mafuyu
	main.player_team = [mafuyu]
	if not mafuyu.died.is_connected(main._on_entity_died):
		mafuyu.died.connect(main._on_entity_died.bind(mafuyu))
		
	# Dọn dẹp kẻ địch cũ, tạo mới 3 tên Level 30
	main.enemy_team.clear()
	for i in range(3):
		spawn_counter += 1
		var e = Terrorist.new()
		e.entity_name = "Khủng Bố " + str(spawn_counter)
		LevelManager.set_initial_level(e, 30)
		main.enemy_team.append(e)
		e.died.connect(main._on_entity_died.bind(e))
		
	# Cập nhật toàn bộ hệ thống Battle Engine
	main.all_entities = main.player_team + main.enemy_team
	main._refresh_team_context()
	for e in main.all_entities:
		e.action_gauge = 0.0 # Reset thanh hành động để bắt đầu pha cứu viện công bằng
	main.hud.setup(main.player_team, main.enemy_team)
	main._setup_gauge_teams()
	main._regenerate_timeline()
	
	# Hiển thị Banner cứu viện
	if main.hud.has_method("_create_banner"):
		var banner = main.hud._create_banner("MAFUYU CỨU VIỆN!", Color(0.6, 0.4, 1.0))
		main.hud.add_child(banner)
		banner.position.y -= 150
		var tw = main.create_tween()
		tw.tween_property(banner, "modulate:a", 1.0, 0.3)
		tw.tween_interval(1.5)
		tw.tween_property(banner, "modulate:a", 0.0, 0.3)
		tw.tween_callback(banner.queue_free)

func check_battle_end(main: Node) -> bool:
	if not is_rescue_phase:
		# Trong pha sinh tồn, không bao giờ thua (đợi trigger_rescue_phase)
		return false
		
	# Phe ta thua nếu Mafuyu gục ngã
	if AIManager.get_alive_targets(main.player_team).is_empty():
		main.hud.show_defeat()
		main.battle_over = true
		return true
		
	# Phe ta thắng nếu hạ đủ 10 quái
	if kill_count >= 10:
		main.hud.show_victory()
		main.battle_over = true
		return true
		
	return false

func get_victory_status(main: Node) -> bool:
	return kill_count >= 10

func on_battle_completed(main: Node, is_victory: bool):
	# Khôi phục chỉ số gốc của Mafuyu
	var mafuyu = GameManager.get_party_member("Mafuyu")
	if mafuyu and original_mafuyu_atk > 0:
		mafuyu.atk = original_mafuyu_atk
		mafuyu.defense = original_mafuyu_def
		
	# Đảm bảo tắt cờ skills_disabled
	var ichika = GameManager.get_party_member("Ichika")
	var mizuki = GameManager.get_party_member("Mizuki")
	if ichika: ichika.skills_disabled = false
	if mizuki: mizuki.skills_disabled = false
	
	if is_victory:
		GameManager.story.set_flag("street_survival_done", true)
		
	super.on_battle_completed(main, is_victory)
