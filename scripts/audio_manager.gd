extends Node

# Autoload singleton. 兩個 AudioStreamPlayer 輪流播 BGM，切軌時 crossfade。
# 用法：AudioManager.play_bgm("battle_normal")  /  AudioManager.stop_bgm()
# 音檔放 assets/audio/bgm/<track_id>.ogg；缺檔自動靜音不 crash。

const BGM_DIR: String = "res://assets/audio/bgm/"
const CROSSFADE_SEC: float = 0.8
const FADE_OUT_SEC: float = 0.4

var _players: Array[AudioStreamPlayer] = []
var _active_idx: int = 0
var _current_track: String = ""
var _tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暫停時音樂繼續
	for i in range(2):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)

func play_bgm(track_id: String) -> void:
	if track_id == _current_track:
		return
	var path: String = _find_track_path(track_id)
	if path == "":
		# 缺檔靜默 skip：開發階段允許 assets/audio/bgm/ 是空的
		_current_track = track_id
		_fade_out_active()
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		_current_track = track_id
		_fade_out_active()
		return
	# 預設不 loop —— 強制 loop（避免每首都要手動匯入設定）
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		(stream as AudioStreamWAV).loop_end = 0  # 0 = 整段
	_current_track = track_id
	var next_idx: int = 1 - _active_idx
	var next_player: AudioStreamPlayer = _players[next_idx]
	next_player.stream = stream
	next_player.volume_db = -80.0
	next_player.play()
	_kill_tween()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(next_player, "volume_db", 0.0, CROSSFADE_SEC)
	_tween.tween_property(_players[_active_idx], "volume_db", -80.0, CROSSFADE_SEC)
	_tween.chain().tween_callback(_players[_active_idx].stop)
	_active_idx = next_idx

func stop_bgm() -> void:
	_current_track = ""
	_fade_out_active()

func _fade_out_active() -> void:
	var active: AudioStreamPlayer = _players[_active_idx]
	if not active.playing:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(active, "volume_db", -80.0, FADE_OUT_SEC)
	_tween.tween_callback(active.stop)

func _find_track_path(track_id: String) -> String:
	for ext in [".ogg", ".wav"]:
		var p: String = BGM_DIR + track_id + ext
		if ResourceLoader.exists(p):
			return p
	return ""

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
