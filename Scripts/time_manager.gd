# TimeManager.gd (Configurado como Autoload en los ajustes del proyecto)
extends Node

# Señales para avisar a otras partes del juego cuando cambia el tiempo
signal time_changed(hours: int, minutes: int)
signal day_ended

# Configuración del tiempo del juego
var current_hour: int = 8      # El taller abre a las 08:00
var current_minute: int = 0
var end_hour: int = 18         # El taller cierra a las 18:00

# Parámetros de velocidad
var minute_duration: float = 1.0 # ¿Cuántos segundos reales dura 1 minuto en el juego?
# Si minute_duration = 0.5, un día de 10 horas en el juego (de 8:00 a 18:00 = 600 minutos de juego) durará 5 minutos reales.
# Ahora está en 1 por lo que un día dura 10 minutos reales.

var time_accumulator: float = 0.0
var is_timer_running: bool = false

func _process(delta: float) -> void:
	if not is_timer_running:
		return
		
	time_accumulator += delta
	
	# Cuando el acumulador supera la duración de un minuto del juego
	if time_accumulator >= minute_duration:
		time_accumulator -= minute_duration
		advance_minute()

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
