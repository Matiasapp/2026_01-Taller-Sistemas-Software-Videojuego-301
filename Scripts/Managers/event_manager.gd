extends Node

const EVENTO_ROBO_SCENE := "res://Scenes/Events/EventoRobo.tscn"

func intentar_evento_fin_dia() -> bool:
	if randf() <= 0.35:
		CARGADOR.cambiar_escena(EVENTO_ROBO_SCENE)
		return true
	
	return false
