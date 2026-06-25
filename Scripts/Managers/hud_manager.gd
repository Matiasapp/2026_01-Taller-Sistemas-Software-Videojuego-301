extends CanvasLayer

@onready var label_dia = $MarginContainer/VBoxContainer/HBoxContainer/LabelDia
@onready var label_hora = $MarginContainer/VBoxContainer/HBoxContainer/LabelHora
@onready var label_dinero = $MarginContainer/VBoxContainer/LabelDinero

var dinero_anterior: int = 0

func _ready() -> void:
	# 1. Actualizamos los textos al iniciar con los datos actuales
	dinero_anterior = DATOSGLOBALES.dinero
	actualizar_dinero(DATOSGLOBALES.dinero)
	actualizar_dia(DATOSGLOBALES.dia_actual)

	# 2. Conectamos las señales de los Autoloads a este script
	DATOSGLOBALES.dinero_cambiado.connect(actualizar_dinero)
	DATOSGLOBALES.dia_cambiado.connect(actualizar_dia)

	# Asegúrate de que TIEMPOMANAGER tenga la señal time_changed(hours, minutes)
	if TIEMPOMANAGER:
		TIEMPOMANAGER.time_changed.connect(actualizar_hora)

func actualizar_dinero(nuevo_monto: int) -> void:
	# Cambio de dinero EN VIVO (mientras el HUD está presente): mostramos el delta.
	var delta := nuevo_monto - dinero_anterior
	dinero_anterior = nuevo_monto
	label_dinero.text = "$" + str(nuevo_monto)
	if delta != 0:
		mostrar_popup_dinero(delta)

## Muestra un texto flotante "+$X" (verde) / "-$X" (rojo) junto al dinero, que sube y se desvanece.
func mostrar_popup_dinero(delta: int) -> void:
	if delta == 0:
		return

	# Esperamos un frame para que el layout del HUD esté calculado (posición del label).
	await get_tree().process_frame

	var popup := Label.new()
	popup.text = ("+$%d" % delta) if delta > 0 else ("-$%d" % absi(delta))
	popup.add_theme_font_size_override("font_size", 30)
	popup.add_theme_color_override("font_color", Color(0.45, 1.0, 0.45) if delta > 0 else Color(1.0, 0.4, 0.4))
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	popup.add_theme_constant_override("outline_size", 6)
	add_child(popup)

	# El contador de dinero está abajo-derecha, así que el popup va ARRIBA de él
	# (a su derecha quedaría fuera de la pantalla).
	popup.global_position = label_dinero.global_position + Vector2(0.0, -46.0)

	var destino_y := popup.global_position.y - 40.0
	var tween := create_tween()
	tween.tween_property(popup, "global_position:y", destino_y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.0)
	tween.tween_callback(popup.queue_free)

func actualizar_dia(nuevo_dia: int) -> void:
	label_dia.text = "Día: " + str(nuevo_dia)

func actualizar_hora(horas: int, minutos: int) -> void:
	# Este formato "%02d" asegura que los números menores a 10 tengan un cero a la izquierda
	# Ejemplo: las 8:5 se verá como "08:05" en lugar de "8:5"
	var hora_formateada = "%02d:%02d" % [horas, minutos]
	label_hora.text = "Hora: " + hora_formateada
