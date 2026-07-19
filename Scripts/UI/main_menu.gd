extends Node2D

@onready var en_desarrollo = $en_desarrollo
@onready var confirmar_nueva_partida = $ConfirmarNuevaPartida
@onready var creditos_link: Button = $CanvasLayer/CreditosLink
@onready var creditos_resplandor: Label = $CanvasLayer/CreditosResplandor
@onready var creditos_overlay: Control = $CanvasLayer/CreditosOverlay
@onready var creditos_panel: PanelContainer = $CanvasLayer/CreditosOverlay/CreditosPanel
@onready var creditos_scroll: ScrollContainer = $CanvasLayer/CreditosOverlay/CreditosPanel/Contenido/Rollo
@onready var creditos_cerrar: Button = $CanvasLayer/CreditosOverlay/CreditosPanel/Contenido/Cerrar

const VELOCIDAD_CREDITOS := 18.0
const ESPERA_INICIAL_CREDITOS := 0.8

var creditos_scroll_pos := 0.0
var creditos_scroll_espera := 0.0
var creditos_scroll_activo := false

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
	# Cargar partida salta la introducción, que normalmente es la encargada de
	# apagar la música persistente del menú antes de entrar al taller.
	await GlobalMusic.fade_out_and_stop(0.35)
	var destino := DATOSGLOBALES.obtener_destino_post_escena(
		"res://Scenes/Gameplay/GameScreen.tscn"
	)
	CARGADOR.cambiar_escena(destino)


func _on_button_exit_pressed() -> void:
	play_click()

	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func _on_button_options_pressed() -> void:
	play_click()
	var opciones := preload("res://Scenes/UI/Opciones.tscn").instantiate()
	add_child(opciones)


# =========================
# CRÉDITOS
# =========================

func _on_creditos_link_pressed() -> void:
	play_click()
	_animar_resplandor_creditos()
	_abrir_creditos()


func _on_cerrar_creditos_pressed() -> void:
	play_click()
	_cerrar_creditos()


func _abrir_creditos() -> void:
	if creditos_overlay.visible:
		return

	creditos_overlay.visible = true
	creditos_overlay.modulate.a = 0.0
	creditos_panel.scale = Vector2(0.96, 0.96)
	creditos_scroll.scroll_vertical = 0
	creditos_scroll_pos = 0.0
	creditos_scroll_espera = ESPERA_INICIAL_CREDITOS
	creditos_scroll_activo = true

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(creditos_overlay, "modulate:a", 1.0, 0.18)
	tween.tween_property(creditos_panel, "scale", Vector2.ONE, 0.22)
	creditos_cerrar.grab_focus()


func _cerrar_creditos() -> void:
	if not creditos_overlay.visible:
		return

	creditos_scroll_activo = false

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(creditos_overlay, "modulate:a", 0.0, 0.14)
	tween.tween_property(creditos_panel, "scale", Vector2(0.97, 0.97), 0.14)
	await tween.finished
	creditos_overlay.visible = false
	creditos_panel.scale = Vector2.ONE
	creditos_link.grab_focus()


func _process(delta: float) -> void:
	if not creditos_scroll_activo or not creditos_overlay.visible:
		return

	if creditos_scroll_espera > 0.0:
		creditos_scroll_espera -= delta
		return

	var barra := creditos_scroll.get_v_scroll_bar()
	var limite := maxf(0.0, barra.max_value - barra.page)
	if creditos_scroll_pos >= limite:
		creditos_scroll_activo = false
		return

	creditos_scroll_pos = minf(creditos_scroll_pos + VELOCIDAD_CREDITOS * delta, limite)
	creditos_scroll.scroll_vertical = roundi(creditos_scroll_pos)


func _animar_resplandor_creditos() -> void:
	creditos_resplandor.modulate.a = 0.0
	creditos_resplandor.scale = Vector2(0.98, 0.98)

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(creditos_resplandor, "modulate:a", 0.9, 0.08)
	tween.tween_property(creditos_resplandor, "scale", Vector2(1.035, 1.035), 0.16)
	await tween.finished

	tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(creditos_resplandor, "modulate:a", 0.0, 0.28)
	tween.tween_property(creditos_resplandor, "scale", Vector2.ONE, 0.28)


func _unhandled_input(event: InputEvent) -> void:
	if creditos_overlay.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cerrar_creditos()


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


func _on_creditos_link_mouse_entered() -> void:
	play_hover()
