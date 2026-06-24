extends Node2D

var jugador_en_rango_abrir_taller = false
var jugador_en_rango_interactuar_pc = false
var jugador_en_rango_atender_cliente = false
var puede_interactuar = true
var jugador_en_rango_easter_egg = false

@onready var en_desarrollo = $en_desarrollo
@onready var resumen_dia = $PantallaResumenDia
@onready var mensaje_abrir_taller = $Marker2DAbrirTaller/LabelAbrirTaller
@onready var mensaje_interactuar_pc = $Marker2DInteractuarPc/LabelInteractuarPc
@onready var mensaje_atender_cliente = $Marker2DAtenderCliente/LabelAtenderCliente
@onready var ambient_fx: AudioStreamPlayer = $AmbientFX
@onready var music_loop: AudioStreamPlayer = $MusicLoop
@onready var fan_sound: AudioStreamPlayer2D = $Node2D/ventilador/AudioStreamPlayer2D
@onready var pc_sound_in: AudioStreamPlayer = $PCSoundin
@onready var pc_sound_out: AudioStreamPlayer = $PCSoundout


func _ready() -> void:
	mensaje_abrir_taller.visible = false
	mensaje_interactuar_pc.visible = false
	mensaje_atender_cliente.visible = false
	
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
	
	if GLOBALSIGNALS:
		GLOBALSIGNALS.cerrar_pc.connect(play_pc_out)
	
	if TIEMPOMANAGER:
		TIEMPOMANAGER.day_ended.connect(_on_day_ended)
	
	if TIEMPOMANAGER and not TIEMPOMANAGER.has_initialized:
		TIEMPOMANAGER.stop_timer()
		TIEMPOMANAGER.has_initialized = true


func iniciar_audio_taller() -> void:
	print("Iniciando audio taller")

	if ambient_fx:
		print("AmbientFX encontrado")
		ambient_fx.volume_db = 6.0
		ambient_fx.play()
	else:
		print("AmbientFX NULL")

	if music_loop:
		print("MusicLoop encontrado")
		music_loop.volume_db = 0.0
		music_loop.play()
	else:
		print("MusicLoop NULL")


func play_pc_in() -> void:
	if pc_sound_in:
		pc_sound_in.play()


func play_pc_out() -> void:
	if pc_sound_out:
		pc_sound_out.play()


func _process(_delta: float) -> void:
	#Se comprueba que las malas reseñas influyen en la reputacion 
	#if Input.is_key_pressed(KEY_G):
	#	get_tree().change_scene_to_file("res://Scenes/Clientes/Mala_Reseña/Mala_reseña.tscn")
	pass


func _on_day_ended():
	get_tree().paused = true
	resumen_dia.visible = true
	
	if jugador_en_rango_abrir_taller:
		actualizar_mensaje_puerta()


func _input(event):
	if get_tree().paused: 
		return
	
	if not puede_interactuar:
		return
	
	if jugador_en_rango_abrir_taller and event.is_action_pressed("interactuar"):
		if not TIEMPOMANAGER.is_timer_running:
			TIEMPOMANAGER.reset_day()
			print("¡Se abrió el taller!")
			TIEMPOMANAGER.start_timer()
			TIEMPOMANAGER.avanzar_dia()
			actualizar_mensaje_puerta()
		else: 
			print("día ya iniciado")
		
	if jugador_en_rango_easter_egg and event.is_action_pressed("interactuar"):
		print("¡Se atendió cliente!")
		get_tree().change_scene_to_file("res://Scenes/Crossy_Road/Crossy Road.tscn")
		
	if jugador_en_rango_atender_cliente and event.is_action_pressed("interactuar"):
		print("¡Se atendió cliente!")
		en_desarrollo.popup_centered()
	
	if jugador_en_rango_interactuar_pc and event.is_action_pressed("interactuar"):
		play_pc_in()
		GLOBALSIGNALS.abrir_pc.emit()
		print("¡Se abrió el pc!")


'''
CODIGO INTERACCIÓN TALLER
'''

func _on_area_abrir_taller_body_entered(body):
	if body.name == "Player":
		actualizar_mensaje_puerta()			
		jugador_en_rango_abrir_taller = true
		mensaje_abrir_taller.visible = true


func _on_area_abrir_taller_body_exited(body):
	if body.name == "Player":
		jugador_en_rango_abrir_taller = false
		mensaje_abrir_taller.visible = false


func actualizar_mensaje_puerta():
	if TIEMPOMANAGER.is_timer_running:
		mensaje_abrir_taller.text = "El Taller ya está Abierto"
		mensaje_abrir_taller.modulate = Color.RED
	else:
		mensaje_abrir_taller.text = "Presiona [E] para Abrir Taller"
		mensaje_abrir_taller.modulate = Color.WHITE


'''
CODIGO INTERACCIÓN USAR PC
'''

func _on_area_interactuar_pc_body_entered(body):
	if body.name == "Player":
		jugador_en_rango_interactuar_pc = true
		mensaje_interactuar_pc.visible = true


func _on_area_interactuar_pc_body_exited(body):
	if body.name == "Player":
		jugador_en_rango_interactuar_pc = false
		mensaje_interactuar_pc.visible = false


'''
CODIGO INTERACCIÓN ATENDER CLIENTE
'''

func _on_area_atender_cliente_body_entered(body: Node2D):
	if body.name == "Player":
		jugador_en_rango_atender_cliente = true
		mensaje_atender_cliente.visible = true


func _on_area_atender_cliente_body_exited(body):
	if body.name == "Player":
		jugador_en_rango_atender_cliente = false
		mensaje_atender_cliente.visible = false


func _on_botón_resumen_dia_pressed() -> void:
	resumen_dia.visible = false
	#Se guardan los datos del dia
	DATOSGLOBALES.guardar_dia()
	DATOSGLOBALES.reiniciar_estadisticas_dia()
	get_tree().paused = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		jugador_en_rango_easter_egg = true
