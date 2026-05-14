extends Node

"""
AudioManager: Hệ thống quản lý âm nhạc nền toàn cục (Autoload).

Xử lý việc chuyển đổi giữa các bài nhạc bằng hiệu ứng Fade In/Out.
Không phát lại nếu bài hiện tại đang được phát (tránh ngắt mạch).
"""

var _player: AudioStreamPlayer
var _current_track: String = ""

const MUSIC_DIR = "res://Music/"
const TRACKS = {
	"after_warehouse": "after_warehouse.mp3",
	"base": "base_music.mp3",
	"battle": "battle_music.mp3",
	"main_menu": "main_menu.mp3",
	"map": "map_music.mp3"
}

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.bus = "Master"
	add_child(_player)

func play_music(track_name: String, fade_duration: float = 1.0):
	if _current_track == track_name:
		return
	
	if not TRACKS.has(track_name):
		push_error("Music track not found: " + track_name)
		return
	
	var new_stream = load(MUSIC_DIR + TRACKS[track_name])
	if not new_stream:
		return
		
	_current_track = track_name
	
	# Đảm bảo nhạc tự động lặp lại (Loop)
	if new_stream is AudioStreamMP3 or new_stream is AudioStreamWAV:
		new_stream.loop = true
	
	if _player.playing and fade_duration > 0:
		var tween = create_tween()
		tween.tween_property(_player, "volume_db", -40, fade_duration)
		await tween.finished
		_player.stop()
	
	_player.stream = new_stream
	_player.volume_db = 0
	_player.play()
	
	if fade_duration > 0:
		_player.volume_db = -40
		var tween = create_tween()
		tween.tween_property(_player, "volume_db", 0, fade_duration)

func stop_music(fade_duration: float = 1.0):
	_current_track = ""
	if fade_duration > 0 and _player.playing:
		var tween = create_tween()
		tween.tween_property(_player, "volume_db", -40, fade_duration)
		await tween.finished
	_player.stop()

func update_volume(value: float):
	"""
	Cập nhật âm lượng tổng (Master) của toàn bộ game.
	- value: Giá trị từ 0.0 (tắt) đến 1.0 (tối đa).
	"""
	var bus_index = AudioServer.get_bus_index("Master")
	# Chuyển đổi linear sang decibel: 0.0 -> -80dB, 1.0 -> 0dB
	var db = linear_to_db(max(value, 0.0001))
	AudioServer.set_bus_volume_db(bus_index, db)
