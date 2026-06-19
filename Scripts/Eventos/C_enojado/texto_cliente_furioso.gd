extends Control

var texto = [
	" Necesito el auto para trabajar todos los días,
 y llevo semanas esperando una solución.
 Cada vez que vengo me hablan con términos técnicos
 que no entiendo, y mientras tanto sigo perdiendo tiempo y dinero.
 No me interesa la teoría, quiero resultados, quiero que el auto funcione
 y que me digan exactamente cuándo estará listo.",

" Yo no entiendo de mecánica, pero sí entiendo que el auto
no funciona como debería. Cada vez que lo traigo me hablan
de repuestos, de diagnósticos y de cosas que no sé ni pronunciar,
pero al final sigo con el mismo problema. Me siento impotente 
porque dependo de ustedes para que el vehículo ande, y lo único
que recibo son explicaciones confusas y cuentas cada vez más altas.",

" Miren, yo vine porque el auto hacía un ruido en la rueda,
 y ahora me dicen que es la transmisión, que hay que
 cambiar no sé cuántas cosas más. ¿Cómo esperan que
 yo entienda todo eso? Lo único que quiero es que me
 expliquen claramente qué tiene y que lo arreglen de una
 vez, porque cada explicación me deja con más dudas que certezas."
]

var current_text: int = 0
var rng = RandomNumberGenerator.new()

@onready var visual_text: Label = $Panel/RichTextLabel
@onready var mark: Control = $Panel/Control
@onready var animation_text: AnimationPlayer = $Panel/AnimationPlayer2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_text = rng.randf_range(0,texto.size() - 1)
	visual_text.visible_ratio = 0
	visual_text.text = texto[current_text]
	show_text()

func show_text():
	animation_text.play("MostrarTextoAnimado")
