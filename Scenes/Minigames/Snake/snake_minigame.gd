extends Node2D

@export var grid_size := 64
@export var move_interval := 0.12

@onready var car := $Car
@onready var move_timer := $MoveTimer
@export var burn_mark_scene: PackedScene
@onready var trail_container := $TrailContainer


var direction := Vector2.RIGHT


func _ready() -> void:
	move_timer.wait_time = move_interval
	move_timer.timeout.connect(_move_car)


func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("ui_up"):
		direction = Vector2.UP
		car.rotation_degrees = -90

	elif Input.is_action_just_pressed("ui_down"):
		direction = Vector2.DOWN
		car.rotation_degrees = 90

	elif Input.is_action_just_pressed("ui_left"):
		direction = Vector2.LEFT
		car.rotation_degrees = 180

	elif Input.is_action_just_pressed("ui_right"):
		direction = Vector2.RIGHT
		car.rotation_degrees = 0


func _move_car() -> void:
	var previous_position = car.position

	car.position += direction * grid_size

	var burn = burn_mark_scene.instantiate()
	trail_container.add_child(burn)

	burn.position = previous_position
	burn.rotation_degrees = car.rotation_degrees
	burn.scale *= randf_range(0.95, 1.05)
	burn.modulate.a = randf_range(0.75, 1.0)

	var burn_sprite: AnimatedSprite2D = burn.get_node("AnimatedSprite2D")
	burn_sprite.frame = randi() % 4
