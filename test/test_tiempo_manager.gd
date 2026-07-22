extends GutTest


func before_each() -> void:
	_restablecer_autoloads()


func after_each() -> void:
	_restablecer_autoloads()


func _restablecer_autoloads() -> void:
	DATOSGLOBALES.reiniciar()
	DATOSGLOBALES.reiniciar_estadisticas_dia()
	DATOSGLOBALES.historial_dias.clear()
	CLIENTMANAGER.reiniciar()
	TIEMPOMANAGER.current_hour = 8
	TIEMPOMANAGER.current_minute = 0
	TIEMPOMANAGER.end_hour = 18
	TIEMPOMANAGER.minute_duration = 0.5
	TIEMPOMANAGER.time_accumulator = 0.0
	TIEMPOMANAGER.is_timer_running = false
	TIEMPOMANAGER.has_initialized = false


func test_start_y_stop_timer_cambian_el_estado_sin_esperas_reales() -> void:
	TIEMPOMANAGER.start_timer()
	assert_true(TIEMPOMANAGER.is_timer_running)

	TIEMPOMANAGER.stop_timer()
	assert_false(TIEMPOMANAGER.is_timer_running)


func test_reset_day_reinicia_reloj_y_emite_hora() -> void:
	TIEMPOMANAGER.current_hour = 17
	TIEMPOMANAGER.current_minute = 45
	TIEMPOMANAGER.time_accumulator = 3.5
	watch_signals(TIEMPOMANAGER)

	TIEMPOMANAGER.reset_day(9)

	assert_eq(TIEMPOMANAGER.current_hour, 9)
	assert_eq(TIEMPOMANAGER.current_minute, 0)
	assert_eq(TIEMPOMANAGER.time_accumulator, 0.0)
	assert_true(TIEMPOMANAGER.has_initialized)
	assert_signal_emit_count(TIEMPOMANAGER.time_changed, 1)
	assert_signal_emitted_with_parameters(TIEMPOMANAGER.time_changed, [9, 0])


func test_avanzar_horas_actualiza_reloj_sin_terminar_antes_del_cierre() -> void:
	watch_signals(TIEMPOMANAGER)

	TIEMPOMANAGER.avanzar_horas(2)

	assert_eq(TIEMPOMANAGER.current_hour, 10)
	assert_eq(TIEMPOMANAGER.current_minute, 0)
	assert_signal_emitted_with_parameters(TIEMPOMANAGER.time_changed, [10, 0])
	assert_signal_not_emitted(TIEMPOMANAGER.day_ended)


func test_avanzar_horas_limita_a_la_hora_de_cierre_y_finaliza_jornada() -> void:
	TIEMPOMANAGER.current_hour = 17
	TIEMPOMANAGER.current_minute = 30
	watch_signals(TIEMPOMANAGER)

	TIEMPOMANAGER.avanzar_horas(2)

	assert_eq(TIEMPOMANAGER.current_hour, 18)
	assert_eq(TIEMPOMANAGER.current_minute, 0)
	assert_signal_emit_count(TIEMPOMANAGER.time_changed, 1)
	assert_signal_emitted_with_parameters(TIEMPOMANAGER.time_changed, [18, 0])
	assert_signal_emit_count(TIEMPOMANAGER.day_ended, 1)


func test_advance_minute_hace_rollover_a_la_hora_siguiente() -> void:
	TIEMPOMANAGER.current_hour = 9
	TIEMPOMANAGER.current_minute = 59
	watch_signals(TIEMPOMANAGER)

	TIEMPOMANAGER.advance_minute()

	assert_eq(TIEMPOMANAGER.current_hour, 10)
	assert_eq(TIEMPOMANAGER.current_minute, 0)
	assert_signal_emitted_with_parameters(TIEMPOMANAGER.time_changed, [10, 0])
	assert_signal_not_emitted(TIEMPOMANAGER.day_ended)


func test_advance_minute_detiene_timer_al_llegar_al_cierre() -> void:
	TIEMPOMANAGER.current_hour = 17
	TIEMPOMANAGER.current_minute = 59
	TIEMPOMANAGER.start_timer()
	watch_signals(TIEMPOMANAGER)

	TIEMPOMANAGER.advance_minute()

	assert_eq(TIEMPOMANAGER.current_hour, 18)
	assert_eq(TIEMPOMANAGER.current_minute, 0)
	assert_false(TIEMPOMANAGER.is_timer_running)
	assert_signal_emitted_with_parameters(TIEMPOMANAGER.time_changed, [18, 0])
	assert_signal_emit_count(TIEMPOMANAGER.day_ended, 1)


func test_avanzar_dia_incrementa_dia_global_y_reinicia_reloj() -> void:
	DATOSGLOBALES.dia_actual = 3
	TIEMPOMANAGER.current_hour = 18
	watch_signals(DATOSGLOBALES)
	watch_signals(TIEMPOMANAGER)

	TIEMPOMANAGER.avanzar_dia()

	assert_eq(DATOSGLOBALES.dia_actual, 4)
	assert_eq(TIEMPOMANAGER.current_hour, 8)
	assert_eq(TIEMPOMANAGER.current_minute, 0)
	assert_signal_emit_count(DATOSGLOBALES.dia_cambiado, 1)
	assert_signal_emitted_with_parameters(DATOSGLOBALES.dia_cambiado, [4])
	assert_signal_emit_count(TIEMPOMANAGER.time_changed, 1)
	assert_signal_emitted_with_parameters(TIEMPOMANAGER.time_changed, [8, 0])
