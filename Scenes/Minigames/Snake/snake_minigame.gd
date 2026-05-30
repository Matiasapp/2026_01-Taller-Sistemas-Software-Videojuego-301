extends Node2D

@export var grid_size := 80
@export var board_size := 8

@onready var car := $Car
@onready var grid_debug := $GridDebug

var car_cell := Vector2i.ZERO

func _ready():
	randomize()
	car.z_index = 100
	spawn_car_random()


func _unhandled_input(event):
	var dir := Vector2i.ZERO

	if event.is_action_pressed("ui_up"):
		dir = Vector2i.UP
		car.rotation_degrees = -90
	elif event.is_action_pressed("ui_down"):
		dir = Vector2i.DOWN
		car.rotation_degrees = 90
	elif event.is_action_pressed("ui_left"):
		dir = Vector2i.LEFT
		car.rotation_degrees = 180
	elif event.is_action_pressed("ui_right"):
		dir = Vector2i.RIGHT
		car.rotation_degrees = 0

	if dir != Vector2i.ZERO:
		move_one_cell(dir)


func spawn_car_random():
	car_cell = Vector2i(
		randi_range(0, board_size - 1),
		randi_range(0, board_size - 1)
	)

	car.global_position = cell_to_world(car_cell)
	print("Spawn cell: ", car_cell, " Pos: ", car.global_position)


func move_one_cell(dir: Vector2i):
	var next_cell := car_cell + dir

	if not is_inside_board(next_cell):
		print("Fuera del tablero: ", next_cell)
		return

	car_cell = next_cell
	car.global_position = cell_to_world(car_cell)

	print("Car cell: ", car_cell, " Pos: ", car.global_position)

func cell_to_world(cell: Vector2i) -> Vector2:
	return grid_debug.global_position \
		+ Vector2(cell.x * grid_size, cell.y * grid_size) \
		+ Vector2(grid_size / 2, grid_size / 2)

func is_inside_board(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < board_size \
		and cell.y >= 0 and cell.y < board_size
