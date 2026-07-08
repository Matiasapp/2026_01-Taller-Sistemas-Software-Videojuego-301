extends Node2D

@onready var progress = $CanvasLayer/ProgressBar
@onready var label_piezas = $CanvasLayer/LabelPiezas
@onready var timer = $CanvasLayer/Timer
@onready var label_tiempo = $CanvasLayer/LabelTiempo
@onready var start_label = $CanvasLayer/start_label
@onready var pieza_container = $PiezaContainer
#Audio
@onready var complete_sound = $CompleteSound

var piezas_completadas := 0

var dinero_por_pieza := 36

var indice_pieza := 0
var escena_anterior

var escenas_piezas = [
	preload("res://Scenes/Minigames/Soldadura/Scene/PiezasMetal/PiezaMetal.tscn"),
	preload("res://Scenes/Minigames/Soldadura/Scene/PiezasMetal/pieza_metal_2.tscn"),
	preload("res://Scenes/Minigames/Soldadura/Scene/PiezasMetal/pieza_metal_3.tscn"),
	preload("res://Scenes/Minigames/Soldadura/Scene/PiezasMetal/pieza_metal_4.tscn"),
	preload("res://Scenes/Minigames/Soldadura/Scene/PiezasMetal/pieza_metal_5.tscn"),
	preload("res://Scenes/Minigames/Soldadura/Scene/PiezasMetal/pieza_metal_6.tscn"),
	preload("res://Scenes/Minigames/Soldadura/Scene/PiezasMetal/pieza_metal_7.tscn")
]

var pieza_actual

var game_started = false


func start_countdown() -> void:
	game_started = false
	timer.stop()

	start_label.visible = true
	start_label.text = "Comienza a soldar"

	await get_tree().create_timer(1.0).timeout
	start_label.text = "3"

	await get_tree().create_timer(1.0).timeout
	start_label.text = "2"

	await get_tree().create_timer(1.0).timeout
	start_label.text = "1"

	await get_tree().create_timer(1.0).timeout
	start_label.text = "¡YA!"

	await get_tree().create_timer(0.5).timeout

	start_label.visible = false
	game_started = true
	timer.start()
	cargar_pieza()


func _ready():
	
	start_countdown()
	timer.wait_time = 30
	
	timer.timeout.connect(_on_timer_timeout)


func _process(_delta):
	if not game_started:
		return
	label_tiempo.text = "Tiempo: " + str(int(ceil(timer.time_left))) 


func cargar_pieza():	
	if pieza_actual:
		pieza_actual.queue_free()

	# Elegimos una pieza al azar por primera vez
	var escena_elegida = escenas_piezas.pick_random()

	# Si la elegida es exactamente igual a la anterior, elige otra de nuevo.
	# Repetirá esto hasta que saque una diferente.
	while escena_elegida == escena_anterior:
		escena_elegida = escenas_piezas.pick_random()

	# Guardamos la que acaba de salir como la "nueva" escena anterior
	# para que no se repita en el siguiente turno.
	escena_anterior = escena_elegida

	# Instanciamos la pieza
	pieza_actual = escena_elegida.instantiate()

	pieza_container.add_child(pieza_actual)
	pieza_actual.progreso_actualizado.connect(actualizar_barra)
	pieza_actual.pieza_completada.connect(_on_pieza_completada)
	progress.value = 0
func actualizar_barra(valor):

	progress.value = valor
	

func _on_pieza_completada():

	if complete_sound:
		complete_sound.play()

	piezas_completadas += 1

	label_piezas.text = "Piezas: " + str(piezas_completadas)

	indice_pieza += 1

	cargar_pieza()

func _on_timer_timeout():

	terminar_juego()

func terminar_juego():

	GLOBALSOLDADURA.piezas_completadas = piezas_completadas
	GLOBALSOLDADURA.dinero = piezas_completadas * dinero_por_pieza

	get_tree().change_scene_to_file(
		"res://Scenes/Minigames/Soldadura/Scene/Resultados.tscn"
	)
	
	
