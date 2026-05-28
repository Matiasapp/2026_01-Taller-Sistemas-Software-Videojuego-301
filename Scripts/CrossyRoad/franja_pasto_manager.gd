extends Node2D

# Cargamos el "molde" del árbol
var arbol_escena = preload("res://Scenes/Crossy_Road/arbol.tscn")

@export var tamaño_casilla = 64
@export var cantidad_columnas = 10

func _ready() -> void:
	generar_obstaculos()

func generar_obstaculos() -> void:
	# 1. Creamos una lista con todas las posiciones posibles (ej: 0, 1, 2... hasta 9)
	var columnas_disponibles = []
	for i in range(cantidad_columnas):
		columnas_disponibles.append(i)
		
	# 2. Mezclamos la lista al azar (como barajar cartas)
	columnas_disponibles.shuffle()
	
	# 3. EL TRUCO: Quitamos 1 o 2 posiciones de la lista
	# Esto asegura que NUNCA se llene toda la fila de árboles y el jugador pueda pasar
	columnas_disponibles.pop_back() 
	columnas_disponibles.pop_back() # Quitamos un segundo hueco opcional
	
	# 4. Plantamos los árboles en las posiciones que quedaron en la lista
	for columna in columnas_disponibles:
		# Lanzamos una moneda (50% de probabilidad) para decidir si ponemos árbol o no
		# Así a veces hay muchos árboles y a veces la fila está casi vacía
		if randf() > 0.5:
			var nuevo_arbol = arbol_escena.instantiate()
			
			# Calculamos su posición X exacta multiplicando la columna por 64
			# (Si el centro de tu pantalla es 0, podrías necesitar ajustar esto)
			nuevo_arbol.position.x = columna * tamaño_casilla
			nuevo_arbol.position.y = 0 
			
			# Lo añadimos a la escena
			add_child(nuevo_arbol)
