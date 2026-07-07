extends Node2D

@onready var en_desarrollo = $en_desarrollo
@onready var confirmar_nueva_partida = $ConfirmarNuevaPartida

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

	# En navegador no se puede cerrar la pestaña desde el juego, así que ocultamos "Salir".
	if OS.has_feature("web"):
		$CanvasLayer/VBoxContainer/button_exit.hide()

	# Si no hay partida guardada, atenuamos (deshabilitamos) "Cargar Partida".
	$CanvasLayer/VBoxContainer/button_load_game.disabled = not PARTIDA.hay_partida()

	confirmar_nueva_partida.confirmado.connect(_on_confirmar_nueva_partida_confirmed)


# ========================= 
# BOTONES
# =========================

func _on_button_new_game_pressed() -> void:
	play_click()

	# Si ya hay una partida guardada, confirmamos antes de sobrescribirla.
	if PARTIDA.hay_partida():
		confirmar_nueva_partida.abrir(
			"Nueva Partida",
			"Ya tienes una partida guardada. Si empiezas una nueva, la sobrescribirás. ¿Continuar?",
			"Sí, empezar",
			"Cancelar"
		)
		return

	_iniciar_nueva_partida()


func _on_confirmar_nueva_partida_confirmed() -> void:
	_iniciar_nueva_partida()


func _iniciar_nueva_partida() -> void:
	# Nueva partida: borramos el guardado anterior y reiniciamos todo el estado.
	PARTIDA.borrar()
	DATOSGLOBALES.reiniciar()
	if CLIENTMANAGER:
		CLIENTMANAGER.reiniciar()
	if TIEMPOMANAGER:
		TIEMPOMANAGER.reset_day()

	await get_tree().create_timer(0.15).timeout

	GlobalMusic.set_intro_volume()

	print("Iniciando el nivel...")
	get_tree().change_scene_to_file("res://Scenes/Gameplay/IntroScreen.tscn")


func _on_button_load_game_pressed() -> void:
	play_click()

	if not PARTIDA.hay_partida():
		en_desarrollo.dialog_text = "No hay ninguna partida guardada."
		en_desarrollo.popup_centered()
		return

	if not PARTIDA.cargar():
		en_desarrollo.dialog_text = "No se pudo cargar la partida."
		en_desarrollo.popup_centered()
		return

	await get_tree().create_timer(0.15).timeout
	GlobalMusic.set_intro_volume()
	CARGADOR.cambiar_escena("res://Scenes/Gameplay/GameScreen.tscn")


func _on_button_exit_pressed() -> void:
	play_click()

	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func _on_button_options_pressed() -> void:
	play_click()
	var opciones := preload("res://Scenes/UI/Opciones.tscn").instantiate()
	add_child(opciones)


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
