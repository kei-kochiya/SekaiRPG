extends BaseMapStage
class_name LobbyStage

"""
LobbyStage: Gốc chung của PostStreetStage và HonamiHouseUnlockedStage - hai Stage dùng cùng một sảnh:
cả đội đứng ở chỗ cũ dưới ánh sáng xanh nhạt, Mafuyu mở menu luyện tập cho cả năm người.
Mỗi Stage con chỉ giữ phần lời thoại và cốt truyện riêng.
"""

# Mafuyu cho luyện tập cả năm người ở sảnh này (không ẩn ai đã tập xong; Honami chưa tham gia)
const TRAINEES := ["Ichika", "Kanade", "Ena", "Mizuki", "Mafuyu"]

func get_npc_positions() -> Dictionary:
	return {
		"Ena": Vector2(17 * map.TILE_SIZE, 11 * map.TILE_SIZE),
		"Kanade": Vector2(23 * map.TILE_SIZE, 13 * map.TILE_SIZE),
		"Mizuki": Vector2(19 * map.TILE_SIZE, 12 * map.TILE_SIZE),
		"Mafuyu": Vector2(24 * map.TILE_SIZE, 11 * map.TILE_SIZE),
	}

# BaseMap áp ánh sáng này trước fade_in nên không bị "nháy sáng"
func get_scene_lighting() -> Color:
	return Color(0.9, 0.9, 1.0)
