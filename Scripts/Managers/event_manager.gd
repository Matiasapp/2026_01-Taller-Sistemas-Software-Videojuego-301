extends Node

signal minigame_finished(exito: bool, monto: int)


func minigame_completed(exito: bool, monto: int) -> void:
	if exito:
		DATOSGLOBALES.sumar_dinero(monto)
	else:
		DATOSGLOBALES.restar_dinero(abs(monto))

	SERVICEMANAGER.completar_reparacion(exito, monto)
	minigame_finished.emit(exito, monto)

	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScreen.tscn")
