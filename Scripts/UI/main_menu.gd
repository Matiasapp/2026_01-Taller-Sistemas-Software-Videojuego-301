extends Node2D

@onready var en_desarrollo = $en_desarrollo

@export var click_sound: AudioStreamPlayer
@export var hover_sound: AudioStreamPlayer
@export var menu_music: AudioStream


# =========================
# AUDIO
# =========================

func play_click() -> void:
	if click_sound:
		var semitones = randf_range(-2.0, 2.0)
		click_sound.pitch_scale = pow(2.0, semitones / 12.0)
		click_sound.play()


func play_hover() -> void:
	if hover_sound:
		var semitones = randf_range(-5.0, 5.0)
		hover_sound.pitch_scale = pow(2.0, semitones / 12.0)
		hover_sound.play()


# =========================
# READY
# =========================

func _ready() -> void:
	randomize()

	if menu_music:
		GlobalMusic.play_music(menu_music)
		GlobalMusic.set_menu_volume()
	else:
		push_warning("No hay música asignada en Menu Music.")


# ========================= 
# BOTONES
# =========================

func _on_button_new_game_pressed() -> void:
	play_click()

	# Nueva partida: reiniciamos el estado que debe empezar "de cero" cada partida.
	DATOSGLOBALES.modal_bienvenida_mostrado = false

	await get_tree().create_timer(0.15).timeout

	GlobalMusic.set_intro_volume()

	print("Iniciando el nivel...")
	get_tree().change_scene_to_file("res://Scenes/Gameplay/IntroScreen.tscn")


func _on_button_load_game_pressed() -> void:
	play_click()
	print("Cargando el nivel...")
	en_desarrollo.popup_centered()


func _on_button_exit_pressed() -> void:
	play_click()

	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func _on_button_options_pressed() -> void:
	play_click()
	en_desarrollo.popup_centered()


# =========================
# HOVER
# =========================

func _on_button_new_game_mouse_entered() -> void:
	play_hover()


func _on_button_load_game_mouse_entered() -> void:
	play_hover()


func _on_button_options_mouse_entered() -> void:
	play_hover()


func _on_button_exit_mouse_entered() -> void:
	play_hover()
