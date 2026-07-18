extends GutTest

const ControladorCrossy = preload("res://script_templates/AIController/crossy_road.gd")
const Vehiculo = preload("res://Scripts/CrossyRoad/vehiculo_manager.gd")
const Sincronizador = preload("res://addons/godot_rl_agents/sync.gd")

class AgenteTerminalFalso:
	extends Node
	var reset_ejecutado := false
	var pending_reset := false
	var terminado := true

	func get_done() -> bool:
		return terminado

	func set_done_false() -> void:
		terminado = false

	func reset() -> void:
		reset_ejecutado = true
		pending_reset = false
		terminado = false


func test_limite_de_pasos_cierra_el_episodio_sin_reiniciarlo() -> void:
	var controlador := AIController2D.new()
	controlador.reset_after = 2

	controlador._physics_process(0.0)
	assert_false(controlador.get_done())
	controlador._physics_process(0.0)

	assert_true(controlador.get_done())
	assert_false(controlador.needs_reset)
	controlador.free()


func test_reset_limpia_estado_terminal_y_contador() -> void:
	var controlador := AIController2D.new()
	controlador.done = true
	controlador.needs_reset = true
	controlador.n_steps = 25

	controlador.reset()

	assert_false(controlador.done)
	assert_false(controlador.needs_reset)
	assert_eq(controlador.n_steps, 0)
	controlador.free()


func test_inferencia_resetea_el_agente_al_terminar() -> void:
	var sincronizador := Sincronizador.new()
	var agente := AgenteTerminalFalso.new()

	sincronizador._reset_agents_if_done([agente])

	assert_true(agente.reset_ejecutado)
	agente.free()
	sincronizador.free()


func test_done_reportado_deja_un_reset_pendiente() -> void:
	var sincronizador := Sincronizador.new()
	var agente := AgenteTerminalFalso.new()

	var terminados := sincronizador._get_done_from_agents([agente])

	assert_eq(terminados, [true])
	assert_true(agente.pending_reset)
	assert_false(agente.terminado)
	agente.free()
	sincronizador.free()


func test_accion_nueva_resetea_un_episodio_terminal_pendiente() -> void:
	var sincronizador := Sincronizador.new()
	var agente := AgenteTerminalFalso.new()
	agente.pending_reset = true

	sincronizador._reset_pending_agents([agente])

	assert_true(agente.reset_ejecutado)
	assert_false(agente.pending_reset)
	agente.free()
	sincronizador.free()


func test_los_limites_laterales_forman_parte_de_la_observacion() -> void:
	var controlador := ControladorCrossy.new()
	controlador.limite_columna = 8

	assert_eq(controlador._valor_celda({}, Vector2(9, 0)), 1.0)
	assert_eq(controlador._valor_celda({}, Vector2(-9, 0)), 1.0)
	assert_eq(controlador._valor_celda({}, Vector2(8, 0)), 0.0)
	controlador.free()


func test_vehiculos_exponen_su_ancho_para_la_grilla() -> void:
	var vehiculo := Vehiculo.new()

	assert_eq(vehiculo.ancho_en_casillas, 2)
	vehiculo.free()


func test_arboles_son_observables_por_el_agente() -> void:
	var arbol := preload("res://Scenes/Minigames/Crossy_Road/arbol.tscn").instantiate()

	assert_true(arbol.is_in_group("arboles"))
	arbol.free()
