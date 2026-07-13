extends Control

@onready var tutorial = $Tutorial

# RESUMEN COMPLETO VIEJO (Lo guardamos para destruirlo al final)
@onready var panel_final = $Resumen

@onready var barra = $AreaMovimiento
@onready var zona = $AreaMovimiento/ZonaVerde
@onready var indicador = $AreaMovimiento/Indicador

@onready var tiempo_label = $Tiempo
@onready var neumatico = $Neumatico

@onready var Tuerca1 = $Vidas/Tuerca1
@onready var Tuerca2 = $Vidas/Tuerca2
@onready var Tuerca3 = $Vidas/Tuerca3
@onready var Tuerca4 = $Vidas/Tuerca4

# NEUMATICOS GUARDADOS
@onready var neumaticos_guardados = [
	$Neumaticos/Neumatico1,
	$Neumaticos/Neumatico2,
	$Neumaticos/Neumatico3,
	$Neumaticos/Neumatico4,
	$Neumaticos/Neumatico5,
	$Neumaticos/Neumatico6,
	$Neumaticos/Neumatico7,
	$Neumaticos/Neumatico8,
	$Neumaticos/Neumatico9,
	$Neumaticos/Neumatico10
]

# AUDIO
@onready var sfx_break = $BreakSound
@onready var sfx_hit = $HitSound
@onready var sfx_inflate = $InflateSound
@onready var sfx_complete = $CompleteSound

# MUSICA
@onready var music_loop = $MusicLoop

# MOVIMIENTO
var velocidad = 650.0
var direccion = 1

# PROGRESO
var nivel_inflado = 0
var golpes_para_inflar = 4

# TOTAL
var neumaticos_inflados = 0

# TIEMPO
var tiempo_restante = 30.0

# ESTADOS
var juego_terminado = false
var juego_iniciado = false

# VIDAS
const VIDAS_INICIALES := 4
var vidas = VIDAS_INICIALES
var vidas_perdidas = 0

# DINERO
var dinero_obtenido = 0
@export var dinero_por_neumatico = 40
@export var costo_por_tuerca = 10

# DIFICULTAD
var ancho_minimo_zona = 60
var reduccion_zona = 30
var ancho_inicial_zona = 190


func _ready():
	randomize()
	
	music_loop.play()

	# OCULTAR RESUMEN VIEJO
	if panel_final:
		panel_final.hide()

	# MOSTRAR TUTORIAL
	tutorial.visible = true

	Tuerca1.play("Idle")
	Tuerca2.play("Idle")
	Tuerca3.play("Idle")
	Tuerca4.play("Idle")

	# OCULTAR NEUMATICOS DEL ESTANTE
	for neumatico_guardado in neumaticos_guardados:
		neumatico_guardado.visible = false

	# POSICION INICIAL
	indicador.position.x = 0
	zona.size.x = ancho_inicial_zona

	actualizar_tiempo()


func _process(delta):
	# ESPERAR INICIO
	if not juego_iniciado:
		if Input.is_action_just_pressed("ui_accept"):
			iniciar_juego()
		return

	# TERMINADO
	if juego_terminado:
		return

	# TIEMPO
	tiempo_restante -= delta
	velocidad += delta * 5

	actualizar_tiempo()

	# TERMINAR POR TIEMPO
	if tiempo_restante <= 0:
		tiempo_restante = 0
		juego_terminado = true
		calcular_dinero_final()
		return

	# MOVER INDICADOR
	mover_indicador(delta)

	# GOLPE
	if Input.is_action_just_pressed("ui_accept"):
		evaluar_golpe()


func mover_indicador(delta):
	indicador.position.x += (velocidad * direccion * delta)

	if indicador.position.x >= (barra.size.x - indicador.size.x):
		indicador.position.x = (barra.size.x - indicador.size.x)
		direccion = -1
		reproducir_hit()

	if indicador.position.x <= 0:
		indicador.position.x = 0
		direccion = 1
		reproducir_hit()


func evaluar_golpe():
	var centro_indicador = (indicador.position.x + indicador.size.x / 2)
	var inicio_zona = zona.position.x
	var final_zona = (zona.position.x + zona.size.x)
	var margen = 8

	var dentro = (centro_indicador >= inicio_zona - margen and centro_indicador <= final_zona + margen)

	# GOLPE CORRECTO
	if dentro:
		sfx_inflate.play()
		nivel_inflado += 1

		# CAMBIAR FRAME
		if nivel_inflado <= 3:
			neumatico.frame = nivel_inflado

		cambiar_zona()
		velocidad += 15

		# COMPLETAR NEUMATICO
		if nivel_inflado >= 4:
			sfx_complete.play()
			neumaticos_inflados += 1

			if neumaticos_inflados <= neumaticos_guardados.size():
				neumaticos_guardados[neumaticos_inflados - 1].visible = true

			neumatico.frame = 3
			nivel_inflado = 0
			zona.size.x = ancho_inicial_zona
			neumatico.frame = 0

			await get_tree().create_timer(0.3).timeout

	# GOLPE FALLIDO
	else:
		sfx_break.play()
		vidas -= 1
		vidas_perdidas += 1
		romper_tuerca()

		if vidas <= 0:
			juego_terminado = true
			calcular_dinero_final()


func cambiar_zona():
	var nueva_x = randf_range(0, barra.size.x - zona.size.x)
	zona.position.x = nueva_x

	var nuevo_ancho = (zona.size.x - reduccion_zona)
	nuevo_ancho = max(nuevo_ancho, ancho_minimo_zona)
	zona.size.x = nuevo_ancho


func actualizar_tiempo():
	tiempo_label.text = "Tiempo: " + str(int(tiempo_restante))


func romper_tuerca():
	if vidas == 3:
		Tuerca4.play("Romper")
	elif vidas == 2:
		Tuerca3.play("Romper")
	elif vidas == 1:
		Tuerca2.play("Romper")
	elif vidas <= 0:
		Tuerca1.play("Romper")


func iniciar_juego():
	tutorial.visible = false
	juego_iniciado = true


func calcular_dinero_final():
	# Pausamos todo para que el fondo se detenga
	get_tree().paused = true
	
	dinero_obtenido = (neumaticos_inflados * dinero_por_neumatico) - (vidas_perdidas * costo_por_tuerca)
	dinero_obtenido = max(dinero_obtenido, 0)

	# Eliminamos el panel viejo de la memoria
	if panel_final:
		panel_final.queue_free()

	var progreso: float = float(neumaticos_inflados) / float(neumaticos_guardados.size())
	var penal_vidas: float = float(vidas_perdidas) / float(VIDAS_INICIALES) * 0.4
	var rendimiento: float = clampf(progreso - penal_vidas, 0.0, 1.0)
	
	DATOSGLOBALES.reportar_rendimiento_minijuego(rendimiento, dinero_obtenido)
	
	# FUNDAMENTAL: Prevenir autodestrucción
	DATOSGLOBALES.volviendo_de_atencion = true
	
	var resumen = $ResumenAtencion
	resumen.layer = 100 # Capa por encima
	
	# Como ya está en la escena, NO usamos add_child(). Solo lo activamos:
	resumen.activar_panel()
	
	# CONEXIÓN SEGURA
	if not resumen.continuar.is_connected(_on_boton_continuar_pressed):
		resumen.continuar.connect(_on_boton_continuar_pressed)


func reproducir_hit():
	sfx_hit.pitch_scale = randf_range(0.95, 1.05)
	sfx_hit.play()


func _on_boton_continuar_pressed() -> void:
	AUDIOMANAGER.play_ui_click()
	
	# Timer a prueba de pausas
	await get_tree().create_timer(0.15, true, false, true).timeout
	
	Engine.time_scale = 1.0
	get_tree().paused = false
	
	print("Volviendo al taller desde Neumáticos. Dinero obtenido: $", dinero_obtenido)
	DATOSGLOBALES.sumar_dinero(dinero_obtenido)

	get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScreen.tscn")
