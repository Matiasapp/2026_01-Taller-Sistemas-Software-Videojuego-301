extends TextureRect

@export var move_amount := Vector2(18.0, 8.0)
@export var move_time := 6.0

var original_position: Vector2

func _ready() -> void:
	original_position = position

	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		self,
		"position",
		original_position + move_amount,
		move_time
	)

	tween.tween_property(
		self,
		"position",
		original_position - move_amount,
		move_time
	)
