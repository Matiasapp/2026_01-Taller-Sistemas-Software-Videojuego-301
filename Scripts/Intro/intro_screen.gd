extends Node2D

@onready var label = $CanvasLayer/VistaTextoIntroduccion/Panel/RichTextLabel
@onready var vista_introduccion = $CanvasLayer/VistaTextoIntroduccion
@onready var vista_genero = $CanvasLayer/VistaGenero
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

var mensajes_pendientes = [
	"Es lunes por la mañana y el aire en el taller huele a aceite quemado y a desesperación.",
	"Heredaste este negocio con la promesa de un futuro brillante, pero hoy la realidad es otra: las deudas se acumulan, el refrigerador está vacío y el inspector municipal ya ha pasado dos veces por la acera.",
	"Tienes exactamente 7 días para evitar que la cortina metálica se cierre para siempre.",
	"Deberás diagnosticar fallas con precisión, decidir si usas repuestos de calidad o piezas dudosas para ahorrar unos pesos, y gestionar tu reputación mientras el hambre aprieta.",
	"En este taller, el motor más difícil de reparar no es el de un auto... es tu propia supervivencia.  ¿Lograrás llegar al domingo con el taller en pie o terminarás en la quiebra absoluta?"
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
	bg_animation.play("background_move")
	vista_genero.hide()
	comenzar_button.disabled = true
	comenzar_button.modulate.a = 0.35
	mostrar_siguiente_mensaje()

# =========================
# TEXTO INTRO
# =========================

func _input(event) -> void:
	if not vista_introduccion.visible:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if escribiendo:
			saltar_animacion()
		else:
			mostrar_siguiente_mensaje()


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

func mostrar_siguiente_mensaje() -> void:
	if mensajes_pendientes.size() > 0:
		var mensaje = mensajes_pendientes.pop_front()
		animar_texto(mensaje)
	else:
		stop_talking()
		print("Fin de la introducción")
		comenzar_button.disabled = false
		comenzar_button.modulate.a = 1.0
		

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

	get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScreen.tscn")


# =========================
# HOVER
# =========================

func _on_comenzar_mouse_entered() -> void:
	play_hover()


func _on_chico_button_mouse_entered() -> void:
	play_hover_character()


func _on_chica_button_mouse_entered() -> void:
	play_hover_character()
