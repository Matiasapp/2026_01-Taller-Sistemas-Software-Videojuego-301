extends Node2D

func _ready():
	
	$Sprite2D.position = Vector2(600, 383)
	
	$LabelPiezas.text = "Piezas completadas: " + str(GlobalSoldadura.piezas_completadas)

	$LabelDinero.text = "Dinero ganado: $" + str(GlobalSoldadura.dinero)
