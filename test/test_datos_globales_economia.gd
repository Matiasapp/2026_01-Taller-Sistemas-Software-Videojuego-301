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


func test_sumar_dinero_actualiza_saldo_ingresos_y_senales() -> void:
	watch_signals(DATOSGLOBALES)

	DATOSGLOBALES.sumar_dinero(125)

	assert_eq(DATOSGLOBALES.dinero, 625)
	assert_eq(DATOSGLOBALES.ingresos_dia, 125)
	assert_signal_emit_count(DATOSGLOBALES.dinero_cambiado, 1)
	assert_signal_emitted_with_parameters(DATOSGLOBALES.dinero_cambiado, [625])
	assert_signal_emit_count(DATOSGLOBALES.ingresos_dia_cambiado, 1)
	assert_signal_emitted_with_parameters(DATOSGLOBALES.ingresos_dia_cambiado, [125])


func test_restar_dinero_actualiza_saldo_y_gasto_con_la_convencion_actual() -> void:
	watch_signals(DATOSGLOBALES)

	DATOSGLOBALES.restar_dinero(80)

	assert_eq(DATOSGLOBALES.dinero, 420)
	# El codigo de produccion almacena los gastos diarios con signo negativo.
	assert_eq(DATOSGLOBALES.gastos_dia, -80)
	assert_signal_emit_count(DATOSGLOBALES.dinero_cambiado, 1)
	assert_signal_emitted_with_parameters(DATOSGLOBALES.dinero_cambiado, [420])
	assert_signal_emit_count(DATOSGLOBALES.gastos_dia_cambiado, 1)
	assert_signal_emitted_with_parameters(DATOSGLOBALES.gastos_dia_cambiado, [-80])


func test_asignar_dinero_emite_el_nuevo_saldo() -> void:
	watch_signals(DATOSGLOBALES)

	DATOSGLOBALES.dinero = 735

	assert_signal_emit_count(DATOSGLOBALES.dinero_cambiado, 1)
	assert_signal_emitted_with_parameters(DATOSGLOBALES.dinero_cambiado, [735])


func test_registrar_atenciones_separa_ingresos_y_gastos_en_estadisticas() -> void:
	DATOSGLOBALES.registrar_atencion_dia(200, 1)
	DATOSGLOBALES.registrar_atencion_dia(-60, 1)

	var stats: Dictionary = DATOSGLOBALES.get_estadistica_dia(1)
	assert_eq(stats["clientes_atendidos"], 2)
	assert_eq(stats["ingresos"], 200)
	assert_eq(stats["gastos"], 60)
	assert_eq(stats["balance"], 140)


func test_registrar_gastos_diarios_descuenta_y_guarda_el_desglose() -> void:
	var pagados: Array[String] = ["Arriendo", "Electricidad"]
	var postergados: Array[String] = ["Publicidad"]

	var registrado: bool = DATOSGLOBALES.registrar_gastos_diarios(
		1, pagados, postergados, 180, 0
	)

	var stats: Dictionary = DATOSGLOBALES.get_estadistica_dia(1)
	assert_true(registrado)
	assert_eq(DATOSGLOBALES.dinero, 320)
	assert_eq(stats["gastos_diarios_total"], 180)
	assert_eq(stats["gastos_diarios_pagados"], pagados)
	assert_eq(stats["gastos_diarios_postergados"], postergados)
	assert_eq(stats["gastos"], 180)
	assert_eq(stats["balance"], -180)
	assert_eq(stats["dinero_final"], 320)


func test_registrar_gastos_diarios_no_cobra_dos_veces_el_mismo_dia() -> void:
	var pagados: Array[String] = ["Arriendo"]
	var postergados: Array[String] = []

	var primera_vez: bool = DATOSGLOBALES.registrar_gastos_diarios(
		1, pagados, postergados, 120, 0
	)
	var segunda_vez: bool = DATOSGLOBALES.registrar_gastos_diarios(
		1, pagados, postergados, 120, 0
	)

	assert_true(primera_vez)
	assert_false(segunda_vez)
	assert_eq(DATOSGLOBALES.dinero, 380)
	assert_eq(DATOSGLOBALES.get_estadistica_dia(1)["gastos"], 120)


func test_registrar_perdida_evento_actualiza_saldo_y_estadisticas() -> void:
	watch_signals(DATOSGLOBALES)

	DATOSGLOBALES.registrar_perdida_evento(90, "Herramienta rota", 0, 2)

	var stats: Dictionary = DATOSGLOBALES.get_estadistica_dia(2)
	assert_eq(DATOSGLOBALES.dinero, 410)
	assert_eq(stats["gastos"], 90)
	assert_eq(stats["balance"], -90)
	assert_eq(stats["dinero_final"], 410)
	assert_eq(stats["eventos"], ["Herramienta rota"])
	assert_signal_emitted_with_parameters(DATOSGLOBALES.dinero_cambiado, [410])


func test_estadisticas_generales_suman_todos_los_dias() -> void:
	DATOSGLOBALES.registrar_atencion_dia(150, 1)
	DATOSGLOBALES.registrar_atencion_dia(-40, 2)

	var generales: Dictionary = DATOSGLOBALES.get_estadisticas_generales()
	assert_eq(generales["clientes_atendidos"], 2)
	assert_eq(generales["ingresos"], 150)
	assert_eq(generales["gastos"], 40)
	assert_eq(generales["balance"], 110)
	assert_eq(generales["dinero_actual"], 500)


func test_formatear_monto_distingue_positivo_cero_y_negativo() -> void:
	assert_eq(DATOSGLOBALES.formatear_monto(75), "+$75")
	assert_eq(DATOSGLOBALES.formatear_monto(0), "+$0")
	assert_eq(DATOSGLOBALES.formatear_monto(-25), "-$25")
