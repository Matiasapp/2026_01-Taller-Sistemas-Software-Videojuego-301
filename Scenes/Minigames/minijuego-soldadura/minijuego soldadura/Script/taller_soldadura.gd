extends Node2D

@onready var progress = $CanvasLayer/ProgressBar
@onready var label_piezas = $CanvasLayer/LabelPiezas
@onready var timer = $CanvasLayer/Timer
@onready var label_tiempo = $CanvasLayer/LabelTiempo

@onready var pieza_container = $PiezaContainer

var piezas_completadas := 0

var dinero_por_pieza := 100

var indice_pieza := 0


var escenas_piezas = [
	preload("res://minijuego soldadura/Scene/PiezasMetal/PiezaMetal.tscn"),
	preload("res://minijuego soldadura/Scene/PiezasMetal/pieza_metal_2.tscn"),
	preload("res://minijuego soldadura/Scene/PiezasMetal/pieza_metal_3.tscn")
]

var pieza_actual

func _ready():

	timer.wait_time = 15
	
	timer.timeout.connect(_on_timer_timeout)

	timer.start()

	cargar_pieza()

func _process(_delta):
	label_tiempo.text = "Tiempo: " + str(int(ceil(timer.time_left))) 


func cargar_pieza():	
	
	if pieza_actual:
		pieza_actual.queue_free()

	if indice_pieza >= escenas_piezas.size():

		terminar_juego()
		return

	pieza_actual = escenas_piezas[indice_pieza].instantiate()

	pieza_container.add_child(pieza_actual)

	pieza_actual.progreso_actualizado.connect(actualizar_barra)

	pieza_actual.pieza_completada.connect(_on_pieza_completada)

	progress.value = 0

func actualizar_barra(valor):

	progress.value = valor
	

func _on_pieza_completada():

	piezas_completadas += 1

	label_piezas.text = "Piezas: " + str(piezas_completadas)

	indice_pieza += 1

	cargar_pieza()

func _on_timer_timeout():

	terminar_juego()

func terminar_juego():

	Global.piezas_completadas = piezas_completadas

	Global.dinero = piezas_completadas * dinero_por_pieza

	get_tree().change_scene_to_file(
		"res://minijuego soldadura/Resultados.tscn"
	)
