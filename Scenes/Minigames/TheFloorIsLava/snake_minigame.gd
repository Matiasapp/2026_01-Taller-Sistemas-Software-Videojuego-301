extends Node2D
#Grilla
@export var grid_size := 80
@export var board_size := 9
@export var move_interval := 0.35
@export var survival_time := 30.0

#Spawn rate
@export var lava_spawn_interval := 0.35
@export var lava_lifetime := 10.0
@export var lava_amount_per_wave := 1

#Dinero
@export var valor_por_segundo := 2
@export var bonus_victoria := 30
@export var penalizacion_derrota := 20


#Sprites
@export var burn_mark_scene: PackedScene
@onready var car := $Car
@onready var grid_debug := $GridDebug
@onready var move_timer := $MoveTimer
@onready var trail_container := $TrailContainer
@onready var death_particles := $Car/DeathParticles
@onready var car_sprite: AnimatedSprite2D = $Car/AnimatedSprite2D

#Tutorial
@onready var panel_tutorial := $CanvasLayer/Tutorial
@onready var panel_tutorial_interno := $CanvasLayer/Tutorial/PanelTutorial
@onready var label_parpadeo := $CanvasLayer/Tutorial/PanelTutorial/Comenzar

#Panel Final
@onready var panel_final := $CanvasLayer/Resumen
@onready var label_resultado_final := $CanvasLayer/Resumen/PanelFinal/PuntajeFinal
@onready var label_dinero_final := $CanvasLayer/Resumen/PanelFinal/DineroObtenido
@onready var boton_continuar := $CanvasLayer/Resumen/PanelFinal/Button

#Sfx
@onready var lava_spawn_sound := $LavaSpawnSound
@onready var fire_loop_sound := $FireLoopSound
@onready var turn_sound := $TurnSound
@onready var death_sound := $DeathSound
@onready var countdown_sound := $CountdownSound

#Musica
@onready var music_loop = $MusicLoop

var rapid_turn_count := 0
var last_turn_time := 0.0

var start_label: Label
var danger_label: Label
var time_label: Label

var car_cell := Vector2i.ZERO
var direction := Vector2i.RIGHT

var lava_cells := {}

var countdown_activo := false
var tutorial_can_start := false
var game_started := false
var tutorial_activo := true
var is_game_over := false
var has_won := false
var elapsed_time := 0.0
var dinero_obtenido := 0

var ultimo_segundo_anunciado := -1



func _ready() -> void:
	randomize()
	
	music_loop.play()

	create_start_label()
	create_danger_label()
	setup_time_label()

	time_label.visible = false
	danger_label.visible = false
	start_label.visible = false

	if panel_final:
		panel_final.hide()

	if boton_continuar:
		boton_continuar.pressed.connect(_on_boton_continuar_pressed)

	car_sprite.play("avanzar")

	move_timer.wait_time = move_interval
	move_timer.timeout.connect(_move_car)

	spawn_car_random()
	mostrar_tutorial()


func mostrar_tutorial() -> void:
	game_started = false
	tutorial_activo = true
	tutorial_can_start = false
	move_timer.stop()

	time_label.visible = false

	panel_tutorial.visible = true
	panel_tutorial.show()
	panel_tutorial.position = Vector2.ZERO
	panel_tutorial.size = get_viewport_rect().size
	panel_tutorial.z_index = 100

	panel_tutorial_interno.visible = true
	panel_tutorial_interno.show()
	panel_tutorial_interno.z_index = 101

	await get_tree().create_timer(0.35).timeout
	tutorial_can_start = true

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
	time_label.z_index = 198
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
	start_label.z_index = 200
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
	danger_label.z_index = 199
	danger_label.visible = false


func _process(delta: float) -> void:
	handle_direction_input()

	if tutorial_activo:
		if tutorial_can_start and direction_input_pressed():
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

		if remaining > 0 and remaining != ultimo_segundo_anunciado:
			ultimo_segundo_anunciado = remaining
			play_countdown_sound(0)
	else:
		danger_label.visible = false

	if elapsed_time >= survival_time and not is_game_over:
		win_game()
		return


func handle_direction_input() -> void:
	var changed := false

	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("mover_arriba"):
		direction = Vector2i.UP
		car.rotation_degrees = -90
		changed = true

	elif Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("mover_abajo"):
		direction = Vector2i.DOWN
		car.rotation_degrees = 90
		changed = true

	elif Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("mover_izquierda"):
		direction = Vector2i.LEFT
		car.rotation_degrees = 180
		changed = true

	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("mover_derecha"):
		direction = Vector2i.RIGHT
		car.rotation_degrees = 0
		changed = true

	if changed:
		var now := Time.get_ticks_msec() / 1000.0

		if now - last_turn_time < 0.25:
			rapid_turn_count += 1
		else:
			rapid_turn_count = 1

		last_turn_time = now

		if rapid_turn_count >= 3 and turn_sound:
			turn_sound.pitch_scale = randf_range(0.7, 1.1)
			turn_sound.volume_db = randf_range(-15.0, -10.0)
			turn_sound.play()

			rapid_turn_count = 0

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
	countdown_activo = true
	move_timer.stop()

	time_label.visible = false
	danger_label.visible = false

	if panel_tutorial:
		panel_tutorial.hide()

	start_label.visible = true

	start_label.text = "3"
	play_countdown_sound(0)

	await get_tree().create_timer(1.0).timeout
	if is_game_over or has_won or not countdown_activo:
		return

	start_label.text = "2"
	play_countdown_sound(0)

	await get_tree().create_timer(1.0).timeout
	if is_game_over or has_won or not countdown_activo:
		return

	start_label.text = "1"
	play_countdown_sound(0)

	await get_tree().create_timer(1.0).timeout
	if is_game_over or has_won or not countdown_activo:
		return

	start_label.text = "¡YA!"
	play_countdown_sound(12)

	await get_tree().create_timer(0.5).timeout
	if is_game_over or has_won or not countdown_activo:
		return

	start_label.visible = false
	time_label.visible = true

	elapsed_time = 0.0
	ultimo_segundo_anunciado = -1

	time_label.text = "Tiempo restante: %ds" % int(survival_time)

	if fire_loop_sound:
		fire_loop_sound.play()

	countdown_activo = false
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

	if lava_spawn_sound:
		lava_spawn_sound.pitch_scale = randf_range(0.85, 1.20)
		lava_spawn_sound.volume_db = randf_range(-2.0, 1.0)
		lava_spawn_sound.global_position = cell_to_world(cell)
		lava_spawn_sound.play()

	lava_sprite.play("spawn_lava")

	if cell == car_cell:
		game_over()
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
	var segundos_sobrevividos := int(elapsed_time)

	dinero_obtenido = segundos_sobrevividos * valor_por_segundo

	if has_won:
		dinero_obtenido += bonus_victoria
	elif is_game_over:
		dinero_obtenido -= penalizacion_derrota

	dinero_obtenido = max(0, dinero_obtenido)

	print("Dinero obtenido: $", dinero_obtenido)


func game_over() -> void:
	if is_game_over or has_won:
		return

	is_game_over = true
	has_won = false
	game_started = false
	countdown_activo = false

	move_timer.stop()
	car_sprite.stop()

	if fire_loop_sound:
		fire_loop_sound.stop()

	if death_sound:
		death_sound.pitch_scale = randf_range(0.95, 1.08)
		death_sound.play()

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
	start_label.text = "GAME OVER"

	mostrar_pantalla_final(false)

func win_game() -> void:
	if has_won or is_game_over:
		return

	has_won = true
	is_game_over = false
	game_started = false
	countdown_activo = false

	move_timer.stop()
	car_sprite.stop()

	time_label.text = "Tiempo restante: 0s"
	time_label.modulate = Color.GREEN
	danger_label.visible = false

	car.modulate = Color(0.731, 0.896, 1.0, 1.0)

	calcular_dinero_final()

	start_label.visible = true
	start_label.text = "¡GANASTE!"

	mostrar_pantalla_final(true)

func mostrar_pantalla_final(gano: bool) -> void:
	await get_tree().create_timer(1.0).timeout

	start_label.visible = false
	danger_label.visible = false
	time_label.visible = false

	panel_final.visible = true
	panel_final.show()
	panel_final.position = panel_tutorial.position
	panel_final.size = panel_tutorial.size
	panel_final.z_index = panel_tutorial.z_index + 10

	label_resultado_final.text = "¡GANASTE!" if gano else "GAME OVER"
	label_dinero_final.text = "Dinero obtenido: $" + str(dinero_obtenido)
		
func _on_boton_continuar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScreen.tscn")	
	
func play_countdown_sound(semitones := 0) -> void:
	if not countdown_sound:
		return

	countdown_sound.stream = preload("res://Assets/Audio/MinigameAudio/TheFloorIsLava/countdown.wav")
	countdown_sound.pitch_scale = pow(2.0, semitones / 12.0)
	countdown_sound.stop()
	countdown_sound.play()
