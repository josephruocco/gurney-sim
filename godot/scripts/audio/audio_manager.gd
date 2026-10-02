class_name GurneyAudioManager
extends Node

var music_player: AudioStreamPlayer
var roll_player: AudioStreamPlayer
var music_playback: AudioStreamGeneratorPlayback
var roll_playback: AudioStreamGeneratorPlayback
var music_phase := 0.0
var roll_phase := 0.0
var music_clock := 0.0
var target_roll := 0.0
const MIX_RATE := 22050.0
const NOTES := [196.0, 246.94, 293.66, 246.94, 174.61, 220.0, 261.63, 220.0]

func _ready() -> void:
	music_player = _generator_player(-23.0)
	roll_player = _generator_player(-30.0)
	music_playback = music_player.get_stream_playback()
	roll_playback = roll_player.get_stream_playback()
	set_process(true)

func _generator_player(volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = MIX_RATE
	stream.buffer_length = 0.25
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	player.play()
	return player

func set_gurney_speed(speed_kph: float) -> void:
	target_roll = clampf(speed_kph / 28.0, 0.0, 1.0)
	roll_player.volume_db = lerpf(-42.0, -13.0, target_roll)

func _process(_delta: float) -> void:
	_fill_music()
	_fill_roll()

func _fill_music() -> void:
	if !music_playback: return
	for sample in music_playback.get_frames_available():
		var note_index := int(music_clock / (MIX_RATE * 0.75)) % NOTES.size()
		var frequency: float = NOTES[note_index]
		music_phase = fmod(music_phase + frequency / MIX_RATE, 1.0)
		music_clock += 1.0
		var triangle := 1.0 - 4.0 * absf(music_phase - 0.5)
		var pulse := sin(music_phase * TAU * 0.5) * 0.15
		music_playback.push_frame(Vector2.ONE * (triangle * 0.055 + pulse * 0.025))

func _fill_roll() -> void:
	if !roll_playback: return
	for sample in roll_playback.get_frames_available():
		roll_phase = fmod(roll_phase + (42.0 + target_roll * 75.0) / MIX_RATE, 1.0)
		var rumble := sin(roll_phase * TAU) * 0.12
		var caster_tick := 0.08 if roll_phase < 0.035 else 0.0
		roll_playback.push_frame(Vector2.ONE * (rumble + caster_tick) * target_roll)

func play_click() -> void: _play_tone(520.0, 0.07, -13.0)
func play_grab(grabbed: bool) -> void: _play_tone(360.0 if grabbed else 250.0, 0.11, -10.0)
func play_win() -> void:
	_play_tone(660.0, 0.28, -6.0)
	await get_tree().create_timer(0.13).timeout
	_play_tone(880.0, 0.34, -6.0)
func play_loss() -> void: _play_tone(145.0, 0.48, -5.0)

func _play_tone(frequency: float, duration: float, volume: float) -> void:
	var frame_count := int(MIX_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for index in frame_count:
		var envelope := 1.0 - float(index) / float(frame_count)
		var value := int(sin(TAU * frequency * float(index) / MIX_RATE) * envelope * 12500.0)
		bytes.encode_s16(index * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(MIX_RATE)
	stream.data = bytes
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
