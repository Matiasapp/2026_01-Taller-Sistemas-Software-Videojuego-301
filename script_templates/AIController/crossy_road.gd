extends "res://addons/godot_rl_agents/controller/ai_controller_2d.gd"

@export var mostrar_vision_debug: bool = true

# Corrige el desfase entre la grilla lógica y las posiciones reales.
# Negativo = mueve la grilla hacia ADELANTE (arriba, ya que subir es Y negativa).
# Ajusta este valor desde el Inspector en tiempo real hasta que la cuadrícula
# calce exactamente con los autos/árboles en pantalla.
@export var ajuste_filas: int = 0

# Los vehículos ya están posicionados sobre el centro de su carril.
# Este ajuste queda disponible solo para escenas con un desfase excepcional.
@export var ajuste_filas_vehiculos: int = 0
@export var limite_columna: int = 8

# ANTICIPACIÓN: segundos hacia el futuro que proyectamos la posición de cada
# auto al construir la grilla de peligro. Un auto a 250 px/s recorre casi una
# casilla (64 px) en 0.25 s; darle al agente el "barrido" futuro del auto (y no
# solo su posición actual) evita que salte a una casilla que estará ocupada
# justo cuando aterrice. Es el arreglo clave para que aprenda a cruzar.
@export var horizonte_anticipacion: float = 0.35

var celdas_debug: Array = []
var penalizacion_intencion: float = 0.0

# Última acción humana capturada durante la grabación de demos. Es la "etiqueta"
# que el plugin guarda para cada estado (ver get_action()).
var _accion_humana: int = 0

# Latch del ciclo de episodio en demos. El plugin lee get_done() CADA frame y
# guarda un episodio cada vez que es true. Como el jugador queda "muerto" varios
# frames, sin latch se guardan cientos de episodios fantasma (el bug del
# contador que sube sin parar). Con esto reportamos el terminal UNA sola vez por
# episodio y no volvemos a reportarlo hasta que el jugador esté vivo de nuevo.
var _demo_terminal_reportado: bool = false

# ---------------------------------------------------------
# 0. SINCRONIZACIÓN VISUAL POR FRAME
# ---------------------------------------------------------
# El plugin llama a get_obs() solo en cada paso de decisión de la IA,
# pero los autos se mueven en cada frame. Por eso el debug visual se
# recalcula aquí, en _process(), para que nunca quede desfasado
# respecto a las posiciones reales de los objetos en pantalla.
func _process(_delta: float) -> void:
	if not _debug_visible() or not _player:
		# Si la grilla estaba dibujada (p. ej. al pasar a modo demo), la borramos.
		if not celdas_debug.is_empty():
			celdas_debug.clear()
			queue_redraw()
		return

	var grilla = _construir_grilla_peligro()
	var px = round(_player.posicion_logica.x / _player.tamaño_casilla)
	var py = round(_player.posicion_logica.y / _player.tamaño_casilla) + ajuste_filas

	celdas_debug.clear()
	for y_offset in range(-3, 2):
		for x_offset in range(-3, 4):
			var coordenada = Vector2(px + x_offset, py + y_offset)
			var valor = _valor_celda(grilla, coordenada)
			celdas_debug.append({"pos": coordenada * _player.tamaño_casilla, "valor": valor})

	queue_redraw()

# La grilla de visión de la IA se muestra solo si está activado el debug Y NO
# estamos grabando demos: durante la grabación queremos jugar "a ciegas", como
# un humano normal, sin la ayuda visual (así la demo refleja decisiones reales
# y el juego es más difícil/limpio de completar a mano).
func _debug_visible() -> bool:
	return mostrar_vision_debug and control_mode != ControlModes.RECORD_EXPERT_DEMOS

# ---------------------------------------------------------
# 1. OBSERVACIONES (EL MINIMAPA VIRTUAL)
# ---------------------------------------------------------
func get_obs() -> Dictionary:
	var progreso_meta = float(_player.maximas_casillas_avanzadas) / float(_player.meta_casillas)
	var tiempo_norm = _player.tiempo_restante / _player.tiempo_limite

	# Posición lateral normalizada a ~[-1, 1] respecto al carril de salida.
	# Antes se usaba position.x/1000 y position.y/1000; la Y crecía sin límite
	# (hasta -5000 al final del mapa), dando a la red una entrada no estacionaria
	# imposible de normalizar. La progresión vertical ya la aporta "progreso_meta".
	var rango_lateral = max(1.0, float(limite_columna) * _player.tamaño_casilla)
	var lateral_norm = (_player.position.x - _player.posicion_inicial_x) / rango_lateral

	# Señal global de peligro: ¿hay algún auto en el radio de alerta? Le da
	# contexto a la red aunque el auto aún no toque la ventana de la grilla.
	var hay_auto_cerca = 1.0 if _autos_en_alerta() else 0.0

	var obs_array = [
		progreso_meta, tiempo_norm,
		clampf(lateral_norm, -1.0, 1.0), hay_auto_cerca
	]

	var grilla = _construir_grilla_peligro()
	var px = round(_player.posicion_logica.x / _player.tamaño_casilla)
	var py = round(_player.posicion_logica.y / _player.tamaño_casilla) + ajuste_filas

	for y_offset in range(-3, 2):
		for x_offset in range(-3, 4):
			var coordenada_revisar = Vector2(px + x_offset, py + y_offset)
			obs_array.append(_valor_celda(grilla, coordenada_revisar))

	return {"obs": obs_array}

func get_obs_space() -> Dictionary:
	return {"obs": {"size": [39], "space": "box"}}

# ---------------------------------------------------------
# FUNCIÓN COMPARTIDA: construye la grilla de peligro.
# La usan tanto get_obs() como _process() (debug visual), así
# ambas SIEMPRE ven exactamente la misma información: lo que
# la IA "piensa" es lo mismo que tú ves dibujado en pantalla.
# ---------------------------------------------------------
func _construir_grilla_peligro() -> Dictionary:
	var grilla = {}
	var tamaño = _player.tamaño_casilla

	# Árboles: un solo punto de bloqueo
	for arbol in get_tree().get_nodes_in_group("arboles"):
		var cx = round(arbol.global_position.x / tamaño)
		var cy = round(arbol.global_position.y / tamaño)
		grilla[Vector2(cx, cy)] = 1.0

	# Autos: ocupan varias celdas de ancho, no solo una.
	# Requiere que el script del auto exponga "ancho_en_casillas"
	# (mismo patrón que "alto_en_casillas" en las franjas). Si no
	# existe, se asume un ancho de 1 casilla por defecto.
	for auto in get_tree().get_nodes_in_group("vehiculos"):
		var cy = round(auto.global_position.y / tamaño) + ajuste_filas_vehiculos
		var cx_centro = round(auto.global_position.x / tamaño)

		var celdas_ancho = 1
		if "ancho_en_casillas" in auto:
			celdas_ancho = max(1, int(auto.ancho_en_casillas))

		var inicio_ocupado = -int(floor(celdas_ancho / 2.0))
		var fin_ocupado = inicio_ocupado + celdas_ancho - 1

		# ANTICIPACIÓN: cuántas casillas avanzará el auto en el horizonte.
		# Marcamos como OCUPADO todo el corredor entre su posición actual y su
		# posición futura, para que el agente no salte "delante" de un auto que
		# llegará en el próximo salto. Sin esto, la grilla solo veía el presente
		# y el agente se metía bajo autos que "aún no estaban ahí".
		var velocidad = 250.0
		if "velocidad" in auto:
			velocidad = float(auto.velocidad)
		var celdas_barrido = int(ceil(velocidad * horizonte_anticipacion / tamaño))

		# Cuerpo actual + barrido futuro = celdas realmente peligrosas (-1.0).
		var barrido_inicio = inicio_ocupado
		var barrido_fin = fin_ocupado
		if auto.direccion > 0:
			barrido_fin += celdas_barrido
		else:
			barrido_inicio -= celdas_barrido
		for i in range(barrido_inicio, barrido_fin + 1):
			grilla[Vector2(cx_centro + i, cy)] = -1.0

		# Advertencias decrecientes justo más allá del corredor de barrido, en la
		# dirección de avance: dan margen de reacción sin bloquear el cruce.
		var frente = barrido_fin + 1 if auto.direccion > 0 else barrido_inicio - 1
		_marcar_min(grilla, Vector2(cx_centro + frente, cy), -0.6)
		_marcar_min(grilla, Vector2(cx_centro + frente + auto.direccion, cy), -0.4)

	return grilla

# Escribe el valor solo si es MÁS peligroso (más negativo) que lo ya presente,
# para que una advertencia leve nunca pise una celda ya marcada como ocupada.
func _marcar_min(grilla: Dictionary, coordenada: Vector2, valor: float) -> void:
	if not grilla.has(coordenada) or valor < grilla[coordenada]:
		grilla[coordenada] = valor

# ¿Hay algún vehículo dentro del radio de alerta del jugador?
func _autos_en_alerta() -> bool:
	var distancia_alerta = _player.tamaño_casilla * 3.5
	for auto in get_tree().get_nodes_in_group("vehiculos"):
		if _player.global_position.distance_to(auto.global_position) <= distancia_alerta:
			return true
	return false

func _valor_celda(grilla: Dictionary, coordenada: Vector2) -> float:
	if coordenada.x < -limite_columna or coordenada.x > limite_columna:
		return 1.0
	return float(grilla.get(coordenada, 0.0))

# ---------------------------------------------------------
# 2. ESPACIO DE ACCIÓN
# ---------------------------------------------------------
func get_action_space() -> Dictionary:
	return {"movimiento": {"size": 5, "action_type": "discrete"}}

# ---------------------------------------------------------
# 3. EJECUCIÓN MATEMÁTICA
# ---------------------------------------------------------
# El parámetro es opcional para soportar los dos modos del plugin:
#  - Entrenamiento / inferencia (ONNX): llega el Dictionary con la acción de la red.
#  - Grabación de demos (RECORD_EXPERT_DEMOS): el plugin llama set_action() SIN
#    argumento y esperamos que TÚ muevas al jugador con el teclado; esa acción
#    humana se captura aquí y get_action() la devuelve para guardarla en la demo.
func set_action(action = null) -> void:
	if done or not _player.modo_entrenamiento or _player.se_esta_moviendo or _player.esta_muerto or _player.ha_ganado:
		return

	var accion: int
	if action == null:
		accion = _leer_accion_humana()
		_accion_humana = accion
	else:
		accion = int(action["movimiento"])

	penalizacion_intencion = 0.0

	var px = round(_player.posicion_logica.x / _player.tamaño_casilla)
	var py = round(_player.posicion_logica.y / _player.tamaño_casilla)
	var destino = Vector2.ZERO
	var hay_movimiento = accion >= 1 and accion <= 4

	match accion:
		1: destino = Vector2(px, py - 1)
		2: destino = Vector2(px, py + 1)
		3: destino = Vector2(px - 1, py)
		4: destino = Vector2(px + 1, py)

	# Penalización de INTENCIÓN: castiga la decisión ANTES de que ocurra la
	# muerte (señal densa), no solo el -50 de morir (señal escasa y tardía).
	# BUG corregido: antes solo se penalizaban celdas > 0.0 (árboles/borde),
	# así que meterse DIRECTO a un auto (valor negativo) no costaba nada.
	if hay_movimiento:
		var valor_destino = _valor_celda(_construir_grilla_peligro(), destino)
		if valor_destino <= -0.9:
			penalizacion_intencion = -1.0   # saltar hacia un auto (ocupado/proyectado)
		elif valor_destino > 0.0:
			penalizacion_intencion = -0.5   # árbol o borde: movimiento inútil

	_player.accion_ia = accion
	if _player.accion_ia != 0:
		_player.ejecutar_movimiento(_player.accion_ia)

# ---------------------------------------------------------
# 3b. GRABACIÓN DE DEMOS DE EXPERTO
# ---------------------------------------------------------
# El plugin guarda como acción de la demo lo que devuelva get_action().
# Formato plano que espera para una acción discreta de tamaño 5: [indice].
func get_action() -> Array:
	return [_accion_humana]

# Traduce las teclas de movimiento al mismo índice de acción de la red
# (0 = quieto, 1 = arriba, 2 = abajo, 3 = izquierda, 4 = derecha).
# Reutiliza las acciones del InputMap ya definidas para el juego manual.
func _leer_accion_humana() -> int:
	if Input.is_action_just_pressed("mover_arriba"):
		return 1
	elif Input.is_action_just_pressed("mover_abajo"):
		return 2
	elif Input.is_action_just_pressed("mover_izquierda"):
		return 3
	elif Input.is_action_just_pressed("mover_derecha"):
		return 4
	return 0

# En GRABACIÓN de demos el plugin cierra el episodio llamando solo a
# set_done_false() (nunca a reset()). Aquí reiniciamos el entorno para que
# empiece limpio el siguiente episodio. get_done() (con su latch) garantiza que
# esto se llame UNA sola vez por muerte, así que no hay reinicios repetidos.
# Solo en modo demo: en entrenamiento/inferencia el reinicio ya lo hace reset().
func set_done_false() -> void:
	done = false
	# El plugin llama esto justo tras un get_done() terminal (una vez por
	# episodio, gracias al latch). Reiniciamos el entorno para el siguiente.
	if control_mode == ControlModes.RECORD_EXPERT_DEMOS:
		if is_instance_valid(_player) and _player.has_method("reiniciar_entorno"):
			_player.reiniciar_entorno()

# ---------------------------------------------------------
# 4. RECOMPENSAS
# ---------------------------------------------------------
func get_reward() -> float:
	var recompensa: float = 0.0
	recompensa += (penalizacion_intencion * 2.0)
	penalizacion_intencion = 0.0

	if _player.esta_muerto:
		recompensa -= 50.0
	elif _player.ha_ganado:
		recompensa += 300.0
	else:
		# Costo de tiempo pequeño: empuja a avanzar sin castigar la PACIENCIA.
		# (Antes había además un -0.2 por "auto cerca" que penalizaba justo la
		#  conducta necesaria: esperar el hueco junto a la calle para cruzar.
		#  Con eso el agente aprendía a NO acercarse a las calles y se estancaba.)
		recompensa -= 0.05

		# Recompensa densa de progreso: solo al pisar una fila NUEVA (récord).
		# Es la señal principal que guía a la red hacia la meta.
		if _player.maximas_casillas_avanzadas > _player.casillas_historico_ia:
			var filas_nuevas = _player.maximas_casillas_avanzadas - _player.casillas_historico_ia
			recompensa += 5.0 * filas_nuevas
			_player.casillas_historico_ia = _player.maximas_casillas_avanzadas

	return recompensa

func get_done() -> bool:
	var terminal: bool = _player.esta_muerto or _player.ha_ganado

	# En GRABACIÓN de demos: reportar el terminal SOLO en el flanco (una vez).
	# El plugin guarda un episodio cada vez que get_done() es true; si el jugador
	# sigue muerto varios frames y devolviéramos true en todos, guardaría cientos
	# de episodios fantasma (el bug del contador). Latch: true una sola vez, y no
	# volvemos a reportar hasta que el jugador reviva.
	if control_mode == ControlModes.RECORD_EXPERT_DEMOS:
		if not terminal:
			_demo_terminal_reportado = false
			done = false
			return false
		if _demo_terminal_reportado:
			return false
		_demo_terminal_reportado = true
		done = true
		return true

	# Entrenamiento / inferencia: comportamiento normal por nivel.
	if terminal:
		done = true
		return true
	return done

func reset() -> void:
	penalizacion_intencion = 0.0
	_demo_terminal_reportado = false
	if is_instance_valid(_player) and _player.has_method("reiniciar_entorno"):
		_player.reiniciar_entorno()
	super.reset()

# La clase base incrementa n_steps cada frame y, al superar reset_after, deja
# done = true para truncar el episodio (útil SOLO en entrenamiento). En GRABACIÓN
# de demos el plugin nunca llama reset(), así que n_steps nunca se reiniciaría:
# al pasar reset_after, done quedaría pegado en true, set_action() abortaría
# siempre y el personaje se CONGELARÍA sin poder moverse ni reiniciar. Por eso en
# modo demo saltamos esa truncación. En entrenamiento/inferencia se mantiene igual.
func _physics_process(delta: float) -> void:
	if control_mode == ControlModes.RECORD_EXPERT_DEMOS:
		return
	super._physics_process(delta)

# ---------------------------------------------------------
# 5. DIBUJO DE DEBUG
# ---------------------------------------------------------
func _draw() -> void:
	if not _debug_visible():
		return

	var tamaño = _player.tamaño_casilla
	var escala_global := global_transform.get_scale().abs()
	if is_zero_approx(escala_global.x) or is_zero_approx(escala_global.y):
		return
	var tamaño_local := Vector2(tamaño / escala_global.x, tamaño / escala_global.y)

	for celda in celdas_debug:
		var pos_local = to_local(celda["pos"])
		var rect = Rect2(pos_local - (tamaño_local / 2.0), tamaño_local)

		var color = Color(0, 0, 0, 0)
		if celda["valor"] == 0.0:
			color = Color(0, 1, 0, 0.15)
		elif celda["valor"] > 0.0:
			color = Color(0, 0, 1, 0.3)
		elif celda["valor"] < 0.0:
			color = Color(1, 0, 0, abs(celda["valor"]) * 0.7)

		draw_rect(rect, color, true)
		draw_rect(rect, Color(1, 1, 1, 0.2), false)
