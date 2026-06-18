extends Area2D

@onready var chispa: AnimatedSprite2D = $ChispaSprite
#Audio
@onready var welding_sound = $WeldingSound
var fade_tween: Tween

var pieza_actual = null

var marca = preload("res://Scenes/Minigames/Soldadura/Scene/Marca_soldadura.tscn")


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

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):

		chispa.play("encender")

		if welding_sound:

			if fade_tween:
				fade_tween.kill()

			welding_sound.volume_db = 0

			if not welding_sound.playing:
				welding_sound.play()

		if pieza_actual:
			crear_marca()

			if pieza_actual.has_method("soldar"):
				pieza_actual.soldar(delta)

	else:

		chispa.play("reposo")

		if welding_sound and welding_sound.playing:

			if fade_tween:
				fade_tween.kill()

			fade_tween = create_tween()
			fade_tween.tween_property(
				welding_sound,
				"volume_db",
				-40,
				0.15
			)

			await fade_tween.finished

			if welding_sound:
				welding_sound.stop()
				welding_sound.volume_db = 0
			
func _on_area_entered(area):
	print("Entré en area:", area.name, " grupos:", area.get_groups())

	if area.is_in_group("pieza"):
		pieza_actual = area
		print("Pieza actual asignada")

func _on_area_exited(area):
	if area == pieza_actual:
		pieza_actual = null
