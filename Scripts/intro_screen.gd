extends Node2D

@onready var label = $CanvasLayer/VistaTextoIntroduccion/Panel/RichTextLabel
@onready var vista_introduccion = $CanvasLayer/VistaTextoIntroduccion
@onready var vista_genero = $CanvasLayer/VistaGenero
var animador_texto: Tween # Variable para controlar la animación actual

# Variables de control de estado (Fuera de las funciones)
var mensajes_pendientes = [
	"Es lunes por la mañana y el aire en el taller huele a aceite quemado y a desesperación.",
	"Heredaste este negocio con la promesa de un futuro brillante, pero hoy la realidad es otra: las deudas se acumulan, el refrigerador está vacío y el inspector municipal ya ha pasado dos veces por la acera.",
	"Tienes exactamente 7 días para evitar que la cortina metálica se cierre para siempre.",
	"Deberás diagnosticar fallas con precisión, decidir si usas repuestos de calidad o piezas dudosas para ahorrar unos pesos, y gestionar tu reputación mientras el hambre aprieta.",
	"En este taller, el motor más difícil de reparar no es el de un auto... es tu propia supervivencia.  ¿Lograrás llegar al domingo con el taller en pie o terminarás en la quiebra absoluta?"
]

var escribiendo = false # Flag para saber si el texto se está animando

func _ready() -> void:
	vista_genero.hide()
	mostrar_siguiente_mensaje()

func _input(event):
	# Detecta el clic del mouse
	if event is InputEventMouseButton and event.pressed:
		if escribiendo:
			# ACCIÓN: Saltar la animación
			saltar_animacion()
		else:
			# ACCIÓN: Pasar al siguiente mensaje
			mostrar_siguiente_mensaje()

func animar_texto(nuevo_texto: String):
	escribiendo = true
	label.text = nuevo_texto
	label.visible_characters = 0
	
	# Guardamos el tween en una variable de clase para poder manipularlo luego
	if animador_texto: 
		animador_texto.kill() # Detenemos cualquier animación previa
	
	animador_texto = create_tween()
	animador_texto.tween_property(label, "visible_characters", nuevo_texto.length(), 1.5)
	animador_texto.finished.connect(func(): escribiendo = false)

func saltar_animacion():
	# 1. Matamos el tween para que deje de contar letras
	if animador_texto:
		animador_texto.kill()
	
	# 2. Mostramos todos los caracteres de inmediato
	label.visible_characters = label.text.length()
	
	# 3. Importante: decir que ya no está escribiendo para que el próximo clic pase de página
	escribiendo = false
func mostrar_siguiente_mensaje():
	if mensajes_pendientes.size() > 0:
		var mensaje = mensajes_pendientes.pop_front()
		animar_texto(mensaje)
	else:
		print("Fin de la introducción")


func _on_comenzar_pressed() -> void:
	vista_introduccion.hide()
	vista_genero.show()
	


func _on_chico_button_pressed() -> void:
	DatosGlobales.genero_jugador = "Masculino"
	get_tree().change_scene_to_file("res://Scenes/GameScreen.tscn")


func _on_chica_button_pressed() -> void:
	DatosGlobales.genero_jugador = "Femenino"
	get_tree().change_scene_to_file("res://Scenes/GameScreen.tscn")
