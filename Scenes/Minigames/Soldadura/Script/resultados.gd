extends Node2D

func _ready():
	
	$Sprite2D.position = Vector2(600, 383)
	
	$Resumen/PanelFinal/LabelPiezas.text = "Piezas completadas: " + str(GLOBALSOLDADURA.piezas_completadas)

	$Resumen/PanelFinal/LabelDinero.text = "Dinero ganado: $" + str(GLOBALSOLDADURA.dinero)

	if not $Resumen/PanelFinal/Button.pressed.is_connected(_on_button_pressed):
		$Resumen/PanelFinal/Button.pressed.connect(_on_button_pressed)


func _on_button_pressed():
	var exito: bool = GLOBALSOLDADURA.piezas_completadas > 0
	var monto: int = GLOBALSOLDADURA.dinero if exito else -30

	EVENTMANAGER.minigame_completed(exito, monto)
