extends Node2D

@export var grid_size := 80
@export var board_size := 9
@export var move_interval := 0.35
@export var survival_time := 30.0

@export var lava_spawn_interval := 0.7
@export var lava_lifetime := 2.8
@export var lava_amount_per_wave := 2

@export var valor_por_segundo := 2
@export var bonus_victoria := 30
@export var penalizacion_derrota := 20

@export var burn_mark_scene: PackedScene

@onready var car := $Car
@onready var grid_debug := $GridDebug
@onready var move_timer := $MoveTimer
@onready var trail_container := $TrailContainer
@onready var death_particles := $Car/DeathParticles
@onready var car_sprite: AnimatedSprite2D = $Car/AnimatedSprite2D

@onready var panel_tutorial := $CanvasLayer/Tutorial
@onready var label_parpadeo := $CanvasLayer/Tutorial/PanelTutorial/Comenzar

var start_label: Label
var danger_label: Label
var time_label: Label

var car_cell := Vector2i.ZERO
var direction := Vector2i.RIGHT

var lava_cells := {}

var game_started := false
var tutorial_activo := true
var is_game_over := false
var has_won := false
var elapsed_time := 0.0
var dinero_obtenido := 0


func _ready() -> void:
	randomize()

	create_start_label()
	create_danger_label()
	setup_time_label()

	time_label.visible = false

	car_sprite.play("avanzar")

	move_timer.wait_time = move_interval
	move_timer.timeout.connect(_move_car)

	spawn_car_random()

	mostrar_tutorial()


func mostrar_tutorial() -> void:
	game_started = false
	tutorial_activo = true
	move_timer.stop()

	time_label.visible = false

	if panel_tutorial:
		panel_tutorial.show()
		panel_tutorial.visible = true
		panel_tutorial.z_index = 5000

		panel_tutorial.set_anchors_preset(Control.PRESET_FULL_RECT)
		panel_tutorial.call_deferred("set_position", Vector2.ZERO)
		panel_tutorial.call_deferred("set_size", get_viewport_rect().size)

	var panel_interno := $CanvasLayer/HUD/Tutorial/PanelTutorial
	if panel_interno:
		panel_interno.show()
		panel_interno.visible = true
		panel_interno.z_index = 5001

	if label_parpadeo:
		var tween_blink := create_tween().set_loops()
		tween_blink.tween_property(label_parpadeo, "modulate:a", 0.0, 0.6)
		tween_blink.tween_property(label_parpadeo, "modulate:a", 1.0, 0.6)

func setup_time_label() -> void:
	time_label = Label.new()
	$CanvasLayer.add_child(time_label)

	time_label.position = Vector2(24, 20)
	time_label.size = Vector2(450, 60)
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
	start_label.z_index = 9000
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

	handle_direction_input()

	if tutorial_activo:

		if direction_input_pressed():

			tutorial_activo = false

			if panel_tutorial:
				panel_tutorial.hide()

			start_countdown()

		return

	if not game_started or is_game_over or has_won:
		return

	elapsed_time += delta

	var remaining := int(ceil(max(0.0, survival_time - elapsed_time)))
	time_label.text = "Tiempo restante: %ds" % remaining

	if remaining <= 3:
		danger_label.visible = true
		danger_label.text = str(remaining)
	else:
		danger_label.visible = false

	if elapsed_time >= survival_time:
		win_game()
		return


func handle_direction_input() -> void:
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("mover_arriba"):
		direction = Vector2i.UP
		car.rotation_degrees = -90

	elif Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("mover_abajo"):
		direction = Vector2i.DOWN
		car.rotation_degrees = 90

	elif Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("mover_izquierda"):
		direction = Vector2i.LEFT
		car.rotation_degrees = 180

	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("mover_derecha"):
		direction = Vector2i.RIGHT
		car.rotation_degrees = 0


func direction_input_pressed() -> bool:
	return (
		Input.is_action_just_pressed("ui_up")
		or Input.is_action_just_pressed("ui_down")
		or Input.is_action_just_pressed("ui_left")
		or Input.is_action_just_pressed("ui_right")
		or Input.is_action_just_pressed("mover_arriba")
		or Input.is_action_just_pressed("mover_abajo")
		or Input.is_action_just_pressed("mover_izquierda")
		or Input.is_action_just_pressed("mover_derecha")
	)


func start_countdown() -> void:
	game_started = false
	move_timer.stop()

	if panel_tutorial:
		panel_tutorial.hide()
		panel_tutorial.visible = false
		panel_tutorial.mouse_filter = Control.MOUSE_FILTER_IGNORE

	time_label.visible = true
	danger_label.visible = false

	start_label.visible = true
	start_label.z_index = 9000
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
	time_label.text = "Tiempo restante: %ds" % int(survival_time)

	game_started = true
	move_timer.start()
	start_lava_loop()


func start_lava_loop() -> void:
	while game_started and not is_game_over and not has_won:
		spawn_lava_wave()
		await get_tree().create_timer(lava_spawn_interval).timeout


func spawn_lava_wave() -> void:
	for i in range(lava_amount_per_wave):
		spawn_random_lava()


func spawn_random_lava() -> void:
	if burn_mark_scene == null:
		push_error("burn_mark_scene no asignado")
		return

	var attempts := 0
	var cell := Vector2i.ZERO

	while attempts < 30:
		cell = Vector2i(
			randi_range(0, board_size - 1),
			randi_range(0, board_size - 1)
		)

		if cell != car_cell and not lava_cells.has(cell):
			break

		attempts += 1

	if attempts >= 30:
		return

	var lava = burn_mark_scene.instantiate()
	trail_container.add_child(lava)
	lava.global_position = cell_to_world(cell)

	var lava_sprite := lava.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if lava_sprite == null:
		return

	# Fase 1: aviso visual, NO mata
	lava_sprite.play("spawn_burn")

	await lava_sprite.animation_finished

	if is_game_over or has_won:
		if is_instance_valid(lava):
			lava.queue_free()
		return

	# Fase 2: lava inicial, YA mata
	lava_cells[cell] = true
	lava_sprite.play("spawn_lava")

	if cell == car_cell:
		game_over()
		return

	await lava_sprite.animation_finished

	if is_game_over or has_won:
		if is_instance_valid(lava):
			lava_cells.erase(cell)
			lava.queue_free()
		return

	# Fase 3: lava en loop, sigue matando
	lava_sprite.play("lava")

	var smoke := lava.get_node_or_null("SmokeParticles") as GPUParticles2D
	if smoke:
		smoke.restart()
		smoke.emitting = true

	await get_tree().create_timer(lava_lifetime).timeout

	if is_instance_valid(lava):
		lava_cells.erase(cell)
		lava.queue_free()


func _move_car() -> void:
	if is_game_over or has_won:
		return

	var next_cell := car_cell + direction

	if not is_inside_board(next_cell):
		game_over()
		return

	if lava_cells.has(next_cell):
		game_over()
		return

	car_cell = next_cell
	car.global_position = cell_to_world(car_cell)

	if not car_sprite.is_playing():
		car_sprite.play("avanzar")


func spawn_car_random() -> void:
	car_cell = Vector2i(
		randi_range(0, board_size - 1),
		randi_range(0, board_size - 1)
	)

	car.global_position = cell_to_world(car_cell)


func cell_to_world(cell: Vector2i) -> Vector2:
	return grid_debug.global_position \
		+ Vector2(4, -4) \
		+ Vector2(cell) * grid_size \
		+ Vector2(grid_size * 0.5, grid_size * 0.5)


func is_inside_board(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < board_size and cell.y >= 0 and cell.y < board_size


func calcular_dinero_final() -> void:
	dinero_obtenido = int(elapsed_time) * valor_por_segundo

	if has_won:
		dinero_obtenido += bonus_victoria
	else:
		dinero_obtenido = max(0, dinero_obtenido - penalizacion_derrota)

	DATOSGLOBALES.dinero += dinero_obtenido


func game_over() -> void:
	if is_game_over or has_won:
		return

	is_game_over = true
	game_started = false

	move_timer.stop()
	car_sprite.stop()

	time_label.text = "Tiempo restante: X"
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

	calcular_dinero_final()

	start_label.visible = true
	start_label.text = "GAME OVER\n+$" + str(dinero_obtenido)


func win_game() -> void:
	if has_won or is_game_over:
		return

	has_won = true
	game_started = false

	move_timer.stop()
	car_sprite.stop()

	time_label.text = "Tiempo restante: 0s"
	time_label.modulate = Color.GREEN
	danger_label.visible = false

	car.modulate = Color(0.731, 0.896, 1.0, 1.0)

	calcular_dinero_final()

	start_label.visible = true
	start_label.text = "¡GANASTE!\n+$" + str(dinero_obtenido)
