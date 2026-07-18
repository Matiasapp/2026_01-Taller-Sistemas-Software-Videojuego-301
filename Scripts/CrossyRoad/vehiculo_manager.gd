extends Area2D

@export var texturas_derecha: Array[Texture2D]
@export var texturas_izquierda: Array[Texture2D]
@export var velocidad: float = 250.0
@export var ancho_en_casillas: int = 2

@export var probabilidad_sonido: float = 0.25
@export var distancia_maxima_sonido: float = 500.0
@export var indice_policia: int = 7
@export var sonido_normal: AudioStream
@export var sonido_policia: AudioStream

var direccion: int = 1
var sonido_activado: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var audio_vocina: AudioStreamPlayer2D = get_node_or_null("AudioVocina")
@onready var jugador: Node2D = get_tree().get_first_node_in_group("jugador")

func _ready() -> void:
	add_to_group("vehiculos")
	# Selección aleatoria del vehículo
	if texturas_derecha.size() > 0:
		var indice_aleatorio = randi() % texturas_derecha.size()

		if direccion == 1:
			sprite.texture = texturas_derecha[indice_aleatorio]

		elif direccion == -1:
			if texturas_izquierda.size() > indice_aleatorio and texturas_izquierda[indice_aleatorio] != null:
				sprite.texture = texturas_izquierda[indice_aleatorio]
			else:
				sprite.texture = texturas_derecha[indice_aleatorio]
				sprite.flip_h = true

		# El Sprite2D nace con visible = false en la escena (para no mostrar una
		# textura por defecto antes de asignar la real). Ya tenemos una textura
		# válida, así que ahora sí lo mostramos. Sin esto los autos son
		# invisibles aunque colisionen (la colisión es un nodo aparte).
		sprite.visible = true

		# Sonido del vehículo
		if audio_vocina and randf() <= probabilidad_sonido:

			if indice_aleatorio == indice_policia:
				audio_vocina.stream = sonido_policia
			else:
				audio_vocina.stream = sonido_normal

			audio_vocina.pitch_scale = randf_range(1.00, 1.05)
			audio_vocina.play()

			sonido_activado = true

			print("Sonido vehiculo:", indice_aleatorio)

func _process(delta: float) -> void:
	position.x += velocidad * direccion * delta

	# Si el jugador murió, apagamos el audio y no hacemos nada más
	if jugador and "esta_muerto" in jugador and jugador.esta_muerto:
		detener_audio()

	elif sonido_activado and audio_vocina and jugador:
		var distancia = global_position.distance_to(jugador.global_position)

		if distancia > distancia_maxima_sonido:
			audio_vocina.stop()
		elif not audio_vocina.playing:
			audio_vocina.play()

	# La lógica de destrucción se mantiene igual
	if direccion == 1 and position.x > 650:
		queue_free()
	elif direccion == -1 and position.x < -650:
		queue_free()
func detener_audio() -> void:
	sonido_activado = false
	
	if audio_vocina:
		audio_vocina.stop()		
