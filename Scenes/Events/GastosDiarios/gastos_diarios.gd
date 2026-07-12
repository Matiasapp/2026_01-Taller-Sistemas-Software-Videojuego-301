extends Control

const ESCENA_SIGUIENTE := "res://Scenes/Events/TransicionDia/transicion_dia.tscn"
const COLOR_OK := Color(0.247, 0.729, 0.314)
const COLOR_ALERTA := Color(0.9, 0.35, 0.3)
const GASTOS: Array[Dictionary] = [
	{
		"nombre": "Arriendo del taller",
		"detalle": "Mantiene el local disponible para la próxima jornada.",
		"base": 110,
		"aumento": 10,
		"penalizacion": 12,
	},
	{
		"nombre": "Luz y servicios",
		"detalle": "Electricidad, agua y herramientas conectadas.",
		"base": 55,
		"aumento": 5,
		"penalizacion": 7,
	},
	{
		"nombre": "Comida",
		"detalle": "Algo caliente para recuperar fuerzas.",
		"base": 45,
		"aumento": 5,
		"penalizacion": 5,
	},
]

@onready var titulo: Label = %Titulo
@onready var caja_label: Label = %CajaLabel
@onready var total_label: Label = %TotalLabel
@onready var saldo_label: Label = %SaldoLabel
@onready var consecuencia_label: Label = %ConsecuenciaLabel
@onready var confirmar_button: Button = %ConfirmarButton
@onready var sello: Label = %Sello
@onready var fade_rect: ColorRect = %FadeRect

@onready var checks: Array[CheckButton] = [
	%ArriendoCheck,
	%ServiciosCheck,
	%ComidaCheck,
]
@onready var precios: Array[Label] = [
	%ArriendoPrecio,
	%ServiciosPrecio,
	%ComidaPrecio,
]

var dia_cerrado: int
var costos: Array[int] = []
var procesando := false


func _ready() -> void:
	dia_cerrado = maxi(1, DATOSGLOBALES.dia_actual - 1)
	titulo.text = "CIERRE DE CAJA  ·  DÍA %d" % dia_cerrado
	caja_label.text = "Caja disponible:  $%d" % DATOSGLOBALES.dinero

	for i in range(GASTOS.size()):
		var costo := int(GASTOS[i]["base"]) + int(GASTOS[i]["aumento"]) * (dia_cerrado - 1)
		costos.append(costo)
		precios[i].text = "$%d" % costo
		checks[i].button_pressed = true
		checks[i].toggled.connect(_on_gasto_toggled)
		checks[i].mouse_entered.connect(AUDIOMANAGER.play_ui_hover)

	confirmar_button.pressed.connect(_on_confirmar_pressed)
	confirmar_button.mouse_entered.connect(_on_confirmar_mouse_entered)
	_actualizar_resumen()

	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func _on_gasto_toggled(_activo: bool) -> void:
	if procesando:
		return
	AUDIOMANAGER.play_ui_click()
	_actualizar_resumen()


func _actualizar_resumen() -> void:
	var total := 0
	var penalizacion := 0
	var postergados := 0

	for i in range(checks.size()):
		if checks[i].button_pressed:
			checks[i].text = "PAGAR"
			total += costos[i]
		else:
			checks[i].text = "POSTERGAR"
			penalizacion += int(GASTOS[i]["penalizacion"])
			postergados += 1

	var saldo := DATOSGLOBALES.dinero - total
	total_label.text = "TOTAL A PAGAR:  $%d" % total
	saldo_label.text = "SALDO PARA MAÑANA:  $%d" % saldo
	saldo_label.add_theme_color_override("font_color", COLOR_OK if saldo >= 0 else COLOR_ALERTA)

	if saldo < 0:
		consecuencia_label.text = "No alcanza la caja. Posterga uno o más pagos para continuar."
		consecuencia_label.add_theme_color_override("font_color", COLOR_ALERTA)
		confirmar_button.disabled = true
	elif postergados > 0:
		consecuencia_label.text = "Pagos postergados: %d  ·  Reputación: -%d" % [postergados, penalizacion]
		consecuencia_label.add_theme_color_override("font_color", COLOR_ALERTA)
		confirmar_button.disabled = false
	else:
		consecuencia_label.text = "Todas las obligaciones quedarán cubiertas."
		consecuencia_label.add_theme_color_override("font_color", COLOR_OK)
		confirmar_button.disabled = false


func _on_confirmar_pressed() -> void:
	if procesando or confirmar_button.disabled:
		return

	procesando = true
	confirmar_button.disabled = true
	AUDIOMANAGER.play_ui_click()

	var pagados: Array[String] = []
	var postergados: Array[String] = []
	var total := 0
	var penalizacion := 0

	for i in range(checks.size()):
		var nombre := str(GASTOS[i]["nombre"])
		if checks[i].button_pressed:
			pagados.append(nombre)
			total += costos[i]
		else:
			postergados.append(nombre)
			penalizacion += int(GASTOS[i]["penalizacion"])

	DATOSGLOBALES.registrar_gastos_diarios(
		dia_cerrado, pagados, postergados, total, penalizacion
	)
	PARTIDA.guardar()

	sello.visible = true
	sello.text = "REGISTRADO\n-$%d" % total
	sello.scale = Vector2(1.6, 1.6)
	sello.modulate.a = 0.0
	var sello_tween := create_tween().set_parallel(true)
	sello_tween.tween_property(sello, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sello_tween.tween_property(sello, "modulate:a", 1.0, 0.12)

	await get_tree().create_timer(0.85).timeout
	await _fundir_a_negro()
	get_tree().change_scene_to_file(ESCENA_SIGUIENTE)


func _on_confirmar_mouse_entered() -> void:
	if not confirmar_button.disabled:
		AUDIOMANAGER.play_ui_hover()


func _fundir_a_negro() -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.45)
	await tween.finished
