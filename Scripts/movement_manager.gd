extends CharacterBody2D

# Velocidad de movimiento del personaje (puedes ajustarla)
@export var walk_speed = 200
@export var run_speed = 350

@onready var anim = $AnimatedSprite2D
var ultima_direccion = Vector2(0, 1)

func _physics_process(delta):
	var input_direction = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	
	if input_direction != Vector2.ZERO:
		ultima_direccion = input_direction
	# --- Lógica para saber si camina o corre ---
	var actual_speed = walk_speed
	var estado = "caminar"
	
	if Input.is_action_pressed("correr"):
		actual_speed = run_speed
		estado = "correr"
	velocity = input_direction * actual_speed
	move_and_slide()
	
	if velocity.length() == 0:
		# Animaciones de Idle (reposo)
		if ultima_direccion.x > 0:
			anim.play("idle_derecha")
		elif ultima_direccion.x < 0:
			anim.play("idle_izquierda")
		elif ultima_direccion.y < 0:
			anim.play("idle_arriba")
		elif ultima_direccion.y > 0:
			anim.play("idle_abajo")

	else:
		if input_direction.y < 0:
			anim.play(estado + "_arriba")
		elif input_direction.y > 0:
			anim.play(estado + "_abajo")
		elif input_direction.x > 0:
			anim.play(estado + "_derecha")
		elif input_direction.x < 0:
			anim.play(estado + "_izquierda")
