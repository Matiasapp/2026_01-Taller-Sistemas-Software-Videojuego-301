extends Node2D
@onready var label_parpadeo = $Tutorial/PanelTutorial/Comenzar
func _ready() -> void:
	$Sprite2D.position = Vector2(600, 383)

	GlobalMusic.play_music(
		"res://Assets/Audio/MinigameAudio/Soldadura/soldaduraloop.ogg"
	)
	GlobalMusic.set_minigame_volume()

	if label_parpadeo:
		var tween_blink = create_tween().set_loops()
		tween_blink.tween_property(label_parpadeo, "modulate:a", 0.0, 0.6)
		tween_blink.tween_property(label_parpadeo, "modulate:a", 1.0, 0.6)

func _on_tutorial_gui_input(event: InputEvent) -> void:
	# Si el evento es un botón del ratón, es el clic izquierdo, y acaba de presionarse:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://Scenes/Minigames/Soldadura/Scene/Taller_soldadura.tscn")


func _on_panel_tutorial_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_tree().change_scene_to_file("res://Scenes/Minigames/Soldadura/Scene/Taller_soldadura.tscn")
