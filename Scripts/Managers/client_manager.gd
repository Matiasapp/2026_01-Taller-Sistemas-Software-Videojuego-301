extends Node

## Se emite cada vez que el taller abre o cierra (para que el HUD u otros reaccionen).
signal estado_taller_cambiado(abierto: bool)

## Se emite cada vez que cambia la cantidad de clientes atendidos (para el HUD).
signal clientes_atendidos_cambiado(atendidos: int, total: int)

const MAX_CLIENTES_DIA := 5

var taller_abierto := false
var clientes_atendidos := 0
var clientes_llegados := 0

func abrir_taller() -> void:
	taller_abierto = true
	clientes_atendidos = 0
	clientes_llegados = 0
	estado_taller_cambiado.emit(true)
	clientes_atendidos_cambiado.emit(clientes_atendidos, MAX_CLIENTES_DIA)

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
	clientes_atendidos_cambiado.emit(clientes_atendidos, MAX_CLIENTES_DIA)

func dia_completo() -> bool:
	return clientes_atendidos >= MAX_CLIENTES_DIA

func cerrar_taller() -> void:
	taller_abierto = false
	estado_taller_cambiado.emit(false)

## Pone a cero el conteo del día al terminar la jornada, para que la mañana
## siguiente no arrastre los clientes de ayer (el HUD los seguía mostrando
## hasta que el jugador volvía a abrir el taller).
##
## Va aparte de cerrar_taller() a propósito: hay que llamarla DESPUÉS de
## DATOSGLOBALES.guardar_dia(), que lee clientes_atendidos para el historial.
func reiniciar_conteo_dia() -> void:
	clientes_atendidos = 0
	clientes_llegados = 0
	clientes_atendidos_cambiado.emit(clientes_atendidos, MAX_CLIENTES_DIA)

## Reinicia el estado del taller/clientes (nueva partida o carga).
func reiniciar() -> void:
	taller_abierto = false
	clientes_atendidos = 0
	clientes_llegados = 0
	estado_taller_cambiado.emit(false)
	clientes_atendidos_cambiado.emit(clientes_atendidos, MAX_CLIENTES_DIA)
