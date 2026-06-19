extends CanvasLayer

@onready var animacion = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animacion.play("parpadeo")
	await animacion.animation_finished
	
	get_tree().change_scene_to_file("res://Scenes/Clientes/C_Enojado/Scenas/Escenario.tscn")

# Ubicacion del archivo que redirecciona a la pantalla principal
# "res://Scripts/Eventos/C_enojado/texto_cliente_furioso.gd"
