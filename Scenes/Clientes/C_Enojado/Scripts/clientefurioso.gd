extends Node2D

@onready var AnimacionCliente = $SpriteCliente


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AnimacionCliente.play("ClienteMov")
