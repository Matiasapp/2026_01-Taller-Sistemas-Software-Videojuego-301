extends Area2D

signal gota_perdida

@export var velocidad := 400.0


func _ready():

	add_to_group("gotas")


func _process(delta):

	position.y += velocidad * delta


func _on_visible_on_screen_notifier_2d_screen_exited():

	gota_perdida.emit()

	queue_free()
