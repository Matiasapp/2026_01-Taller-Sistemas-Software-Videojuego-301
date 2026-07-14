extends Node2D

@onready var label: RichTextLabel = $CanvasLayer/VistaTextoIntroduccion/Panel/RichTextLabel
@onready var vista_evento: Control = $CanvasLayer/VistaTextoIntroduccion
@onready var imagen: TextureRect = $CanvasLayer/VistaTextoIntroduccion/TextureRect
@onready var bg_animation: AnimationPlayer = $CanvasLayer/VistaTextoIntroduccion/TextureRect/AnimationPlayer
@onready var continuar_button: Button = $CanvasLayer/VistaTextoIntroduccion/Panel/Comenzar
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var risa_sound: AudioStreamPlayer = $Risa
@onready var temporizador_risa: Timer = $TemporizadorRisa

@export var talking_sound: AudioStreamPlayer

@export var imagen_hombre: Texture2D
@export var imagen_mujer: Texture2D

var animador_texto: Tween
var escribiendo := false
var indice_mensaje := 0
var evento_finalizando := false

const COSTO_MATERIALES: int = 100   # Pérdida real: repuestos/materiales gastados en la reparación
const INTERVALO_RISA_MINIMO := 4.0
const INTERVALO_RISA_MAXIMO := 7.0

var mensajes := []
var imagen_evento: Texture2D
var monto_perdido := 0


func _ready() -> void:
	randomize()

	if bg_animation:
		bg_animation.play("background_move")

	continuar_button.visible = false
	continuar_button.disabled = true
	continuar_button.text = "Continuar"

	if not continuar_button.pressed.is_connected(_on_comenzar_pressed):
		continuar_button.pressed.connect(_on_comenzar_pressed)

	if not continuar_button.mouse_entered.is_connected(_on_comenzar_mouse_entered):
		continuar_button.mouse_entered.connect(_on_comenzar_mouse_entered)

	if not temporizador_risa.timeout.is_connected(_on_temporizador_risa_timeout):
		temporizador_risa.timeout.connect(_on_temporizador_risa_timeout)
	programar_proxima_risa()

	procesar_estafa()
	configurar_evento()
	mostrar_mensaje_actual()


## Procesa la estafa: revierte el pago falso (no te lo quedas) y, además, te resta
## de verdad el costo de los materiales gastados en la reparación.
func procesar_estafa() -> void:
	# El pago del minijuego era falso: lo revertimos.
	var pago_falso: int = DATOSGLOBALES.dinero - DATOSGLOBALES.dinero_antes_estafa
	if pago_falso > 0:
		DATOSGLOBALES.restar_dinero(pago_falso)

	# Pérdida real: los repuestos/materiales que pusiste para la reparación.
	DATOSGLOBALES.restar_dinero(COSTO_MATERIALES)
	monto_perdido = COSTO_MATERIALES

	DATOSGLOBALES.estafa_pendiente = false


func configurar_evento() -> void:
	var nombre: String = DATOSGLOBALES.nombre_estafador
	if nombre.is_empty():
		nombre = "El cliente"

	var es_mujer := DATOSGLOBALES.genero_jugador == "Femenino"
	var frase_huida := "¡Ilusa! Caíste redondita en mi truco. ¡Hasta nunca!" if es_mujer else "¡Iluso! Caíste redondito en mi truco. ¡Hasta nunca!"

	mensajes = [
		"Terminas la reparación y %s te paga sin mirarte a los ojos, con prisa." % nombre,
		"Apenas recibe las llaves, sale a toda prisa del taller.",
		"Desde la puerta alcanzas a oírlo gritar: \"%s\"" % frase_huida,
	]

	mensajes.append("Cuentas el dinero y se te cae el alma: los billetes son FALSOS. No cobraste nada y encima perdiste $%d en repuestos." % monto_perdido)

	imagen_evento = imagen_mujer if es_mujer else imagen_hombre


func _input(event) -> void:
	if not vista_evento.visible:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not continuar_button.disabled:
			return

		if escribiendo:
			saltar_animacion()
		else:
			avanzar_mensaje()


func mostrar_mensaje_actual() -> void:
	if indice_mensaje >= mensajes.size():
		stop_talking()
		continuar_button.visible = true
		continuar_button.disabled = false
		continuar_button.modulate.a = 1.0
		return

	if imagen_evento:
		imagen.texture = imagen_evento
	animar_texto(mensajes[indice_mensaje])


func avanzar_mensaje() -> void:
	if escribiendo:
		saltar_animacion()
		return

	indice_mensaje += 1
	mostrar_mensaje_actual()


func animar_texto(nuevo_texto: String) -> void:
	escribiendo = true
	start_talking()

	label.text = nuevo_texto
	label.visible_characters = 0

	if animador_texto:
		animador_texto.kill()

	animador_texto = create_tween()
	animador_texto.tween_property(label, "visible_characters", nuevo_texto.length(), 1.5)
	animador_texto.finished.connect(func():
		escribiendo = false
		stop_talking()
	)


func saltar_animacion() -> void:
	if animador_texto:
		animador_texto.kill()

	label.visible_characters = label.text.length()
	stop_talking()
	escribiendo = false


func start_talking() -> void:
	if talking_sound and not talking_sound.playing:
		talking_sound.pitch_scale = randf_range(0.95, 1.05)
		talking_sound.play()


func stop_talking() -> void:
	if talking_sound and talking_sound.playing:
		talking_sound.stop()


func programar_proxima_risa() -> void:
	if evento_finalizando:
		return

	temporizador_risa.start(randf_range(INTERVALO_RISA_MINIMO, INTERVALO_RISA_MAXIMO))


func _on_temporizador_risa_timeout() -> void:
	if evento_finalizando or not vista_evento.visible:
		return

	if risa_sound and not risa_sound.playing:
		risa_sound.pitch_scale = randf_range(0.96, 1.04)
		risa_sound.play()

	programar_proxima_risa()


func fade_to_black(duration := 0.6) -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)

	await tween.finished


func finalizar_evento() -> void:
	evento_finalizando = true
	temporizador_risa.stop()
	if risa_sound and risa_sound.playing:
		risa_sound.stop()
	stop_talking()

	await fade_to_black(0.6)

	Engine.time_scale = 1.0
	get_tree().paused = false
	var destino := DATOSGLOBALES.obtener_destino_post_escena(
		"res://Scenes/Gameplay/GameScreen.tscn"
	)
	get_tree().change_scene_to_file(destino)


func _on_comenzar_pressed() -> void:
	if continuar_button.disabled:
		return

	AUDIOMANAGER.play_ui_click()

	await get_tree().create_timer(0.15).timeout
	finalizar_evento()


func _on_comenzar_mouse_entered() -> void:
	if not continuar_button.disabled:
		AUDIOMANAGER.play_ui_hover()
