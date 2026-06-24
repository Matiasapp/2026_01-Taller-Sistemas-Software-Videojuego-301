extends CanvasLayer

@onready var Contenido = [
	$MarginContainer/VBoxContainer/Dia_actual,
	$MarginContainer/VBoxContainer/Clientes_atendidos,
	$MarginContainer/VBoxContainer/Porc_reputacion,
	$MarginContainer/VBoxContainer/Dinero,
	$MarginContainer/VBoxContainer/Ingresos_hoy,
	$MarginContainer/VBoxContainer/Gastos
]
@onready var animacion = $MarginContainer/VBoxContainer/AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	_on_dia_cambiado(DATOSGLOBALES.dia_actual)
	_on_dinero_cambiado(DATOSGLOBALES.dinero)
	_on_n_cliente_dia(DATOSGLOBALES.n_cliente_dia)
	_on_reputacion_cambiada(DATOSGLOBALES.reputacion)
	_on_ingresos_dia(DATOSGLOBALES.ingresos_dia)
	_on_gastos_dia(DATOSGLOBALES.gastos_dia)
	
	DATOSGLOBALES.dinero_cambiado.connect(_on_dinero_cambiado)
	DATOSGLOBALES.dia_cambiado.connect(_on_dia_cambiado)
	DATOSGLOBALES.reputacion_cambiado.connect(_on_reputacion_cambiada)
	DATOSGLOBALES.n_cliente_dia_cambiado.connect(_on_n_cliente_dia)
	DATOSGLOBALES.ingresos_dia_cambiado.connect(_on_ingresos_dia)
	DATOSGLOBALES.gastos_dia_cambiado.connect(_on_gastos_dia)
	
	animacion.play("MostrarTexto")
	

func _on_dinero_cambiado(nuevo_dinero:int):
	Contenido[3].text = "Dinero: " + str(nuevo_dinero)

func _on_dia_cambiado(nuevo_dia:int):
	Contenido[0].text = "Dia actual: " + str(nuevo_dia)

func _on_reputacion_cambiada(nueva_rep:int):
	Contenido[2].text = "Porcentaje de reputacion: " + str(nueva_rep)
	
func _on_n_cliente_dia(nuevo_clien:int):
	Contenido[1].text = "Numero de clientes atendidos: " + str(nuevo_clien)

func _on_ingresos_dia(ingreso_d:int):
	Contenido[4].text = "Ingreso: " + str(ingreso_d)

func _on_gastos_dia(gasto_d:int):
	Contenido[5].text = "Gastos: " + str(gasto_d)
