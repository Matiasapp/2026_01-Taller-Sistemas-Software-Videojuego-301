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


func test_iniciar_resumen_establece_valores_predeterminados() -> void:
	DATOSGLOBALES.iniciar_resumen_atencion()

	var resumen: Dictionary = DATOSGLOBALES.get_resumen_atencion()
	assert_true(resumen["diagnostico_correcto"])
	assert_eq(resumen["penalizacion_diagnostico"], 0)
	assert_eq(resumen["costo_pieza"], 0)
	assert_eq(resumen["tipo_pieza"], "")
	assert_eq(resumen["recompensa_minijuego"], 0)
	assert_eq(resumen["rendimiento"], 0.5)
	assert_eq(resumen["balance_dinero"], 0)
	assert_eq(resumen["rep_total"], 0)


func test_resumen_calcula_balance_monetario_y_reputacion_total() -> void:
	DATOSGLOBALES.iniciar_resumen_atencion()
	DATOSGLOBALES.resumen_atencion["recompensa_minijuego"] = 300
	DATOSGLOBALES.resumen_atencion["costo_pieza"] = 150
	DATOSGLOBALES.resumen_atencion["penalizacion_diagnostico"] = 50
	DATOSGLOBALES.resumen_atencion["rep_diagnostico"] = 2
	DATOSGLOBALES.resumen_atencion["rep_pieza"] = 5
	DATOSGLOBALES.resumen_atencion["rep_desempeno"] = 3

	var resumen: Dictionary = DATOSGLOBALES.get_resumen_atencion()
	assert_eq(resumen["balance_dinero"], 100)
	assert_eq(resumen["rep_total"], 10)
	assert_eq(resumen["rep_pieza"], 5)
	assert_eq(resumen["rep_desempeno"], 3)


func test_resumen_admite_balance_negativo() -> void:
	DATOSGLOBALES.iniciar_resumen_atencion()
	DATOSGLOBALES.resumen_atencion["recompensa_minijuego"] = 100
	DATOSGLOBALES.resumen_atencion["costo_pieza"] = 300
	DATOSGLOBALES.resumen_atencion["penalizacion_diagnostico"] = 50

	var resumen: Dictionary = DATOSGLOBALES.get_resumen_atencion()
	assert_eq(resumen["balance_dinero"], -250)


func test_resumen_vacio_calcula_totales_en_cero() -> void:
	DATOSGLOBALES.resumen_atencion = {}

	var resumen: Dictionary = DATOSGLOBALES.get_resumen_atencion()
	assert_eq(resumen["balance_dinero"], 0)
	assert_eq(resumen["rep_pieza"], 0)
	assert_eq(resumen["rep_desempeno"], 0)
	assert_eq(resumen["rep_total"], 0)


func test_get_resumen_devuelve_una_copia_independiente() -> void:
	DATOSGLOBALES.iniciar_resumen_atencion()
	DATOSGLOBALES.resumen_atencion["rep_diagnostico"] = 2

	var primera_copia: Dictionary = DATOSGLOBALES.get_resumen_atencion()
	primera_copia["rep_diagnostico"] = 99
	primera_copia["balance_dinero"] = 999
	var segunda_copia: Dictionary = DATOSGLOBALES.get_resumen_atencion()

	assert_eq(segunda_copia["rep_diagnostico"], 2)
	assert_eq(segunda_copia["balance_dinero"], 0)
	assert_eq(segunda_copia["rep_total"], 2)


func test_reportar_rendimiento_actualiza_resumen_y_limita_porcentaje() -> void:
	DATOSGLOBALES.iniciar_resumen_atencion()
	watch_signals(DATOSGLOBALES)

	var cambio_reputacion: int = DATOSGLOBALES.reportar_rendimiento_minijuego(
		1.4,
		250,
		DATOSGLOBALES.DESEMPENO_EXITOSO,
		"Prueba controlada"
	)

	var resumen: Dictionary = DATOSGLOBALES.get_resumen_atencion()
	assert_eq(cambio_reputacion, DATOSGLOBALES.REP_MINIJUEGO_EXITOSO)
	assert_eq(resumen["rendimiento"], 1.0)
	assert_eq(resumen["recompensa_minijuego"], 250)
	assert_eq(resumen["rep_desempeno"], DATOSGLOBALES.REP_MINIJUEGO_EXITOSO)
	assert_eq(resumen["rep_total"], DATOSGLOBALES.REP_MINIJUEGO_EXITOSO)
	assert_signal_emit_count(DATOSGLOBALES.reputacion_cambiado, 1)
	assert_signal_emitted_with_parameters(
		DATOSGLOBALES.reputacion_cambiado,
		[DATOSGLOBALES.REPUTACION_INICIAL + DATOSGLOBALES.REP_MINIJUEGO_EXITOSO]
	)
