extends Node

var genero_jugador: String = ""

signal dinero_cambiado(nuevo_monto: int)
signal dia_cambiado(nuevo_dia: int)
signal reputacion_cambiado(nuevo_reputacion:int)
signal n_cliente_cambiado(nuevo_n_cliente:int)
signal n_cliente_dia_cambiado(nuevo_n_cliente_dia:int)
signal ingresos_dia_cambiado(nuevo_ingreso:int)
signal gastos_dia_cambiado(nuevo_gasto:int)

var dia_actual: int = 0:
	set(value):
		dia_actual = value
		dia_cambiado.emit(dia_actual)

var dinero: int = 99999:
	set(value):
		dinero = value
		dinero_cambiado.emit(dinero)

var ingresos_dia:int = 6:
	set(value):
		ingresos_dia = value
		ingresos_dia_cambiado.emit(ingresos_dia)

var gastos_dia:int = 100:
	set(value):
		gastos_dia = value
		gastos_dia_cambiado.emit(gastos_dia)

var reputacion: int = 100:
	set(value):
		reputacion = value
		reputacion_cambiado.emit(reputacion)

# El numero total de clientes atendidos
var n_cliente:int = 0:
	set(value):
		n_cliente = value
		n_cliente_cambiado.emit(n_cliente)

var n_cliente_dia:int = 0:
	set(value):
		n_cliente_dia = value
		n_cliente_dia_cambiado.emit(n_cliente_dia)

var historial_dias = []


func sumar_dinero(cantidad: int):
	dinero += cantidad
	ingresos_dia += cantidad

func restar_dinero(cantidad: int):
	dinero -= cantidad
	gastos_dia += cantidad

func sumar_reputacion(cantidad:int):
	reputacion = mini(100,reputacion + cantidad)

func restar_reputacion(cantidad:int):
	reputacion = maxi(0,reputacion - cantidad)

#reinicia los gastos diarios
func reiniciar_estadisticas_dia():
	print("Reiniciando estadisticas diarias")
	ingresos_dia = 0
	gastos_dia = 0
	n_cliente_dia = 0

func guardar_dia():
	print("Guardando datos diarios")

	var datos = {
		"dia": dia_actual,
		"ingresos": ingresos_dia,
		"gastos": gastos_dia,
		"clientes": n_cliente_dia,
		"reputacion": reputacion,
		"dinero": dinero
	}

	historial_dias.append(datos)

	print("Guardado:")
	print(datos)
	print("Total días:", historial_dias.size())
