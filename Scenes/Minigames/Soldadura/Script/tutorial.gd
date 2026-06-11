extends Node2D

func _ready() -> void:
	$Sprite2D.position = Vector2(600, 383)  


func _on_ir_a_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Minigames/Soldadura/Scene/Taller_soldadura.tscn")
