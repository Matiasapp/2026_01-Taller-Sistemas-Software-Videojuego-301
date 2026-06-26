extends Node2D

var jugador_en_rango_abrir_taller = false
var jugador_en_rango_interactuar_pc = false
var jugador_en_rango_atender_cliente = false
var puede_interactuar = true
var jugador_en_rango_easter_egg = false

# =========================
# FLUJO DEL DÍA / CLIENTES
# =========================

const MAX_CLIENTES_DIA := 5

var taller_abierto := false
var clientes_atendidos := 0

# Placeholder hasta que exista el sistema real de inventario/piezas
var inventario := {
	"neumatico": 5,
	"bateria": 3,
	"aceite": 4,
	"frenos": 3
}

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

func _ready() -> void:
	randomize()
	
	mensaje_abrir_taller.visible = false
	mensaje_interactuar_pc.visible = false
	mensaje_atender_cliente.visible = false
	
	if resumen_dia:
		resumen_dia.visible = false
	
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
	if DATOSGLOBALES.volviendo_de_atencion:
		DATOSGLOBALES.volviendo_de_atencion = false
		var delta_dinero: int = DATOSGLOBALES.dinero - DATOSGLOBALES.dinero_antes_atencion
		if delta_dinero != 0 and hud:
			hud.mostrar_popup_dinero(delta_dinero)
	
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
	# SI VOLVIMOS DESDE EVENTOROBO / TRANSICIONDIA,
	# MOSTRAMOS EL RESUMEN ENCIMA DEL TALLER
	# =========================================================
	if DATOSGLOBALES.mostrar_resumen_dia_al_volver:
		DATOSGLOBALES.mostrar_resumen_dia_al_volver = false
		
		if CLIENTMANAGER:
			CLIENTMANAGER.cerrar_taller()
		
		taller_abierto = false
		clientes_atendidos = 0
		
		if resumen_dia:
			resumen_dia.visible = true
		
		get_tree().paused = true
		return
	
	# Recuperar estado del flujo al volver desde un minijuego
	if CLIENTMANAGER:
		taller_abierto = CLIENTMANAGER.taller_abierto
		clientes_atendidos = CLIENTMANAGER.clientes_atendidos
		
		# Si volvimos desde el minijuego del último cliente,
		# ahora sí corresponde cerrar el día.
		if taller_abierto and CLIENTMANAGER.dia_completo():
			cerrar_dia()
			return
	
	if taller_abierto and TIEMPOMANAGER:
		TIEMPOMANAGER.start_timer()
	
	actualizar_mensaje_puerta()
	
	# Recuperar estado del flujo al volver desde un minijuego
	if CLIENTMANAGER:
		taller_abierto = CLIENTMANAGER.taller_abierto
		clientes_atendidos = CLIENTMANAGER.clientes_atendidos
		
		# Si volvimos desde el minijuego del último cliente,
		# ahora sí corresponde cerrar el día.
		if taller_abierto and CLIENTMANAGER.dia_completo():
			cerrar_dia()
			return
	
	if taller_abierto and TIEMPOMANAGER:
		TIEMPOMANAGER.start_timer()
	
	actualizar_mensaje_puerta()


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


func _process(_delta: float) -> void:

	if Input.is_key_pressed(KEY_P) and not debug_apagon_lanzado:

		debug_apagon_lanzado = true

		var apagon = preload("res://Scenes/Events/EventoDelApagon/EventoApagon.tscn").instantiate()

		add_child(apagon)

	if not Input.is_key_pressed(KEY_P):
		debug_apagon_lanzado = false

func _input(event):
	if get_tree().paused: 
		return
	
	if not puede_interactuar:
		return
	
	if jugador_en_rango_abrir_taller and event.is_action_pressed("interactuar"):
		if not taller_abierto:
			abrir_taller()
		else:
			print("El taller ya está abierto")
	
	if jugador_en_rango_easter_egg and event.is_action_pressed("interactuar"):
		lanzar_minijuego_random()
	
	if jugador_en_rango_atender_cliente and event.is_action_pressed("interactuar"):
		atender_cliente()
	
	if jugador_en_rango_interactuar_pc and event.is_action_pressed("interactuar"):
		play_pc_in()
		GLOBALSIGNALS.abrir_pc.emit()
		print("¡Se abrió el pc!")


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

	print("Taller abierto. Clientes del día: 0/%d" % CLIENTMANAGER.MAX_CLIENTES_DIA)
	actualizar_mensaje_puerta()


func atender_cliente() -> void:
	if not taller_abierto:
		print("Primero debes abrir el taller")
		return
	
	# Si por alguna razón ya se completó el día y el jugador vuelve a interactuar,
	# cerramos el día directamente.
	if CLIENTMANAGER.dia_completo():
		cerrar_dia()
		return
	
	# Registramos que este cliente ya fue atendido en el flujo del día.
	# Ojo: esto incluye también al cliente 5.
	CLIENTMANAGER.registrar_cliente_atendido()
	clientes_atendidos = CLIENTMANAGER.clientes_atendidos
	
	print("Cliente atendido: %d/%d" % [clientes_atendidos, MAX_CLIENTES_DIA])
	
	# TODO: Integrar selección de pieza.
	# Aquí debería elegirse/descontarse una pieza buena, barata o dudosa.

	# TODO: Integrar resultado del servicio.
	# El resultado del minijuego debería afectar dinero/reputación.

	if CLIENTMANAGER.dia_completo():
		cerrar_dia()
	else:
		# Guardamos el dinero actual para, al volver, mostrar en el HUD cuánto cambió.
		DATOSGLOBALES.dinero_antes_atencion = DATOSGLOBALES.dinero
		DATOSGLOBALES.volviendo_de_atencion = true

		# Abre la pantalla de atención: ahí el cliente da la pista, el jugador
		# diagnostica la falla y se lanza el minijuego correspondiente.
		get_tree().change_scene_to_file(ATENCION_CLIENTE_SCENE)


func lanzar_minijuego_random() -> void:
	if minijuegos.is_empty():
		print("No hay minijuegos disponibles")
		return

	var escena_random = minijuegos.pick_random()
	print("Cargando minijuego:", escena_random)
	get_tree().change_scene_to_file(escena_random)


func cerrar_dia() -> void:
	print("Día terminado")

	taller_abierto = false

	if CLIENTMANAGER:
		CLIENTMANAGER.cerrar_taller()

	if TIEMPOMANAGER:
		TIEMPOMANAGER.stop_timer()
		TIEMPOMANAGER.avanzar_dia()

	if randf() <= 0.30:
		DATOSGLOBALES.siguiente_evento_dia = "robo"
	else:
		DATOSGLOBALES.siguiente_evento_dia = "transicion"

	DATOSGLOBALES.mostrar_resumen_dia_al_volver = true

	get_tree().paused = false
	Engine.time_scale = 1.0

	await fade_to_black(0.6)

	match DATOSGLOBALES.siguiente_evento_dia:
		"robo":
			get_tree().change_scene_to_file("res://Scenes/Events/EventoRobo/EventoRobo.tscn")
		"transicion":
			get_tree().change_scene_to_file("res://Scenes/Events/TransicionDia/transicion_dia.tscn")

func ejecutar_evento_robo() -> void:
	print("EVENTO: Entraron a robar")

	var piezas_disponibles := []

	for pieza in inventario.keys():
		if inventario[pieza] > 0:
			piezas_disponibles.append(pieza)

	if piezas_disponibles.is_empty():
		print("No había piezas para robar")
		mostrar_resumen_dia()
		return

	var cantidad_robada := randi_range(1, 3)
	var piezas_robadas := []

	for i in cantidad_robada:
		if piezas_disponibles.is_empty():
			break

		var pieza = piezas_disponibles.pick_random()
		inventario[pieza] -= 1
		piezas_robadas.append(pieza)

		if inventario[pieza] <= 0:
			piezas_disponibles.erase(pieza)

	print("Piezas robadas:", piezas_robadas)
	print("Inventario actualizado:", inventario)

	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://Scenes/Events/EventoRobo/EventoRobo.tscn")


func _on_day_ended():
	cerrar_dia()

func _on_botón_resumen_dia_pressed() -> void:
	if resumen_dia:
		resumen_dia.visible = false

	get_tree().paused = false
	Engine.time_scale = 1.0
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
	if taller_abierto:
		mensaje_abrir_taller.text = "El Taller ya está Abierto"
		mensaje_abrir_taller.modulate = Color.RED
	else:
		mensaje_abrir_taller.text = "Presiona [E] para Abrir Taller"
		mensaje_abrir_taller.modulate = Color.WHITE


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
		mensaje_atender_cliente.visible = true


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
		
func mostrar_resumen_dia() -> void:
	get_tree().paused = true

	if resumen_dia:
		resumen_dia.visible = true		
		
func fade_to_black(duration := 0.6) -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)

	await tween.finished		
	
var debug_apagon_lanzado := false
