extends Node2D

# Lista donde pondremos nuestras franjas (Pasto y Calle)
@export var franjas_posibles: Array[PackedScene]

# Cuántas franjas queremos que se generen al iniciar el juego
@export var franjas_iniciales: int = 64
@export var tamaño_casilla: int = 64

# Empezamos en Y = 0 y de ahí iremos subiendo hacia los números negativos
var posicion_y_actual: int = 0 

func _ready() -> void:
	randomize() # Asegura que el azar sea diferente en cada partida
	
	# Opcional pero recomendado: Generar unas cuantas franjas de pasto seguidas 
	# al principio para que el jugador nazca en una zona segura sin autos.
	# Asumimos que tu pasto es el elemento 0 de la lista.
	for i in range(3):
		generar_franja_segura()
		
	# Generar el resto del mapa aleatoriamente
	for i in range(franjas_iniciales - 3):
		generar_franja_aleatoria()

func generar_franja_aleatoria() -> void:
	# Nos aseguramos de tener ambas opciones configuradas en el Inspector
	if franjas_posibles.size() < 2:
		return
		
	var escena_elegida: PackedScene
	
	# Tiramos un dado virtual que da un número del 1 al 100
	var probabilidad = randi_range(1, 100)
	
	# Si el número cae entre 1 y 20 (20% de probabilidad), generamos Pasto
	if probabilidad <= 20:
		escena_elegida = franjas_posibles[1] 
	# Si cae entre 21 y 100 (80% de probabilidad), generamos Calle
	else:
		escena_elegida = franjas_posibles[0] 
		
	# Instanciamos la escena elegida por nuestro dado
	var nueva_franja = escena_elegida.instantiate()
	
	nueva_franja.position.y = posicion_y_actual
	nueva_franja.position.x = 0
	
	add_child(nueva_franja)
	move_child(nueva_franja, 0)
	
	# Revisamos si la franja es más gorda (como tu pasto doble)
	var salto_casillas = 1 
	if "alto_en_casillas" in nueva_franja:
		salto_casillas = nueva_franja.alto_en_casillas
		
	posicion_y_actual -= (tamaño_casilla * salto_casillas)


func generar_franja_segura() -> void:
	if franjas_posibles.size() > 0:
		var franja_pasto = franjas_posibles[0].instantiate()
		franja_pasto.position.y = posicion_y_actual
		franja_pasto.position.x = 0
		add_child(franja_pasto)
		move_child(franja_pasto, 0)
		
		# Hacemos la misma validación aquí para el inicio del juego
		var salto_casillas = 1
		if "alto_en_casillas" in franja_pasto:
			salto_casillas = franja_pasto.alto_en_casillas
			
		posicion_y_actual -= (tamaño_casilla * salto_casillas)
