extends Node2D

signal progreso_actualizado(valor)
signal pieza_completada

@export var marca_scene : PackedScene = preload("res://Scenes/Minigames/Soldadura/Scene/Marca_soldadura.tscn")

@onready var linea = $Trayectoria
@onready var marcas = $Marca_soldadura/AnimatedSprite2D

var porcentaje := 0.0
var completada := false

var puntos_visitados := {}

func _process(_delta):

	if completada:
		return

	var mouse_pos = get_global_mouse_position()

	for i in range(linea.points.size()):

		var punto_global = linea.to_global(linea.points[i])

		if mouse_pos.distance_to(punto_global) < 15:

			if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):

				if !puntos_visitados.has(i):

					puntos_visitados[i] = true

					crear_marca(punto_global)

					calcular_porcentaje()

func crear_marca(pos):

	var marca = marca_scene.instantiate()

	marcas.add_child(marca)

	marca.global_position = pos

func calcular_porcentaje():

	var total = linea.points.size()

	var completados = puntos_visitados.size()

	porcentaje = (float(completados) / float(total)) * 100

	progreso_actualizado.emit(porcentaje)

	if porcentaje >= 100:

		completada = true

		pieza_completada.emit()
