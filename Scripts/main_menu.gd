extends Node2D
@onready var en_desarrollo = $en_desarrollo


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_new_game_pressed() -> void:
	#añadir sonido click
	print("Iniciando el nivel...")
	get_tree().change_scene_to_file("res://Scenes/GameScreen.tscn")

func _on_button_load_game_pressed() -> void:
	#añadir sonido click
	print("cargando el nivel...")
	en_desarrollo.popup_centered()


func _on_button_exit_pressed() -> void:
	get_tree().quit()


func _on_button_options_pressed() -> void:
	en_desarrollo.popup_centered()
