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

signal dinero_cambiado(nuevo_monto: int)
signal dia_cambiado(nuevo_dia: int)

var dia_actual: int = 1:
	set(value):
		dia_actual = value
		dia_cambiado.emit(dia_actual)

var dinero: int = 150:
	set(value):
		dinero = value
		dinero_cambiado.emit(dinero)

func sumar_dinero(cantidad: int):
	dinero += cantidad

func restar_dinero(cantidad: int):
	dinero -= cantidad

## Reinicia todo el estado de la partida a los valores iniciales (Nueva Partida).
func reiniciar() -> void:
	dia_actual = 1
	dinero = 150
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
