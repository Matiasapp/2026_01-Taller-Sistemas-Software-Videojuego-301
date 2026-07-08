extends CanvasLayer

@onready var estrellas = [
	$Reputacion/stars_1,
	$Reputacion/stars_2,
	$Reputacion/stars_3,
	$Reputacion/stars_4,
	$Reputacion/stars_5
]


var texturas = []

@onready var Contenido = [
	$MarginContainer/VBoxContainer/Dia_actual,
	$MarginContainer/VBoxContainer/Clientes_atendidos,
	$MarginContainer/VBoxContainer/Dinero,
	$MarginContainer/VBoxContainer/Ingresos_hoy,
	$MarginContainer/VBoxContainer/Gastos,
]
@onready var animacion = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	_on_dia_cambiado(DATOSGLOBALES.dia_actual)
	_on_dinero_cambiado(DATOSGLOBALES.dinero)
	actualizar_clientes_atendidos(CLIENTMANAGER.clientes_atendidos, CLIENTMANAGER.MAX_CLIENTES_DIA)
	_on_ingresos_dia(DATOSGLOBALES.ingresos_dia)
	_on_gastos_dia(DATOSGLOBALES.gastos_dia)
	
	DATOSGLOBALES.dinero_cambiado.connect(_on_dinero_cambiado)
	DATOSGLOBALES.dia_cambiado.connect(_on_dia_cambiado)
	DATOSGLOBALES.reputacion_cambiado.connect(actualizar_reputacion)
	
	DATOSGLOBALES.ingresos_dia_cambiado.connect(_on_ingresos_dia)
	DATOSGLOBALES.gastos_dia_cambiado.connect(_on_gastos_dia)
	
		# Se cargan las estrellas de reputacion
	texturas = [
		preload("res://Assets/Sprites/estrellas_reputacion/estrella_0%.png"),
		preload("res://Assets/Sprites/estrellas_reputacion/estrella_25%.png"),
		preload("res://Assets/Sprites/estrellas_reputacion/estrella_50%.png"),
		preload("res://Assets/Sprites/estrellas_reputacion/estrella_75%.png"),
		preload("res://Assets/Sprites/estrellas_reputacion/estrella_100%.png")
	]
	
	actualizar_reputacion()
	
	$Reputacion.visible = 0
	animacion.play("mostrar_texto")


func _on_dinero_cambiado(nuevo_dinero:int):
	Contenido[2].text = "Dinero: " + str(nuevo_dinero)

func _on_dia_cambiado(nuevo_dia:int):
	Contenido[0].text = "Dia actual: " + str(nuevo_dia)


func actualizar_clientes_atendidos(atendidos: int, total: int) -> void:
		Contenido[1].text = "Clientes atendidos: %d/%d" % [atendidos, total]

func _on_ingresos_dia(ingreso_d:int):
	Contenido[3].add_theme_color_override("font_color", Color(0,1,0))
	Contenido[3].text = "Ingreso: " + str(ingreso_d)


func _on_gastos_dia(gasto_d:int):
	Contenido[4].add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	Contenido[4].text = "Gastos: " + str(gasto_d)

func actualizar_reputacion():
	var reputacion = clamp(DATOSGLOBALES.reputacion, 0, 100)

	for i in range(5):
		var valor_estrella = reputacion - i * 20
		
		
		if valor_estrella <= 0:
			estrellas[i].texture = texturas[0] # vacía
		elif valor_estrella <= 5:
			estrellas[i].texture = texturas[1] # 25%
		elif valor_estrella <= 10:
			estrellas[i].texture = texturas[2] # 50%
		elif valor_estrella <= 15:
			estrellas[i].texture = texturas[3] # 75%
		else: # 16–20 o más
			estrellas[i].texture = texturas[4] # llena
