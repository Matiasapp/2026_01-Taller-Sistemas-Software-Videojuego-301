extends Control
## Spinner circular dibujado por código (sin necesidad de assets).
## Se dibuja centrado dentro del nodo: si el Control no tiene tamaño (por ejemplo
## cuando se ancla a un punto) el centro coincide con su origen local.

@export var radio: float = 28.0
@export var grosor: float = 6.0
@export var velocidad: float = 5.0

var _angulo: float = 0.0


func _process(delta: float) -> void:
	_angulo += delta * velocidad
	queue_redraw()


func _draw() -> void:
	var centro := size * 0.5
	# Pista tenue de fondo (círculo completo).
	draw_arc(centro, radio, 0.0, TAU, 48, Color(1, 1, 1, 0.15), grosor, true)
	# Arco giratorio.
	draw_arc(centro, radio, _angulo, _angulo + TAU * 0.7, 48, Color(1, 1, 1, 0.9), grosor, true)
