extends Node

const MAX_CLIENTES_DIA := 5

var taller_abierto := false
var clientes_atendidos := 0
var clientes_llegados := 0

func abrir_taller() -> void:
	taller_abierto = true
	clientes_atendidos = 0
	clientes_llegados = 0

func puede_llegar_cliente() -> bool:
	return taller_abierto and clientes_llegados < MAX_CLIENTES_DIA

func registrar_llegada_cliente() -> void:
	if not puede_llegar_cliente():
		return
	
	clientes_llegados += 1
	print("Llegó cliente:", clientes_llegados, "/", MAX_CLIENTES_DIA)

func registrar_cliente_atendido() -> void:
	clientes_atendidos += 1
	print("Cliente atendido:", clientes_atendidos, "/", MAX_CLIENTES_DIA)

func dia_completo() -> bool:
	return clientes_atendidos >= MAX_CLIENTES_DIA

func cerrar_taller() -> void:
	taller_abierto = false
