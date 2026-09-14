extends Node

const CLICK_PATH := "res://assets/audio/ui/ui_click.ogg"
const CONFIRMATION_PATH := "res://assets/audio/ui/ui_confirmation.ogg"
const ERROR_PATH := "res://assets/audio/ui/ui_error.ogg"
const TOWER_SHOT_PATH := "res://assets/audio/combat/tower_shot.ogg"

var _click_stream: AudioStream
var _confirmation_stream: AudioStream
var _error_stream: AudioStream
var _tower_shot_stream: AudioStream

func _ready() -> void:
    _click_stream = load(CLICK_PATH) as AudioStream
    _confirmation_stream = load(CONFIRMATION_PATH) as AudioStream
    _error_stream = load(ERROR_PATH) as AudioStream
    _tower_shot_stream = load(TOWER_SHOT_PATH) as AudioStream

func attach_control(control: Control) -> void:
    if control is BaseButton and not control.pressed.is_connected(play_click):
        control.pressed.connect(play_click)

func play_click() -> void:
    _play(_click_stream)

func play_confirmation() -> void:
    _play(_confirmation_stream)

func play_place() -> void:
    _play(_confirmation_stream)

func play_error() -> void:
    _play(_error_stream)

func play_tower_shot() -> void:
    _play(_tower_shot_stream, -8.0)

func _play(stream: AudioStream, volume_db := -4.0) -> void:
    if stream == null:
        return
    if AudioServer.get_bus_index("SFX") < 0:
        AudioServer.add_bus()
        AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
    var player := AudioStreamPlayer.new()
    player.stream = stream
    player.bus = "SFX"
    player.volume_db = volume_db
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()
