extends Control

@onready var barra = $AreaMovimiento
@onready var zona = $AreaMovimiento/ZonaVerde
@onready var indicador = $AreaMovimiento/Indicador

@onready var resultado = $Resultado
@onready var nivel_label = $NivelNeumatico


# Movimiento
var velocidad = 350.0
var direccion = 1


# Progreso
var nivel_inflado = 0
var max_nivel = 5

var juego_terminado = false


# Dificultad
var ancho_minimo_zona = 45
var reduccion_zona = 10


func _ready():

	randomize()

	# Indicador inicia arriba
	indicador.position.y = 0

	actualizar_nivel()


func _process(delta):

	if juego_terminado:
		return

	mover_indicador(delta)

	if Input.is_action_just_pressed("ui_accept"):
		evaluar_golpe()


func mover_indicador(delta):

	indicador.position.y += velocidad * direccion * delta

	# Límite inferior
	if indicador.position.y >= barra.size.y - indicador.size.y:
		indicador.position.y = barra.size.y - indicador.size.y
		direccion = -1

	# Límite superior
	if indicador.position.y <= 0:
		indicador.position.y = 0
		direccion = 1


func evaluar_golpe():

	var centro_indicador = indicador.position.y

	var inicio_zona = zona.position.y
	var final_zona = zona.position.y + zona.size.y

	var margen = 8

	var dentro = (
		centro_indicador >= inicio_zona - margen
		and centro_indicador <= final_zona + margen
	)

	if dentro:

		nivel_inflado += 1

		resultado.text = "BIEN"

		actualizar_nivel()

		cambiar_zona()

		# Aumenta dificultad gradualmente
		velocidad += 20

		if nivel_inflado >= max_nivel:

			resultado.text = "NEUMATICO INFLADO"
			juego_terminado = true

	else:

		resultado.text = "FALLASTE"


func cambiar_zona():

	# Nueva posición aleatoria
	var nueva_y = randf_range(
		0,
		barra.size.y - zona.size.y
	)

	zona.position.y = nueva_y

	# Reducir tamaño zona
	var nuevo_alto = zona.size.y - reduccion_zona

	nuevo_alto = max(nuevo_alto, ancho_minimo_zona)

	zona.size.y = nuevo_alto


func actualizar_nivel():

	nivel_label.text = "Nivel: " + str(nivel_inflado)
