extends Node

var music_player: AudioStreamPlayer


func _enter_tree() -> void:
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	music_player.name = "GlobalMusicPlayer"
	music_player.bus = "Music"
	music_player.volume_db = 0.0
	music_player.autoplay = false


func play_music(stream: AudioStream) -> void:
	if stream == null:
		push_warning("GlobalMusic.play_music recibió un stream null.")
		return

	if music_player == null:
		push_warning("music_player todavía no existe.")
		return

	if music_player.stream == stream and music_player.playing:
		return

	music_player.stream = stream
	music_player.volume_db = 0.0
	music_player.play()


func set_menu_volume() -> void:
	if music_player == null:
		return

	music_player.volume_db = 0.0


func set_intro_volume() -> void:
	if music_player == null:
		return

	music_player.volume_db = -10.0


func fade_out_and_stop(duration := 1.0) -> void:
	if music_player == null:
		return

	var tween := create_tween()
	tween.tween_property(music_player, "volume_db", -40.0, duration)
	await tween.finished

	music_player.stop()
	music_player.volume_db = 0.0
