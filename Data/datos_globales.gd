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

## Rendimiento (0.0 = peor resultado posible, 1.0 = mejor resultado posible) que cada
## minijuego reporta antes de volver a GameScreen, vía reportar_rendimiento_minijuego().
## -1.0 = "no reportado" (fallback neutro): sirve de defensa si algún minijuego no llega
## a reportar (p. ej. una ruta de salida no contemplada).
var rendimiento_minijuego_pendiente: float = -1.0

## Desglose de la atención en curso, para mostrarlo en la pantalla de resultado del
## minijuego (costo de la pieza, penalización de diagnóstico, recompensa del minijuego,
## y los cambios de reputación). Se rellena a medida que avanza la atención; se lee con
## get_resumen_atencion().
var resumen_atencion: Dictionary = {}

var estadisticas_dias: Dictionary = {}

# ============================================================
# REPUTACION (única fuente de verdad)
# ------------------------------------------------------------
# La reputación es un único valor global (0-100) que persiste entre días y
# alimenta las estrellas del HUD. Atender clientes, diagnosticar y los eventos
# la modifican directamente; las estadísticas por día solo guardan una FOTO
# de este valor para mostrarla en el resumen.
# ============================================================
const REPUTACION_INICIAL: int = 75
const REP_DIAGNOSTICO_CORRECTO: int = 8
const REP_DIAGNOSTICO_INCORRECTO: int = 7
const REP_CLIENTE_ATENDIDO: int = 2

## Rango de ajuste de reputación según el rendimiento (0.0-1.0) reportado por el
## minijuego de reparación: de -REP_MINIJUEGO_RANGO (rendimiento 0.0) a +REP_MINIJUEGO_RANGO
## (rendimiento 1.0), interpolado linealmente y redondeado (sin truncar a 0 como antes).
const REP_MINIJUEGO_RANGO: int = 6

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

	var rep_diag: int
	if correcto:
		stats["diagnosticos_correctos"] += 1
		rep_diag = REP_DIAGNOSTICO_CORRECTO
	else:
		stats["diagnosticos_incorrectos"] += 1
		rep_diag = -REP_DIAGNOSTICO_INCORRECTO
	ajustar_reputacion(rep_diag)

	# Guardamos el detalle para el resumen de la atención (pantalla de resultado del minijuego).
	resumen_atencion["diagnostico_correcto"] = correcto
	resumen_atencion["rep_diagnostico"] = rep_diag

	stats["reputacion"] = reputacion
	estadisticas_dias[dia] = stats

func registrar_evento_dia(texto: String, dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var stats: Dictionary = asegurar_estadistica_dia(dia)
	var eventos: Array = stats.get("eventos", [])
	eventos.append(texto)

	stats["eventos"] = eventos
	stats["dinero_final"] = dinero
	estadisticas_dias[dia] = stats

## Reinicia el desglose de la atención (lo llama GameScreen al iniciar una atención,
## antes de mandar al cliente al diagnóstico + minijuego).
func iniciar_resumen_atencion() -> void:
	resumen_atencion = {
		"diagnostico_correcto": true,
		"rep_diagnostico": 0,
		"penalizacion_diagnostico": 0,
		"costo_pieza": 0,
		"tipo_pieza": "",
		"recompensa_minijuego": 0,
		"rendimiento": 0.5,
	}

## Reputación que otorga el desempeño en el minijuego (base por atender + ajuste por
## rendimiento). Compartida por registrar_atencion_dia (aplicación real) y por
## get_resumen_atencion (previsualización en la pantalla de resultado), para que
## siempre coincidan.
func calcular_rep_desempeno(rendimiento: float) -> int:
	var r: float = clampf(rendimiento, 0.0, 1.0)
	return REP_CLIENTE_ATENDIDO + roundi(lerpf(-REP_MINIJUEGO_RANGO, REP_MINIJUEGO_RANGO, r))

## Los minijuegos llaman a esto (justo antes de volver a GameScreen) para reportar
## qué tan bien les fue (0.0 = peor, 1.0 = mejor) y cuánto dinero dio la reparación.
func reportar_rendimiento_minijuego(rendimiento: float, recompensa: int = 0) -> void:
	rendimiento_minijuego_pendiente = clampf(rendimiento, 0.0, 1.0)
	resumen_atencion["rendimiento"] = rendimiento_minijuego_pendiente
	resumen_atencion["recompensa_minijuego"] = recompensa

## Devuelve el desglose completo de la atención para mostrarlo en la pantalla de
## resultado del minijuego: cuánto dinero varió (recompensa, costos, balance neto) y
## cuánta reputación (diagnóstico + desempeño + total).
func get_resumen_atencion() -> Dictionary:
	var r: Dictionary = resumen_atencion.duplicate()
	var recompensa: int = int(r.get("recompensa_minijuego", 0))
	var costo_pieza: int = int(r.get("costo_pieza", 0))
	var penal_diag: int = int(r.get("penalizacion_diagnostico", 0))
	var rep_diag: int = int(r.get("rep_diagnostico", 0))
	var rendimiento: float = float(r.get("rendimiento", 0.5))
	var rep_desempeno: int = calcular_rep_desempeno(rendimiento)

	r["balance_dinero"] = recompensa - costo_pieza - penal_diag
	r["rep_desempeno"] = rep_desempeno
	r["rep_total"] = rep_diag + rep_desempeno
	return r

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

	# Atender suma reputación base, más un ajuste según qué tan bien te fue en el
	# minijuego de reparación (no según el dinero: eso truncaba a 0 cualquier
	# variación menor a $100 y dejaba el mal rendimiento sin castigo real).
	var rendimiento: float = rendimiento_minijuego_pendiente if rendimiento_minijuego_pendiente >= 0.0 else 0.5
	ajustar_reputacion(calcular_rep_desempeno(rendimiento))
	rendimiento_minijuego_pendiente = -1.0

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

	for dia in get_dias_con_estadisticas():
		var stats: Dictionary = estadisticas_dias[dia]
		total_clientes += int(stats.get("clientes_atendidos", 0))
		total_correctos += int(stats.get("diagnosticos_correctos", 0))
		total_incorrectos += int(stats.get("diagnosticos_incorrectos", 0))
		total_ingresos += int(stats.get("ingresos", 0))
		total_gastos += int(stats.get("gastos", 0))
		total_balance += int(stats.get("balance", 0))

	return {
		"clientes_atendidos": total_clientes,
		"diagnosticos_correctos": total_correctos,
		"diagnosticos_incorrectos": total_incorrectos,
		"ingresos": total_ingresos,
		"gastos": total_gastos,
		"balance": total_balance,
		"dinero_actual": dinero,
		"reputacion": reputacion
	}

func formatear_monto(monto: int) -> String:
	if monto >= 0:
		return "+$%d" % monto

	return "-$%d" % absi(monto)

## Reinicia todo el estado de la partida a los valores iniciales (Nueva Partida).
func reiniciar() -> void:
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
	rendimiento_minijuego_pendiente = -1.0
	resumen_atencion.clear()
	estadisticas_dias.clear()

# Datos asociados a la reputacion
signal reputacion_cambiado(nuevo_reputacion:int)

var reputacion: int = REPUTACION_INICIAL:
	set(value):
		reputacion = clampi(value, 0, 100)
		reputacion_cambiado.emit(reputacion)


func sumar_reputacion(cantidad:int):
	reputacion = mini(100,reputacion + cantidad)

func restar_reputacion(cantidad:int):
	reputacion = maxi(0,reputacion - cantidad)

## Ajusta la reputación con una cantidad con signo (+ sube, - baja). El setter
## se encarga de mantenerla dentro de 0-100.
func ajustar_reputacion(cantidad:int):
	reputacion += cantidad

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
