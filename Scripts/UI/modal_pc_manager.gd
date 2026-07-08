extends Panel

const SPLASHES: Dictionary = {
	"generica": {
		"titulo": "Orden general",
		"subtitulo": "Revision completa del vehiculo",
		"texture": preload("res://Assets/Sprites/clientes_atendidos/bg_clientes_atender.png")
	},
	"pinchazo": {
		"titulo": "Modulo neumaticos",
		"subtitulo": "Presion, desgaste y estabilidad",
		"texture": preload("res://Assets/Sprites/inflado_neumatico/FondoTaller.png")
	},
	"soldadura": {
		"titulo": "Banco de soldadura",
		"subtitulo": "Chasis, placas y puntos debiles",
		"texture": preload("res://Scenes/Minigames/Soldadura/Imagenes/fondo minijuego.png")
	},
	"gasolina": {
		"titulo": "Control de combustible",
		"subtitulo": "Combustible, potencia y entrega",
		"texture": preload("res://Assets/Sprites/snake_sprites/burning_car.png")
	},
	"circuito": {
		"titulo": "Diagnostico electrico",
		"subtitulo": "Memoria, senales e intermitencias",
		"texture": preload("res://Assets/Sprites/clientes_atendidos/ventana_personajes.png")
	}
}

var dia_consultado: int = 1
var actualizando_selector: bool = false

var titulo_label: Label
var estado_label: Label
var splash_texture: TextureRect
var dia_selector: OptionButton
var prev_button: Button
var next_button: Button
var clientes_value: Label
var diagnosticos_value: Label
var balance_value: Label
var dinero_value: Label
var reputacion_bar: ProgressBar
var reputacion_label: Label
var detalle_dia_label: Label
var eventos_dia_label: RichTextLabel
var general_label: Label


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_interfaz_estadisticas()

	if GLOBALSIGNALS and not GLOBALSIGNALS.abrir_pc.is_connected(_on_abrir_pc):
		GLOBALSIGNALS.abrir_pc.connect(_on_abrir_pc)


func _crear_interfaz_estadisticas() -> void:
	if has_node("Label"):
		$Label.hide()

	var root := PanelContainer.new()
	root.name = "EstadisticasRoot"
	root.position = Vector2(-330, -225)
	root.size = Vector2(700, 410)
	root.add_theme_stylebox_override("panel", _crear_style(Color("#11151b"), Color("#f2cc60"), 2, 8))
	add_child(root)
	move_child(root, 1)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 12)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_right", 12)
	margen.add_theme_constant_override("margin_bottom", 10)
	root.add_child(margen)

	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 8)
	margen.add_child(main)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	main.add_child(header)

	var header_text := VBoxContainer.new()
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_text)

	titulo_label = _crear_label("TERMINAL DEL TALLER", 24, Color("#f2cc60"))
	header_text.add_child(titulo_label)

	estado_label = _crear_label("", 14, Color("#7ee787"))
	header_text.add_child(estado_label)

	var selector_box := HBoxContainer.new()
	selector_box.add_theme_constant_override("separation", 8)
	header.add_child(selector_box)

	prev_button = _crear_boton("<", Vector2(40, 34))
	prev_button.pressed.connect(_on_prev_dia_pressed)
	selector_box.add_child(prev_button)

	dia_selector = OptionButton.new()
	dia_selector.custom_minimum_size = Vector2(130, 34)
	dia_selector.item_selected.connect(_on_dia_selector_selected)
	selector_box.add_child(dia_selector)

	next_button = _crear_boton(">", Vector2(40, 34))
	next_button.pressed.connect(_on_next_dia_pressed)
	selector_box.add_child(next_button)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	main.add_child(body)

	var splash_panel := PanelContainer.new()
	splash_panel.custom_minimum_size = Vector2(220, 325)
	splash_panel.add_theme_stylebox_override("panel", _crear_style(Color("#1f252d"), Color("#3b4655"), 2, 6))
	body.add_child(splash_panel)

	var splash_margin := MarginContainer.new()
	splash_margin.add_theme_constant_override("margin_left", 10)
	splash_margin.add_theme_constant_override("margin_top", 10)
	splash_margin.add_theme_constant_override("margin_right", 10)
	splash_margin.add_theme_constant_override("margin_bottom", 10)
	splash_panel.add_child(splash_margin)

	var splash_box := VBoxContainer.new()
	splash_box.add_theme_constant_override("separation", 8)
	splash_margin.add_child(splash_box)

	splash_texture = TextureRect.new()
	splash_texture.custom_minimum_size = Vector2(198, 303)
	splash_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	splash_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	splash_box.add_child(splash_texture)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	body.add_child(right)

	var cards := GridContainer.new()
	cards.columns = 2
	cards.add_theme_constant_override("h_separation", 7)
	cards.add_theme_constant_override("v_separation", 7)
	right.add_child(cards)

	clientes_value = _crear_tarjeta(cards, "Clientes", "0")
	diagnosticos_value = _crear_tarjeta(cards, "Diagnostico", "0 / 0")
	balance_value = _crear_tarjeta(cards, "Balance dia", "+$0")
	dinero_value = _crear_tarjeta(cards, "Caja actual", "$0")

	var rep_panel := PanelContainer.new()
	rep_panel.add_theme_stylebox_override("panel", _crear_style(Color("#181e25"), Color("#303946"), 1, 6))
	right.add_child(rep_panel)

	var rep_margin := MarginContainer.new()
	rep_margin.add_theme_constant_override("margin_left", 10)
	rep_margin.add_theme_constant_override("margin_top", 8)
	rep_margin.add_theme_constant_override("margin_right", 10)
	rep_margin.add_theme_constant_override("margin_bottom", 8)
	rep_panel.add_child(rep_margin)

	var rep_box := VBoxContainer.new()
	rep_box.add_theme_constant_override("separation", 4)
	rep_margin.add_child(rep_box)

	reputacion_label = _crear_label("Reputacion del taller", 13, Color("#f0f6fc"))
	rep_box.add_child(reputacion_label)

	reputacion_bar = ProgressBar.new()
	reputacion_bar.min_value = 0
	reputacion_bar.max_value = 100
	reputacion_bar.custom_minimum_size = Vector2(0, 18)
	rep_box.add_child(reputacion_bar)

	detalle_dia_label = _crear_label("", 13, Color("#c9d1d9"))
	detalle_dia_label.custom_minimum_size = Vector2(0, 62)
	right.add_child(detalle_dia_label)

	eventos_dia_label = RichTextLabel.new()
	eventos_dia_label.custom_minimum_size = Vector2(0, 92)
	eventos_dia_label.bbcode_enabled = false
	eventos_dia_label.scroll_active = true
	eventos_dia_label.add_theme_font_size_override("normal_font_size", 13)
	eventos_dia_label.add_theme_color_override("default_color", Color("#f0f6fc"))
	eventos_dia_label.add_theme_stylebox_override("normal", _crear_style(Color("#0d1117"), Color("#303946"), 1, 6))
	right.add_child(eventos_dia_label)

	general_label = _crear_label("", 12, Color("#8b949e"))
	right.add_child(general_label)


func _crear_tarjeta(parent: Control, titulo: String, valor: String) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(210, 55)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _crear_style(Color("#181e25"), Color("#303946"), 1, 6))
	parent.add_child(panel)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 9)
	margen.add_theme_constant_override("margin_top", 5)
	margen.add_theme_constant_override("margin_right", 9)
	margen.add_theme_constant_override("margin_bottom", 5)
	panel.add_child(margen)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	margen.add_child(box)

	var title_label := _crear_label(titulo.to_upper(), 11, Color("#8b949e"))
	box.add_child(title_label)

	var value_label := _crear_label(valor, 20, Color("#f0f6fc"))
	box.add_child(value_label)
	return value_label


func _crear_label(texto: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = texto
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	return label


func _crear_boton(texto: String, size: Vector2) -> Button:
	var button := Button.new()
	button.text = texto
	button.custom_minimum_size = size
	button.add_theme_stylebox_override("normal", _crear_style(Color("#202832"), Color("#4c5b6d"), 1, 5))
	button.add_theme_stylebox_override("hover", _crear_style(Color("#2d3744"), Color("#f2cc60"), 1, 5))
	button.add_theme_stylebox_override("pressed", _crear_style(Color("#151a21"), Color("#7ee787"), 1, 5))
	return button


func _crear_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style


func _on_abrir_pc() -> void:
	dia_consultado = DATOSGLOBALES.dia_actual
	_actualizar_estadisticas()


func _actualizar_estadisticas() -> void:
	var generales: Dictionary = DATOSGLOBALES.get_estadisticas_generales()
	var max_dia: int = maxi(1, DATOSGLOBALES.dia_actual)
	dia_consultado = clampi(dia_consultado, 1, max_dia)
	_actualizar_selector_dias(max_dia)

	var stats: Dictionary = DATOSGLOBALES.get_estadistica_dia(dia_consultado)
	var reputacion: int = int(stats.get("reputacion", 50))
	var correctos: int = int(stats.get("diagnosticos_correctos", 0))
	var incorrectos: int = int(stats.get("diagnosticos_incorrectos", 0))
	var balance: int = int(stats.get("balance", 0))
	var eventos: Array = stats.get("eventos", [])

	estado_label.text = _obtener_estado_dia(stats)
	clientes_value.text = "%d atendidos" % int(stats.get("clientes_atendidos", 0))
	diagnosticos_value.text = "%d bien / %d mal" % [correctos, incorrectos]
	balance_value.text = DATOSGLOBALES.formatear_monto(balance)
	balance_value.add_theme_color_override("font_color", Color("#7ee787") if balance >= 0 else Color("#ff7b72"))
	dinero_value.text = "$%d" % int(stats.get("dinero_final", DATOSGLOBALES.dinero))
	reputacion_bar.value = reputacion
	reputacion_label.text = "Reputacion del dia: %d/100" % reputacion

	detalle_dia_label.text = (
		"Orden de trabajo del dia %d\n" % dia_consultado
		+ "Ingresos: %s    Gastos/perdidas: %s\n" % [
			DATOSGLOBALES.formatear_monto(int(stats.get("ingresos", 0))),
			DATOSGLOBALES.formatear_monto(-int(stats.get("gastos", 0)))
		]
		+ "Caja inicial: $%d    Caja final: $%d"
		% [int(stats.get("dinero_inicio", 0)), int(stats.get("dinero_final", DATOSGLOBALES.dinero))]
	)

	_actualizar_splash(_obtener_falla_destacada(eventos, dia_consultado))
	_actualizar_eventos(eventos)

	general_label.text = (
		"Acumulado: %d clientes | %d diagnosticos correctos | %d incorrectos | Reputacion global %d/100"
		% [
			int(generales.get("clientes_atendidos", 0)),
			int(generales.get("diagnosticos_correctos", 0)),
			int(generales.get("diagnosticos_incorrectos", 0)),
			int(generales.get("reputacion", 50))
		]
	)

	prev_button.disabled = dia_consultado <= 1
	next_button.disabled = dia_consultado >= max_dia


func _actualizar_splash(falla: String) -> void:
	var splash: Dictionary = SPLASHES.get(falla, SPLASHES["generica"])
	splash_texture.texture = splash.get("texture")


func _actualizar_eventos(eventos: Array) -> void:
	if eventos.is_empty():
		eventos_dia_label.text = "BITACORA DE TALLER\n\nNo hay ordenes registradas para este dia."
		return

	var texto_eventos: String = "BITACORA DE TALLER"
	var numero: int = 1
	for evento in eventos:
		texto_eventos += "\n\n%02d  %s" % [numero, str(evento)]
		numero += 1

	eventos_dia_label.text = texto_eventos


func _obtener_estado_dia(stats: Dictionary) -> String:
	var clientes: int = int(stats.get("clientes_atendidos", 0))
	var balance: int = int(stats.get("balance", 0))
	var incorrectos: int = int(stats.get("diagnosticos_incorrectos", 0))

	if clientes == 0:
		return "Sistema listo | Sin ordenes registradas para este dia"
	if incorrectos >= 2:
		return "Alerta de calidad | Revisar diagnosticos del dia %d" % dia_consultado
	if balance < 0:
		return "Caja en rojo | Jornada con perdidas"

	return "Operacion estable | Dia %d cargado en terminal" % dia_consultado


func _obtener_falla_destacada(eventos: Array, dia: int) -> String:
	for i in range(eventos.size() - 1, -1, -1):
		var evento: String = str(eventos[i]).to_lower()
		for falla in SPLASHES.keys():
			if evento.find(str(falla)) >= 0:
				return str(falla)

	var fallas: Array = SPLASHES.keys()
	return str(fallas[(dia - 1) % fallas.size()])


func _actualizar_selector_dias(max_dia: int) -> void:
	if dia_selector == null:
		return

	actualizando_selector = true
	dia_selector.clear()

	for dia in range(1, max_dia + 1):
		dia_selector.add_item("Dia %d" % dia, dia)
		if dia == dia_consultado:
			dia_selector.select(dia - 1)

	actualizando_selector = false


func _on_prev_dia_pressed() -> void:
	dia_consultado -= 1
	_actualizar_estadisticas()


func _on_next_dia_pressed() -> void:
	dia_consultado += 1
	_actualizar_estadisticas()


func _on_dia_selector_selected(index: int) -> void:
	if actualizando_selector:
		return

	dia_consultado = dia_selector.get_item_id(index)
	_actualizar_estadisticas()


func _on_button_pressed() -> void:
	$Button.disabled = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)

	tween.chain().tween_callback(func():
		visible = false
		modulate.a = 1.0
		scale = Vector2(1.0, 1.0)
		get_tree().paused = false
		GLOBALSIGNALS.cerrar_pc.emit()
		$Button.disabled = false
	)
