extends Area2D

# Cambiamos las variables individuales por Listas (Arrays)
@export var texturas_derecha: Array[Texture2D]
@export var texturas_izquierda: Array[Texture2D]
@export var velocidad: float = 250.0

var direccion: int = 1
@onready var sprite = $Sprite2D

func _ready() -> void:
	# Verificamos que al menos haya una textura cargada
	if texturas_derecha.size() > 0:
		# Elegimos un "índice" al azar (ejemplo: 0 para el auto rojo, 1 para el azul)
		var indice_aleatorio = randi() % texturas_derecha.size()
		
		if direccion == 1:
			# Si vamos a la derecha, le ponemos la textura correspondiente a ese número
			sprite.texture = texturas_derecha[indice_aleatorio]
			
		elif direccion == -1:
			# Si vamos a la izquierda, revisamos si tenemos la textura izquierda para ese mismo número
			if texturas_izquierda.size() > indice_aleatorio and texturas_izquierda[indice_aleatorio] != null:
				sprite.texture = texturas_izquierda[indice_aleatorio]
			else:
				# PLAN B (Para tus autos): Si no le pusiste texturas izquierdas, 
				# usa la derecha elegida y la voltea
				sprite.texture = texturas_derecha[indice_aleatorio]
				sprite.flip_h = true

func _process(delta: float) -> void:
	# El movimiento constante
	position.x += velocidad * direccion * delta
	
	# La zona de autodestrucción
	# Si va hacia la derecha y pasa el límite derecho (750)
	if direccion == 1 and position.x > 650:
		queue_free()
		
	# Si va hacia la izquierda y pasa el límite izquierdo (-750)
	elif direccion == -1 and position.x < -650:
		queue_free()
