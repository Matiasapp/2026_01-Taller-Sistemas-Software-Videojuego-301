extends Node2D 

@onready var valor_por_casilla: int = 2
@export var tamaño_casilla = 64
@export var velocidad_movimiento = 0.15 
@export var limite_retroceso: int = 3 
@export var limite_lateral_casillas: int = 8
@onready var puntaje = $"../Hud/Puntaje"
@onready var label_tiempo_restante = $"../Hud/TiempoRestante"

# META: distancia (en casillas) que el jugador debe recorrer para llegar a la tienda y ganar.
@onready var meta_casillas: int = 80
@export var bonus_meta: int = 200
@export var penalizacion_fracaso: int = 100
@export var tiempo_limite: float = 45.0

var tiempo_restante: float = 45.0
var ha_ganado: bool = false
@onready var dinero_obtenido: int = 0
@onready var panel_tutorial = $"../Hud/Tutorial"
var juego_iniciado: bool = false

@export var label_parpadeo: Label
@onready var resumen_atencion = $"../Hud/ResumenAtencion"
@onready var atropellado: bool = false
@onready var anim = $AnimatedSprite2D
@onready var genero = DATOSGLOBALES.genero_jugador
@onready var entorno_visual = $WorldEnvironment.environment
@onready var raycast = $RayCast2D
@onready var camara = $Camera2D 

@onready var audio_salto: AudioStreamPlayer = $SaltoAudio
@onready var audio_muerte: AudioStreamPlayer = $MuerteAudio
@onready var audio_atropello: AudioStreamPlayer = $AtropelloAudio

var frames_hombre = preload("res://Assets/Sprites/animaciones_hombre.tres")
var frames_mujer = preload("res://Assets/Sprites/animaciones_mujer.tres")
var esta_muerto = false 
var se_esta_moviendo = false
var ultima_direccion = Vector2(0, 1)

var posicion_logica: Vector2 
var tween_actual: Tween 

var posicion_inicial_y: float
var posicion_inicial_x: float
var maximas_casillas_avanzadas: int = 0

# --- VARIABLES IA ---
@onready var ai_controller = get_node_or_null("AIController2D")
@export var modo_entrenamiento: bool = true # Cambia a false cuando quieras jugar tú manualmente
var casillas_historico_ia: int = 0 # Para darle puntos a la IA solo cuando avanza a zonas nuevas
var accion_ia: int = 0 # Guarda el input actual de la red neuronal

func _ready() -> void:
	# Inicializamos la IA
	if ai_controller:
		ai_controller.init(self)
		
	if panel_tutorial:
		panel_tutorial.show()

		if label_parpadeo:
			var tween_blink = create_tween().set_loops()
			tween_blink.tween_property(label_parpadeo, "modulate:a", 0.0, 0.6)
			tween_blink.tween_property(label_parpadeo, "modulate:a", 1.0, 0.6)

	# ===============================================================
	# NUEVO: Si la IA entrena, saltar el tutorial de inmediato
	# ===============================================================
	if modo_entrenamiento:
		juego_iniciado = true
		if panel_tutorial:
			panel_tutorial.hide()
	# ===============================================================

	z_index = 2
	entorno_visual.adjustment_saturation = 1.0
	Engine.time_scale = 1.0

	if genero == "Masculino":
		anim.sprite_frames = frames_hombre
	else:
		anim.sprite_frames = frames_mujer

	tiempo_restante = tiempo_limite
	posicion_logica = position
	posicion_inicial_x = position.x
	posicion_inicial_y = position.y
	actualizar_idle()

	if camara:
		camara.top_level = true
		camara.global_position = global_position

	if puntaje:
		puntaje.text = str(maximas_casillas_avanzadas) + " / " + str(meta_casillas)

	# Nos aseguramos de que el panel viejo del minijuego esté oculto
	if resumen_atencion:
		resumen_atencion.hide()


func _process(delta: float) -> void:
	# --- NUEVO: La IA revisa si necesita reiniciar el entorno ---
	if modo_entrenamiento and ai_controller and ai_controller.needs_reset:
		reiniciar_entorno()
		ai_controller.reset()
		return # Cortamos el frame aquí para evitar errores visuales
	if camara and not esta_muerto:
		var destino_x = global_position.x
		var destino_y = posicion_inicial_y - (maximas_casillas_avanzadas * tamaño_casilla)
		var posicion_destino = Vector2(destino_x, destino_y)
		camara.global_position = camara.global_position.lerp(posicion_destino, 8.0 * delta)
		
		if juego_iniciado and tiempo_restante > 0 and not ha_ganado:
			tiempo_restante -= delta 
			
			if label_tiempo_restante:
				label_tiempo_restante.text = "Tiempo Restante: " + str(int((ceil(tiempo_restante)))) + "s"
				
			if tiempo_restante <= 0:
				tiempo_restante = 0
				if label_tiempo_restante:
					label_tiempo_restante.text = "Tiempo Restante: 0s"
				print("¡Se acabó el tiempo!")
				morir()


func _unhandled_input(event: InputEvent) -> void:
	# Bloqueamos el input manual si la IA está entrenando
	if modo_entrenamiento:
		return
		
	if se_esta_moviendo or esta_muerto or ha_ganado:
		return
		
	var accion_manual = 0
	if event.is_action_pressed("mover_arriba"): accion_manual = 1
	elif event.is_action_pressed("mover_abajo"): accion_manual = 2
	elif event.is_action_pressed("mover_izquierda"): accion_manual = 3
	elif event.is_action_pressed("mover_derecha"): accion_manual = 4
	
	if accion_manual != 0:
		ejecutar_movimiento(accion_manual)


func ejecutar_movimiento(accion: int) -> void:
	if not juego_iniciado:
		juego_iniciado = true
		if panel_tutorial:
			panel_tutorial.hide()

	var direccion = Vector2.ZERO
	var casillas_actuales = int((posicion_inicial_y - posicion_logica.y) / tamaño_casilla)
	
	if accion == 1: # Arriba
		direccion = Vector2.UP
		anim.play("saltar_arriba")
			
	elif accion == 2: # Abajo
		var casilla_destino = casillas_actuales - 1
		var casilla_minima_permitida = maximas_casillas_avanzadas - limite_retroceso
		
		if casilla_destino >= casilla_minima_permitida:
			direccion = Vector2.DOWN
			anim.play("saltar_abajo")
		else:
			print("¡Límite de retroceso! No puedes volver más de ", limite_retroceso, " casillas.")
			
	elif accion == 3: # Izquierda
		direccion = Vector2.LEFT
		anim.play("saltar_izquierda")
		
	elif accion == 4: # Derecha
		direccion = Vector2.RIGHT
		anim.play("saltar_derecha")

	if direccion != Vector2.ZERO:
		ultima_direccion = direccion

		var posicion_destino_logica := posicion_logica + (direccion * tamaño_casilla)
		var desplazamiento_lateral := int(round((posicion_destino_logica.x - posicion_inicial_x) / tamaño_casilla))
		if abs(desplazamiento_lateral) > limite_lateral_casillas:
			actualizar_idle()
			return
		
		raycast.target_position = direccion * (tamaño_casilla - 33)
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			actualizar_idle()
		else:
			if direccion == Vector2.UP:
				if (casillas_actuales + 1) > maximas_casillas_avanzadas:
					maximas_casillas_avanzadas = casillas_actuales + 1
					if puntaje:
						puntaje.text = str(maximas_casillas_avanzadas) + " / " + str(meta_casillas)

			dar_salto(direccion)

			if maximas_casillas_avanzadas >= meta_casillas:
				ganar()


func dar_salto(direccion: Vector2) -> void:
	if audio_salto:
		audio_salto.pitch_scale = randf_range(0.9, 1.2)
		audio_salto.play()

	se_esta_moviendo = true
	posicion_logica = posicion_logica + (direccion * tamaño_casilla)
	
	if tween_actual and tween_actual.is_running():
		tween_actual.kill()
	
	tween_actual = create_tween()
	tween_actual.tween_property(self, "position", posicion_logica, velocidad_movimiento).set_trans(Tween.TRANS_SINE)
	
	var tiempo_desbloqueo = velocidad_movimiento * 0.6
	get_tree().create_timer(tiempo_desbloqueo).timeout.connect(func(): se_esta_moviendo = false)
	
	await tween_actual.finished
	
	if not se_esta_moviendo:
		actualizar_idle()


func morir() -> void:
	if esta_muerto or ha_ganado: return
	
	esta_muerto = true
	se_esta_moviendo = true 
	anim.play("atropellado")

	if audio_muerte:
		audio_muerte.play()
	
	if tween_actual and tween_actual.is_running():
		tween_actual.kill()
		
	# MODO ENTRENAMIENTO: Abortamos la UI para no trabar a la IA
	if modo_entrenamiento:
		ai_controller.done = true
		return
	
	entorno_visual.adjustment_enabled = true
	Engine.time_scale = 0.3 
	
	var tween_color = create_tween()
	tween_color.set_ignore_time_scale(true)
	tween_color.tween_property(entorno_visual, "adjustment_saturation", 0.0, 1.5)
	
	print("¡Game Over!")
	calculo_dinero_final()
	get_tree().create_timer(1.5, true, false, true).timeout.connect(mostrar_pantalla_final)


func ganar() -> void:
	if ha_ganado or esta_muerto: return

	ha_ganado = true
	print("¡Llegaste a la tienda de repuestos!")
	
	# MODO ENTRENAMIENTO: Abortamos la UI para no trabar a la IA
	if modo_entrenamiento:
		ai_controller.done = true
		return
		
	calculo_dinero_final()
	get_tree().create_timer(1.2, true, false, true).timeout.connect(mostrar_pantalla_final)


func mostrar_pantalla_final() -> void:
	get_tree().paused = true
	var rendimiento: float = 1.0 if ha_ganado else clampf(float(maximas_casillas_avanzadas) / float(meta_casillas), 0.0, 1.0)
	var nivel_desempeno := DATOSGLOBALES.DESEMPENO_FALLIDO
	if ha_ganado:
		nivel_desempeno = DATOSGLOBALES.DESEMPENO_EXITOSO
	elif maximas_casillas_avanzadas >= int(meta_casillas * 0.65):
		nivel_desempeno = DATOSGLOBALES.DESEMPENO_ACEPTABLE
	DATOSGLOBALES.reportar_rendimiento_minijuego(
		rendimiento,
		dinero_obtenido,
		nivel_desempeno,
		"Busqueda de repuesto",
		"Progreso: %d/%d casillas." % [maximas_casillas_avanzadas, meta_casillas]
	)
	DATOSGLOBALES.volviendo_de_atencion = true
	var resumen := preload("res://Scenes/UI/ResumenAtencion.tscn").instantiate()
	resumen.layer = 100
	add_child(resumen)
	resumen.continuar.connect(_on_button_continuar_pressed)
	resumen.show()


func actualizar_idle() -> void:
	if ultima_direccion.x > 0:
		anim.play("idle_derecha")
	elif ultima_direccion.x < 0:
		anim.play("idle_izquierda")
	elif ultima_direccion.y < 0:
		anim.play("idle_arriba")
	else:
		anim.play("idle_abajo")


func _on_area_2d_area_entered(area: Area2D) -> void:
	if esta_muerto or ha_ganado:
		return

	if area.is_in_group("vehiculos"):
		atropellado = true
		z_index = 1
		
		if audio_atropello:
			audio_atropello.play()
			
		morir()


func calculo_dinero_final() -> void:
	if ha_ganado:
		dinero_obtenido = (maximas_casillas_avanzadas * valor_por_casilla) + bonus_meta
	else:
		dinero_obtenido = -penalizacion_fracaso


func _on_button_continuar_pressed() -> void:
	await get_tree().create_timer(0.15, true, false, true).timeout
	Engine.time_scale = 1.0
	get_tree().paused = false
	DATOSGLOBALES.sumar_dinero(dinero_obtenido)
	var destino := DATOSGLOBALES.obtener_destino_post_escena("res://Scenes/Gameplay/GameScreen.tscn")
	get_tree().change_scene_to_file(destino)
func reiniciar_entorno() -> void:
	# 1. Limpieza absoluta de estados físicos
	if tween_actual and tween_actual.is_running():
		tween_actual.kill()
		
	position = Vector2(posicion_inicial_x, posicion_inicial_y)
	posicion_logica = position
	accion_ia = 0
	
	# 2. Reseteo de contadores de la IA
	tiempo_restante = tiempo_limite
	maximas_casillas_avanzadas = 0
	casillas_historico_ia = 0
	
	# 3. Limpieza de estados críticos
	esta_muerto = false
	ha_ganado = false
	se_esta_moviendo = false
	atropellado = false
	juego_iniciado = true

	var generador := get_parent()
	if generador and generador.has_method("reiniciar_entorno_entrenamiento"):
		generador.reiniciar_entorno_entrenamiento()
	
	actualizar_idle()
