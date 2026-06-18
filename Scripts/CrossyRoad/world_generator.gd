extends Node2D

@export var franjas_posibles: Array[PackedScene]
@export var tamaño_casilla: int = 64
@export var franjas_iniciales: int = 25 # Con 30 para empezar es más que suficiente
@export var buffer_generacion: int = 20 # Mantiene siempre 25 casillas por delante del jugador

# NUEVO: Necesitamos saber dónde está el jugador para generar el mapa frente a él
@export var jugador: Node2D 
#Audio Ambiente
@onready var ambiente_mapa: AudioStreamPlayer = $AmbienteMapa
#Musica
@onready var musica_loop: AudioStreamPlayer = $MusicLoop

var posicion_y_actual: int = 0 
var franjas_activas: Array[Node] = [] # NUEVO: Lista para guardar y borrar las franjas viejas

func _ready() -> void:
	randomize()

	if ambiente_mapa:
		ambiente_mapa.process_mode = Node.PROCESS_MODE_ALWAYS
		ambiente_mapa.play()
		
	if musica_loop:
		musica_loop.process_mode = Node.PROCESS_MODE_ALWAYS
		musica_loop.play()
	
	for i in range(3):
		generar_franja_segura()
		
	for i in range(franjas_iniciales - 3):
		generar_franja_aleatoria()

# NUEVO: Vigila constantemente al jugador
func _process(_delta: float) -> void:
	if not jugador:
		return # Si no hay jugador asignado, no hacemos nada
		
	# Calculamos cuántas casillas hay entre el jugador y la última casilla generada
	var distancia_y = jugador.position.y - posicion_y_actual
	var casillas_de_distancia = int(distancia_y / tamaño_casilla)
	
	# Si el jugador se acerca al borde, generamos una nueva franja y borramos una vieja
	if casillas_de_distancia < buffer_generacion:
		generar_franja_aleatoria()
		limpiar_franjas_viejas()

func generar_franja_aleatoria() -> void:
	if franjas_posibles.size() < 2:
		return
		
	var escena_elegida: PackedScene
	var probabilidad = randi_range(1, 100)
	
	if probabilidad <= 20:
		escena_elegida = franjas_posibles[1] 
	else:
		escena_elegida = franjas_posibles[0] 
		
	instanciar_y_posicionar(escena_elegida)

func generar_franja_segura() -> void:
	if franjas_posibles.size() > 0:
		instanciar_y_posicionar(franjas_posibles[0])

# NUEVO: Función unificada para no repetir código al crear casillas
func instanciar_y_posicionar(escena: PackedScene) -> void:
	var nueva_franja = escena.instantiate()
	nueva_franja.position.y = posicion_y_actual
	nueva_franja.position.x = 0
	
	add_child(nueva_franja)
	move_child(nueva_franja, 0)
	
	# Guardamos la franja en nuestra lista para vigilarla
	franjas_activas.append(nueva_franja)
	
	var salto_casillas = 1 
	if "alto_en_casillas" in nueva_franja:
		salto_casillas = nueva_franja.alto_en_casillas
		
	posicion_y_actual -= (tamaño_casilla * salto_casillas)

# NUEVO: Destructor de memoria
func limpiar_franjas_viejas() -> void:
	# Si hay más de 40 franjas en la pantalla, empezamos a borrar las que quedaron atrás
	if franjas_activas.size() > 10:
		# pop_front() saca el elemento más viejo de la lista (el que quedó hasta abajo)
		var franja_vieja = franjas_activas.pop_front() 
		if is_instance_valid(franja_vieja):
			franja_vieja.queue_free() # Destruye el nodo de la escena liberando la memoria
