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
			"reputacion": 50,
			"eventos": []
		}
	elif not estadisticas_dias[dia].has("eventos"):
		estadisticas_dias[dia]["eventos"] = []

	return estadisticas_dias[dia]

func registrar_diagnostico_dia(correcto: bool, dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var stats := asegurar_estadistica_dia(dia)

	if correcto:
		stats["diagnosticos_correctos"] += 1
	else:
		stats["diagnosticos_incorrectos"] += 1

	stats["reputacion"] = _calcular_reputacion(stats)
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

	stats["dinero_final"] = dinero
	stats["reputacion"] = _calcular_reputacion(stats)
	estadisticas_dias[dia] = stats

func registrar_cierre_dia(dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var stats := asegurar_estadistica_dia(dia)
	stats["dinero_final"] = dinero
	stats["reputacion"] = _calcular_reputacion(stats)
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

	var reputacion := 50 + total_correctos * 6 - total_incorrectos * 5 + int(float(total_balance) / 100.0)
	reputacion = clampi(reputacion, 0, 100)

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

func _calcular_reputacion(stats: Dictionary) -> int:
	var reputacion := 50
	reputacion += int(stats.get("diagnosticos_correctos", 0)) * 8
	reputacion -= int(stats.get("diagnosticos_incorrectos", 0)) * 7
	reputacion += int(stats.get("clientes_atendidos", 0)) * 2
	reputacion += int(float(int(stats.get("balance", 0))) / 100.0)
	return clampi(reputacion, 0, 100)

func formatear_monto(monto: int) -> String:
	if monto >= 0:
		return "+$%d" % monto

	return "-$%d" % absi(monto)

## Reinicia todo el estado de la partida a los valores iniciales (Nueva Partida).
func reiniciar() -> void:
	dia_actual = 1
	dinero = 500
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

var reputacion: int = 75:
	set(value):
		reputacion = value
		reputacion_cambiado.emit(reputacion)


func sumar_reputacion(cantidad:int):
	reputacion = mini(100,reputacion + cantidad)

func restar_reputacion(cantidad:int):
	reputacion = maxi(0,reputacion - cantidad)

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
