extends Area2D

@onready var chispa: AnimatedSprite2D = $ChispaSprite

var pieza_actual = null

var marca = preload("res://minijuego soldadura/Scene/Marca_soldadura.tscn")


func crear_marca():

	var nueva_marca = marca.instantiate()

	get_parent().add_child(nueva_marca)

	nueva_marca.global_position = global_position

func _ready():
	chispa.play("reposo")

	connect("area_entered", _on_area_entered)
	connect("area_exited", _on_area_exited)

func _process(delta):
	global_position = get_global_mouse_position()

	if pieza_actual and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		crear_marca()
		chispa.play("encender")

		if pieza_actual.has_method("soldar"):
			pieza_actual.soldar(delta)
			
	else:
		chispa.play("reposo")

func _on_area_entered(area):
	if area.is_in_group("pieza"):
		pieza_actual = area

func _on_area_exited(area):
	if area == pieza_actual:
		pieza_actual = null
