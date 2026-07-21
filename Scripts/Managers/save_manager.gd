extends Node
## Guardado y carga de la partida.
## Persiste en user://partida.save. En el navegador (export web) user:// se guarda
## en el IndexedDB del navegador, así que la partida persiste entre sesiones sin
## necesidad de código extra.
## Autoload: PARTIDA.

const RUTA := "user://partida.save"


## ¿Existe una partida guardada?
func hay_partida() -> bool:
	return FileAccess.file_exists(RUTA)


## Guarda el estado actual de la partida.
func guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("partida", "dia_actual", DATOSGLOBALES.dia_actual)
	cfg.set_value("partida", "dinero", DATOSGLOBALES.dinero)
	cfg.set_value("partida", "reputacion", DATOSGLOBALES.reputacion)
	cfg.set_value("partida", "arriendos_postergados", DATOSGLOBALES.arriendos_postergados)
	cfg.set_value("partida", "genero_jugador", DATOSGLOBALES.genero_jugador)
	cfg.set_value("partida", "clientes_usados", DATOSGLOBALES.clientes_usados)
	cfg.set_value("partida", "modal_bienvenida_mostrado", DATOSGLOBALES.modal_bienvenida_mostrado)
	cfg.set_value("partida", "estadisticas_dias", DATOSGLOBALES.estadisticas_dias)
	# Progreso hacia la protesta: sin esto, el contador de piezas dudosas volvía
	# a cero al cargar y el evento podía no dispararse nunca.
	cfg.set_value("partida", "contador_pieza_defectuosa", DATOSGLOBALES.contador_pieza_defectuosa)
	cfg.set_value("partida", "protesta_pendiente", DATOSGLOBALES.protesta_pendiente)
	# Las reseñas en sí viven dentro de estadisticas_dias; esto es solo el contador
	# de las que el jugador todavía no fue a leer al PC.
	cfg.set_value("partida", "resenas_sin_leer", DATOSGLOBALES.resenas_sin_leer)

	var err := cfg.save(RUTA)
	if err == OK:
		print("Partida guardada (día %d, $%d)." % [DATOSGLOBALES.dia_actual, DATOSGLOBALES.dinero])
	else:
		push_error("No se pudo guardar la partida (error %d)." % err)


## Carga la partida guardada en DATOSGLOBALES. Devuelve true si lo logró.
func cargar() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		return false
	DATOSGLOBALES.limpiar_avisos_reputacion()

	DATOSGLOBALES.dia_actual = cfg.get_value("partida", "dia_actual", 1)
	DATOSGLOBALES.dinero = cfg.get_value("partida", "dinero", 150)
	DATOSGLOBALES.reputacion = cfg.get_value(
		"partida", "reputacion", DATOSGLOBALES.REPUTACION_INICIAL
	)
	DATOSGLOBALES.arriendos_postergados = int(
		cfg.get_value("partida", "arriendos_postergados", 0)
	)
	DATOSGLOBALES.genero_jugador = cfg.get_value("partida", "genero_jugador", "")
	DATOSGLOBALES.modal_bienvenida_mostrado = cfg.get_value("partida", "modal_bienvenida_mostrado", false)
	DATOSGLOBALES.estadisticas_dias = cfg.get_value("partida", "estadisticas_dias", {})
	DATOSGLOBALES.contador_pieza_defectuosa = int(
		cfg.get_value("partida", "contador_pieza_defectuosa", 0)
	)
	DATOSGLOBALES.protesta_pendiente = bool(
		cfg.get_value("partida", "protesta_pendiente", false)
	)
	DATOSGLOBALES.resenas_sin_leer = int(
		cfg.get_value("partida", "resenas_sin_leer", 0)
	)
	# Se agregan los datos diarios generales del juego
	DATOSGLOBALES.historial_dias = cfg.get_value("partida","datos_del_dia",[0,0,0,0,0,0])
	# clientes_usados es Array[int]: lo reconstruimos con el tipo correcto.
	DATOSGLOBALES.clientes_usados.clear()
	for c in cfg.get_value("partida", "clientes_usados", []):
		DATOSGLOBALES.clientes_usados.append(int(c))

	# La partida cargada empieza un día nuevo con el taller cerrado a las 08:00.
	if CLIENTMANAGER:
		CLIENTMANAGER.reiniciar()
	if TIEMPOMANAGER:
		TIEMPOMANAGER.reset_day()

	# Estado transitorio que no debe arrastrarse al cargar.
	DATOSGLOBALES.mostrar_resumen_dia_al_volver = false
	DATOSGLOBALES.volviendo_de_atencion = false
	DATOSGLOBALES.estafa_pendiente = false

	print("Partida cargada (día %d, $%d)." % [DATOSGLOBALES.dia_actual, DATOSGLOBALES.dinero])
	return true


## Borra la partida guardada.
func borrar() -> void:
	if FileAccess.file_exists(RUTA):
		DirAccess.remove_absolute(RUTA)
