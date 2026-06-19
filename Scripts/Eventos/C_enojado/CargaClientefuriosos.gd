extends Node2D

var rng = RandomNumberGenerator.new()

@onready var cliente_container = $ClienteContainer


var clientes_enojados = [
	preload("res://Scenes/Clientes/C_Enojado/Scenas/ClientesFuriosos/cliente_furioso_1.tscn"),
	preload("res://Scenes/Clientes/C_Enojado/Scenas/ClientesFuriosos/cliente_furioso_2.tscn"),
	preload("res://Scenes/Clientes/C_Enojado/Scenas/ClientesFuriosos/cliente_furioso_3.tscn"),
]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()
	var cliente = rng.randi_range(0,clientes_enojados.size()- 1)
	var cliente_enojado = clientes_enojados[cliente].instantiate()
	
	cliente_container.add_child(cliente_enojado)
