extends Node2D

var arbol_escena = preload("res://Scenes/Minigames/Crossy_Road/arbol.tscn")

@export var alto_en_casillas: int = 2
@export var tamaño_casilla = 64
@export var cantidad_columnas = 17

func _ready() -> void:
	generar_obstaculos()

func generar_obstaculos() -> void:
	var columnas_disponibles = []
	for i in range(cantidad_columnas):
		columnas_disponibles.append(i)
		
	columnas_disponibles.shuffle()
	
	# Quitamos 2 huecos para que el jugador siempre tenga un camino
	if columnas_disponibles.size() > 2:
		columnas_disponibles.pop_back()
		columnas_disponibles.pop_back()
	
	# EL TRUCO: Calcular el borde izquierdo matemático
	# Tomamos el ancho total (1152) y nos movemos la mitad hacia la izquierda (negativo)
	# Le sumamos la mitad de una casilla (32) para que el tronco quede en el centro de su espacio
	var ancho_total = cantidad_columnas * tamaño_casilla
	var posicion_inicial_x = -(ancho_total / 2.0) + (tamaño_casilla / 2.0)
	
	for columna in columnas_disponibles:
		# 90% de probabilidad de que aparezca un árbol en esta casilla
		if randf() > 0.1:
			var nuevo_arbol = arbol_escena.instantiate()
			
			# Ahora el árbol parte desde el borde izquierdo real y avanza según su columna
			nuevo_arbol.position.x = posicion_inicial_x + (columna * tamaño_casilla)
			nuevo_arbol.position.y = 0 
			
			add_child(nuevo_arbol)
