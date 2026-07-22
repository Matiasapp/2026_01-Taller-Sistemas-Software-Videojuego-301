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


func test_abrir_taller_reinicia_clientes_y_emite_estado() -> void:
	CLIENTMANAGER.clientes_atendidos = 3
	CLIENTMANAGER.clientes_llegados = 4
	watch_signals(CLIENTMANAGER)

	CLIENTMANAGER.abrir_taller()

	assert_true(CLIENTMANAGER.taller_abierto)
	assert_eq(CLIENTMANAGER.clientes_atendidos, 0)
	assert_eq(CLIENTMANAGER.clientes_llegados, 0)
	assert_signal_emitted_with_parameters(CLIENTMANAGER.estado_taller_cambiado, [true])
	assert_signal_emitted_with_parameters(
		CLIENTMANAGER.clientes_atendidos_cambiado,
		[0, CLIENTMANAGER.MAX_CLIENTES_DIA]
	)


func test_cliente_no_puede_llegar_con_taller_cerrado() -> void:
	assert_false(CLIENTMANAGER.puede_llegar_cliente())

	CLIENTMANAGER.registrar_llegada_cliente()

	assert_eq(CLIENTMANAGER.clientes_llegados, 0)


func test_llegadas_no_superan_el_maximo_diario() -> void:
	CLIENTMANAGER.abrir_taller()

	for _i in range(CLIENTMANAGER.MAX_CLIENTES_DIA + 2):
		CLIENTMANAGER.registrar_llegada_cliente()

	assert_eq(CLIENTMANAGER.clientes_llegados, CLIENTMANAGER.MAX_CLIENTES_DIA)
	assert_false(CLIENTMANAGER.puede_llegar_cliente())


func test_registrar_cliente_atendido_actualiza_contador_y_senal() -> void:
	CLIENTMANAGER.abrir_taller()
	watch_signals(CLIENTMANAGER)

	CLIENTMANAGER.registrar_cliente_atendido()

	assert_eq(CLIENTMANAGER.clientes_atendidos, 1)
	assert_signal_emit_count(CLIENTMANAGER.clientes_atendidos_cambiado, 1)
	assert_signal_emitted_with_parameters(
		CLIENTMANAGER.clientes_atendidos_cambiado,
		[1, CLIENTMANAGER.MAX_CLIENTES_DIA]
	)


func test_dia_completo_se_activa_al_atender_cinco_clientes() -> void:
	CLIENTMANAGER.abrir_taller()
	watch_signals(CLIENTMANAGER)

	for _i in range(CLIENTMANAGER.MAX_CLIENTES_DIA - 1):
		CLIENTMANAGER.registrar_cliente_atendido()
	assert_false(CLIENTMANAGER.dia_completo())

	CLIENTMANAGER.registrar_cliente_atendido()

	assert_true(CLIENTMANAGER.dia_completo())
	assert_signal_emit_count(
		CLIENTMANAGER.clientes_atendidos_cambiado,
		CLIENTMANAGER.MAX_CLIENTES_DIA
	)
	assert_signal_emitted_with_parameters(
		CLIENTMANAGER.clientes_atendidos_cambiado,
		[CLIENTMANAGER.MAX_CLIENTES_DIA, CLIENTMANAGER.MAX_CLIENTES_DIA]
	)


func test_cerrar_taller_emite_estado_cerrado() -> void:
	CLIENTMANAGER.abrir_taller()
	watch_signals(CLIENTMANAGER)

	CLIENTMANAGER.cerrar_taller()

	assert_false(CLIENTMANAGER.taller_abierto)
	assert_signal_emit_count(CLIENTMANAGER.estado_taller_cambiado, 1)
	assert_signal_emitted_with_parameters(CLIENTMANAGER.estado_taller_cambiado, [false])


func test_reiniciar_restablece_todo_y_emite_los_valores_iniciales() -> void:
	CLIENTMANAGER.taller_abierto = true
	CLIENTMANAGER.clientes_atendidos = 4
	CLIENTMANAGER.clientes_llegados = 5
	watch_signals(CLIENTMANAGER)

	CLIENTMANAGER.reiniciar()

	assert_false(CLIENTMANAGER.taller_abierto)
	assert_eq(CLIENTMANAGER.clientes_atendidos, 0)
	assert_eq(CLIENTMANAGER.clientes_llegados, 0)
	assert_signal_emitted_with_parameters(CLIENTMANAGER.estado_taller_cambiado, [false])
	assert_signal_emitted_with_parameters(
		CLIENTMANAGER.clientes_atendidos_cambiado,
		[0, CLIENTMANAGER.MAX_CLIENTES_DIA]
	)
