extends Control

@onready var barra = $ProgressBar
@onready var psi_label = $LabelPSI
@onready var resultado = $Resultado
@onready var nivel_label = $NivelNeumatico

var presion = 0.0

var tiempo_estable = 0.0
var tiempo_objetivo = 3.0

var nivel_inflado = 0
var max_nivel = 3

var juego_terminado = false

func _ready():
	actualizar_nivel()


func _process(delta):

	if juego_terminado:
		return

	# Bombear aire
	if Input.is_action_just_pressed("ui_accept"):
		presion += 4

	# Aire baja lentamente
	presion -= 8 * delta

	# Limitar presión
	presion = clamp(presion, 0, 100)

	# Actualizar UI
	barra.value = presion
	psi_label.text = str(int(presion)) + " PSI"

	# Mantener presión correcta
	if presion >= 30 and presion <= 50 :

		tiempo_estable += delta

		var restante = snapped(tiempo_objetivo - tiempo_estable, 0.1)

		resultado.text = "MANTEN PRESION: " + str(restante)

		# Completa una fase
		if tiempo_estable >= tiempo_objetivo:

			tiempo_estable = 0
			nivel_inflado += 1

			actualizar_nivel()

			# Reinicia presión
			presion = 10

			# Victoria
			if nivel_inflado >= max_nivel:

				resultado.text = "NEUMATICO LISTO"
				juego_terminado = true

	else:
		tiempo_estable = 0

	# Explota
	if presion > 45:
		resultado.text = "EXPLOTO"
		juego_terminado = true


func actualizar_nivel():

	nivel_label.text = "Nivel Neumatico: " + str(nivel_inflado)
