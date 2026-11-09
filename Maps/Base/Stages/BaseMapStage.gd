extends Node
class_name BaseMapStage

"""
BaseMapStage: Lớp cơ sở cho các kịch bản diễn ra tại BaseMap.
Mỗi Stage quản lý vị trí NPC, hội thoại và logic nhiệm vụ riêng biệt.
"""

# Tham chiếu ngược lại BaseMap để điều khiển visual
var map: Node2D

# Đang chạy cảnh tự chạy: talk_to_npc bỏ qua mọi tương tác NPC (thay cho biến + dòng `if _cutscene_active: return` chép ở 8 Stage)
var _cutscene_active: bool = false

# true = cửa ra bị khoá suốt Stage này (các cảnh tự chạy Hồi kết 2, đặt trong _init); thay cho các handle_exit() chỉ trả về true.
# Stage ghi đè handle_exit (vd. Finale, có thêm dòng dẫn truyện) thì không cần cờ này.
var exit_locked: bool = false

func setup(p_map: Node2D):
	map = p_map

# Trả về danh sách vị trí NPC: { "Name": Vector2 }
func get_npc_positions() -> Dictionary:
	return {}

# Logic chạy ngay khi vào Map
func on_stage_start():
	pass

# Trả về màu ánh sáng của bản đồ (Color.WHITE = bình thường, tối hơn = ban đêm)
# Được gọi TRƯỚC fade_in để tránh flash sáng
func get_scene_lighting() -> Color:
	return Color.WHITE

# Xác định bài nhạc nền sẽ phát ở Stage này
func get_bgm_track() -> String:
	return "base"

# BaseMap gọi khi người chơi chạm NPC: bỏ qua lúc đang cảnh tự chạy, còn lại giao cho handle_npc_interaction của Stage
func talk_to_npc(npc_name: String):
	if _cutscene_active:
		return
	handle_npc_interaction(npc_name)

# Xử lý tương tác với NPC
func handle_npc_interaction(_npc_name: String):
	pass

# NPC chưa có gì để nói: một dòng "..." để người chơi thấy phản hồi thay vì bấm ENTER mà không có gì xảy ra
func say_nothing(npc_name: String) -> void:
	DialogueManager.play_dialogue([{"text": "...", "type": "dialogue", "name": npc_name, "color": Color.WHITE}])

# Trả về text hiển thị trên HUD Quest
func get_quest_text() -> String:
	return ""

# Khoá cảnh tự chạy: chặn tương tác NPC và giữ yên người chơi (thay cho cặp `_cutscene_active = true` + `map.freeze_player()` chép ở nhiều Stage)
func lock_scene() -> void:
	_cutscene_active = true
	map.freeze_player()

# Mở lại tương tác và cho người chơi đi lại sau lock_scene
func unlock_scene() -> void:
	_cutscene_active = false
	map.unfreeze_player()

# Đội hình chính của cốt truyện (Honami chỉ là người giúp đỡ nên không có trong bảng nâng cấp ở giai đoạn này)
const MAIN_TEAM := ["Ichika", "Kanade", "Mafuyu", "Ena", "Mizuki"]

# Mở bảng nâng cấp chỉ số cho các thành viên (mặc định cả đội chính); ai đã chết trong cốt truyện thì bị bỏ qua
func open_upgrade_ui(names: Array = MAIN_TEAM):
	var p_list: Array[Entity] = []
	for member in names:
		if GameManager.is_member_alive_in_story(member):
			p_list.append(GameManager.get_party_member(member))
	UpgradeUI.show_ui(p_list)

# Menu chọn người luyện tập rồi sang TrainingWarehouse (thay cho 7 bản chép "ask -> begin_training -> change_map" ở các Stage).
# hide_done: ẩn người đã có cờ training_<tên>_done; before_start: chạy ngay trước khi vào trận (đặt cờ, khoá cảnh...);
# alive_only: bỏ người đã chết trong cốt truyện; group_label: thêm mục cho cả nhóm (cần >= 2 người, vd. "Cả hai (10 Waves)").
# Trả về true nếu đã bắt đầu luyện tập, false nếu người chơi chọn "Để sau.".
func offer_training(trainees: Array, hide_done: bool = false, before_start: Callable = Callable(), alive_only: bool = false, group_label: String = "") -> bool:
	var members: Array = []
	for member in trainees:
		if hide_done and GameManager.get_flag("training_%s_done" % member.to_lower()):
			continue
		if alive_only and not GameManager.is_member_alive_in_story(member):
			continue
		members.append(member)

	if members.is_empty():
		# Ai cũng đã tập xong (hide_done): không mở menu chỉ có mỗi nút "Để sau."
		DialogueManager.play_dialogue([{"text": "Mọi người đều đã luyện tập xong.", "type": "narrator"}])
		return false

	var opts: Array = []
	var groups: Array = []
	for member in members:
		opts.append("%s (5 Waves)" % member)
		groups.append([member])
	if group_label != "" and members.size() > 1:
		opts.append(group_label)
		groups.append(members.duplicate())
	opts.append("Để sau.")

	var idx: int = await DialogueManager.ask(opts)
	if idx >= groups.size():
		return false

	if before_start.is_valid():
		before_start.call()
	GameManager.begin_training(groups[idx])

	await GameManager.change_map(MapPaths.TRAINING, 1.0)
	return true

# Màu tên người nói, khớp với các file hội thoại JSON trong Data/storyline
const SPEAKER_COLORS := {
	"Mafuyu": Color("#665588"),
	"Ena": Color("#b86028"),
	"Mizuki": Color("#d8a4cc"),
	"Ichika": Color("#4a9e9e"),
	"Kanade": Color("#ccccdd"),
	"Honami": Color("#ffaa88"),
}

# Một dòng thoại nhân vật dựng tay (bên trái như mặc định của DialogueUI); thay cho dict {"text","type","name","color"} chép ở nhiều Stage
func say(speaker: String, text: String) -> Dictionary:
	return {"text": text, "type": "dialogue", "name": speaker, "color": SPEAKER_COLORS.get(speaker, Color.WHITE)}

# Trả về true nếu stage tự xử lý việc rời map (vd. khóa cửa trong cảnh tự chạy); false = BaseMap tự xử lý
func handle_exit() -> bool:
	return exit_locked
