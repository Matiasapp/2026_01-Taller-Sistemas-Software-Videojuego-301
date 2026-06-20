extends Node2D

func _ready():
	
	$Sprite2D.position = Vector2(600, 383)
	
	$Resumen/PanelFinal/LabelPiezas.text = "Piezas completadas: " + str(GLOBALSOLDADURA.piezas_completadas)

	$Resumen/PanelFinal/LabelDinero.text = "Dinero ganado: $" + str(GLOBALSOLDADURA.dinero)


func _on_boton_continuar_pressed() -> void:
	Engine.time_scale = 0.8
	get_tree().paused = false
	
	print("Volviendo al taller desde Crossy Road")
	get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScreen.tscn")
