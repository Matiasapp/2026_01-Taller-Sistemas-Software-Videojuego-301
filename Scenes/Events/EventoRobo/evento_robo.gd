extends Node2D

const PERDIDA_MINIMA := 300
const PERDIDA_MAXIMA := 500

@onready var label: RichTextLabel = $CanvasLayer/VistaTextoIntroduccion/Panel/RichTextLabel
@onready var vista_evento: Control = $CanvasLayer/VistaTextoIntroduccion
@onready var imagen: TextureRect = $CanvasLayer/VistaTextoIntroduccion/TextureRect
@onready var bg_animation: AnimationPlayer = $CanvasLayer/VistaTextoIntroduccion/TextureRect/AnimationPlayer
@onready var continuar_button: Button = $CanvasLayer/VistaTextoIntroduccion/Panel/Comenzar
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect

@export var talking_sound: AudioStreamPlayer

@export var imagen_hombre_1: Texture2D
@export var imagen_hombre_2: Texture2D
@export var imagen_hombre_3: Texture2D
@export var imagen_hombre_4: Texture2D

@export var imagen_mujer_1: Texture2D
@export var imagen_mujer_2: Texture2D
@export var imagen_mujer_3: Texture2D
@export var imagen_mujer_4: Texture2D

var animador_texto: Tween
var escribiendo := false
var indice_mensaje := 0

var mensajes := []
var imagenes := []
var monto_robado := 0


func _ready() -> void:
	randomize()
	_aplicar_consecuencias_robo()

	if bg_animation:
		bg_animation.play("background_move")

	continuar_button.disabled = true
	continuar_button.modulate.a = 0.35
	continuar_button.text = "Continuar"

	if not continuar_button.pressed.is_connected(_on_comenzar_pressed):
		continuar_button.pressed.connect(_on_comenzar_pressed)

	if not continuar_button.mouse_entered.is_connected(_on_comenzar_mouse_entered):
		continuar_button.mouse_entered.connect(_on_comenzar_mouse_entered)

	configurar_evento()
	mostrar_mensaje_actual()


func configurar_evento() -> void:
	mensajes = [
		"Al llegar al taller, notas algo extraño. La cortina metálica está forzada.",
		"Adentro, el desorden confirma lo peor: alguien entró durante la noche.",
		"Revisas el inventario. Entre piezas robadas y daños, perdiste $%d." % monto_robado,
		"La caja queda golpeada, pero la calidad de tu trabajo no cambia. El taller debe continuar."
	]

	if DATOSGLOBALES.genero_jugador == "Femenino":
		imagenes = [
			imagen_mujer_1,
			imagen_mujer_2,
			imagen_mujer_3,
			imagen_mujer_4
		]
	else:
		imagenes = [
			imagen_hombre_1,
			imagen_hombre_2,
			imagen_hombre_3,
			imagen_hombre_4
		]

func _aplicar_consecuencias_robo() -> void:
	monto_robado = randi_range(PERDIDA_MINIMA, PERDIDA_MAXIMA)
	var dia_afectado := maxi(1, DATOSGLOBALES.dia_actual - 1)
	DATOSGLOBALES.registrar_perdida_evento(
		monto_robado,
		"Robo nocturno: -$%d. Sin cambio de reputacion." % monto_robado,
		0,
		dia_afectado
	)
	PARTIDA.guardar()


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
		continuar_button.disabled = false
		continuar_button.modulate.a = 1.0
		return

	imagen.texture = imagenes[indice_mensaje]
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


func fade_to_black(duration := 0.6) -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)

	await tween.finished


func finalizar_evento() -> void:
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
