class_name SettingsManager
extends RefCounted

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION_AUDIO: String = "audio"
const SECTION_VIDEO: String = "video"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"

const DEFAULT_MASTER: float = 80.0
const DEFAULT_MUSIC: float = 70.0
const DEFAULT_SFX: float = 80.0
const DEFAULT_FULLSCREEN: bool = false

static var master_volume: float = DEFAULT_MASTER
static var music_volume: float = DEFAULT_MUSIC
static var sfx_volume: float = DEFAULT_SFX
static var fullscreen: bool = DEFAULT_FULLSCREEN

static func load_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: int = cfg.load(SETTINGS_PATH)
	if err != OK:
		_apply_defaults()
		return
	master_volume = float(cfg.get_value(SECTION_AUDIO, "master", DEFAULT_MASTER))
	music_volume = float(cfg.get_value(SECTION_AUDIO, "music", DEFAULT_MUSIC))
	sfx_volume = float(cfg.get_value(SECTION_AUDIO, "sfx", DEFAULT_SFX))
	fullscreen = bool(cfg.get_value(SECTION_VIDEO, "fullscreen", DEFAULT_FULLSCREEN))
	apply_runtime()

static func save_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value(SECTION_AUDIO, "master", master_volume)
	cfg.set_value(SECTION_AUDIO, "music", music_volume)
	cfg.set_value(SECTION_AUDIO, "sfx", sfx_volume)
	cfg.set_value(SECTION_VIDEO, "fullscreen", fullscreen)
	cfg.save(SETTINGS_PATH)

static func apply_runtime() -> void:
	_ensure_buses()
	AudioServer.set_bus_volume_db(0, _to_db(master_volume))
	AudioServer.set_bus_mute(0, master_volume <= 0.0)
	var music_idx: int = AudioServer.get_bus_index(BUS_MUSIC)
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, _to_db(music_volume))
		AudioServer.set_bus_mute(music_idx, music_volume <= 0.0)
	var sfx_idx: int = AudioServer.get_bus_index(BUS_SFX)
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, _to_db(sfx_volume))
		AudioServer.set_bus_mute(sfx_idx, sfx_volume <= 0.0)
	# 手機平台的全螢幕由 OS + 匯出 immersive_mode 控制，不要在執行階段覆蓋
	# （否則會把 Android 的 immersive 狀態打回視窗模式，露出狀態列與手勢列）。
	if OS.has_feature("mobile"):
		return
	var mode: int = DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

static func _ensure_buses() -> void:
	if AudioServer.get_bus_index(BUS_MUSIC) == -1:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS_MUSIC)
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index(BUS_SFX) == -1:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS_SFX)
		AudioServer.set_bus_send(idx, "Master")

static func _apply_defaults() -> void:
	master_volume = DEFAULT_MASTER
	music_volume = DEFAULT_MUSIC
	sfx_volume = DEFAULT_SFX
	fullscreen = DEFAULT_FULLSCREEN
	apply_runtime()

static func _to_db(percent: float) -> float:
	if percent <= 0.0:
		return -80.0
	return linear_to_db(percent / 100.0)
