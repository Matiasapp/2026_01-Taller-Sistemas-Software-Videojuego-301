extends CanvasLayer

# =====================================================================
# RESUMEN DEL DÍA
# ---------------------------------------------------------------------
# Panel de cierre de jornada. Toda la interfaz vive en la escena
# (PantallaResumenDia.tscn); este script solo la rellena con los datos
# del día que acaba de terminar (DATOSGLOBALES.dia_actual) y gestiona el
# cierre. Comparte el estilo visual del terminal del PC.
# =====================================================================

signal cerrado

# Paleta del taller (misma que las pantallas de resultado de los minijuegos).
const COLOR_OK := Color(0.247, 0.729, 0.314)
const COLOR_MAL := Color(0.9, 0.35, 0.3)
const COLOR_TEXTO := Color(0.95, 0.93, 0.88)

var texturas_estrellas := [
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_res_0.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_res_25.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_res_50.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_res_75.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_res_100.png"),
	#estrellas color rojo
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_perdida_25%.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_perdida_50%.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_perdida_75%.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_perdida_100%.png"),
	#estrellas color verde
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_buena_25%.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_buena_50%.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_buena_75%.png"),
	preload("res://Assets/Sprites/estrellas_reputacion/estrella_buena_100%.png")	
]

@onready var root_panel: NinePatchRect = $Panel
@onready var titulo_label: Label = %Titulo
@onready var estado_label: Label = %Estado
@onready var clientes_value: Label = %ClientesValue
@onready var diagnosticos_value: Label = %DiagnosticoValue
@onready var balance_value: Label = %BalanceValue
@onready var dinero_value: Label = %CajaValue
@onready var reputacion_bar: ProgressBar = %ReputacionBar
@onready var reputacion_label: Label = %ReputacionLabel
@onready var eventos_label: RichTextLabel = %EventosLabel
@onready var estrellas: Array[TextureRect] = [
	%stars_1, %stars_2, %stars_3, %stars_4, %stars_5,
]


# ---------------------------------------------------------------------
# API pública: la llama game_screen para refrescar y mostrar el resumen.
# ---------------------------------------------------------------------
func mostrar_resumen() -> void:
	_refrescar()
	visible = true

	# Animación de entrada. El árbol está en pausa, pero este CanvasLayer
	# procesa siempre (process_mode ALWAYS), así que el tween avanza igual.
	root_panel.pivot_offset = root_panel.size / 2.0
	root_panel.modulate.a = 0.0
	root_panel.scale = Vector2(0.92, 0.92)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(root_panel, "modulate:a", 1.0, 0.22)
	tween.tween_property(root_panel, "scale", Vector2.ONE, 0.28) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_cerrar_pressed() -> void:
	visible = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	cerrado.emit()


# ---------------------------------------------------------------------
# Refresco de datos del día actual.
# ---------------------------------------------------------------------
func _refrescar() -> void:
	var dia: int = DATOSGLOBALES.dia_actual
	var stats: Dictionary = DATOSGLOBALES.get_estadistica_dia(dia)

	var rep: int = int(stats.get("reputacion", DATOSGLOBALES.reputacion))
	var correctos: int = int(stats.get("diagnosticos_correctos", 0))
	var incorrectos: int = int(stats.get("diagnosticos_incorrectos", 0))
	var balance: int = int(stats.get("balance", 0))

	titulo_label.text = "RESUMEN DEL DÍA %d" % dia
	estado_label.text = _estado_dia(stats, dia)

	clientes_value.text = "%d atendidos" % int(stats.get("clientes_atendidos", 0))
	diagnosticos_value.text = "%d bien / %d mal" % [correctos, incorrectos]
	balance_value.text = DATOSGLOBALES.formatear_monto(balance)
	balance_value.add_theme_color_override("font_color", COLOR_OK if balance >= 0 else COLOR_MAL)
	dinero_value.text = "$%d" % int(stats.get("dinero_final", DATOSGLOBALES.dinero))

	reputacion_bar.value = rep
	reputacion_label.text = "Reputación: %d/100" % rep
	_actualizar_estrellas(rep)

	_actualizar_eventos(stats.get("eventos", []))


func _actualizar_estrellas(reputacion: int) -> void:
	reputacion = clampi(reputacion, 0, 100)
	if reputacion <= 15:
		for i in range(estrellas.size()):
			var valor_estrella: int = reputacion - i * 20
			var idx: int
			if valor_estrella <= 0:
				idx = 0
			elif valor_estrella <= 5:
				idx = 5
			elif valor_estrella <= 10:
				idx = 6
			elif valor_estrella <= 15:
				idx = 7
			else:
				idx = 8
			estrellas[i].texture = texturas_estrellas[idx]
	elif reputacion >= 75:
		for i in range(estrellas.size()):
			var valor_estrella: int = reputacion - i * 20
			var idx: int
			if valor_estrella <= 0:
				idx = 0
			elif valor_estrella <= 5:
				idx = 9
			elif valor_estrella <= 10:
				idx = 10
			elif valor_estrella <= 15:
				idx = 11
			else:
				idx = 12
			estrellas[i].texture = texturas_estrellas[idx]
	else:
		for i in range(estrellas.size()):
			var valor_estrella: int = reputacion - i * 20
			var idx: int
			if valor_estrella <= 0:
				idx = 0
			elif valor_estrella <= 5:
				idx = 1
			elif valor_estrella <= 10:
				idx = 2
			elif valor_estrella <= 15:
				idx = 3
			else:
				idx = 4
			estrellas[i].texture = texturas_estrellas[idx]
	

func _actualizar_eventos(eventos: Array) -> void:
	if eventos.is_empty():
		eventos_label.text = "Sin eventos registrados."
		return

	var texto := ""
	var numero := 1
	for evento in eventos:
		if numero > 1:
			texto += "\n\n"
		texto += "%02d  %s" % [numero, str(evento)]
		numero += 1
	eventos_label.text = texto


func _estado_dia(stats: Dictionary, dia: int) -> String:
	var clientes: int = int(stats.get("clientes_atendidos", 0))
	var balance: int = int(stats.get("balance", 0))
	var incorrectos: int = int(stats.get("diagnosticos_incorrectos", 0))

	if clientes == 0:
		return "Jornada sin clientes atendidos"
	if incorrectos >= 2:
		return "Alerta de calidad · revisa tus diagnósticos"
	if balance < 0:
		return "Caja en rojo · jornada con pérdidas"
	return "Jornada cerrada con éxito · día %d" % dia
