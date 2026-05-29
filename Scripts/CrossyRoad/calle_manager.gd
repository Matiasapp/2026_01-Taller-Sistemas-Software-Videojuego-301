extends Node2D

# Lista donde arrastraremos las escenas (auto.tscn, camion.tscn, etc.) en el Inspector
@export var vehiculos_posibles: Array[PackedScene]

var direccion_autos: int = 1 

# IMPORTANTE: Tu nodo reloj debe llamarse "Timer"
@onready var timer = $Timer

func _ready() -> void:
	# 1. Elegimos hacia dónde va esta calle (1 = derecha, -1 = izquierda)
	var direcciones_posibles = [1, -1]
	direccion_autos = direcciones_posibles.pick_random()
	
	# 2. Preparamos el reloj para el primer vehículo
	timer.wait_time = randf_range(1.5, 3.0)
	timer.timeout.connect(generar_auto)
	timer.start()

func generar_auto() -> void:
	if vehiculos_posibles.size() == 0:
		return
		
	var escena_elegida = vehiculos_posibles.pick_random()
	var nuevo_vehiculo = escena_elegida.instantiate()
	
	# EL ARREGLO:
	# Como la pantalla mide 1152 de ancho y el punto 0 está en el medio,
	# el borde izquierdo es -576 y el borde derecho es +576.
	
	if direccion_autos == 1:
		# Si van a la derecha, nacen en el extremo izquierdo (-576 - 64 de margen)
		nuevo_vehiculo.position.x = -640
	else:
		# Si van a la izquierda, nacen en el extremo derecho (576 + 64 de margen)
		nuevo_vehiculo.position.x = 640
		
	nuevo_vehiculo.position.y = 0
	nuevo_vehiculo.direccion = direccion_autos
	
	add_child(nuevo_vehiculo)
	
	timer.wait_time = randf_range(1.5, 3.0)
