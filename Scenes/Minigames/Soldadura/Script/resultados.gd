extends Node2D

func _ready():
	
	$Sprite2D.position = Vector2(600, 383)
	
	$Resumen/PanelFinal/LabelPiezas.text = "Piezas completadas: " + str(GLOBALSOLDADURA.piezas_completadas)

	$Resumen/PanelFinal/LabelDinero.text = "Dinero ganado: $" + str(GLOBALSOLDADURA.dinero)


func _on_boton_continuar_pressed() -> void:
	AUDIOMANAGER.play_ui_click()

	await get_tree().create_timer(0.15).timeout

	Engine.time_scale = 1.0
	get_tree().paused = false

	if GlobalMusic:
		GlobalMusic.stop_music()

	print("Volviendo al taller desde Soldadura")

	DATOSGLOBALES.sumar_dinero(GLOBALSOLDADURA.dinero)

	# Rendimiento: piezas completadas sobre lo que haría un jugador hábil en la ronda.
	var rendimiento: float = clampf(
		float(GLOBALSOLDADURA.piezas_completadas) / float(GLOBALSOLDADURA.PIEZAS_RENDIMIENTO_MAX),
		0.0, 1.0
	)
	DATOSGLOBALES.reportar_rendimiento_minijuego(rendimiento)

	get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScreen.tscn")

func _on_boton_continuar_mouse_entered() -> void:
	AUDIOMANAGER.play_ui_hover()
