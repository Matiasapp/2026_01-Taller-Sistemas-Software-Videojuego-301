extends "res://addons/godot_rl_agents/controller/ai_controller_2d.gd"

@export var mostrar_vision_debug: bool = true

# Corrige el desfase entre la grilla lógica y las posiciones reales.
# Negativo = mueve la grilla hacia ADELANTE (arriba, ya que subir es Y negativa).
# Ajusta este valor desde el Inspector en tiempo real hasta que la cuadrícula
# calce exactamente con los autos/árboles en pantalla.
@export var ajuste_filas: int = 0

# Ajuste SOLO para vehículos: su pivote/anchor no está alineado igual que
# el resto de los objetos, así que su fila necesita una corrección aparte.
# Positivo = mueve los autos una fila hacia ABAJO (Y aumenta hacia abajo).
@export var ajuste_filas_vehiculos: int = 1
@export var limite_columna: int = 8

var celdas_debug: Array = []
var penalizacion_intencion: float = 0.0

# ---------------------------------------------------------
# 0. SINCRONIZACIÓN VISUAL POR FRAME
# ---------------------------------------------------------
# El plugin llama a get_obs() solo en cada paso de decisión de la IA,
# pero los autos se mueven en cada frame. Por eso el debug visual se
# recalcula aquí, en _process(), para que nunca quede desfasado
# respecto a las posiciones reales de los objetos en pantalla.
func _process(_delta: float) -> void:
	if not mostrar_vision_debug or not _player:
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

# ---------------------------------------------------------
# 1. OBSERVACIONES (EL MINIMAPA VIRTUAL)
# ---------------------------------------------------------
func get_obs() -> Dictionary:
	var progreso_meta = float(_player.maximas_casillas_avanzadas) / float(_player.meta_casillas)
	var tiempo_norm = _player.tiempo_restante / _player.tiempo_limite

	var obs_array = [
		progreso_meta, tiempo_norm,
		_player.position.x / 1000.0, _player.position.y / 1000.0
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

		var mitad = int(celdas_ancho / 2)
		for i in range(-mitad, celdas_ancho - mitad):
			grilla[Vector2(cx_centro + i, cy)] = -1.0

		# Celdas de advertencia hacia donde avanza el auto
		grilla[Vector2(cx_centro + celdas_ancho * auto.direccion, cy)] = -0.8
		grilla[Vector2(cx_centro + celdas_ancho * auto.direccion * 2, cy)] = -0.5

	return grilla

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
func set_action(action: Dictionary) -> void:
	if done or not _player.modo_entrenamiento or _player.se_esta_moviendo or _player.esta_muerto or _player.ha_ganado:
		return

	var accion = int(action["movimiento"])
	penalizacion_intencion = 0.0

	var px = round(_player.posicion_logica.x / _player.tamaño_casilla)
	var py = round(_player.posicion_logica.y / _player.tamaño_casilla)
	var destino = Vector2.ZERO

	match accion:
		1: destino = Vector2(px, py - 1)
		2: destino = Vector2(px, py + 1)
		3: destino = Vector2(px - 1, py)
		4: destino = Vector2(px + 1, py)

	if destino != Vector2.ZERO and _valor_celda(_construir_grilla_peligro(), destino) > 0.0:
		penalizacion_intencion = -1.0

	_player.accion_ia = accion
	if _player.accion_ia != 0:
		_player.ejecutar_movimiento(_player.accion_ia)

# ---------------------------------------------------------
# 4. RECOMPENSAS
# ---------------------------------------------------------
func get_reward() -> float:
	var recompensa: float = 0.0
	recompensa += (penalizacion_intencion * 2.0)
	penalizacion_intencion = 0.0

	var hay_auto_cerca = false
	var distancia_alerta = _player.tamaño_casilla * 3.5

	for auto in get_tree().get_nodes_in_group("vehiculos"):
		if _player.global_position.distance_to(auto.global_position) <= distancia_alerta:
			hay_auto_cerca = true
			break

	if _player.esta_muerto:
		recompensa -= 50.0
	elif _player.ha_ganado:
		recompensa += 300.0
	else:
		recompensa -= 0.1
		if hay_auto_cerca:
			recompensa -= 0.2
		if _player.maximas_casillas_avanzadas > _player.casillas_historico_ia:
			recompensa += 5.0
			_player.casillas_historico_ia = _player.maximas_casillas_avanzadas

	return recompensa

func get_done() -> bool:
	return done or _player.esta_muerto or _player.ha_ganado

func reset() -> void:
	penalizacion_intencion = 0.0
	super.reset()

# ---------------------------------------------------------
# 5. DIBUJO DE DEBUG
# ---------------------------------------------------------
func _draw() -> void:
	if not mostrar_vision_debug:
		return

	var tamaño = _player.tamaño_casilla

	for celda in celdas_debug:
		var pos_local = to_local(celda["pos"])
		var offset_visual = Vector2(tamaño / 2.0, tamaño / 2.0)
		var rect = Rect2(pos_local - offset_visual, Vector2(tamaño, tamaño))

		var color = Color(0, 0, 0, 0)
		if celda["valor"] == 0.0:
			color = Color(0, 1, 0, 0.15)
		elif celda["valor"] > 0.0:
			color = Color(0, 0, 1, 0.3)
		elif celda["valor"] < 0.0:
			color = Color(1, 0, 0, abs(celda["valor"]) * 0.7)

		draw_rect(rect, color, true)
		draw_rect(rect, Color(1, 1, 1, 0.2), false)
