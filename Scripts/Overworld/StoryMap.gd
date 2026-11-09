extends Node2D
class_name StoryMap

"""
StoryMap: gốc chung của các map cảnh dựng bằng code và chạy theo kịch bản (Bounty, Thẩm vấn): hội thoại `await` được, đổi map có fade
và vài tiện ích dựng cảnh. Trước đây các hàm này được chép nguyên văn ở cả hai map.
"""

# Đổi sang map khác có fade (cũng dùng để nạp lại chính map này ở giai đoạn kế tiếp)
func _go(path: String) -> void:
	await GameManager.change_map(path, 1.0)

# Phát một đoạn hội thoại và chờ xong; khóa thiếu (mảng rỗng) thì chạy tiếp ngay
func _say(key: String) -> void:
	await _play(DialogueLoader.get_lines(key))

func _narrate(text: String) -> void:
	await _play([{"text": text, "type": "narrator"}])

func _play(lines: Array) -> void:
	await DialogueManager.play_async(lines)

func _tile(file: String, g: Vector2, collide: bool = false) -> void:
	MapUtils.place_tile(self, file, g, collide)

func _block(g: Vector2) -> void:
	MapUtils.add_block(self, g)

# Texture đèn: gradient tròn tự tạo một lần cho mỗi map (không thêm tài nguyên nhị phân)
var _light_tex: GradientTexture2D

# Hình chữ nhật màu không nhận chuột (vệt sàn, vạch cảnh báo, ánh trăng...); `parent` mặc định là chính map
func _rect(pos: Vector2, size: Vector2, color: Color, parent: Node = null) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else self).add_child(r)
	return r

# Đèn điểm tại `pos` (px) với bán kính `radius` (px); `parent` mặc định là chính map
func _light(pos: Vector2, color: Color, energy: float, radius: float, parent: Node = null) -> void:
	if _light_tex == null:
		_light_tex = GradientTexture2D.new()
		_light_tex.width = 128
		_light_tex.height = 128
		_light_tex.fill = GradientTexture2D.FILL_RADIAL
		_light_tex.fill_from = Vector2(0.5, 0.5)
		_light_tex.fill_to = Vector2(1.0, 0.5)
		_light_tex.gradient = Gradient.new()
		_light_tex.gradient.set_color(0, Color.WHITE)
		_light_tex.gradient.set_color(1, Color(1, 1, 1, 0))
	var l := PointLight2D.new()
	l.texture = _light_tex
	l.texture_scale = radius / 64.0
	l.color = color
	l.energy = energy
	l.position = pos
	(parent if parent else self).add_child(l)
