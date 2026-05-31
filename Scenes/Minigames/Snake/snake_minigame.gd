extends Node2D

@export var grid_size := 80
@export var board_size := 8
@export var move_interval := 0.3

@export var burn_mark_scene: PackedScene

@onready var car := $Car
@onready var grid_debug := $GridDebug
@onready var move_timer := $MoveTimer
@onready var trail_container := $TrailContainer
@onready var death_particles := $Car/DeathParticles

var car_cell := Vector2i.ZERO
var direction := Vector2i.RIGHT
var burned_cells := {}


func _ready() -> void:
	randomize()

	move_timer.wait_time = move_interval
	move_timer.timeout.connect(_move_car)
	move_timer.start()

	spawn_car_random()


func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("ui_up") and direction != Vector2i.DOWN:
		direction = Vector2i.UP
		car.rotation_degrees = -90

	elif Input.is_action_just_pressed("ui_down") and direction != Vector2i.UP:
		direction = Vector2i.DOWN
		car.rotation_degrees = 90

	elif Input.is_action_just_pressed("ui_left") and direction != Vector2i.RIGHT:
		direction = Vector2i.LEFT
		car.rotation_degrees = 180

	elif Input.is_action_just_pressed("ui_right") and direction != Vector2i.LEFT:
		direction = Vector2i.RIGHT
		car.rotation_degrees = 0


func _move_car() -> void:

	var previous_cell := car_cell
	var next_cell := car_cell + direction

	# Sale del tablero
	if not is_inside_board(next_cell):
		game_over()
		return

	# Pisa fuego
	if burned_cells.has(next_cell):
		game_over()
		return

	# Mover auto
	car_cell = next_cell
	car.global_position = cell_to_world(car_cell)

	# Quemar casilla anterior
	spawn_burn(previous_cell)


func spawn_car_random() -> void:

	car_cell = Vector2i(
		randi_range(0, board_size - 1),
		randi_range(0, board_size - 1)
	)

	car.global_position = cell_to_world(car_cell)


func spawn_burn(cell: Vector2i) -> void:
	if burn_mark_scene == null:
		push_error("burn_mark_scene no asignado")
		return

	burned_cells[cell] = true

	var burn = burn_mark_scene.instantiate()
	trail_container.add_child(burn)

	burn.global_position = cell_to_world(cell)

	var smoke := burn.get_node_or_null("SmokeParticles") as GPUParticles2D

	if smoke:
		smoke.visible = true
		smoke.one_shot = false
		smoke.emitting = false
		smoke.restart()
		smoke.emitting = true
	else:
		print("No existe SmokeParticles")

	var burn_sprite: AnimatedSprite2D = burn.get_node("AnimatedSprite2D")
	burn_sprite.play("spawn_burn")

	burn_sprite.animation_finished.connect(func():
		if is_instance_valid(burn_sprite):
			burn_sprite.play("lava")
	, CONNECT_ONE_SHOT)


func cell_to_world(cell: Vector2i) -> Vector2:

	return grid_debug.global_position \
		+ Vector2(4, -4) \
		+ Vector2(cell) * grid_size \
		+ Vector2(grid_size * 0.5, grid_size * 0.5)


func is_inside_board(cell: Vector2i) -> bool:

	return (
		cell.x >= 0
		and cell.x < board_size
		and cell.y >= 0
		and cell.y < board_size
	)


func game_over() -> void:
	move_timer.stop()
	print("GAME OVER")

	car.modulate = Color(1.0, 0.2, 0.1, 1.0)
	car.scale *= 1.15

	var tween := create_tween()
	tween.tween_property(car, "rotation_degrees", car.rotation_degrees + 15, 0.08)
	tween.tween_property(car, "rotation_degrees", car.rotation_degrees - 15, 0.08)
	tween.tween_property(car, "rotation_degrees", car.rotation_degrees, 0.08)
	death_particles.restart()
	death_particles.emitting = true
