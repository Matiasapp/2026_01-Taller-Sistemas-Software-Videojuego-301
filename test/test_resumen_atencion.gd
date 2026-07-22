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
	assert_eq(resumen["nivel_desempeno"], DATOSGLOBALES.DESEMPENO_ACEPTABLE)
	assert_false(resumen["resultado_minijuego_registrado"])
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
	assert_eq(resumen["nivel_desempeno"], DATOSGLOBALES.DESEMPENO_EXITOSO)
	assert_true(resumen["resultado_minijuego_registrado"])
	assert_eq(resumen["rep_total"], DATOSGLOBALES.REP_MINIJUEGO_EXITOSO)
	assert_signal_emit_count(DATOSGLOBALES.reputacion_cambiado, 1)
	assert_signal_emitted_with_parameters(
		DATOSGLOBALES.reputacion_cambiado,
		[DATOSGLOBALES.REPUTACION_INICIAL + DATOSGLOBALES.REP_MINIJUEGO_EXITOSO]
	)


func test_final_reputacion_no_interrumpe_el_minijuego_de_la_atencion() -> void:
	DATOSGLOBALES.iniciar_resumen_atencion()
	DATOSGLOBALES.volviendo_de_atencion = true
	DATOSGLOBALES.reputacion = 0
	var minijuego := "res://Scenes/Minigames/Prueba.tscn"

	var destino := DATOSGLOBALES.obtener_destino_post_escena(minijuego)

	assert_eq(destino, minijuego)
	assert_eq(
		DATOSGLOBALES.final_pendiente_scene,
		DATOSGLOBALES.FINAL_REPUTACION_SCENE
	)


func test_minijuego_exitoso_compensa_y_cancela_el_final_reputacion() -> void:
	DATOSGLOBALES.iniciar_resumen_atencion()
	DATOSGLOBALES.volviendo_de_atencion = true
	DATOSGLOBALES.reputacion = 0

	DATOSGLOBALES.reportar_rendimiento_minijuego(
		1.0,
		0,
		DATOSGLOBALES.DESEMPENO_EXITOSO,
		"Prueba de compensacion"
	)
	var destino := DATOSGLOBALES.obtener_destino_post_escena(
		DATOSGLOBALES.GAME_SCREEN_SCENE
	)

	assert_eq(DATOSGLOBALES.reputacion, DATOSGLOBALES.REP_MINIJUEGO_EXITOSO)
	assert_eq(DATOSGLOBALES.final_pendiente_scene, "")
	assert_eq(destino, DATOSGLOBALES.GAME_SCREEN_SCENE)


func test_final_reputacion_se_mantiene_si_el_minijuego_no_compensa() -> void:
	DATOSGLOBALES.iniciar_resumen_atencion()
	DATOSGLOBALES.volviendo_de_atencion = true
	DATOSGLOBALES.reputacion = 0

	DATOSGLOBALES.reportar_rendimiento_minijuego(
		0.5,
		0,
		DATOSGLOBALES.DESEMPENO_ACEPTABLE,
		"Prueba sin compensacion"
	)

	assert_eq(DATOSGLOBALES.reputacion, 0)
	assert_eq(
		DATOSGLOBALES._obtener_final_critico(),
		DATOSGLOBALES.FINAL_REPUTACION_SCENE
	)


func test_final_deuda_no_interrumpe_el_minijuego_de_la_atencion() -> void:
	DATOSGLOBALES.iniciar_resumen_atencion()
	DATOSGLOBALES.volviendo_de_atencion = true
	DATOSGLOBALES.dinero = DATOSGLOBALES.UMBRAL_DEUDA_EXTREMA
	var minijuego := "res://Scenes/Minigames/Prueba.tscn"

	var destino := DATOSGLOBALES.obtener_destino_post_escena(minijuego)

	assert_eq(destino, minijuego)
	assert_eq(
		DATOSGLOBALES.final_pendiente_scene,
		DATOSGLOBALES.FINAL_DEUDA_SCENE
	)


func test_recompensa_compensa_y_cancela_el_final_deuda() -> void:
	DATOSGLOBALES.iniciar_resumen_atencion()
	DATOSGLOBALES.volviendo_de_atencion = true
	DATOSGLOBALES.dinero = DATOSGLOBALES.UMBRAL_DEUDA_EXTREMA

	DATOSGLOBALES.sumar_dinero(1)
	var destino := DATOSGLOBALES.obtener_destino_post_escena(
		DATOSGLOBALES.GAME_SCREEN_SCENE
	)

	assert_eq(DATOSGLOBALES.dinero, DATOSGLOBALES.UMBRAL_DEUDA_EXTREMA + 1)
	assert_eq(DATOSGLOBALES.final_pendiente_scene, "")
	assert_eq(destino, DATOSGLOBALES.GAME_SCREEN_SCENE)


func test_final_deuda_se_mantiene_si_la_recompensa_no_compensa() -> void:
	DATOSGLOBALES.iniciar_resumen_atencion()
	DATOSGLOBALES.volviendo_de_atencion = true
	DATOSGLOBALES.dinero = DATOSGLOBALES.UMBRAL_DEUDA_EXTREMA

	assert_eq(
		DATOSGLOBALES._obtener_final_critico(),
		DATOSGLOBALES.FINAL_DEUDA_SCENE
	)
