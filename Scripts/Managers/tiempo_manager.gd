extends Node

# Señales para avisar a otras partes del juego cuando cambia el tiempo
signal time_changed(hours: int, minutes: int)
signal day_ended

# Configuración del tiempo del juego
var current_hour: int = 8      # El taller abre a las 08:00
var current_minute: int = 0
var end_hour: int = 18         # El taller cierra a las 18:00

# Parámetros de velocidad
var minute_duration: float = 0.5 # ¿Cuántos segundos reales dura 1 minuto en el juego?
# Si minute_duration = 0.5, un día de 10 horas en el juego (de 8:00 a 18:00 = 600 minutos de juego) durará 5 minutos reales.
# Ahora está en 1 por lo que un día dura 10 minutos reales.

var time_accumulator: float = 0.0
var is_timer_running: bool = false
var has_initialized: bool = false

func _ready() -> void:
	has_initialized = false

func _process(_delta: float) -> void:
	# El tiempo ya NO corre en tiempo real: avanza 2 horas cada vez que se atiende
	# a un cliente (ver avanzar_horas). Por eso el loop de minutos queda desactivado.
	pass

## Avanza el reloj del juego una cantidad de horas (se llama al atender a un cliente).
## Llega como tope a la hora de cierre. El fin del día lo decide la cantidad de clientes.
func avanzar_horas(horas: int) -> void:
	current_hour += horas
	current_minute = 0
	if current_hour >= end_hour:
		current_hour = end_hour
	time_changed.emit(current_hour, current_minute)

	# Al llegar a la hora de cierre (tras atender al 5º cliente) avisamos que terminó
	# la jornada. No cierra el taller: el jugador debe hacerlo en la cortina.
	if current_hour >= end_hour:
		day_ended.emit()

func advance_minute() -> void:
	current_minute += 1
	
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		
	# Emitir señal para que la UI se actualice
	time_changed.emit(current_hour, current_minute)
	
	# Verificar si llegó la hora de cierre
	if current_hour >= end_hour:
		stop_timer()
		day_ended.emit()
#
#
#
# Funciones de control para el loop de juego
#
#
#
func start_timer() -> void:
	is_timer_running = true

func stop_timer() -> void:
	is_timer_running = false

func reset_day(start_h: int = 8) -> void:
	current_hour = start_h
	current_minute = 0
	time_accumulator = 0.0
	time_changed.emit(current_hour, current_minute)
	has_initialized = true
	
func avanzar_dia():
	DATOSGLOBALES.dia_actual += 1
	# Al pasar al día siguiente el reloj vuelve a la hora de apertura (08:00);
	# si no, quedaría marcando la hora de cierre (18:00) del día anterior.
	reset_day()
	print("Ahora es el día: ", DATOSGLOBALES.dia_actual)
