extends Node2D

@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready():
	anim.play("logo_float")
