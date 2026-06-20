extends Node

var genero_jugador: String = ""

signal dinero_cambiado(nuevo_monto: int)
signal dia_cambiado(nuevo_dia: int)

var dia_actual: int = 150:
	set(value):
		dia_actual = value
		dia_cambiado.emit(dia_actual)

var dinero: int = 0:
	set(value):
		dinero = value
		dinero_cambiado.emit(dinero)

func sumar_dinero(cantidad: int):
	dinero += cantidad
	dinero_cambiado.emit(dinero)

func restar_dinero(cantidad: int):
	dinero -= cantidad
	dinero_cambiado.emit(dinero)
