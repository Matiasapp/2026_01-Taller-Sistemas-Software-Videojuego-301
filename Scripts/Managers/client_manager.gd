extends Node

const MAX_CLIENTES_DIA := 5

var taller_abierto := false
var clientes_atendidos := 0

func abrir_taller() -> void:
	taller_abierto = true
	clientes_atendidos = 0

func registrar_cliente_atendido() -> void:
	clientes_atendidos += 1

func dia_completo() -> bool:
	return clientes_atendidos >= MAX_CLIENTES_DIA

func cerrar_taller() -> void:
	taller_abierto = false
