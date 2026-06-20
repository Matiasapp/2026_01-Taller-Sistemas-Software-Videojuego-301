extends Node2D

func _ready():
	
	$Sprite2D.position = Vector2(600, 383)
	
	$Resumen/PanelFinal/LabelPiezas.text = "Piezas completadas: " + str(GLOBALSOLDADURA.piezas_completadas)

	$Resumen/PanelFinal/LabelDinero.text = "Dinero ganado: $" + str(GLOBALSOLDADURA.dinero)


func _on_boton_continuar_pressed() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	
	if GlobalMusic:
		GlobalMusic.stop_music()
	
	print("Volviendo al taller desde Soldadura")
	DATOSGLOBALES.sumar_dinero(GLOBALSOLDADURA.dinero)
	get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScreen.tscn")
