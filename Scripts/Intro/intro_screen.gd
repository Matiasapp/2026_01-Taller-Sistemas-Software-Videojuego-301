extends Node2D

@onready var label = $CanvasLayer/VistaTextoIntroduccion/Panel/RichTextLabel
@onready var vista_introduccion = $CanvasLayer/VistaTextoIntroduccion
@onready var vista_genero = $CanvasLayer/VistaGenero
@onready var imagen_intro: TextureRect = $CanvasLayer/VistaTextoIntroduccion/TextureRect
@onready var bg_animation: AnimationPlayer = $CanvasLayer/VistaTextoIntroduccion/TextureRect/AnimationPlayer
@onready var comenzar_button = $CanvasLayer/VistaTextoIntroduccion/Comenzar
@onready var fade_rect = $CanvasLayer/FadeRect

@export var click_sound: AudioStreamPlayer
@export var hover_sound: AudioStreamPlayer
@export var hover_character_sound: AudioStreamPlayer
@export var select_character_sound: AudioStreamPlayer
@export var whoosh_sound: AudioStreamPlayer
@export var talking_sound: AudioStreamPlayer

var animador_texto: Tween
var escribiendo := false
var indice_escena := -1

const MENSAJES_INTRO: Array[String] = [
	"Es lunes por la mañana. Frente a ti está el taller que tu padre mantuvo abierto durante casi toda su vida.",
	"Heredaste sus herramientas, sus clientes y su promesa de mantener el negocio familiar. También heredaste las cuentas que nunca pudo pagar.",
	"El propietario dejó su última advertencia: si el arriendo no está al día este viernes, cambiará la cerradura. Tienes cinco días.",
	"Tu madre insiste en que no te preocupes por ella. Dice que ya comió. El refrigerador casi vacío cuenta otra historia.",
	"Cada noche tendrás que decidir qué pagar y qué postergar. Una cuenta pendiente puede salvarte hoy, pero mañana seguirá esperando. Tienes cinco días para recuperar a tus clientes, proteger a tu familia y evitar que estas puertas se cierren para siempre."
]

const IMAGENES_INTRO: Array[Texture2D] = [
	preload("res://Assets/Events/IntroScreen/1.png"),
	preload("res://Assets/Events/IntroScreen/2.png"),
	preload("res://Assets/Events/IntroScreen/3.png"),
	preload("res://Assets/Events/IntroScreen/4.png"),
	preload("res://Assets/Events/IntroScreen/5.png")
]


# =========================
# AUDIO
# =========================

func play_click() -> void:
	if click_sound:
		var semitones := randf_range(-2.0, 2.0)
		click_sound.pitch_scale = pow(2.0, semitones / 12.0)
		click_sound.play()


func play_hover() -> void:
	if hover_sound:
		var semitones := randf_range(-5.0, 5.0)
		hover_sound.pitch_scale = pow(2.0, semitones / 12.0)
		hover_sound.play()


func play_hover_character() -> void:
	if hover_character_sound:
		var semitones := randf_range(-1.0, 1.0)
		hover_character_sound.pitch_scale = pow(2.0, semitones / 12.0)
		hover_character_sound.play()


func play_select_character() -> void:
	if select_character_sound:
		var semitones := randf_range(-1.0, 1.0)
		select_character_sound.pitch_scale = pow(2.0, semitones / 12.0)
		select_character_sound.play()


func play_whoosh() -> void:
	if whoosh_sound:
		whoosh_sound.pitch_scale = 1.0
		whoosh_sound.play()


func start_talking() -> void:
	if talking_sound and not talking_sound.playing:
		talking_sound.pitch_scale = randf_range(0.95, 1.05)
		talking_sound.play()


func stop_talking() -> void:
	if talking_sound and talking_sound.playing:
		talking_sound.stop()


# =========================
# READY
# =========================

func _ready() -> void:
	randomize()
	assert(MENSAJES_INTRO.size() == IMAGENES_INTRO.size(), "Cada texto de la introducción necesita una imagen.")
	bg_animation.play("background_move")
	vista_genero.hide()
	comenzar_button.disabled = true
	comenzar_button.modulate.a = 0.35
	mostrar_siguiente_escena()

# =========================
# TEXTO INTRO
# =========================

func _input(event) -> void:
	if not vista_introduccion.visible:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if escribiendo:
			saltar_animacion()
		elif indice_escena < MENSAJES_INTRO.size() - 1:
			mostrar_siguiente_escena()


func animar_texto(nuevo_texto: String) -> void:
	escribiendo = true
	start_talking()
	label.text = nuevo_texto
	label.visible_characters = 0
	
	if animador_texto:
		animador_texto.kill()
	
	animador_texto = create_tween()
	animador_texto.tween_property(label, "visible_characters", nuevo_texto.length(), 1.5)
	animador_texto.finished.connect(_finalizar_escritura)


func saltar_animacion() -> void:
	if animador_texto:
		animador_texto.kill()
	
	label.visible_characters = label.text.length()
	_finalizar_escritura()


func _finalizar_escritura() -> void:
	stop_talking()
	escribiendo = false
	if indice_escena == MENSAJES_INTRO.size() - 1:
		print("Fin de la introducción")
		comenzar_button.disabled = false
		comenzar_button.modulate.a = 1.0


func mostrar_siguiente_escena() -> void:
	var siguiente_indice := indice_escena + 1
	if siguiente_indice >= MENSAJES_INTRO.size():
		return

	indice_escena = siguiente_indice
	imagen_intro.texture = IMAGENES_INTRO[indice_escena]
	animar_texto(MENSAJES_INTRO[indice_escena])
		

# =========================
# TRANSICION
# =========================		

func fade_to_black(duration := 0.6) -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished


# =========================
# BOTONES
# =========================

func _on_comenzar_pressed() -> void:
	play_click()

	await get_tree().create_timer(0.15).timeout

	vista_introduccion.hide()
	vista_genero.show()


func _on_chico_button_pressed() -> void:
	await seleccionar_personaje("Masculino")


func _on_chica_button_pressed() -> void:
	await seleccionar_personaje("Femenino")


func seleccionar_personaje(genero: String) -> void:
	play_select_character()

	await get_tree().create_timer(0.15).timeout

	DATOSGLOBALES.genero_jugador = genero

	play_whoosh()

	await fade_to_black(0.6)
	await GlobalMusic.fade_out_and_stop(0.6)

	CARGADOR.cambiar_escena("res://Scenes/Gameplay/GameScreen.tscn")


# =========================
# HOVER
# =========================

func _on_comenzar_mouse_entered() -> void:
	play_hover()


func _on_chico_button_mouse_entered() -> void:
	play_hover_character()


func _on_chica_button_mouse_entered() -> void:
	play_hover_character()
