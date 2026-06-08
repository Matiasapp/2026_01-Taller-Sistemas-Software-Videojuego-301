extends Node2D

func _ready():

	$LabelPiezas.text = "Piezas completadas: " + str(Global.piezas_completadas)

	$LabelDinero.text = "Dinero ganado: $" + str(Global.dinero)
