extends Node

var genero_jugador: String = ""

signal dinero_cambiado(nuevo_monto: int)
signal dia_cambiado(nuevo_dia: int)
signal reputacion_cambiado(nuevo_reputacion:int)

var dia_actual: int = 0:
	set(value):
		dia_actual = value
		dia_cambiado.emit(dia_actual)

var dinero: int = 99999:
	set(value):
		dinero = value
		dinero_cambiado.emit(dinero)

var reputacion: int = 4:
	set(value):
		reputacion = value
		reputacion_cambiado.emit(reputacion)

func sumar_dinero(cantidad: int):
	dinero += cantidad

func restar_dinero(cantidad: int):
	dinero -= cantidad

func sumar_reputacion(cantidad:int):
	reputacion = mini(100,reputacion + cantidad)

func restar_reputacion(cantidad:int):
	reputacion = maxi(0,reputacion - cantidad)
