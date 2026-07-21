extends Node2D 

@onready var valor_por_casilla: int = 2
@export var tamaño_casilla = 64
@export var velocidad_movimiento = 0.15 
@export var limite_retroceso: int = 3 
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
var maximas_casillas_avanzadas: int = 0

func _ready() -> void:
	if panel_tutorial:
		panel_tutorial.show()

		if label_parpadeo:
			var tween_blink = create_tween().set_loops()
			tween_blink.tween_property(label_parpadeo, "modulate:a", 0.0, 0.6)
			tween_blink.tween_property(label_parpadeo, "modulate:a", 1.0, 0.6)

	z_index = 2
	entorno_visual.adjustment_saturation = 1.0
	Engine.time_scale = 1.0

	if genero == "Masculino":
		anim.sprite_frames = frames_hombre
	else:
		anim.sprite_frames = frames_mujer

	tiempo_restante = tiempo_limite
	posicion_logica = position
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
	if se_esta_moviendo or esta_muerto or ha_ganado:
		return
		
	if not juego_iniciado:
		if event.is_action_pressed("mover_arriba") or event.is_action_pressed("mover_abajo") or event.is_action_pressed("mover_izquierda") or event.is_action_pressed("mover_derecha"):
			juego_iniciado = true
			if panel_tutorial:
				panel_tutorial.hide()

	var direccion = Vector2.ZERO
	var casillas_actuales = int((posicion_inicial_y - posicion_logica.y) / tamaño_casilla)
	
	if event.is_action_pressed("mover_arriba"):
		direccion = Vector2.UP
		anim.play("saltar_arriba")
			
	elif event.is_action_pressed("mover_abajo"):
		var casilla_destino = casillas_actuales - 1
		var casilla_minima_permitida = maximas_casillas_avanzadas - limite_retroceso
		
		if casilla_destino >= casilla_minima_permitida:
			direccion = Vector2.DOWN
			anim.play("saltar_abajo")
		else:
			print("¡Límite de retroceso! No puedes volver más de ", limite_retroceso, " casillas.")
			
	elif event.is_action_pressed("mover_izquierda"):
		direccion = Vector2.LEFT
		anim.play("saltar_izquierda")
	elif event.is_action_pressed("mover_derecha"):
		direccion = Vector2.RIGHT
		anim.play("saltar_derecha")

	if direccion != Vector2.ZERO:
		ultima_direccion = direccion
		
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
	calculo_dinero_final()
	get_tree().create_timer(1.2, true, false, true).timeout.connect(mostrar_pantalla_final)


func mostrar_pantalla_final() -> void:
	# 1. Usar pausa nativa en lugar de time_scale = 0.0 para no romper el panel
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
	# 2. Forzar esta variable para que el panel NO se autodestruya al nacer
	DATOSGLOBALES.volviendo_de_atencion = true
	# 3. Instanciamos el nuevo panel
	var resumen := preload("res://Scenes/UI/ResumenAtencion.tscn").instantiate()
	# 4. Lo ponemos en una capa altísima para que nada lo tape
	resumen.layer = 100
	# Lo agregamos a la escena
	add_child(resumen)
	# CONEXIÓN: unimos la señal "continuar" a nuestra función de regreso
	resumen.continuar.connect(_on_button_continuar_pressed)
	
	# Nos aseguramos de que sea visible (por si le habías puesto hide() en su _ready)
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
	# Esta función se ejecutará automáticamente cuando el usuario pulse "Continuar" 
	# en la escena de ResumenAtencion.

	# El timer ignorará la escala de tiempo (argumento final = true)
	await get_tree().create_timer(0.15, true, false, true).timeout
	
	Engine.time_scale = 1.0
	get_tree().paused = false
	
	DATOSGLOBALES.sumar_dinero(dinero_obtenido)

	print("Volviendo al taller desde Crossy Road. Dinero obtenido: $", dinero_obtenido)
	var destino := DATOSGLOBALES.obtener_destino_post_escena(
		"res://Scenes/Gameplay/GameScreen.tscn"
	)
	CARGADOR.cambiar_escena(destino)
