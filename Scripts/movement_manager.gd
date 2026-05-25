extends CharacterBody2D

# Velocidad de movimiento
@export var walk_speed = 200
@export var run_speed = 350
@onready var genero = DATOSGLOBALES.genero_jugador
@onready var anim = $AnimatedSprite2D

var frames_hombre = preload("res://Assets/Sprites/animaciones_hombre.tres")
var frames_mujer = preload("res://Assets/Sprites/animaciones_mujer.tres")

# Variable para recordar hacia dónde miraba el personaje antes de detenerse
var ultima_direccion = Vector2(0, 1)

func _ready() -> void:
	if genero == "Masculino":
		anim.sprite_frames = frames_hombre
	else:
		anim.sprite_frames = frames_mujer
		
func _physics_process(delta):
	
	var input_direction = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	
	# 2. Lógica de movimiento
	var actual_speed = walk_speed
	var estado = "caminar"
	
	if Input.is_action_pressed("correr"):
		actual_speed = run_speed
		estado = "correr"
	
	velocity = input_direction * actual_speed
	
	move_and_slide()
	
	if input_direction == Vector2.ZERO:
		
		if ultima_direccion.x > 0:
			anim.play("idle_derecha")
		elif ultima_direccion.x < 0:
			anim.play("idle_izquierda")
		elif ultima_direccion.y < 0:
			anim.play("idle_arriba")
		else:
			anim.play("idle_abajo")
	else:
		# Estamos moviéndonos: guardamos la dirección actual
		ultima_direccion = input_direction
		
		# Reproducimos animación según la dirección de la entrada
		if input_direction.y < 0:
			anim.play(estado + "_arriba")
		elif input_direction.y > 0:
			anim.play(estado + "_abajo")
		elif input_direction.x > 0:
			anim.play(estado + "_derecha")
		elif input_direction.x < 0:
			anim.play(estado + "_izquierda")
