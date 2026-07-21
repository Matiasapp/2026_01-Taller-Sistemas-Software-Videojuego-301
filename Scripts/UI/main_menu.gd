extends Node2D

@onready var en_desarrollo = $en_desarrollo
@onready var confirmar_nueva_partida = $ConfirmarNuevaPartida
@onready var creditos_link: Button = $CanvasLayer/CreditosLink
@onready var creditos_resplandor: Label = $CanvasLayer/CreditosResplandor
@onready var creditos_overlay: Control = $CanvasLayer/CreditosOverlay
@onready var creditos_panel: NinePatchRect = $CanvasLayer/CreditosOverlay/CreditosPanel
@onready var creditos_scroll: ScrollContainer = $CanvasLayer/CreditosOverlay/CreditosPanel/Contenido/Rollo
@onready var creditos_barra: VScrollBar = creditos_scroll.get_v_scroll_bar()
@onready var creditos_cerrar: Button = $CanvasLayer/CreditosOverlay/CreditosPanel/Contenido/BtnVolver
@onready var fade_nueva_partida: ColorRect = $CanvasLayer/FadeNuevaPartida
@onready var nueva_partida_whoosh: AudioStreamPlayer = $NuevaPartidaWhoosh

const VELOCIDAD_CREDITOS := 18.0
const ESPERA_INICIAL_CREDITOS := 0.8

var creditos_scroll_pos := 0.0
var creditos_scroll_espera := 0.0
var creditos_scroll_activo := false
var creditos_scroll_arrastrando := false
var creditos_scroll_actualizando := false
var iniciando_nueva_partida := false

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
	creditos_barra.value_changed.connect(_on_creditos_barra_value_changed)


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
	if iniciando_nueva_partida:
		return
	iniciando_nueva_partida = true

	# Nueva partida: borramos el guardado anterior y reiniciamos todo el estado.
	PARTIDA.borrar()
	DATOSGLOBALES.reiniciar()
	if CLIENTMANAGER:
		CLIENTMANAGER.reiniciar()
	if TIEMPOMANAGER:
		TIEMPOMANAGER.reset_day()

	await get_tree().create_timer(0.12).timeout
	await _transicion_a_intro()

	print("Iniciando el nivel...")
	CARGADOR.cambiar_escena("res://Scenes/Gameplay/IntroScreen.tscn")


func _transicion_a_intro() -> void:
	fade_nueva_partida.visible = true
	fade_nueva_partida.modulate.a = 0.0
	fade_nueva_partida.mouse_filter = Control.MOUSE_FILTER_STOP

	if nueva_partida_whoosh:
		nueva_partida_whoosh.pitch_scale = 1.0
		nueva_partida_whoosh.play()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(fade_nueva_partida, "modulate:a", 1.0, 0.55)
	await tween.finished

	if nueva_partida_whoosh and nueva_partida_whoosh.playing:
		await nueva_partida_whoosh.finished


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

	creditos_link.release_focus()
	creditos_cerrar.disabled = false
	creditos_overlay.visible = true
	creditos_overlay.modulate.a = 0.0
	creditos_panel.scale = Vector2(0.96, 0.96)
	creditos_scroll_actualizando = true
	creditos_scroll.scroll_vertical = 0
	creditos_scroll_actualizando = false
	creditos_scroll_pos = 0.0
	creditos_scroll_espera = ESPERA_INICIAL_CREDITOS
	creditos_scroll_activo = true
	creditos_scroll_arrastrando = false

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(creditos_overlay, "modulate:a", 1.0, 0.18)
	tween.tween_property(creditos_panel, "scale", Vector2.ONE, 0.22)
	creditos_cerrar.grab_focus()


func _cerrar_creditos() -> void:
	if not creditos_overlay.visible:
		return

	creditos_scroll_activo = false
	creditos_scroll_arrastrando = false

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(creditos_overlay, "modulate:a", 0.0, 0.14)
	tween.tween_property(creditos_panel, "scale", Vector2(0.97, 0.97), 0.14)
	await tween.finished
	creditos_overlay.visible = false
	creditos_panel.scale = Vector2.ONE
	creditos_cerrar.release_focus()
	creditos_link.release_focus()


func _process(delta: float) -> void:
	if not creditos_scroll_activo or not creditos_overlay.visible:
		return

	if creditos_scroll_arrastrando:
		creditos_scroll_pos = float(creditos_scroll.scroll_vertical)
		return

	if creditos_scroll_espera > 0.0:
		creditos_scroll_espera -= delta
		return

	var limite := maxf(0.0, creditos_barra.max_value - creditos_barra.page)
	if creditos_scroll_pos >= limite:
		creditos_scroll_activo = false
		return

	creditos_scroll_pos = minf(creditos_scroll_pos + VELOCIDAD_CREDITOS * delta, limite)
	creditos_scroll_actualizando = true
	creditos_scroll.scroll_vertical = roundi(creditos_scroll_pos)
	creditos_scroll_actualizando = false


func _on_creditos_barra_value_changed(valor: float) -> void:
	if creditos_scroll_actualizando or not creditos_overlay.visible:
		return

	creditos_scroll_pos = valor
	var limite := maxf(0.0, creditos_barra.max_value - creditos_barra.page)
	creditos_scroll_activo = valor < limite


func _input(event: InputEvent) -> void:
	if not creditos_overlay.visible or not event is InputEventMouseButton:
		return

	var evento_mouse := event as InputEventMouseButton
	if evento_mouse.button_index != MOUSE_BUTTON_LEFT:
		return

	if evento_mouse.pressed and creditos_barra.get_global_rect().has_point(evento_mouse.position):
		creditos_scroll_arrastrando = true
		creditos_scroll_pos = float(creditos_scroll.scroll_vertical)
	elif not evento_mouse.pressed and creditos_scroll_arrastrando:
		creditos_scroll_arrastrando = false
		call_deferred("_reanudar_creditos_desde_barra")


func _reanudar_creditos_desde_barra() -> void:
	creditos_scroll_pos = float(creditos_scroll.scroll_vertical)
	creditos_scroll_espera = 0.0
	var limite := maxf(0.0, creditos_barra.max_value - creditos_barra.page)
	creditos_scroll_activo = creditos_scroll_pos < limite


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


func _on_creditos_volver_mouse_entered() -> void:
	if not creditos_cerrar.disabled and creditos_overlay.visible:
		play_hover()
