extends CanvasLayer

@onready var label_dia = $MarginContainer/VBoxContainer/HBoxContainer/LabelDia
@onready var label_hora = $MarginContainer/VBoxContainer/HBoxContainer/LabelHora
@onready var label_dinero = $MarginContainer/VBoxContainer/LabelDinero

func _ready() -> void:
	# 1. Actualizamos los textos al iniciar con los datos actuales
	actualizar_dinero(DATOSGLOBALES.dinero)
	actualizar_dia(DATOSGLOBALES.dia_actual)
	
	# 2. Conectamos las señales de los Autoloads a este script
	DATOSGLOBALES.dinero_cambiado.connect(actualizar_dinero)
	DATOSGLOBALES.dia_cambiado.connect(actualizar_dia)
	
	# Asegúrate de que TIEMPOMANAGER tenga la señal time_changed(hours, minutes)
	if TIEMPOMANAGER:
		TIEMPOMANAGER.time_changed.connect(actualizar_hora)

func actualizar_dinero(nuevo_monto: int) -> void:
	label_dinero.text = "$" + str(nuevo_monto)

func actualizar_dia(nuevo_dia: int) -> void:
	label_dia.text = "Día: " + str(nuevo_dia)

func actualizar_hora(horas: int, minutos: int) -> void:
	# Este formato "%02d" asegura que los números menores a 10 tengan un cero a la izquierda
	# Ejemplo: las 8:5 se verá como "08:05" en lugar de "8:5"
	var hora_formateada = "%02d:%02d" % [horas, minutos]
	label_hora.text = "Hora: " + hora_formateada
