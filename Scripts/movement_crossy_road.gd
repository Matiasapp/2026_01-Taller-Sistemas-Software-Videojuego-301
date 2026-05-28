extends Node2D 

@export var tamaño_casilla = 64
@export var velocidad_movimiento = 0.15 
@onready var anim = $AnimatedSprite2D
@onready var genero = DATOSGLOBALES.genero_jugador

var frames_hombre = preload("res://Assets/Sprites/animaciones_hombre.tres")
var frames_mujer = preload("res://Assets/Sprites/animaciones_mujer.tres")

var se_esta_moviendo = false
var ultima_direccion = Vector2(0, 1) # Por defecto mirará hacia abajo

func _ready() -> void:
	if genero == "Masculino":
		anim.sprite_frames = frames_hombre
	else:
		anim.sprite_frames = frames_mujer
		
	# Iniciar con el personaje en su animación idle por defecto
	actualizar_idle()

func _unhandled_input(event: InputEvent) -> void:
	# Si ya se está moviendo, ignoramos cualquier otro botón
	if se_esta_moviendo:
		return
		
	var direccion = Vector2.ZERO
	
	# Detectamos la tecla y reproducimos la animación de salto correspondiente
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

	# Si se presionó una tecla válida, guardamos hacia dónde mira y saltamos
	if direccion != Vector2.ZERO:
		ultima_direccion = direccion
		dar_salto(direccion)

func dar_salto(direccion: Vector2) -> void:
	se_esta_moviendo = true
	
	# Calculamos la posición destino
	var posicion_destino = position + (direccion * tamaño_casilla)
	
	# Hacemos el movimiento suave con Tween
	var tween = create_tween()
	tween.tween_property(self, "position", posicion_destino, velocidad_movimiento).set_trans(Tween.TRANS_SINE)
	
	# Esperamos a que la animación de movimiento termine (el personaje "aterriza")
	await tween.finished
	
	# Devolvemos el control
	se_esta_moviendo = false
	
	# Aplicamos la animación idle correcta usando la última dirección guardada
	actualizar_idle()

# --- FUNCIONES DE AYUDA ---

func actualizar_idle() -> void:
	# Tu lógica exacta de direcciones para el estado idle
	if ultima_direccion.x > 0:
		anim.play("idle_derecha")
	elif ultima_direccion.x < 0:
		anim.play("idle_izquierda")
	elif ultima_direccion.y < 0:
		anim.play("idle_arriba")
	else:
		anim.play("idle_abajo")
