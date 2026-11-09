extends Node

"""
Tóm tắt: AudioManager là Node Autoload chịu trách nhiệm quản lý phát nhạc nền toàn cục.

Chức năng chính:
- Duy trì việc phát nhạc nền (BGM) xuyên suốt các cảnh chơi mà không bị ngắt quãng.
- Cung cấp tính năng chuyển đổi bài nhạc mượt mà thông qua hiệu ứng Fade In/Fade Out (Tween âm lượng).
- Lưu trữ danh sách đường dẫn các bài nhạc thường dùng qua hằng số `TRACKS`.
- Cung cấp API `update_volume` cho phép tùy chỉnh âm lượng tổng (Master Bus) thông qua Settings.
"""

# ── Biến & Cấu Hình ────────────────────────────────────────────────────────


var _player: AudioStreamPlayer
var _current_track: String = ""

const MUSIC_DIR = "res://Assets/Audio/"
const TRACKS = {
	"base": "base_music.mp3",
	"battle": "battle_music.mp3",
	"main_menu": "main_menu.mp3",
	"map": "map_music.mp3",
	"night": "night.mp3"
}

# ── Khởi Tạo ───────────────────────────────────────────────────────────────

# Khởi tạo Node âm thanh
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)

# ── Điều Khiển Phát Nhạc ───────────────────────────────────────────────────

# Mỗi lần đổi bài tăng số này; coroutine làm mờ cũ thấy số đã đổi thì bỏ cuộc (xem play_music)
var _play_id: int = 0
# Bài nhạc đã nạp theo tên (xem play_music)
var _streams: Dictionary = {}

func play_music(track_name: String, fade_duration: float = 1.0):
	"""
	Phát một bài nhạc nền có sẵn trong thư mục Music.
	
	Args:
		track_name (String): Tên định danh của bài nhạc.
		fade_duration (float): Thời gian làm mờ khi chuyển bài (giây).
	Returns: Không có
	"""
	if _current_track == track_name:
		return
	
	if not TRACKS.has(track_name):
		push_error("Music track not found: " + track_name)
		return
	
	# Giữ lại các bài đã nạp: mp3 vài MB, đổi bài ở mỗi map/trận mà nạp lại từ đĩa sẽ giật
	var new_stream = _streams.get(track_name)
	if new_stream == null:
		new_stream = load(MUSIC_DIR + TRACKS[track_name])
		if not new_stream:
			return
		_streams[track_name] = new_stream
		
	_current_track = track_name
	_play_id += 1
	var my_id := _play_id
	
	if new_stream is AudioStreamMP3:
		new_stream.loop = true
	
	if _player.playing and fade_duration > 0:
		var tween = create_tween()
		tween.tween_property(_player, "volume_db", -40, fade_duration)
		await tween.finished
		_player.stop()
	
	# Có yêu cầu đổi bài mới hơn trong lúc đang làm mờ: bỏ bài này, để chỉ bài mới nhất được phát
	if my_id != _play_id:
		return
	
	_player.stream = new_stream
	_player.volume_db = 0
	_player.play()
	
	if fade_duration > 0:
		_player.volume_db = -40
		var tween = create_tween()
		tween.tween_property(_player, "volume_db", 0, fade_duration)

# ── Cài Đặt Âm Lượng ───────────────────────────────────────────────────────

# Cập nhật âm lượng tổng
func update_volume(value: float):
	var bus_index = AudioServer.get_bus_index("Master")
	var db = linear_to_db(max(value, 0.0001))
	AudioServer.set_bus_volume_db(bus_index, db)
