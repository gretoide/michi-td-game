extends Node

const CLICK_PATH := "res://assets/audio/ui/ui_click.ogg"
const CONFIRMATION_PATH := "res://assets/audio/ui/ui_confirmation.ogg"
const ERROR_PATH := "res://assets/audio/ui/ui_error.ogg"

var _click_stream: AudioStream
var _confirmation_stream: AudioStream
var _error_stream: AudioStream

func _ready() -> void:
    _click_stream = load(CLICK_PATH) as AudioStream
    _confirmation_stream = load(CONFIRMATION_PATH) as AudioStream
    _error_stream = load(ERROR_PATH) as AudioStream

func attach_control(control: Control) -> void:
    if control is BaseButton and not control.pressed.is_connected(play_click):
        control.pressed.connect(play_click)

func play_click() -> void:
    _play(_click_stream)

func play_confirmation() -> void:
    _play(_confirmation_stream)

func play_error() -> void:
    _play(_error_stream)

func _play(stream: AudioStream) -> void:
    if stream == null:
        return
    var player := AudioStreamPlayer.new()
    player.stream = stream
    player.volume_db = -4.0
    add_child(player)
    player.finished.connect(player.queue_free)
    player.play()
