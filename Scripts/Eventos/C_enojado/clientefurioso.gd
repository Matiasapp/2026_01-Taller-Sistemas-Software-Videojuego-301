extends Node2D

@onready var AnimacionCliente = $SpriteCliente
@onready var Texto_cliente = preload("res://Scenes/Clientes/C_Enojado/Scenas/Texto_cliente_furioso.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	AnimacionCliente.play("ClienteMov")

func _process(delta: float) -> void:
	if Input.is_key_label_pressed(KEY_SPACE):
		get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScreen.tscn")
