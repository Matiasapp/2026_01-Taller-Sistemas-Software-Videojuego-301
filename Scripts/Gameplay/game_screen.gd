extends Node2D

#Audio
@onready var transition_whoosh: AudioStreamPlayer = $TransitionWhoosh

var jugador_en_rango_abrir_taller = false
var jugador_en_rango_interactuar_pc = false
var jugador_en_rango_atender_cliente = false
var puede_interactuar = true
var jugador_en_rango_easter_egg = false

# =========================
# FLUJO DEL DÍA / CLIENTES
# =========================

const MAX_CLIENTES_DIA := 5
# Segundos (tiempo real) que tarda en llegar el próximo cliente tras abrir / tras atender uno.
const TIEMPO_LLEGADA_CLIENTE := 5
const PROBABILIDAD_APAGON := 0.30
const APAGON_SCENE := preload("res://Scenes/Events/EventoDelApagon/EventoApagon.tscn")
const GASTOS_DIARIOS_SCENE := "res://Scenes/Events/GastosDiarios/GastosDiarios.tscn"

var taller_abierto := false
var clientes_atendidos := 0
# true cuando este _ready se ejecuta justo tras volver de atender a un cliente.
var venimos_de_atender := false
var apagon_programado := false
var apagon_en_curso := false
# Temporizador (uno a la vez) para la llegada de clientes.
var timer_llegada: Timer
# Sonido de campana que suena cuando llega un cliente.
var campana_sound: AudioStreamPlayer

var minijuegos := [
	"res://Scenes/Minigames/Crossy_Road/Crossy Road.tscn",
	"res://Scenes/Minigames/MemoryGame/MemoryGame.tscn",
	"res://Scenes/Minigames/Neumaticos/MinijuegoNeumatico.tscn",
		"res://Scenes/Minigames/Soldadura/Game_start.tscn",
	"res://Scenes/Minigames/TheFloorIsLava/the_floor_is_lava.tscn"
]

# Pantalla de atención al cliente (diálogo + diagnóstico + minijuego según la falla).
const ATENCION_CLIENTE_SCENE := "res://Scenes/Gameplay/AtencionCliente.tscn"
# Evento que se muestra al volver del minijuego si el cliente era un estafador.
const EVENTO_ESTAFA_SCENE := "res://Scenes/Events/EventoEstafa.tscn"

@onready var en_desarrollo = $en_desarrollo
@onready var resumen_dia = $PantallaResumenDia
@onready var hud = $Hud
@onready var mensaje_abrir_taller = $Marker2DAbrirTaller/LabelAbrirTaller
@onready var mensaje_interactuar_pc = $Marker2DInteractuarPc/LabelInteractuarPc
@onready var mensaje_atender_cliente = $Marker2DAtenderCliente/LabelAtenderCliente
@onready var ambient_fx: AudioStreamPlayer = $AmbientFX
@onready var music_loop: AudioStreamPlayer = $MusicLoop
@onready var fan_sound: AudioStreamPlayer2D = $Node2D/ventilador/AudioStreamPlayer2D
@onready var pc_sound_in: AudioStreamPlayer = $PCSoundin
@onready var pc_sound_out: AudioStreamPlayer = $PCSoundout
@onready var open_sound: AudioStreamPlayer = $OpenSound
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var sprite_taller: Sprite2D = $Taller
@onready var dust_particles: GPUParticles2D = $DustParticles
@onready var modal_bienvenida: CanvasLayer = $ModalBienvenida
@onready var jugador: CharacterBody2D = $Node2D/Player
# Alzadora de autos: se muestra la "ocupada" (con un auto) cuando hay un cliente
# esperando, y la "desocupada" (vacía) el resto del tiempo.
@onready var alzadora_ocupada: Sprite2D = $"Node2D/alzadora de autos ocupada"
@onready var alzadora_desocupada: Sprite2D = $"Node2D/alzadora de autos desocupada"

# El sprite sheet "autos_clientes.png" tiene 25 autos en una grilla de 5x5. Estas
# coordenadas (x/ancho por columna, y/alto por fila) se midieron desde el atlas real
# porque las celdas no son perfectamente uniformes. Al llegar un cliente se elige uno
# al azar y se recorta la región correspondiente sobre la alzadora ocupada.
const AUTO_COLUMNAS_X := [9, 489, 968, 1447, 1923]
const AUTO_COLUMNAS_ANCHO := [433, 432, 432, 432, 435]
const AUTO_FILAS_Y := [65, 394, 720, 1047, 1366]
const AUTO_FILAS_ALTO := [291, 290, 290, 283, 287]

# Emisor de polvo que dispara un "puff" al cambiar la alzadora, para que la
# aparición del auto no sea tan brusca. Es un nodo de la escena (ajustable en el
# editor): GPUParticles2D "ParticulasAlzadora" con one_shot activado.
@onready var particulas_alzadora: GPUParticles2D = $"Node2D/ParticulasAlzadora"

# Textura del mapa cuando el taller está abierto (la cerrada es la que trae la escena).
const TEXTURA_TALLER_ABIERTO: Texture2D = preload("res://Assets/Sprites/mapa final abierto.png")

func _ready() -> void:
	randomize()

	# Temporizador de llegada de clientes (uno a la vez).
	timer_llegada = Timer.new()
	timer_llegada.one_shot = true
	add_child(timer_llegada)
	timer_llegada.timeout.connect(_on_llegada_cliente)

	# Sonido de campana al llegar un cliente.
	campana_sound = AudioStreamPlayer.new()
	campana_sound.stream = preload("res://Assets/Audio/GameScreen/campana.wav")
	campana_sound.bus = &"SFX"
	campana_sound.volume_db = -12.0
	add_child(campana_sound)

	mensaje_abrir_taller.visible = false
	mensaje_interactuar_pc.visible = false
	mensaje_atender_cliente.visible = false
	
	if resumen_dia:
		resumen_dia.visible = false
		if not resumen_dia.cerrado.is_connected(_on_resumen_cerrado):
			resumen_dia.cerrado.connect(_on_resumen_cerrado)

	# Recuperar estado del flujo al volver desde un minijuego
	if CLIENTMANAGER:
		taller_abierto = CLIENTMANAGER.taller_abierto
		clientes_atendidos = CLIENTMANAGER.clientes_atendidos

	# Si el cliente recién atendido era un estafador, la estafa solo tiene sentido si hubo
	# un pago real que falsificar (buen desempeño). Si jugó mal y no ganó nada, se cancela:
	# no se puede "estafar" un pago que no existió.
	if DATOSGLOBALES.estafa_pendiente:
		var pago_estafa: int = DATOSGLOBALES.dinero - DATOSGLOBALES.dinero_antes_estafa
		if pago_estafa > 0:
			get_tree().change_scene_to_file(EVENTO_ESTAFA_SCENE)
			return
		else:
			DATOSGLOBALES.estafa_pendiente = false
			print("Estafa cancelada: el mal desempeño no dejó un pago que estafar.")

	# Al volver de atender un cliente, mostramos en el HUD cuánto cambió el dinero (neto).
	var atencion_consolidada := DATOSGLOBALES.consolidar_atencion_pendiente()
	if bool(atencion_consolidada.get("registrada", false)):
		venimos_de_atender = true
		var delta_dinero: int = int(atencion_consolidada.get("delta_dinero", 0))
		if delta_dinero != 0 and hud:
			hud.mostrar_popup_dinero(delta_dinero)

		# Una sola tirada diaria, justo al volver del segundo cliente. El dia 5
		# queda protegido para no romper el cierre final de la partida.
		if _puede_programar_apagon():
			apagon_programado = randf() <= PROBABILIDAD_APAGON
			if apagon_programado:
				puede_interactuar = false
				_bloquear_movimiento_jugador()

	if hud and hud.has_method("mostrar_cambios_reputacion_pendientes"):
		hud.mostrar_cambios_reputacion_pendientes()
	
	iniciar_audio_taller()
	
	$Node2D/ventilador.play("giro_ventilador")
	
	if fan_sound:
		fan_sound.process_mode = Node.PROCESS_MODE_ALWAYS
		fan_sound.play()
	
	if ambient_fx:
		ambient_fx.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if music_loop:
		music_loop.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if pc_sound_in:
		pc_sound_in.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if pc_sound_out:
		pc_sound_out.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if GLOBALSIGNALS and not GLOBALSIGNALS.cerrar_pc.is_connected(play_pc_out):
		GLOBALSIGNALS.cerrar_pc.connect(play_pc_out)
	
	if TIEMPOMANAGER and not TIEMPOMANAGER.day_ended.is_connected(_on_day_ended):
		TIEMPOMANAGER.day_ended.connect(_on_day_ended)
	
	if TIEMPOMANAGER and not TIEMPOMANAGER.has_initialized:
		TIEMPOMANAGER.stop_timer()
		TIEMPOMANAGER.has_initialized = true

	# =========================================================
	# SI VOLVIMOS DESDE EVENTOROBO / TRANSICIONDIA, preparamos el nuevo día.
	# (Las estadísticas YA se mostraron tras atender al 5º cliente.)
	# =========================================================
	if DATOSGLOBALES.mostrar_resumen_dia_al_volver:
		DATOSGLOBALES.mostrar_resumen_dia_al_volver = false

		if CLIENTMANAGER:
			CLIENTMANAGER.cerrar_taller()

		taller_abierto = false
		clientes_atendidos = 0

	# Recuperar estado del flujo al volver desde un minijuego.
	# NO cerramos el día aquí aunque ya se hayan atendido los 5 clientes:
	# el cierre es manual, el jugador debe acercarse a la cortina e interactuar.
	if CLIENTMANAGER:
		taller_abierto = CLIENTMANAGER.taller_abierto
		clientes_atendidos = CLIENTMANAGER.clientes_atendidos

	if taller_abierto and TIEMPOMANAGER:
		TIEMPOMANAGER.start_timer()

	# Si volvemos con el taller abierto (p.ej. tras un minijuego), mantenemos el mapa abierto.
	if taller_abierto and sprite_taller:
		sprite_taller.texture = TEXTURA_TALLER_ABIERTO

	# Las partículas solo se ven con el taller abierto.
	_actualizar_particulas()

	actualizar_mensaje_puerta()

	# Si volvimos de atender al ÚLTIMO cliente del día (el 5º), mostramos las
	# estadísticas del día. Luego el jugador cerrará el taller en la cortina.
	if venimos_de_atender and taller_abierto and CLIENTMANAGER and CLIENTMANAGER.dia_completo():
		mostrar_resumen_dia()

	# Al volver de atender, programamos la llegada del siguiente cliente (si quedan).
	if taller_abierto and not apagon_programado:
		programar_llegada_cliente()

	# Dejamos la alzadora en el estado correcto según si hay un cliente esperando.
	actualizar_alzadora()

	# Modal de bienvenida: solo el día 1 a las 08:00, una única vez.
	_verificar_modal_bienvenida()

	if apagon_programado:
		call_deferred("_lanzar_apagon")


## Muestra el modal de bienvenida una sola vez, al iniciar el día 1 (08:00).
func _verificar_modal_bienvenida() -> void:
	if DATOSGLOBALES.modal_bienvenida_mostrado:
		return
	if DATOSGLOBALES.dia_actual != 1:
		return
	if TIEMPOMANAGER and TIEMPOMANAGER.current_hour != 8:
		return

	DATOSGLOBALES.modal_bienvenida_mostrado = true

	if modal_bienvenida:
		modal_bienvenida.visible = true
		get_tree().paused = true


func _on_modal_bienvenida_entendido() -> void:
	AUDIOMANAGER.play_ui_click()
	if modal_bienvenida:
		modal_bienvenida.visible = false
	get_tree().paused = false


func _on_modal_bienvenida_entendido_mouse_entered() -> void:
	AUDIOMANAGER.play_ui_hover()


func iniciar_audio_taller() -> void:
	if ambient_fx:
		ambient_fx.volume_db = 6.0
		ambient_fx.play()

	if music_loop:
		music_loop.volume_db = 0.0
		music_loop.play()


func play_pc_in() -> void:
	if pc_sound_in:
		pc_sound_in.play()


func play_pc_out() -> void:
	if pc_sound_out:
		pc_sound_out.play()


func _input(event):
	if get_tree().paused: 
		return
	
	if not puede_interactuar:
		return

	if not event.is_action_pressed("interactuar") or event.is_echo():
		return

	# Una pulsacion solo puede ejecutar una interaccion. La puerta tiene prioridad
	# para impedir que un area superpuesta cargue tambien otra escena.
	if jugador_en_rango_abrir_taller:
		if not taller_abierto:
			abrir_taller()
		elif CLIENTMANAGER.dia_completo():
			# Jornada terminada (5 clientes / 18:00): cierre manual en la cortina.
			cerrar_dia()
		else:
			print("El taller ya está abierto")
		get_viewport().set_input_as_handled()
		return

	if jugador_en_rango_atender_cliente:
		atender_cliente()
		get_viewport().set_input_as_handled()
		return

	if jugador_en_rango_interactuar_pc:
		play_pc_in()
		GLOBALSIGNALS.abrir_pc.emit()
		print("¡Se abrió el pc!")
		get_viewport().set_input_as_handled()
		return

	if jugador_en_rango_easter_egg:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://Scenes/Minigames/Crossy_Road/Crossy Road.tscn")


# =========================
# FLUJO DEL TALLER
# =========================

func abrir_taller() -> void:
	if taller_abierto:
		return

	if open_sound:
		open_sound.play()

	CLIENTMANAGER.abrir_taller()
	taller_abierto = CLIENTMANAGER.taller_abierto
	clientes_atendidos = CLIENTMANAGER.clientes_atendidos

	if TIEMPOMANAGER:
		TIEMPOMANAGER.reset_day()
		TIEMPOMANAGER.start_timer()

	# Cambiamos el mapa al de "taller abierto".
	if sprite_taller:
		sprite_taller.texture = TEXTURA_TALLER_ABIERTO

	_actualizar_particulas()

	print("Taller abierto. Clientes del día: 0/%d" % CLIENTMANAGER.MAX_CLIENTES_DIA)
	actualizar_mensaje_puerta()

	# Los clientes no se atienden enseguida: el primero llega tras una espera.
	programar_llegada_cliente()

## Las partículas de polvo solo se muestran/emiten con el taller abierto.
func _actualizar_particulas() -> void:
	if dust_particles:
		dust_particles.emitting = taller_abierto
		dust_particles.visible = taller_abierto


func atender_cliente() -> void:
	if not taller_abierto:
		print("Primero debes abrir el taller")
		return
	
	# Si ya se atendieron los 5 clientes, no hay más por atender: el jugador debe
	# acercarse a la cortina metálica para cerrar el taller (NO se cierra solo).
	if CLIENTMANAGER.dia_completo():
		print("Ya atendiste a los 5 clientes. Acércate a la cortina para cerrar el taller.")
		return

	# No se puede atender hasta que haya llegado un cliente (no se atiende enseguida).
	if not hay_cliente_esperando():
		print("Aún no ha llegado ningún cliente. Espera a que llegue.")
		return

	# Registramos al cliente (incluye también al 5º) y consumimos 2 horas del día.
	CLIENTMANAGER.registrar_cliente_atendido()
	clientes_atendidos = CLIENTMANAGER.clientes_atendidos

	# La reparación consume 1 hora (la espera/llegada del cliente consumió la otra).
	# Así cada cliente suma 2 h y 5 clientes llenan la jornada; al 5º el reloj llega
	# a 18:00 y se emite day_ended.
	if TIEMPOMANAGER:
		TIEMPOMANAGER.avanzar_horas(1)

	print("Cliente atendido: %d/%d" % [clientes_atendidos, MAX_CLIENTES_DIA])

	# TODO: Integrar selección de pieza.
	# TODO: Integrar resultado del servicio.

	# Guardamos el dinero actual para, al volver, mostrar en el HUD cuánto cambió.
	DATOSGLOBALES.dinero_antes_atencion = DATOSGLOBALES.dinero
	DATOSGLOBALES.volviendo_de_atencion = true

	# Empieza un desglose limpio de esta atención (costos, recompensa, reputación).
	DATOSGLOBALES.iniciar_resumen_atencion()

	# Siempre se atiende al cliente (también al 5º): pantalla de atención + minijuego.
	await transition_to_atencion_cliente()


# =========================
# LLEGADA DE CLIENTES (uno a la vez)
# =========================

## ¿Hay un cliente que ya llegó y todavía no fue atendido?
func hay_cliente_esperando() -> bool:
	return CLIENTMANAGER.clientes_llegados > CLIENTMANAGER.clientes_atendidos

## Programa la llegada del próximo cliente tras una espera, si corresponde.
func programar_llegada_cliente() -> void:
	if not taller_abierto:
		return
	if hay_cliente_esperando():
		return  # ya hay un cliente esperando ser atendido
	if CLIENTMANAGER.clientes_llegados >= CLIENTMANAGER.MAX_CLIENTES_DIA:
		return  # ya llegaron todos los clientes del día
	if timer_llegada.time_left > 0:
		return  # ya hay una llegada en curso
	timer_llegada.start(TIEMPO_LLEGADA_CLIENTE)

## Cuando se cumple el tiempo, llega un cliente al taller.
func _on_llegada_cliente() -> void:
	if not taller_abierto:
		return
	CLIENTMANAGER.registrar_llegada_cliente()

	# Suena la campana para avisar la llegada.
	if campana_sound:
		campana_sound.play()

	# Esperar a que llegue el cliente consume 1 hora del día.
	if TIEMPOMANAGER:
		TIEMPOMANAGER.avanzar_horas(1)
	print("Llegó un cliente al taller.")

	# Avisamos al jugador en pantalla (pasó 1 hora y llegó un cliente).
	if hud:
		var hora_txt := "%02d:%02d" % [TIEMPOMANAGER.current_hour, TIEMPOMANAGER.current_minute]
		hud.mostrar_aviso("🔔 ¡Llegó un cliente! El tiempo avanzó hasta las [color=yellow]%s[/color]" % hora_txt)

	# El cliente trae su auto: mostramos la alzadora ocupada con un auto al azar.
	mostrar_alzadora_ocupada()

	actualizar_mensaje_atender()


# =========================
# ALZADORA DE AUTOS
# =========================

## Muestra la alzadora "ocupada" con un auto elegido al azar (de los 25 del atlas)
## y oculta la alzadora vacía. Se llama al llegar un cliente.
## Con 'con_efecto' se dispara un puff de polvo y un breve fundido para que el
## cambio no sea brusco (se desactiva al restaurar el estado tras recargar la escena).
func mostrar_alzadora_ocupada(con_efecto: bool = true) -> void:
	if alzadora_ocupada == null or alzadora_desocupada == null:
		return

	var columna := randi() % AUTO_COLUMNAS_X.size()
	var fila := randi() % AUTO_FILAS_Y.size()

	var atlas := alzadora_ocupada.texture as AtlasTexture
	if atlas:
		atlas.region = Rect2(
			AUTO_COLUMNAS_X[columna], AUTO_FILAS_Y[fila],
			AUTO_COLUMNAS_ANCHO[columna], AUTO_FILAS_ALTO[fila]
		)

	alzadora_ocupada.visible = true
	alzadora_desocupada.visible = false

	if con_efecto:
		_reproducir_polvo_alzadora()
		# Fundido rápido del auto para acompañar el polvo.
		alzadora_ocupada.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(alzadora_ocupada, "modulate:a", 1.0, 0.35) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		alzadora_ocupada.modulate.a = 1.0

## Vuelve a mostrar la alzadora vacía (sin cliente/auto).
func mostrar_alzadora_vacia() -> void:
	if alzadora_ocupada:
		alzadora_ocupada.visible = false
	if alzadora_desocupada:
		alzadora_desocupada.visible = true

## Sincroniza el estado visual de la alzadora con si hay o no un cliente esperando.
## Útil al (re)cargar la escena para no quedar con la alzadora en un estado incorrecto.
## No usa efecto: es una restauración de estado, no una llegada real.
func actualizar_alzadora() -> void:
	if CLIENTMANAGER and hay_cliente_esperando():
		mostrar_alzadora_ocupada(false)
	else:
		mostrar_alzadora_vacia()

## Dispara el puff de polvo sobre la alzadora.
func _reproducir_polvo_alzadora() -> void:
	if particulas_alzadora:
		particulas_alzadora.restart()

## Texto del cartel de atención según haya o no un cliente esperando.
func actualizar_mensaje_atender() -> void:
	if not jugador_en_rango_atender_cliente:
		return
	if hay_cliente_esperando():
		mensaje_atender_cliente.text = "Presiona [E] para Atender Cliente"
		mensaje_atender_cliente.modulate = Color.WHITE
	else:
		mensaje_atender_cliente.text = "Aún no llega ningún cliente..."
		mensaje_atender_cliente.modulate = Color.GRAY
	mensaje_atender_cliente.visible = true


func lanzar_minijuego_random() -> void:
	if minijuegos.is_empty():
		print("No hay minijuegos disponibles")
		return

	var escena_random = minijuegos.pick_random()
	print("Cargando minijuego:", escena_random)
	get_tree().change_scene_to_file(escena_random)


func cerrar_dia() -> void:
	print("Día terminado")

	DATOSGLOBALES.registrar_cierre_dia()
	DATOSGLOBALES.registrar_evento_dia(
		"Dia cerrado con $%d en caja." % DATOSGLOBALES.dinero
	)

	taller_abierto = false

	if CLIENTMANAGER:
		CLIENTMANAGER.cerrar_taller()

	if TIEMPOMANAGER:
		TIEMPOMANAGER.stop_timer()
		TIEMPOMANAGER.avanzar_dia()

	# Se Guardan los datos diarios
	DATOSGLOBALES.guardar_dia()
	# Autoguardado: se guarda el progreso al cerrar el día (ya con el nuevo día).
	PARTIDA.guardar()

	# ¿Habrá robo esta noche? Se decide ahora, pero el robo se muestra DESPUÉS del cierre.
	if randf() <= 0.30:
		DATOSGLOBALES.siguiente_evento_dia = "robo"
	elif DATOSGLOBALES.condicion_protesta():
		DATOSGLOBALES.siguiente_evento_dia = "protesta"
	else:
		DATOSGLOBALES.siguiente_evento_dia = "transicion"

	DATOSGLOBALES.mostrar_resumen_dia_al_volver = true

	get_tree().paused = false
	Engine.time_scale = 1.0

	await fade_to_black(0.6)

	# Primero se decide qué gastos del cierre pagar. Después se muestra la
	# transición nocturna y, si corresponde, el evento de robo.
	get_tree().change_scene_to_file(GASTOS_DIARIOS_SCENE)

## El apagon corta la jornada y evita el evento nocturno de robo, pero mantiene
## el cierre de caja: los gastos diarios siguen existiendo aunque se trabaje menos.
func cerrar_dia_por_apagon() -> void:
	if not apagon_en_curso:
		return

	DATOSGLOBALES.registrar_cierre_dia()
	DATOSGLOBALES.registrar_evento_dia(
		"Un corte electrico cerro el taller despues de %d clientes."
		% CLIENTMANAGER.clientes_atendidos
	)

	taller_abierto = false
	CLIENTMANAGER.cerrar_taller()
	TIEMPOMANAGER.stop_timer()
	TIEMPOMANAGER.avanzar_dia()

	DATOSGLOBALES.guardar_dia()
	DATOSGLOBALES.siguiente_evento_dia = "transicion"
	DATOSGLOBALES.mostrar_resumen_dia_al_volver = true
	PARTIDA.guardar()

	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(GASTOS_DIARIOS_SCENE)

func _puede_programar_apagon() -> bool:
	return (
		venimos_de_atender
		and taller_abierto
		and DATOSGLOBALES.dia_actual < DATOSGLOBALES.ULTIMO_DIA
		and CLIENTMANAGER.clientes_atendidos == 2
	)

func _lanzar_apagon() -> void:
	if not apagon_programado or apagon_en_curso or not is_inside_tree():
		return

	apagon_en_curso = true
	puede_interactuar = false
	_bloquear_movimiento_jugador()
	if timer_llegada:
		timer_llegada.stop()
	if TIEMPOMANAGER:
		TIEMPOMANAGER.stop_timer()

	mensaje_abrir_taller.visible = false
	mensaje_interactuar_pc.visible = false
	mensaje_atender_cliente.visible = false

	var apagon = APAGON_SCENE.instantiate()
	apagon.connect("evento_terminado", cerrar_dia_por_apagon, Object.CONNECT_ONE_SHOT)
	add_child(apagon)

func _bloquear_movimiento_jugador() -> void:
	if jugador and jugador.has_method("set_movimiento_habilitado"):
		jugador.set_movimiento_habilitado(false)

func _on_day_ended():
	# Terminó la jornada (18:00 / 5 clientes atendidos). NO cerramos solos:
	# el jugador debe acercarse a la cortina metálica para cerrar el taller.
	print("Jornada terminada. Acércate a la cortina para cerrar el taller.")
	actualizar_mensaje_puerta()

## El resumen del día se cerró (el propio panel ya despausó el juego).
func _on_resumen_cerrado() -> void:
	actualizar_mensaje_puerta()


# =========================
# INTERACCIÓN TALLER
# =========================

func _on_area_abrir_taller_body_entered(body):
	if body.name == "Player":
		jugador_en_rango_abrir_taller = true
		mensaje_abrir_taller.visible = true
		actualizar_mensaje_puerta()


func _on_area_abrir_taller_body_exited(body):
	if body.name == "Player":
		jugador_en_rango_abrir_taller = false
		mensaje_abrir_taller.visible = false


func actualizar_mensaje_puerta():
	if not taller_abierto:
		mensaje_abrir_taller.text = "Presiona [E] para Abrir Taller"
		mensaje_abrir_taller.modulate = Color.WHITE
	elif CLIENTMANAGER.dia_completo():
		mensaje_abrir_taller.text = "Presiona [E] para Cerrar Taller"
		mensaje_abrir_taller.modulate = Color.YELLOW
	else:
		mensaje_abrir_taller.text = "El Taller ya está Abierto"
		mensaje_abrir_taller.modulate = Color.RED


# =========================
# INTERACCIÓN PC
# =========================

func _on_area_interactuar_pc_body_entered(body):
	if body.name == "Player":
		jugador_en_rango_interactuar_pc = true
		mensaje_interactuar_pc.visible = true


func _on_area_interactuar_pc_body_exited(body):
	if body.name == "Player":
		jugador_en_rango_interactuar_pc = false
		mensaje_interactuar_pc.visible = false


# =========================
# ATENDER CLIENTE
# =========================

func _on_area_atender_cliente_body_entered(body: Node2D):
	if body.name == "Player":
		jugador_en_rango_atender_cliente = true
		actualizar_mensaje_atender()


func _on_area_atender_cliente_body_exited(body):
	if body.name == "Player":
		jugador_en_rango_atender_cliente = false
		mensaje_atender_cliente.visible = false


# =========================
# EASTER EGG / TEST MINIJUEGO
# =========================

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		jugador_en_rango_easter_egg = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		jugador_en_rango_easter_egg = false


func mostrar_resumen_dia() -> void:
	get_tree().paused = true

	if resumen_dia:
		resumen_dia.mostrar_resumen()
		
func fade_to_black(duration := 0.6) -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)

	await tween.finished		
	
func transition_to_atencion_cliente() -> void:
	puede_interactuar = false

	if transition_whoosh:
		transition_whoosh.volume_db = -4.0
		transition_whoosh.pitch_scale = 1.0
		transition_whoosh.play()

	await fade_to_black(0.45)

	if transition_whoosh and transition_whoosh.playing:
		await transition_whoosh.finished

	get_tree().change_scene_to_file(ATENCION_CLIENTE_SCENE)
