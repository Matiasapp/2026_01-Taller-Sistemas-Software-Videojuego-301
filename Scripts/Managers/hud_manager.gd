extends CanvasLayer

@onready var label_dia = $MarginContainer/VBoxContainer/HBoxContainer/LabelDia
@onready var label_hora = $MarginContainer/VBoxContainer/HBoxContainer/LabelHora
@onready var label_dinero = $MarginContainer/VBoxContainer/LabelDinero
@onready var label_reputacion = $MarginContainer2/VBoxContainer/ProgressBar
func _ready() -> void:
	# 1. Actualizamos los textos al iniciar con los datos actuales
	actualizar_dinero(DATOSGLOBALES.dinero)
	actualizar_dia(DATOSGLOBALES.dia_actual)
	actualizar_reputacion(DATOSGLOBALES.reputacion)
	
	# 2. Conectamos las señales de los Autoloads a este script
	DATOSGLOBALES.dinero_cambiado.connect(actualizar_dinero)
	DATOSGLOBALES.dia_cambiado.connect(actualizar_dia)
	DATOSGLOBALES.reputacion_cambiado.connect(actualizar_reputacion)
	
	# Asegúrate de que TIEMPOMANAGER tenga la señal time_changed(hours, minutes)
	if TIEMPOMANAGER:
		TIEMPOMANAGER.time_changed.connect(actualizar_hora)

func actualizar_dinero(nuevo_monto: int) -> void:
	label_dinero.text = "$" + str(nuevo_monto)

func actualizar_dia(nuevo_dia: int) -> void:
	label_dia.text = "Día: " + str(nuevo_dia)

func actualizar_reputacion(nueva_reputacion:int):
	var bar_style_reputacion = StyleBoxFlat.new()
	
	# Cambiar color según rango de reputación
	if nueva_reputacion >= 0 and nueva_reputacion < 30:
		bar_style_reputacion.bg_color = Color(1.0, 0.0, 0.0, 1.0) # rojo
	elif nueva_reputacion >= 30 and nueva_reputacion < 70:
		bar_style_reputacion.bg_color = Color(1.0, 1.0, 0.0, 1.0) # amarillo
	else:
		bar_style_reputacion.bg_color = Color(0.0, 1.0, 0.0, 1.0) # verde

	# Aplicar el estilo al ProgressBar
	label_reputacion.add_theme_stylebox_override("fill", bar_style_reputacion)
	# Actualizar el valor de la barra
	label_reputacion.value = nueva_reputacion
	print(nueva_reputacion)

func actualizar_hora(horas: int, minutos: int) -> void:
	# Este formato "%02d" asegura que los números menores a 10 tengan un cero a la izquierda
	# Ejemplo: las 8:5 se verá como "08:05" en lugar de "8:5"
	var hora_formateada = "%02d:%02d" % [horas, minutos]
	label_hora.text = "Hora: " + hora_formateada
