extends Control
class_name Pause_menu


func _on_continuar_pressed() -> void:
	self.visible = false
	SceneManager.pause_game(false)


func _on_salir_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
