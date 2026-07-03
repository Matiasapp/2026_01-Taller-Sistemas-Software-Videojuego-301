extends Control
## Spinner circular dibujado por código (sin necesidad de assets).
## Se dibuja centrado en el origen local del nodo.

@export var radio: float = 28.0
@export var grosor: float = 6.0
@export var velocidad: float = 5.0

var _angulo: float = 0.0


func _process(delta: float) -> void:
	_angulo += delta * velocidad
	queue_redraw()


func _draw() -> void:
	# Pista tenue de fondo (círculo completo).
	draw_arc(Vector2.ZERO, radio, 0.0, TAU, 48, Color(1, 1, 1, 0.15), grosor, true)
	# Arco giratorio.
	draw_arc(Vector2.ZERO, radio, _angulo, _angulo + TAU * 0.7, 48, Color(1, 1, 1, 0.9), grosor, true)
