extends Area2D

@export var tiempo_requerido := 3.0

@onready var area_soldada = $AreaSoldada

var progreso := 0.0
var completado := false

func _ready():
	add_to_group("pieza")
	area_soldada.visible = false

func soldar(delta):
	if completado:
		return

	progreso += delta

	if progreso >= tiempo_requerido:

		completado = true

		area_soldada.visible = true
		area_soldada.play("soldado")

		print("Pieza soldada")
