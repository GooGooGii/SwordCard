extends Node

# Autoload singleton. 兩個 AudioStreamPlayer 輪流播 BGM，切軌時 crossfade。
# 用法：AudioManager.play_bgm("battle_normal")  /  AudioManager.stop_bgm()
# 音檔放 assets/audio/bgm/<track_id>.ogg；缺檔自動靜音不 crash。

const BGM_DIR: String = "res://assets/audio/bgm/"
const SFX_DIR: String = "res://assets/audio/sfx/"
const CROSSFADE_SEC: float = 0.8
const FADE_OUT_SEC: float = 0.4
const SFX_POOL_SIZE: int = 6  # 同時可疊放的一次性音效數

var _players: Array[AudioStreamPlayer] = []
var _active_idx: int = 0
var _current_track: String = ""
var _tween: Tween = null

# SFX：一次性音效播放池（round-robin），缺檔靜默 skip
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_idx: int = 0
var _sfx_cache: Dictionary = {}  # id -> AudioStream（缺檔存 null，避免反覆 disk probe）
var _sfx_min_gap: Dictionary = {}  # id -> 上次播放的引擎毫秒（防同幀重複疊太多）

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暫停時音樂繼續
	for i in range(2):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	for i in range(SFX_POOL_SIZE):
		var sp: AudioStreamPlayer = AudioStreamPlayer.new()
		sp.bus = "SFX"
		add_child(sp)
		_sfx_players.append(sp)

# 播一次性音效。sfx_id 對應 assets/audio/sfx/<id>.wav。缺檔靜默不 crash。
func play_sfx(sfx_id: String) -> void:
	if sfx_id == "":
		return
	# 同一音效 35ms 內不重複觸發（連擊分次扣血會短時間連發，避免轟鳴）
	var now_ms: int = Time.get_ticks_msec()
	if _sfx_min_gap.has(sfx_id) and now_ms - int(_sfx_min_gap[sfx_id]) < 35:
		return
	_sfx_min_gap[sfx_id] = now_ms
	var stream: AudioStream = _load_sfx(sfx_id)
	if stream == null:
		return
	var player: AudioStreamPlayer = _sfx_players[_sfx_idx]
	_sfx_idx = (_sfx_idx + 1) % _sfx_players.size()
	player.stream = stream
	player.play()

func _load_sfx(sfx_id: String) -> AudioStream:
	if _sfx_cache.has(sfx_id):
		return _sfx_cache[sfx_id]
	var path: String = SFX_DIR + sfx_id + ".wav"
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	_sfx_cache[sfx_id] = stream  # 含 null（缺檔），避免下次再探 disk
	return stream

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
