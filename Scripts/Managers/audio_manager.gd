extends Node

var click_sound = preload("res://Assets/Audio/Menu/click.wav")
var hover_sound = preload("res://Assets/Audio/Menu/hoverclick.wav")

var ui_player := AudioStreamPlayer.new()

func _ready() -> void:
	add_child(ui_player)
	ui_player.bus = "SFX"
	# Los botones de pausa y de resultados siguen activos con el árbol pausado.
	# Su reproductor también debe ignorar esa pausa para que hover/click se oigan.
	ui_player.process_mode = Node.PROCESS_MODE_ALWAYS

func play_ui_click() -> void:
	if not click_sound:
		return
	
	ui_player.stream = click_sound
	ui_player.pitch_scale = pow(2.0, randf_range(-2.0, 2.0) / 12.0)
	ui_player.play()

func play_ui_hover() -> void:
	if not hover_sound:
		return
	
	ui_player.stream = hover_sound
	ui_player.pitch_scale = pow(2.0, randf_range(-5.0, 5.0) / 12.0)
	ui_player.play()
