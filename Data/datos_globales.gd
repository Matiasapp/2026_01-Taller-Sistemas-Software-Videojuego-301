extends Node

var genero_jugador: String = ""
var siguiente_evento_dia: String = ""
var mostrar_resumen_dia_al_volver: bool = false

## true una vez que se mostró el modal de bienvenida (día 1, 08:00) en la partida actual.
## Se reinicia a false al empezar una Nueva Partida, para que aparezca una vez por partida.
var modal_bienvenida_mostrado: bool = false

## Índices de los clientes (filas del atlas) que ya aparecieron en la partida.
## Persiste entre escenas para que un mismo cliente no se repita durante todo el juego.
var clientes_usados: Array[int] = []

## Estado de estafa pendiente: el cliente actual es estafador y, al volver del minijuego,
## se revela que pagó con billetes falsos. Persiste a través del cambio de escena al minijuego.
var estafa_pendiente: bool = false
var dinero_antes_estafa: int = 0   # Dinero justo antes del minijuego (para revertir el pago falso)
var nombre_estafador: String = ""

## Para mostrar en el HUD cuánto cambió el dinero tras atender a un cliente (reparación).
var dinero_antes_atencion: int = 0
var volviendo_de_atencion: bool = false

var estadisticas_dias: Dictionary = {}

const FINAL_REPUTACION_SCENE := "res://Scenes/Events/FinalMalo/FinalMalo1.tscn"

## El final no interrumpe la pantalla donde se perdio el ultimo punto. Se marca
## como pendiente y se lanza apenas esa escena entrega el control a la siguiente.
var final_reputacion_pendiente := false
var _escena_origen_final_id := 0
var _cambiando_a_final_reputacion := false

## Evitan aplicar dos veces la reputacion si un boton de resultado recibe mas
## de un clic antes de que termine el cambio de escena.
var _pieza_reputacion_registrada := false
var _minijuego_reputacion_registrado := false

func _ready() -> void:
	# El vigilante del final debe seguir activo incluso si una pantalla de
	# resultados deja el arbol pausado durante su transicion.
	process_mode = Node.PROCESS_MODE_ALWAYS

# ============================================================
# REPUTACION (única fuente de verdad)
# ------------------------------------------------------------
# La reputación es un único valor global (0-100) que persiste entre días y
# alimenta las estrellas del HUD. Atender clientes, diagnosticar y los eventos
# la modifican directamente; las estadísticas por día solo guardan una FOTO
# de este valor para mostrarla en el resumen.
# ============================================================
const REPUTACION_INICIAL: int = 75
const REP_DIAGNOSTICO_CORRECTO: int = 2
const REP_DIAGNOSTICO_INCORRECTO: int = 10
const REP_PIEZA_BUENA: int = 5
const REP_PIEZA_BARATA: int = 1
const REP_PIEZA_DUDOSA_PENALIZACION: int = 12
const PROBABILIDAD_FALLO_PIEZA_DUDOSA: float = 0.70
const REP_MINIJUEGO_EXITOSO: int = 3
const REP_MINIJUEGO_FALLIDO: int = 8

signal dinero_cambiado(nuevo_monto: int)
signal dia_cambiado(nuevo_dia: int)

var dia_actual: int = 1:
	set(value):
		dia_actual = value
		dia_cambiado.emit(dia_actual)

var dinero: int = 500:
	set(value):
		dinero = value
		dinero_cambiado.emit(dinero)

func sumar_dinero(cantidad: int):
	dinero += cantidad
	ingresos_dia += cantidad

func restar_dinero(cantidad: int):
	dinero -= cantidad
	gastos_dia -= cantidad

func asegurar_estadistica_dia(dia: int) -> Dictionary:
	if not estadisticas_dias.has(dia):
		estadisticas_dias[dia] = {
			"dia": dia,
			"clientes_atendidos": 0,
			"diagnosticos_correctos": 0,
			"diagnosticos_incorrectos": 0,
			"ingresos": 0,
			"gastos": 0,
			"balance": 0,
			"dinero_inicio": dinero,
			"dinero_final": dinero,
			"reputacion": reputacion,
			"eventos": []
		}
	elif not estadisticas_dias[dia].has("eventos"):
		estadisticas_dias[dia]["eventos"] = []

	return estadisticas_dias[dia]

func registrar_diagnostico_dia(correcto: bool, dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var stats := asegurar_estadistica_dia(dia)
	# Un diagnostico abre un nuevo ciclo reparacion -> pieza -> minijuego.
	_pieza_reputacion_registrada = false
	_minijuego_reputacion_registrado = false

	if correcto:
		stats["diagnosticos_correctos"] += 1
		ajustar_reputacion(REP_DIAGNOSTICO_CORRECTO)
		_agregar_evento_stats(
			stats,
			"Diagnostico correcto: reputacion +%d." % REP_DIAGNOSTICO_CORRECTO
		)
	else:
		stats["diagnosticos_incorrectos"] += 1
		ajustar_reputacion(-REP_DIAGNOSTICO_INCORRECTO)
		_agregar_evento_stats(
			stats,
			"Diagnostico incorrecto: reputacion -%d." % REP_DIAGNOSTICO_INCORRECTO
		)

	stats["reputacion"] = reputacion
	estadisticas_dias[dia] = stats

## Registra el efecto de calidad de la pieza elegida. La dudosa no falla siempre,
## pero su riesgo es suficientemente alto para que no sea la opcion dominante.
func registrar_calidad_pieza(tipo: String, dia: int = -1) -> int:
	if _pieza_reputacion_registrada:
		return 0
	_pieza_reputacion_registrada = true

	if dia < 0:
		dia = dia_actual

	var delta := 0
	var mensaje := ""
	match tipo:
		"buena":
			delta = REP_PIEZA_BUENA
			mensaje = "Pieza buena instalada: reputacion +%d." % delta
		"barata":
			delta = REP_PIEZA_BARATA
			mensaje = "Pieza barata instalada: reputacion +%d." % delta
		"dudosa":
			if randf() < PROBABILIDAD_FALLO_PIEZA_DUDOSA:
				delta = -REP_PIEZA_DUDOSA_PENALIZACION
				mensaje = "La pieza dudosa fallo: reputacion -%d." % absi(delta)
			else:
				mensaje = "La pieza dudosa no genero reclamos esta vez: reputacion sin cambios."
		_:
			push_warning("Tipo de pieza desconocido para reputacion: %s" % tipo)
			return 0

	if delta != 0:
		ajustar_reputacion(delta)

	var stats := asegurar_estadistica_dia(dia)
	var piezas: Dictionary = stats.get("piezas_usadas", {})
	piezas[tipo] = int(piezas.get(tipo, 0)) + 1
	stats["piezas_usadas"] = piezas
	stats["reputacion"] = reputacion
	_agregar_evento_stats(stats, mensaje)
	estadisticas_dias[dia] = stats
	return delta

## Unifica el balance de los cinco minijuegos y garantiza que el resultado de
## una reparacion solo afecte la reputacion una vez.
func registrar_desempeno_minijuego(
	exitoso: bool,
	nombre_minijuego: String,
	detalle: String = "",
	dia: int = -1
) -> int:
	if _minijuego_reputacion_registrado:
		return 0
	_minijuego_reputacion_registrado = true

	if dia < 0:
		dia = dia_actual

	var delta := REP_MINIJUEGO_EXITOSO if exitoso else -REP_MINIJUEGO_FALLIDO
	ajustar_reputacion(delta)

	var stats := asegurar_estadistica_dia(dia)
	var clave := "minijuegos_exitosos" if exitoso else "minijuegos_fallidos"
	stats[clave] = int(stats.get(clave, 0)) + 1
	stats["reputacion"] = reputacion

	var estado := "buen desempeno" if exitoso else "mal desempeno"
	var texto := "%s: %s; reputacion %s%d." % [
		nombre_minijuego,
		estado,
		"+" if delta > 0 else "",
		delta,
	]
	if not detalle.is_empty():
		texto += " " + detalle
	_agregar_evento_stats(stats, texto)
	estadisticas_dias[dia] = stats
	return delta

func _agregar_evento_stats(stats: Dictionary, texto: String) -> void:
	var eventos: Array = stats.get("eventos", [])
	eventos.append(texto)
	stats["eventos"] = eventos

func registrar_evento_dia(texto: String, dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var stats: Dictionary = asegurar_estadistica_dia(dia)
	var eventos: Array = stats.get("eventos", [])
	eventos.append(texto)

	stats["eventos"] = eventos
	stats["dinero_final"] = dinero
	estadisticas_dias[dia] = stats

func registrar_atencion_dia(delta_dinero: int, dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var stats := asegurar_estadistica_dia(dia)

	stats["clientes_atendidos"] += 1
	stats["balance"] += delta_dinero

	if delta_dinero >= 0:
		stats["ingresos"] += delta_dinero
	else:
		stats["gastos"] += abs(delta_dinero)

	# La reputacion ya se resolvio por diagnostico, pieza y minijuego.
	stats["dinero_final"] = dinero
	stats["reputacion"] = reputacion
	estadisticas_dias[dia] = stats

func registrar_cierre_dia(dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var stats := asegurar_estadistica_dia(dia)
	stats["dinero_final"] = dinero
	stats["reputacion"] = reputacion
	estadisticas_dias[dia] = stats

## Aplica una sola vez las decisiones de la libreta de gastos del cierre.
## Devuelve false si ese día ya había sido procesado, evitando cobros duplicados.
func registrar_gastos_diarios(
	dia: int,
	pagados: Array[String],
	postergados: Array[String],
	total_pagado: int,
	penalizacion_reputacion: int
) -> bool:
	var stats := asegurar_estadistica_dia(dia)
	if bool(stats.get("gastos_diarios_procesados", false)):
		return false

	dinero -= total_pagado
	if penalizacion_reputacion > 0:
		ajustar_reputacion(-penalizacion_reputacion)

	stats["gastos_diarios_procesados"] = true
	stats["gastos_diarios_total"] = total_pagado
	stats["gastos_diarios_pagados"] = pagados.duplicate()
	stats["gastos_diarios_postergados"] = postergados.duplicate()
	stats["gastos"] = int(stats.get("gastos", 0)) + total_pagado
	stats["balance"] = int(stats.get("balance", 0)) - total_pagado
	stats["dinero_final"] = dinero
	stats["reputacion"] = reputacion

	var eventos: Array = stats.get("eventos", [])
	if total_pagado > 0:
		eventos.append("Gastos de cierre pagados: -$%d." % total_pagado)
	if not postergados.is_empty():
		eventos.append(
			"Pagos postergados: %s. Reputacion: -%d."
			% [", ".join(PackedStringArray(postergados)), penalizacion_reputacion]
		)
	stats["eventos"] = eventos

	estadisticas_dias[dia] = stats
	return true

func get_estadistica_dia(dia: int) -> Dictionary:
	return asegurar_estadistica_dia(dia)

func get_dias_con_estadisticas() -> Array:
	var dias := estadisticas_dias.keys()
	dias.sort()
	return dias

func get_estadisticas_generales() -> Dictionary:
	var total_clientes := 0
	var total_correctos := 0
	var total_incorrectos := 0
	var total_ingresos := 0
	var total_gastos := 0
	var total_balance := 0
	var total_minijuegos_exitosos := 0
	var total_minijuegos_fallidos := 0

	for dia in get_dias_con_estadisticas():
		var stats: Dictionary = estadisticas_dias[dia]
		total_clientes += int(stats.get("clientes_atendidos", 0))
		total_correctos += int(stats.get("diagnosticos_correctos", 0))
		total_incorrectos += int(stats.get("diagnosticos_incorrectos", 0))
		total_ingresos += int(stats.get("ingresos", 0))
		total_gastos += int(stats.get("gastos", 0))
		total_balance += int(stats.get("balance", 0))
		total_minijuegos_exitosos += int(stats.get("minijuegos_exitosos", 0))
		total_minijuegos_fallidos += int(stats.get("minijuegos_fallidos", 0))

	return {
		"clientes_atendidos": total_clientes,
		"diagnosticos_correctos": total_correctos,
		"diagnosticos_incorrectos": total_incorrectos,
		"ingresos": total_ingresos,
		"gastos": total_gastos,
		"balance": total_balance,
		"minijuegos_exitosos": total_minijuegos_exitosos,
		"minijuegos_fallidos": total_minijuegos_fallidos,
		"dinero_actual": dinero,
		"reputacion": reputacion
	}

func formatear_monto(monto: int) -> String:
	if monto >= 0:
		return "+$%d" % monto

	return "-$%d" % absi(monto)

## Reinicia todo el estado de la partida a los valores iniciales (Nueva Partida).
func reiniciar() -> void:
	final_reputacion_pendiente = false
	_escena_origen_final_id = 0
	_cambiando_a_final_reputacion = false
	_pieza_reputacion_registrada = false
	_minijuego_reputacion_registrado = false
	dia_actual = 1
	dinero = 500
	reputacion = REPUTACION_INICIAL
	genero_jugador = ""
	siguiente_evento_dia = ""
	mostrar_resumen_dia_al_volver = false
	modal_bienvenida_mostrado = false
	clientes_usados.clear()
	estafa_pendiente = false
	dinero_antes_estafa = 0
	nombre_estafador = ""
	dinero_antes_atencion = 0
	volviendo_de_atencion = false
	estadisticas_dias.clear()

# Datos asociados a la reputacion
signal reputacion_cambiado(nuevo_reputacion:int)

var reputacion: int = REPUTACION_INICIAL:
	set(value):
		reputacion = clampi(value, 0, 100)
		reputacion_cambiado.emit(reputacion)
		if reputacion == 0:
			_programar_final_reputacion()


func sumar_reputacion(cantidad:int):
	reputacion = mini(100,reputacion + cantidad)

func restar_reputacion(cantidad:int):
	reputacion = maxi(0,reputacion - cantidad)

## Ajusta la reputación con una cantidad con signo (+ sube, - baja). El setter
## se encarga de mantenerla dentro de 0-100.
func ajustar_reputacion(cantidad:int):
	reputacion += cantidad

func _programar_final_reputacion() -> void:
	if final_reputacion_pendiente or _cambiando_a_final_reputacion:
		return

	final_reputacion_pendiente = true
	if is_inside_tree() and get_tree().current_scene:
		_escena_origen_final_id = get_tree().current_scene.get_instance_id()

func _process(_delta: float) -> void:
	if not final_reputacion_pendiente or _cambiando_a_final_reputacion:
		return

	var escena_actual := get_tree().current_scene
	if escena_actual == null:
		return
	if escena_actual.scene_file_path == FINAL_REPUTACION_SCENE:
		final_reputacion_pendiente = false
		return

	if _escena_origen_final_id == 0:
		_escena_origen_final_id = escena_actual.get_instance_id()
		return

	if escena_actual.get_instance_id() != _escena_origen_final_id:
		_cambiando_a_final_reputacion = true
		call_deferred("_ejecutar_final_reputacion")

func _ejecutar_final_reputacion() -> void:
	final_reputacion_pendiente = false
	_escena_origen_final_id = 0
	get_tree().paused = false
	Engine.time_scale = 1.0
	# Persistimos el estado terminal para que cargar la partida no permita
	# esquivar el final recuperando un autoguardado anterior.
	PARTIDA.guardar()
	get_tree().change_scene_to_file(FINAL_REPUTACION_SCENE)
	_cambiando_a_final_reputacion = false

# Ingreso y Gastos realizados

signal ingresos_dia_cambiado(nuevo_ingreso:int)
signal gastos_dia_cambiado(nuevo_gasto:int)


# Contenedor de datos diarios
var historial_dias = []

# Dinero ingresado por dia
var ingresos_dia:int = 6:
	set(value):
		ingresos_dia = value
		ingresos_dia_cambiado.emit(ingresos_dia)

# Gastos por compra de piezas
var gastos_dia:int = 100:
	set(value):
		gastos_dia = value
		gastos_dia_cambiado.emit(gastos_dia)


#reinicia los gastos diarios
func reiniciar_estadisticas_dia():
	print("Reiniciando estadisticas diarias")
	ingresos_dia = 0
	gastos_dia = 0

# Guardar una copia de los datos diarios en un Diccionario
func guardar_dia():
	print("Guardando datos diarios")

	var datos = {
		"dia": dia_actual,
		"ingresos": ingresos_dia,
		"gastos": gastos_dia,
		"clientes": CLIENTMANAGER.clientes_atendidos,
		"reputacion": reputacion,
		"dinero": dinero
	}

	historial_dias.append(datos)
	reiniciar_estadisticas_dia()

	print("Guardado:")
	print(datos)
	print("Total días:", historial_dias.size())
