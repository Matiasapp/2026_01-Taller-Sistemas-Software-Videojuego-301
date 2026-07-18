extends Control

const ESCENA_SIGUIENTE := "res://Scenes/Events/TransicionDia/transicion_dia.tscn"
const COLOR_OK := Color(0.247, 0.729, 0.314)
const COLOR_ALERTA := Color(0.9, 0.35, 0.3)
const GRUPO_GASTOS := &"gasto_diario"

@onready var titulo: Label = %Titulo
@onready var caja_label: Label = %CajaLabel
@onready var total_label: Label = %TotalLabel
@onready var saldo_label: Label = %SaldoLabel
@onready var consecuencia_label: Label = %ConsecuenciaLabel
@onready var confirmar_button: Button = %ConfirmarButton
@onready var sello: Label = %Sello
@onready var fade_rect: ColorRect = %FadeRect

var dia_cerrado: int
var filas_gastos: Array[GastoDiarioFila] = []
var procesando := false


func _ready() -> void:
	dia_cerrado = maxi(1, DATOSGLOBALES.dia_actual - 1)
	titulo.text = "CIERRE DE CAJA  ·  DÍA %d" % dia_cerrado
	caja_label.text = "Caja disponible:  $%d" % DATOSGLOBALES.dinero

	_buscar_filas_gasto(self)
	for fila in filas_gastos:
		fila.estado_cambiado.connect(_on_gasto_toggled)
		fila.configurar_para_dia(dia_cerrado)
		var boton: CheckButton = fila.get_boton()
		if boton:
			boton.mouse_entered.connect(AUDIOMANAGER.play_ui_hover)

	if filas_gastos.is_empty():
		push_error("GastosDiarios necesita al menos una fila del grupo 'gasto_diario'.")

	confirmar_button.pressed.connect(_on_confirmar_pressed)
	confirmar_button.mouse_entered.connect(_on_confirmar_mouse_entered)
	_actualizar_resumen()

	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)


func _buscar_filas_gasto(nodo: Node) -> void:
	for hijo in nodo.get_children():
		if hijo is GastoDiarioFila and hijo.is_in_group(GRUPO_GASTOS):
			filas_gastos.append(hijo)
		_buscar_filas_gasto(hijo)


func _on_gasto_toggled() -> void:
	if procesando:
		return
	AUDIOMANAGER.play_ui_click()
	_actualizar_resumen()


func _actualizar_resumen() -> void:
	if filas_gastos.is_empty():
		consecuencia_label.text = "Agrega al menos una fila de gasto para continuar."
		consecuencia_label.add_theme_color_override("font_color", COLOR_ALERTA)
		confirmar_button.disabled = true
		return

	var total := 0
	var postergados := 0
	var arriendo_postergado := false

	for fila in filas_gastos:
		fila.actualizar_texto_boton()
		if fila.esta_seleccionado():
			total += fila.costo_actual
		else:
			postergados += 1
			if str(fila.nombre) == DATOSGLOBALES.NOMBRE_GASTO_ARRIENDO:
				arriendo_postergado = true

	var saldo := DATOSGLOBALES.dinero - total
	var pago_causa_quiebra := saldo <= DATOSGLOBALES.UMBRAL_DEUDA_EXTREMA
	total_label.text = "TOTAL A PAGAR:  $%d" % total
	saldo_label.text = "SALDO PARA MAÑANA:  $%d" % saldo
	saldo_label.add_theme_color_override("font_color", COLOR_OK if saldo >= 0 else COLOR_ALERTA)

	if pago_causa_quiebra:
		consecuencia_label.text = (
			"Este pago te dejaría con $%d: llegar a -$%d provoca la quiebra. "
			+ "Posterga uno o más pagos."
		) % [saldo, absi(DATOSGLOBALES.UMBRAL_DEUDA_EXTREMA)]
		consecuencia_label.add_theme_color_override("font_color", COLOR_ALERTA)
		confirmar_button.disabled = true
	elif DATOSGLOBALES.arriendos_postergados >= DATOSGLOBALES.ARRIENDOS_POSTERGADOS_PARA_DESALOJO:
		consecuencia_label.text = "La orden de desalojo ya está vigente. Pagar hoy no elimina los atrasos anteriores."
		consecuencia_label.add_theme_color_override("font_color", COLOR_ALERTA)
		confirmar_button.disabled = false
	elif arriendo_postergado:
		var atrasos_proyectados := DATOSGLOBALES.arriendos_postergados + 1
		if atrasos_proyectados >= DATOSGLOBALES.ARRIENDOS_POSTERGADOS_PARA_DESALOJO:
			consecuencia_label.text = "Arriendo postergado: %d/%d  ·  El desalojo se ejecutará al terminar la semana" % [
				atrasos_proyectados,
				DATOSGLOBALES.ARRIENDOS_POSTERGADOS_PARA_DESALOJO
			]
		else:
			consecuencia_label.text = "Arriendo postergado: %d/%d  ·  La deuda queda registrada" % [
				atrasos_proyectados,
				DATOSGLOBALES.ARRIENDOS_POSTERGADOS_PARA_DESALOJO
			]
		consecuencia_label.add_theme_color_override("font_color", COLOR_ALERTA)
		confirmar_button.disabled = false
	elif postergados > 0:
		consecuencia_label.text = "Pagos postergados: %d  ·  Sin cambio de reputación" % postergados
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

	for fila in filas_gastos:
		var nombre := str(fila.nombre)
		if fila.esta_seleccionado():
			pagados.append(nombre)
			total += fila.costo_actual
		else:
			postergados.append(nombre)

	DATOSGLOBALES.registrar_gastos_diarios(
		dia_cerrado, pagados, postergados, total, 0
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
	var destino := DATOSGLOBALES.obtener_destino_post_escena(ESCENA_SIGUIENTE)
	get_tree().change_scene_to_file(destino)


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
