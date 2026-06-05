extends Control

@onready var barra = $AreaMovimiento
@onready var zona = $AreaMovimiento/ZonaVerde
@onready var indicador = $AreaMovimiento/Indicador

@onready var tiempo_label = $Tiempo

@onready var neumatico = $Neumatico

@onready var Tuerca1 = $Vidas/Tuerca1
@onready var Tuerca2 = $Vidas/Tuerca2
@onready var Tuerca3 = $Vidas/Tuerca3
@onready var Tuerca4 = $Vidas/Tuerca4

@onready var neumaticos_guardados = [
	$Neumaticos/Neumatico1,
	$Neumaticos/Neumatico2,
	$Neumaticos/Neumatico3,
	$Neumaticos/Neumatico4,
	$Neumaticos/Neumatico5,
	$Neumaticos/Neumatico6,
	$Neumaticos/Neumatico7,
	$Neumaticos/Neumatico8,
	$Neumaticos/Neumatico9,
	$Neumaticos/Neumatico10
]

# Movimiento
var velocidad = 650.0
var direccion = 1


# Progreso neumático actual
var nivel_inflado = 0
var golpes_para_inflar = 4


# Total neumáticos
var neumaticos_inflados = 0


# Tiempo
var tiempo_restante = 30.0


# Juego
var juego_terminado = false


# Vidas
var vidas = 4


# Dificultad
var ancho_minimo_zona = 60
var reduccion_zona = 30
var ancho_inicial_zona = 190       


func _ready():

	randomize()

	Tuerca1.play("Idle")
	Tuerca2.play("Idle")
	Tuerca3.play("Idle")
	Tuerca4.play("Idle")

	# OCULTAR NEUMATICOS DEL ESTANTE
	for neumatico_guardado in neumaticos_guardados:
		neumatico_guardado.visible = false

	# INICIO EN HORIZONTAL
	indicador.position.x = 0

	# TAMAÑO INICIAL ZONA
	zona.size.x = ancho_inicial_zona

	actualizar_tiempo()


func _process(delta):

	if juego_terminado:
		return

	tiempo_restante -= delta
	
		# AUMENTAR VELOCIDAD CON EL TIEMPO
	velocidad += delta * 5
	actualizar_tiempo()

	if tiempo_restante <= 0:
		tiempo_restante = 0
		juego_terminado = true
		return

	mover_indicador(delta)

	if Input.is_action_just_pressed("ui_accept"):
		evaluar_golpe()


func mover_indicador(delta):

	# MOVIMIENTO HORIZONTAL
	indicador.position.x += velocidad * direccion * delta

	# LIMITE DERECHO
	if indicador.position.x >= barra.size.x - indicador.size.x:

		indicador.position.x = barra.size.x - indicador.size.x
		direccion = -1

	# LIMITE IZQUIERDO
	if indicador.position.x <= 0:

		indicador.position.x = 0
		direccion = 1


func evaluar_golpe():

	# POSICION X DEL INDICADOR
	var centro_indicador = (
		indicador.position.x + indicador.size.x / 2
	)

	var inicio_zona = zona.position.x
	var final_zona = zona.position.x + zona.size.x

	var margen = 8

	var dentro = (
		centro_indicador >= inicio_zona - margen
		and centro_indicador <= final_zona + margen
	)

	if dentro:

		nivel_inflado += 1

		# CAMBIAR FRAME DEL NEUMATICO
		if nivel_inflado <= 3:
			neumatico.frame = nivel_inflado

		# MOVER ZONA VERDE
		cambiar_zona()

		# AUMENTAR DIFICULTAD
		velocidad += 15

		# COMPLETAR NEUMATICO
		if nivel_inflado >= 4:

			neumaticos_inflados += 1

			# MOSTRAR NEUMATICO EN EL ESTANTE
			if neumaticos_inflados <= neumaticos_guardados.size():

				neumaticos_guardados[
					neumaticos_inflados - 1
				].visible = true


			# DEJAR ULTIMO FRAME
			neumatico.frame = 3

			# REINICIO
			nivel_inflado = 0

			# REINICIAR TAMAÑO ZONA
			zona.size.x = ancho_inicial_zona

			# REINICIAR RUEDA
			neumatico.frame = 0

			await get_tree().create_timer(0.3).timeout

	else:

		vidas -= 1

		romper_tuerca()

		if vidas <= 0:
			juego_terminado = true


func cambiar_zona():

	# MOVER HORIZONTALMENTE
	var nueva_x = randf_range(
		0,
		barra.size.x - zona.size.x
	)

	zona.position.x = nueva_x

	# REDUCIR ANCHO
	var nuevo_ancho = zona.size.x - reduccion_zona

	nuevo_ancho = max(
		nuevo_ancho,
		ancho_minimo_zona
	)

	zona.size.x = nuevo_ancho


func actualizar_tiempo():

	tiempo_label.text = (
		"Tiempo: " + str(int(tiempo_restante))
	)


func romper_tuerca():

	if vidas == 3:
		Tuerca4.play("Romper")

	elif vidas == 2:
		Tuerca3.play("Romper")

	elif vidas == 1:
		Tuerca2.play("Romper")

	elif vidas <= 0:
		Tuerca1.play("Romper")
