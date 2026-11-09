class_name GameSettings
extends RefCounted

"""
GameSettings: lưu/đọc các tùy chọn của người chơi (tốc độ trận, âm lượng, giảm rung màn hình, bỏ qua trận)
vào user://settings.cfg. Tách khỏi file save để đổi slot hay bắt đầu game mới không làm mất tùy chọn.
"""

const PATH := "user://settings.cfg"
const SECTION := "options"

static func load_into(gm: Node) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return # chưa có file (lần chạy đầu) hoặc hỏng: giữ giá trị mặc định
	gm.battle_speed = clampf(float(cfg.get_value(SECTION, "battle_speed", gm.battle_speed)), 0.2, 3.0)
	gm.master_volume = float(cfg.get_value(SECTION, "master_volume", gm.master_volume))
	gm.reduce_motion = bool(cfg.get_value(SECTION, "reduce_motion", gm.reduce_motion))
	gm.skip_battle_unlocked = bool(cfg.get_value(SECTION, "skip_battle_unlocked", gm.skip_battle_unlocked))
	gm.skip_battle_enabled = bool(cfg.get_value(SECTION, "skip_battle_enabled", gm.skip_battle_enabled)) and gm.skip_battle_unlocked

static func save_from(gm: Node) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "battle_speed", gm.battle_speed)
	cfg.set_value(SECTION, "master_volume", gm.master_volume)
	cfg.set_value(SECTION, "reduce_motion", gm.reduce_motion)
	cfg.set_value(SECTION, "skip_battle_unlocked", gm.skip_battle_unlocked)
	cfg.set_value(SECTION, "skip_battle_enabled", gm.skip_battle_enabled)
	cfg.save(PATH)
