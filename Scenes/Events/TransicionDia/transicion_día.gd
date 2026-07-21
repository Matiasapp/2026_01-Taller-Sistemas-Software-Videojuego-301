extends Node2D

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


func _ready() -> void:
	randomize()

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
		"El taller por fin queda en silencio. Guardas las herramientas y cierras la jornada.",
		"Ha sido un día largo: clientes, reparaciones, decisiones apresuradas y cuentas que todavía pesan en la cabeza.",
		"Intentas descansar unas horas, sabiendo que mañana tendrás que volver a empezar con lo poco que queda en pie.",
		"Un nuevo día te espera. Tal vez no sea más fácil... pero el taller sigue abierto."
	]

	var es_mujer := DATOSGLOBALES.genero_jugador == "Femenino"

	imagenes = [
		imagen_mujer_1 if es_mujer else imagen_hombre_1,
		imagen_mujer_2 if es_mujer else imagen_hombre_2,
		imagen_mujer_3 if es_mujer else imagen_hombre_3,
		imagen_mujer_4 if es_mujer else imagen_hombre_4
	]

func _input(event) -> void:
	if not vista_evento.visible:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Si el botón ya está habilitado, no avanzar con click global
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

	if indice_mensaje < imagenes.size() and imagenes[indice_mensaje]:
		imagen.texture = imagenes[indice_mensaje]
	else:
		push_warning("Falta asignar imagen de transición día en índice: " + str(indice_mensaje))

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

	# Si esta noche hay robo, se muestra DESPUÉS del cierre del taller; si no, al taller.
	var destino_normal: String
	if DATOSGLOBALES.siguiente_evento_dia == "robo":
		destino_normal = "res://Scenes/Events/EventoRobo/EventoRobo.tscn"
	elif DATOSGLOBALES.siguiente_evento_dia == "protesta":
		destino_normal = "res://Scenes/Events/EventoProtesta/EventoProtesta.tscn"
	else:
		destino_normal = "res://Scenes/Gameplay/GameScreen.tscn"

	var destino := DATOSGLOBALES.obtener_destino_post_escena(destino_normal)
	CARGADOR.cambiar_escena(destino)


func _on_comenzar_pressed() -> void:
	if continuar_button.disabled:
		return

	AUDIOMANAGER.play_ui_click()

	await get_tree().create_timer(0.15).timeout
	finalizar_evento()


func _on_comenzar_mouse_entered() -> void:
	if not continuar_button.disabled:
		AUDIOMANAGER.play_ui_hover()
