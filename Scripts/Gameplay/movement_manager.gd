extends CharacterBody2D

@export var walk_speed = 200
@export var run_speed = 350

@export var step_distance_walk := 72.0
@export var step_distance_run := 96.0

@onready var genero = DATOSGLOBALES.genero_jugador
@onready var anim = $AnimatedSprite2D
@onready var walk_sound: AudioStreamPlayer = $WalkSound
@onready var run_sound: AudioStreamPlayer = $RunSound

var frames_hombre = preload("res://Assets/Sprites/animaciones_hombre.tres")
var frames_mujer = preload("res://Assets/Sprites/animaciones_mujer.tres")

var ultima_direccion = Vector2(0, 1)
var distancia_acumulada := 0.0
var movimiento_habilitado := true


func _ready() -> void:
	if genero == "Masculino":
		anim.sprite_frames = frames_hombre
	else:
		anim.sprite_frames = frames_mujer


func _physics_process(delta):
	if not movimiento_habilitado:
		velocity = Vector2.ZERO
		return

	var input_direction = Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	
	var actual_speed = walk_speed
	var estado = "caminar"
	
	if Input.is_action_pressed("correr"):
		actual_speed = run_speed
		estado = "correr"
	
	velocity = input_direction * actual_speed
	move_and_slide()
	
	actualizar_animacion(input_direction, estado)
	actualizar_sonido_pasos(input_direction, estado, delta)


func set_movimiento_habilitado(habilitado: bool) -> void:
	movimiento_habilitado = habilitado
	if habilitado:
		return

	velocity = Vector2.ZERO
	distancia_acumulada = 0.0
	stop_movement_sounds()
	actualizar_animacion(Vector2.ZERO, "caminar")


func actualizar_animacion(input_direction: Vector2, estado: String) -> void:
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
		ultima_direccion = input_direction
		
		if input_direction.y < 0:
			anim.play(estado + "_arriba")
		elif input_direction.y > 0:
			anim.play(estado + "_abajo")
		elif input_direction.x > 0:
			anim.play(estado + "_derecha")
		elif input_direction.x < 0:
			anim.play(estado + "_izquierda")


func actualizar_sonido_pasos(input_direction: Vector2, estado: String, delta: float) -> void:
	if input_direction == Vector2.ZERO:
		stop_movement_sounds()
		return

	if estado == "correr":
		if walk_sound.playing:
			walk_sound.stop()

		if not run_sound.playing:
			run_sound.pitch_scale = 1.0
			run_sound.play()
	else:
		if run_sound.playing:
			run_sound.stop()

		if not walk_sound.playing:
			walk_sound.pitch_scale = 1.0
			walk_sound.play()


func stop_movement_sounds() -> void:
	if walk_sound and walk_sound.playing:
		walk_sound.stop()

	if run_sound and run_sound.playing:
		run_sound.stop()


func play_walk_step() -> void:
	if walk_sound and not walk_sound.playing:
		walk_sound.pitch_scale = 1.0
		walk_sound.play()


func play_run_step() -> void:
	if run_sound and not run_sound.playing:
		run_sound.pitch_scale = 1.0
		run_sound.play()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pausa"):
		SceneManager.pause_game(true)
