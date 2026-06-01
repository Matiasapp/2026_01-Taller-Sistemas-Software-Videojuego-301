extends Node2D 

@export var tamaño_casilla = 64
@export var velocidad_movimiento = 0.15 
@onready var anim = $AnimatedSprite2D
@onready var genero = DATOSGLOBALES.genero_jugador
@onready var entorno_visual = $WorldEnvironment.environment
@onready var raycast = $RayCast2D

var frames_hombre = preload("res://Assets/Sprites/animaciones_hombre.tres")
var frames_mujer = preload("res://Assets/Sprites/animaciones_mujer.tres")
var esta_muerto = false 
var se_esta_moviendo = false
var ultima_direccion = Vector2(0, 1)

var posicion_logica: Vector2 
var tween_actual: Tween 

func _ready() -> void:
	z_index = 2
	entorno_visual.adjustment_saturation = 1.0
	Engine.time_scale = 1.0
	if genero == "Masculino":
		anim.sprite_frames = frames_hombre
	else:
		anim.sprite_frames = frames_mujer
		
	posicion_logica = position
	actualizar_idle()
	
	# Conexión por código: Conecta la señal del hijo Area2D a la función de muerte
	# (Asegúrate de que tu nodo hijo Area2D se llame exactamente "Hitbox")

func _unhandled_input(event: InputEvent) -> void:
	if se_esta_moviendo:
		return
	if esta_muerto:
		return
		
	var direccion = Vector2.ZERO
	
	if event.is_action_pressed("mover_arriba"):
		direccion = Vector2.UP
		anim.play("saltar_arriba")
	elif event.is_action_pressed("mover_abajo"):
		direccion = Vector2.DOWN
		anim.play("saltar_abajo")
	elif event.is_action_pressed("mover_izquierda"):
		direccion = Vector2.LEFT
		anim.play("saltar_izquierda")
	elif event.is_action_pressed("mover_derecha"):
		direccion = Vector2.RIGHT
		anim.play("saltar_derecha")

	if direccion != Vector2.ZERO:
		ultima_direccion = direccion
		
		# --- NUEVO: SISTEMA DE COLISIÓN CON ÁRBOLES ---
		
		# 1. Apuntamos el láser hacia la casilla a la que queremos ir
		raycast.target_position = direccion * (tamaño_casilla-50)
		
		# 2. Forzamos a Godot a actualizar la física del láser en este milisegundo
		raycast.force_raycast_update()
		
		# 3. Preguntamos: ¿El láser tocó algo en la Capa 2 (un árbol)?
		if raycast.is_colliding():
			# Hay un árbol. No saltamos, pero actualizamos la animación idle 
			# para que el personaje se gire y "mire" la pared/árbol.
			actualizar_idle()
		else:
			# El camino está libre, procedemos a dar el salto
			dar_salto(direccion)

func dar_salto(direccion: Vector2) -> void:
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

# --- DETECCIÓN DE ATROPELLO ---

func morir() -> void:
	# Bloqueamos controles inmediatamente
	esta_muerto = true
	se_esta_moviendo = true 
	anim.play("atropellado")
	# Si nos atropellan a mitad de un salto, congelamos la posición visual
	if tween_actual and tween_actual.is_running():
		tween_actual.kill()
		
	print("¡Game Over! Te atropellaron.")
	
	# ARREGLO 1: Forzamos que los ajustes de color estén encendidos
	entorno_visual.adjustment_enabled = true
	
	# Activamos la cámara lenta para el juego
	Engine.time_scale = 0.3
	
	var tween_color = create_tween()
	# ARREGLO 2: Le decimos al Tween que se anime en "tiempo real" ignorando el slow-motion
	tween_color.set_ignore_time_scale(true)
	tween_color.tween_property(entorno_visual, "adjustment_saturation", 0.0, 1.5)
	
	# ARREGLO 3: Le pasamos 'true' al final del Timer para que también ignore el slow-motion
	# Parámetros: (tiempo, process_always, process_in_physics, ignore_time_scale)
	get_tree().create_timer(1.5, true, false, true).timeout.connect(func(): get_tree().reload_current_scene())
# --- FUNCIONES DE AYUDA ---

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
		# En el instante en que cualquier Area2D toque a nuestra Hitbox, 
	# comprobamos si tiene la etiqueta "vehiculos"
	if area.is_in_group("vehiculos"):
		z_index = 1
		morir()
	print("¡Algo me acaba de tocar! Se llama: ", area.name)
