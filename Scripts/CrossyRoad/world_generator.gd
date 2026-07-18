extends Node2D

@export var franjas_posibles: Array[PackedScene]
@export var tamaño_casilla: int = 64
@export var franjas_iniciales: int = 25 # Con 30 para empezar es más que suficiente
@export var buffer_generacion: int = 20 # Mantiene siempre 25 casillas por delante del jugador

# Necesitamos saber dónde está el jugador para generar el mapa frente a él
@export var jugador: Node2D

# META: distancia (en casillas) a la que se coloca la tienda de repuestos.
# Debe coincidir con "meta_casillas" del jugador para que la victoria y la franja queden alineadas.
@onready var meta_casillas: int = 79
@export var franja_meta_escena: PackedScene
#Audio Ambiente
@onready var ambiente_mapa: AudioStreamPlayer = $AmbienteMapa
#Musica
@onready var musica_loop: AudioStreamPlayer = $MusicLoop
#Conexión del panel resumen

var posicion_y_actual: int = 0
var franjas_activas: Array[Node] = [] # NUEVO: Lista para guardar y borrar las franjas viejas

# Coordenada Y (mundo) donde debe quedar la franja meta. Se calcula desde la posición inicial del jugador.
var meta_y: float = 0.0
var meta_generada: bool = false

func _ready() -> void:
	randomize()

	# En este minijuego no aplica la economía del taller: ocultamos el dinero y el
	# indicador de "taller abierto/cerrado" del HUD compartido (solo en esta escena).
	_ocultar_hud_taller()

	# La meta la define el JUGADOR (única fuente de verdad). El generador coloca la franja UNA
	# casilla antes (meta_casillas - 1) para que el jugador gane justo al PISAR la franja, no
	# una casilla después. Así basta cambiar meta_casillas en el Player y todo queda alineado.
	if jugador and "meta_casillas" in jugador:
		meta_casillas = jugador.meta_casillas - 1

	# Calculamos a qué altura del mundo quedará la meta, partiendo de la posición del jugador.
	if jugador:
		meta_y = jugador.position.y - (meta_casillas * tamaño_casilla)

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

# Oculta los elementos del HUD compartido que no tienen sentido en el minijuego:
# el dinero, la hora, el día, el estado "taller abierto/cerrado", el aviso
# parpadeante de "abre el taller", el contador de clientes atendidos y los dos
# paneles de fondo que los enmarcan. Solo afecta a esta escena.
func _ocultar_hud_taller() -> void:
	var hud := get_node_or_null("Hud")
	if hud == null:
		return

	var rutas := [
		"PlataHoraDia",         # bloque dinero + hora + día
		"TallerAbiertoCerrado", # "El taller está Abierto/Cerrado"
		"ClientesAtendidos",    # "Clientes atendidos: X/5"
		"AvisoAbrirTaller",     # recordatorio parpadeante
		"NinePatchRect",        # panel de fondo (dinero/hora/día)
		"NinePatchRect2",       # panel de fondo (taller + clientes)
	]
	for ruta in rutas:
		var nodo := hud.get_node_or_null(ruta)
		if nodo:
			nodo.visible = false

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
	# Si ya llegamos a la distancia de la meta, colocamos la franja final y dejamos de generar.
	if meta_generada:
		return

	if franja_meta_escena and meta_y < 0.0 and posicion_y_actual <= meta_y:
		instanciar_y_posicionar(franja_meta_escena)
		meta_generada = true
		return

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
	if not jugador:
		return

	# Distancia (en píxeles) por DEBAJO del jugador a partir de la cual una franja ya no se ve.
	# Recuerda: "arriba" es Y negativa, así que las franjas viejas tienen Y MAYOR que el jugador.
	var margen_limpieza := tamaño_casilla * 80

	# La lista está ordenada de la más vieja (abajo) a la más nueva (arriba).
	# Solo borramos desde el frente mientras esa franja siga muy por detrás del jugador.
	while franjas_activas.size() > 0:
		var franja_vieja = franjas_activas[0]

		if not is_instance_valid(franja_vieja):
			franjas_activas.pop_front()
			continue

		if franja_vieja.position.y - jugador.position.y > margen_limpieza:
			franjas_activas.pop_front()
			franja_vieja.queue_free() # Destruye el nodo liberando memoria
		else:
			break
			
