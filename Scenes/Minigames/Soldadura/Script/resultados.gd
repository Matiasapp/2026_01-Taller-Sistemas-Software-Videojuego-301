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
	var nivel_desempeno := DATOSGLOBALES.DESEMPENO_FALLIDO
	if GLOBALSOLDADURA.piezas_completadas >= 3:
		nivel_desempeno = DATOSGLOBALES.DESEMPENO_EXITOSO
	elif GLOBALSOLDADURA.piezas_completadas >= 1:
		nivel_desempeno = DATOSGLOBALES.DESEMPENO_ACEPTABLE
	DATOSGLOBALES.registrar_desempeno_minijuego(
		nivel_desempeno,
		"Soldadura",
		"Piezas completadas: %d." % GLOBALSOLDADURA.piezas_completadas
	)

	var destino := DATOSGLOBALES.obtener_destino_post_escena(
		"res://Scenes/Gameplay/GameScreen.tscn"
	)
	get_tree().change_scene_to_file(destino)

func _on_boton_continuar_mouse_entered() -> void:
	AUDIOMANAGER.play_ui_hover()
