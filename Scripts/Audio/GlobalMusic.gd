extends Node

var music_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	music_player.bus = "Music"


func play_music(music) -> void:
	if music_player == null:
		return

	var stream: AudioStream = null

	if music is AudioStream:
		stream = music
	elif music is String:
		stream = load(music)

	if stream == null:
		push_warning("No se pudo cargar la música.")
		return

	if music_player.stream == stream and music_player.playing:
		return

	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	if music_player and music_player.playing:
		music_player.stop()


func set_menu_volume() -> void:
	if music_player:
		music_player.volume_db = -8.0


func set_intro_volume() -> void:
	if music_player:
		music_player.volume_db = -16.0


func set_game_volume() -> void:
	if music_player:
		music_player.volume_db = -14.0


func set_minigame_volume() -> void:
	if music_player:
		music_player.volume_db = -10.0
		
func fade_out_and_stop(duration := 0.5) -> void:
	if not music_player or not music_player.playing:
		return

	var tween := create_tween()
	tween.tween_property(
		music_player,
		"volume_db",
		-40.0,
		duration
	)

	await tween.finished

	music_player.stop()
	music_player.volume_db = -10.0		
