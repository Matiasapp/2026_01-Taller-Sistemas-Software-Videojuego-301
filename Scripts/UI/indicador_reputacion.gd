extends HBoxContainer

const TEXTURAS_ESTRELLAS: Array[Texture2D] = [
	preload("res://Assets/Sprites/estrellas_reputacion/estrellas_contorno_blanco/estrella_0.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrellas_contorno_blanco/estrella_25_.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrellas_contorno_blanco/estrella_50_.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrellas_contorno_blanco/estrella_75_.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrellas_contorno_blanco/estrella_100_.png"),
]

@onready var estrellas: Array[TextureRect] = [
	$Estrella1,
	$Estrella2,
	$Estrella3,
	$Estrella4,
	$Estrella5,
]

var _reputacion := 0


func _ready() -> void:
	_actualizar_texturas()


func set_reputacion(valor: int) -> void:
	_reputacion = clampi(valor, 0, 100)
	if is_node_ready():
		_actualizar_texturas()


func _actualizar_texturas() -> void:
	for i in range(estrellas.size()):
		var valor_estrella := _reputacion - i * 20
		var indice_textura := 0

		if valor_estrella > 15:
			indice_textura = 4
		elif valor_estrella > 10:
			indice_textura = 3
		elif valor_estrella > 5:
			indice_textura = 2
		elif valor_estrella > 0:
			indice_textura = 1

		estrellas[i].texture = TEXTURAS_ESTRELLAS[indice_textura]
