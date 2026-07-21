extends Node2D

@export var float_distance := 2.0
@export var float_time := 0.7
@export var scale_amount := 0.003

var base_position := Vector2.ZERO
var base_scale := Vector2.ZERO

func _ready() -> void:
	base_position = position
	base_scale = scale

	var tween := create_tween()
	tween.set_loops()

	tween.tween_property(self, "position:y", base_position.y - float_distance, float_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(self, "scale", base_scale + Vector2(scale_amount, scale_amount), float_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(self, "position:y", base_position.y, float_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.parallel().tween_property(self, "scale", base_scale, float_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
