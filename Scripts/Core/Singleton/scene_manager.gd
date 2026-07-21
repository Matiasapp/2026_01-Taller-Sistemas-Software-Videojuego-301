extends Node

func pause_game(pause: bool):
	get_tree().paused = pause
	
	if pause:
		var canvas: CanvasLayer = get_tree().current_scene.get_node("MenuPausa")
		var pause_menu: Pause_menu = canvas.get_node("Pause_menu")

		pause_menu.abrir()
		
