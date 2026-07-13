extends Node2D

@onready var resumen = $ResumenAtencion

func _ready():
	$Sprite2D.position = Vector2(600, 383)
	
	# Calculamos el rendimiento
	var rendimiento: float = clampf(
		float(GLOBALSOLDADURA.piezas_completadas) / float(GLOBALSOLDADURA.PIEZAS_RENDIMIENTO_MAX),
		0.0, 1.0
	)
	
	# Reportamos a los datos globales
	DATOSGLOBALES.reportar_rendimiento_minijuego(rendimiento, GLOBALSOLDADURA.dinero)
	
	# Avisamos que venimos de una atención
	DATOSGLOBALES.volviendo_de_atencion = true
	
	# Mostramos el panel usando su función propia
	resumen.layer = 100
	resumen.activar_panel()
	
	# CONEXIÓN: unimos la señal (verificando que no esté conectada ya)
	if not resumen.continuar.is_connected(_on_boton_continuar_pressed):
		resumen.continuar.connect(_on_boton_continuar_pressed)


func _on_boton_continuar_pressed() -> void:
	AUDIOMANAGER.play_ui_click()

	await get_tree().create_timer(0.15, true, false, true).timeout

	Engine.time_scale = 1.0
	get_tree().paused = false

	if GlobalMusic:
		GlobalMusic.stop_music()

	print("Volviendo al taller desde Soldadura. Dinero ganado: $", GLOBALSOLDADURA.dinero)

	DATOSGLOBALES.sumar_dinero(GLOBALSOLDADURA.dinero)

	get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScreen.tscn")
