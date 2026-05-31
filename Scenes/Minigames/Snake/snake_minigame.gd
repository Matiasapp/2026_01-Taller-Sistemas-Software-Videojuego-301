extends Node2D

@export var grid_size := 80
@export var board_size := 8
@export var move_interval := 0.3
@export var survival_time := 15.0
@export var burn_mark_scene: PackedScene

@onready var car := $Car
@onready var grid_debug := $GridDebug
@onready var move_timer := $MoveTimer
@onready var trail_container := $TrailContainer
@onready var death_particles := $Car/DeathParticles
@onready var car_sprite: AnimatedSprite2D = $Car/AnimatedSprite2D

var start_label: Label
var danger_label: Label
var time_label: Label

var car_cell := Vector2i.ZERO
var direction := Vector2i.RIGHT
var burned_cells := {}

var game_started := false
var is_game_over := false
var has_won := false
var elapsed_time := 0.0


func _ready() -> void:
	randomize()

	create_start_label()
	create_danger_label()
	setup_time_label()

	car_sprite.play("avanzar")

	move_timer.wait_time = move_interval
	move_timer.timeout.connect(_move_car)

	spawn_car_random()
	start_countdown()


func setup_time_label() -> void:
	time_label = Label.new()
	$CanvasLayer.add_child(time_label)

	time_label.position = Vector2(24, 20)
	time_label.size = Vector2(400, 60)

	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	time_label.text = "Tiempo restante: %ds" % int(survival_time)
	time_label.modulate = Color(1.0, 0.95, 0.8)

	time_label.add_theme_font_size_override("font_size", 28)
	time_label.add_theme_color_override("font_outline_color", Color.BLACK)
	time_label.add_theme_constant_override("outline_size", 3)

	time_label.z_index = 1000
	time_label.visible = true


func create_start_label() -> void:
	start_label = Label.new()
	$CanvasLayer.add_child(start_label)

	start_label.position = Vector2.ZERO
	start_label.size = get_viewport_rect().size
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_label.add_theme_font_size_override("font_size", 56)
	start_label.add_theme_color_override("font_outline_color", Color.BLACK)
	start_label.add_theme_constant_override("outline_size", 4)
	start_label.modulate = Color(1.0, 0.95, 0.8)
	start_label.z_index = 999
	start_label.visible = false


func create_danger_label() -> void:
	danger_label = Label.new()
	$CanvasLayer.add_child(danger_label)

	danger_label.position = Vector2.ZERO
	danger_label.size = get_viewport_rect().size
	danger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	danger_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	danger_label.add_theme_font_size_override("font_size", 96)
	danger_label.add_theme_color_override("font_outline_color", Color.BLACK)
	danger_label.add_theme_constant_override("outline_size", 5)
	danger_label.modulate = Color.RED
	danger_label.z_index = 998
	danger_label.visible = false


func _process(delta: float) -> void:
	if not game_started or is_game_over or has_won:
		return

	elapsed_time += delta

	var remaining := int(ceil(max(0.0, survival_time - elapsed_time)))

	time_label.text = "Tiempo: %ds" % remaining

	if remaining <= 3:
		danger_label.visible = true
		danger_label.text = str(remaining)
	else:
		danger_label.visible = false

	if elapsed_time >= survival_time:
		win_game()
		return

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


func start_countdown() -> void:
	game_started = false
	move_timer.stop()
	danger_label.visible = false

	start_label.visible = true
	start_label.text = "EL PISO ES LAVA"

	await get_tree().create_timer(1.0).timeout
	start_label.text = "3"

	await get_tree().create_timer(1.0).timeout
	start_label.text = "2"

	await get_tree().create_timer(1.0).timeout
	start_label.text = "1"

	await get_tree().create_timer(1.0).timeout
	start_label.text = "¡YA!"

	await get_tree().create_timer(0.5).timeout

	start_label.visible = false
	elapsed_time = 0.0
	time_label.text = "Tiempo: %ds" % int(survival_time)

	game_started = true
	move_timer.start()


func _move_car() -> void:
	if is_game_over or has_won:
		return

	var previous_cell := car_cell
	var next_cell := car_cell + direction

	if not is_inside_board(next_cell):
		game_over()
		return

	if burned_cells.has(next_cell):
		game_over()
		return

	car_cell = next_cell
	car.global_position = cell_to_world(car_cell)

	if not car_sprite.is_playing():
		car_sprite.play("avanzar")

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
		smoke.restart()
		smoke.emitting = true

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
	return cell.x >= 0 and cell.x < board_size and cell.y >= 0 and cell.y < board_size


func game_over() -> void:
	if is_game_over or has_won:
		return

	is_game_over = true
	game_started = false

	move_timer.stop()
	car_sprite.stop()

	time_label.text = "Tiempo: X"
	time_label.modulate = Color.RED
	danger_label.visible = false

	car.modulate = Color(1.0, 0.2, 0.1, 1.0)
	car.scale *= 1.15

	var tween := create_tween()
	tween.tween_property(car, "rotation_degrees", car.rotation_degrees + 15, 0.08)
	tween.tween_property(car, "rotation_degrees", car.rotation_degrees - 15, 0.08)
	tween.tween_property(car, "rotation_degrees", car.rotation_degrees, 0.08)

	death_particles.restart()
	death_particles.emitting = true

	start_label.visible = true
	start_label.text = "GAME OVER"


func win_game() -> void:
	if has_won or is_game_over:
		return

	has_won = true
	game_started = false

	move_timer.stop()
	car_sprite.stop()

	time_label.text = "Tiempo: 0s"
	time_label.modulate = Color.GREEN
	danger_label.visible = false

	car.modulate = Color(0.731, 0.896, 1.0, 1.0)

	start_label.visible = true
	start_label.text = "¡GANASTE!"
