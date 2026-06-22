extends Panel

var titulo_label: Label
var estado_label: Label
var descripcion_label: Label
var diagnostico_label: Label
var pistas_label: Label
var reparacion_label: Label
var accion_button: Button


func _ready() -> void:
	visible = false
	_setup_ui()
	_conectar_senales()
	_actualizar_diagnostico()


func _setup_ui() -> void:
	if has_node("Label"):
		$Label.hide()

	var contenedor := VBoxContainer.new()
	contenedor.name = "DiagnosticoPanel"
	contenedor.position = Vector2(-430, -235)
	contenedor.size = Vector2(780, 465)
	contenedor.add_theme_constant_override("separation", 10)
	add_child(contenedor)

	titulo_label = _crear_label("Sin servicio activo", 26, Color("#f2cc60"))
	contenedor.add_child(titulo_label)

	estado_label = _crear_label("Estado: sin servicio", 16, Color("#8b949e"))
	contenedor.add_child(estado_label)

	descripcion_label = _crear_label("", 16, Color.WHITE)
	contenedor.add_child(descripcion_label)

	diagnostico_label = _crear_label("", 15, Color("#d2a8ff"))
	contenedor.add_child(diagnostico_label)

	pistas_label = _crear_label("", 15, Color("#c9d1d9"))
	contenedor.add_child(pistas_label)

	reparacion_label = _crear_label("", 15, Color("#7ee787"))
	contenedor.add_child(reparacion_label)

	var separador := Control.new()
	separador.custom_minimum_size = Vector2(0, 8)
	contenedor.add_child(separador)

	accion_button = Button.new()
	accion_button.custom_minimum_size = Vector2(0, 44)
	accion_button.text = "Registrar cliente"
	accion_button.pressed.connect(_on_accion_button_pressed)
	contenedor.add_child(accion_button)


func _crear_label(texto: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = texto
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _conectar_senales() -> void:
	if GLOBALSIGNALS and not GLOBALSIGNALS.abrir_pc.is_connected(_on_abrir_pc):
		GLOBALSIGNALS.abrir_pc.connect(_on_abrir_pc)

	if SERVICEMANAGER and not SERVICEMANAGER.servicio_actualizado.is_connected(_on_servicio_actualizado):
		SERVICEMANAGER.servicio_actualizado.connect(_on_servicio_actualizado)


func _on_abrir_pc() -> void:
	_actualizar_diagnostico()


func _on_servicio_actualizado(_falla: Dictionary) -> void:
	_actualizar_diagnostico()


func _actualizar_diagnostico() -> void:
	var falla := SERVICEMANAGER.get_falla_actual()

	if falla.is_empty():
		titulo_label.text = "Sin servicio activo"
		estado_label.text = "Estado: sin servicio"
		descripcion_label.text = "Atiende un cliente o registra un caso para comenzar el diagnostico."
		diagnostico_label.text = ""
		pistas_label.text = ""
		reparacion_label.text = ""
		accion_button.text = "Registrar cliente"
		accion_button.disabled = false
		return

	var estado := SERVICEMANAGER.get_estado_actual()
	titulo_label.text = falla["nombre"]
	estado_label.text = "Estado: " + _estado_legible(estado)
	descripcion_label.text = "Reporte del cliente: " + falla["descripcion_cliente"]
	diagnostico_label.text = "Diagnostico probable: " + falla["diagnostico"]
	reparacion_label.text = "Reparacion: " + falla["reparacion"]
	pistas_label.text = _formatear_pistas(falla["pistas"])

	if estado == SERVICEMANAGER.ESTADO_REPARADO:
		accion_button.text = "Servicio reparado"
		accion_button.disabled = true
	elif estado == SERVICEMANAGER.ESTADO_EN_REPARACION:
		accion_button.text = "Reparacion en curso"
		accion_button.disabled = true
	else:
		accion_button.text = "Iniciar reparacion"
		accion_button.disabled = false


func _estado_legible(estado: String) -> String:
	match estado:
		SERVICEMANAGER.ESTADO_PENDIENTE:
			return "pendiente"
		SERVICEMANAGER.ESTADO_EN_REPARACION:
			return "en reparacion"
		SERVICEMANAGER.ESTADO_REPARADO:
			return "reparado"
		SERVICEMANAGER.ESTADO_FALLIDO:
			return "fallido"
		_:
			return "sin servicio"


func _formatear_pistas(pistas: Array) -> String:
	var texto := "Pistas concretas:"

	for pista in pistas:
		texto += "\n- " + str(pista)

	return texto


func _on_accion_button_pressed() -> void:
	if SERVICEMANAGER.get_falla_actual().is_empty():
		SERVICEMANAGER.crear_servicio()
		return

	accion_button.disabled = true
	visible = false
	modulate.a = 1.0
	scale = Vector2(1.0, 1.0)
	GLOBALSIGNALS.cerrar_pc.emit()
	SERVICEMANAGER.iniciar_reparacion()


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
