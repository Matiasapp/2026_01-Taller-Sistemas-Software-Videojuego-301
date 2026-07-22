extends Panel

# =====================================================================
# TERMINAL DEL TALLER (estadísticas en el PC)
# ---------------------------------------------------------------------
# Toda la interfaz vive en la escena (ModalPC.tscn), con el mismo estilo
# del taller que PantallaResumenDia. Este script solo la rellena con los
# datos por día y gestiona el selector de día y el cierre.
# =====================================================================

const SPLASHES: Dictionary = {
	"generica": {
		"texture": preload("res://Assets/Sprites/clientes_atendidos/bg_clientes_atender.png")
	},
	"pinchazo": {
		"texture": preload("res://Assets/Sprites/inflado_neumatico/FondoTaller.png")
	},
	"soldadura": {
		"texture": preload("res://Scenes/Minigames/Soldadura/Imagenes/fondo minijuego.png")
	},
	"gasolina": {
		"texture": preload("res://Scenes/Minigames/TheFloorIsLava/Background/checkboard.png")
	},
	"circuito": {
		"texture": preload("res://Assets/Sprites/MemorizeGame/fondo_memory.png")
	}
}

const COL_VERDE := Color(0.247, 0.729, 0.314)
const COL_ROJO := Color(0.9, 0.35, 0.3)

# Valor sentinela de dia_consultado para el modo "Todos los días" (los días reales
# son >= 1). En ese modo se muestran las estadísticas acumuladas y TODAS las reseñas.
const DIA_TODOS := 0

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

var dia_consultado: int = 1
var actualizando_selector: bool = false

# La interfaz vive en su propia escena (ModalPCInterfaz.tscn) instanciada
# dentro del SubViewport; se edita plana en el editor y aquí se resuelven
# sus nodos por nombre único DENTRO de esa escena.
@onready var interfaz: Control = $Contenido/Interfaz
@onready var estado_label: Label = interfaz.get_node("%Estado")
@onready var dia_selector: OptionButton = interfaz.get_node("%DiaSelector")
@onready var prev_button: Button = interfaz.get_node("%PrevButton")
@onready var next_button: Button = interfaz.get_node("%NextButton")
@onready var clientes_value: Label = interfaz.get_node("%ClientesValue")
@onready var diagnosticos_value: Label = interfaz.get_node("%DiagnosticoValue")
@onready var balance_value: Label = interfaz.get_node("%BalanceValue")
@onready var dinero_value: Label = interfaz.get_node("%CajaValue")
@onready var reputacion_bar: ProgressBar = interfaz.get_node("%ReputacionBar")
@onready var reputacion_label: Label = interfaz.get_node("%ReputacionLabel")
@onready var reputacion_porcentaje_label: Label = interfaz.get_node("%PorcentajeReputacion")
@onready var splash_texture: TextureRect = interfaz.get_node("%SplashTexture")
@onready var detalle_dia_label: Label = interfaz.get_node("%DetalleLabel")
@onready var eventos_dia_label: RichTextLabel = interfaz.get_node("%EventosLabel")
@onready var general_label: Label = interfaz.get_node("%GeneralLabel")
@onready var estrellas: Array[TextureRect] = [
	interfaz.get_node("%stars_1"), interfaz.get_node("%stars_2"),
	interfaz.get_node("%stars_3"), interfaz.get_node("%stars_4"),
	interfaz.get_node("%stars_5"),
]
@onready var boton_cerrar: Button = interfaz.get_node("%Button")
@onready var btn_resenas: Button = interfaz.get_node("%BtnResenas")
@onready var pantalla_crt: TextureRect = %Pantalla
# Panel de reseñas: se superpone a la terminal dentro del mismo SubViewport.
@onready var resenas_panel: Control = $Contenido/Resenas


func _ready() -> void:
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS

	prev_button.pressed.connect(_on_prev_dia_pressed)
	next_button.pressed.connect(_on_next_dia_pressed)
	dia_selector.item_selected.connect(_on_dia_selector_selected)
	boton_cerrar.pressed.connect(_on_button_pressed)
	btn_resenas.pressed.connect(_on_resenas_pressed)
	resenas_panel.cerrado.connect(_cerrar_resenas)
	resenas_panel.visible = false

	_conectar_sonidos_botones()

	if GLOBALSIGNALS and not GLOBALSIGNALS.abrir_pc.is_connected(_on_abrir_pc):
		GLOBALSIGNALS.abrir_pc.connect(_on_abrir_pc)


## Los botones de la terminal usan la variante suave del sonido de UI (la misma
## del enlace de créditos), para que se distingan del resto de los menús.
func _conectar_sonidos_botones() -> void:
	for boton in [prev_button, next_button, dia_selector, boton_cerrar, btn_resenas]:
		boton.mouse_entered.connect(_on_boton_pc_hover.bind(boton))

	# Abrir el desplegable de días también suena; elegir un día de la lista suena
	# aparte, en _on_dia_selector_selected.
	dia_selector.pressed.connect(AUDIOMANAGER.play_ui_soft_click)


## Un botón deshabilitado (p. ej. "anterior" en el día 1) igual recibe el hover
## del mouse, pero no debe sonar porque no se puede usar.
func _on_boton_pc_hover(boton: Button) -> void:
	if not boton.disabled:
		AUDIOMANAGER.play_ui_soft_hover()


func _on_abrir_pc() -> void:
	dia_consultado = DATOSGLOBALES.dia_actual
	# El PC siempre arranca en el tablero, nunca en el panel de reseñas.
	_cerrar_resenas()
	_actualizar_estadisticas()
	_animar_encendido()


## Animación de encendido del CRT: la imagen nace como una línea brillante
## que se expande (tween del parámetro power_on del shader de la pantalla).
func _animar_encendido() -> void:
	if pantalla_crt == null:
		return
	var mat := pantalla_crt.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("power_on", 0.0)
	var tw := create_tween()
	tw.tween_method(
		func(v: float): mat.set_shader_parameter("power_on", v),
		0.0, 1.0, 0.5
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Animación de apagado del CRT (inversa a la de encendido): la imagen se
## colapsa desde arriba y abajo hacia la línea central brillante y luego
## se apaga. Devuelve el Tween para poder esperar a que termine.
func _animar_apagado() -> Tween:
	if pantalla_crt == null:
		return null
	var mat := pantalla_crt.material as ShaderMaterial
	if mat == null:
		return null
	mat.set_shader_parameter("power_on", 1.0)
	var tw := create_tween()
	tw.tween_method(
		func(v: float): mat.set_shader_parameter("power_on", v),
		1.0, 0.0, 0.4
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return tw


func _actualizar_estadisticas() -> void:
	var generales: Dictionary = DATOSGLOBALES.get_estadisticas_generales()
	var max_dia: int = maxi(1, DATOSGLOBALES.dia_actual)
	var es_todos: bool = dia_consultado == DIA_TODOS
	if not es_todos:
		dia_consultado = clampi(dia_consultado, 1, max_dia)
	_actualizar_selector_dias(max_dia)

	var stats: Dictionary = _stats_agregadas() if es_todos else DATOSGLOBALES.get_estadistica_dia(dia_consultado)
	var reputacion: int = int(stats.get("reputacion", 50))
	var correctos: int = int(stats.get("diagnosticos_correctos", 0))
	var incorrectos: int = int(stats.get("diagnosticos_incorrectos", 0))
	var balance: int = int(stats.get("balance", 0))
	var eventos: Array = stats.get("eventos", [])

	estado_label.text = "Historial completo | Todas las jornadas" if es_todos else _obtener_estado_dia(stats)
	clientes_value.text = "%d atendidos" % int(stats.get("clientes_atendidos", 0))
	diagnosticos_value.text = "%d bien / %d mal" % [correctos, incorrectos]
	balance_value.text = DATOSGLOBALES.formatear_monto(balance)
	balance_value.add_theme_color_override("font_color", COL_VERDE if balance >= 0 else COL_ROJO)
	dinero_value.text = "$%d" % int(stats.get("dinero_final", DATOSGLOBALES.dinero))
	reputacion_bar.value = reputacion
	reputacion_label.text = "Reputacion actual" if es_todos else "Reputacion del dia"
	reputacion_porcentaje_label.text = "%d/100" % reputacion
	_actualizar_estrellas(reputacion)

	detalle_dia_label.text = (
		("Resumen de todas las jornadas\n" if es_todos else "Orden de trabajo del dia %d\n" % dia_consultado)
		+ "Ingresos: %s    Gastos/perdidas: %s\n" % [
			DATOSGLOBALES.formatear_monto(int(stats.get("ingresos", 0))),
			DATOSGLOBALES.formatear_monto(-int(stats.get("gastos", 0)))
		]
		+ "Caja inicial: $%d    Caja final: $%d"
		% [int(stats.get("dinero_inicio", 0)), int(stats.get("dinero_final", DATOSGLOBALES.dinero))]
	)

	_actualizar_splash(_obtener_falla_destacada(eventos, maxi(1, dia_consultado)))
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

	prev_button.disabled = es_todos or dia_consultado <= 1
	next_button.disabled = es_todos or dia_consultado >= max_dia

	# Si el panel está abierto, se repinta para seguir al selector de día, y esas
	# reseñas pasan a estar leídas: el jugador las está viendo ahora mismo.
	var resenas: Array = _resenas_todas() if es_todos else DATOSGLOBALES.get_resenas_dia(dia_consultado)
	if resenas_panel.visible:
		resenas_panel.mostrar_resenas(resenas)
		if es_todos:
			_marcar_todas_leidas()
		else:
			DATOSGLOBALES.marcar_resenas_leidas(dia_consultado)

	_actualizar_boton_resenas(resenas.size())


## El botón muestra las del día visible y, si quedan pendientes en otros días,
## el total sin leer: si no, el aviso manda al PC y el PC parece vacío.
func _actualizar_boton_resenas(cantidad_dia: int) -> void:
	var sin_leer: int = DATOSGLOBALES.contar_resenas_sin_leer()
	if sin_leer > 0:
		btn_resenas.text = "RESEÑAS (%d · %d sin leer)" % [cantidad_dia, sin_leer]
	else:
		btn_resenas.text = "RESEÑAS (%d)" % cantidad_dia


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
	


func _actualizar_splash(falla: String) -> void:
	var splash: Dictionary = SPLASHES.get(falla, SPLASHES["generica"])
	splash_texture.texture = splash.get("texture")


func _actualizar_eventos(eventos: Array) -> void:
	if eventos.is_empty():
		eventos_dia_label.text = "No hay ordenes registradas para este dia."
		return

	var texto_eventos: String = ""
	var numero: int = 1
	for evento in eventos:
		if numero > 1:
			texto_eventos += "\n\n"
		texto_eventos += "%02d  %s" % [numero, str(evento)]
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

	# Opción para ver el acumulado y TODAS las reseñas juntas.
	dia_selector.add_item("Todos los dias", DIA_TODOS)
	if dia_consultado == DIA_TODOS:
		dia_selector.select(dia_selector.get_item_count() - 1)

	actualizando_selector = false


## Suma las estadísticas de todos los días en un diccionario con la misma forma que
## get_estadistica_dia(), para reutilizar todo el pintado de la terminal.
func _stats_agregadas() -> Dictionary:
	var max_dia: int = maxi(1, DATOSGLOBALES.dia_actual)
	var eventos: Array = []
	var agg := {
		"clientes_atendidos": 0,
		"diagnosticos_correctos": 0,
		"diagnosticos_incorrectos": 0,
		"ingresos": 0,
		"gastos": 0,
		"balance": 0,
	}
	for dia in range(1, max_dia + 1):
		var s: Dictionary = DATOSGLOBALES.get_estadistica_dia(dia)
		agg["clientes_atendidos"] += int(s.get("clientes_atendidos", 0))
		agg["diagnosticos_correctos"] += int(s.get("diagnosticos_correctos", 0))
		agg["diagnosticos_incorrectos"] += int(s.get("diagnosticos_incorrectos", 0))
		agg["ingresos"] += int(s.get("ingresos", 0))
		agg["gastos"] += int(s.get("gastos", 0))
		agg["balance"] += int(s.get("balance", 0))
		for ev in s.get("eventos", []):
			eventos.append("D%d  %s" % [dia, str(ev)])
	agg["eventos"] = eventos
	agg["reputacion"] = int(DATOSGLOBALES.reputacion)
	agg["dinero_final"] = int(DATOSGLOBALES.dinero)
	agg["dinero_inicio"] = int(DATOSGLOBALES.get_estadistica_dia(1).get("dinero_inicio", 0))
	return agg


## Junta las reseñas de todos los días, con el día como prefijo del autor.
func _resenas_todas() -> Array:
	var todas: Array = []
	var max_dia: int = maxi(1, DATOSGLOBALES.dia_actual)
	for dia in range(1, max_dia + 1):
		for r in DATOSGLOBALES.get_resenas_dia(dia):
			var copia: Dictionary = (r as Dictionary).duplicate()
			copia["usuario"] = "D%d · %s" % [dia, str(r.get("usuario", "Anonimo"))]
			todas.append(copia)
	return todas


func _marcar_todas_leidas() -> void:
	var max_dia: int = maxi(1, DATOSGLOBALES.dia_actual)
	for dia in range(1, max_dia + 1):
		DATOSGLOBALES.marcar_resenas_leidas(dia)


func _on_prev_dia_pressed() -> void:
	AUDIOMANAGER.play_ui_soft_click()
	dia_consultado -= 1
	_actualizar_estadisticas()


func _on_next_dia_pressed() -> void:
	AUDIOMANAGER.play_ui_soft_click()
	dia_consultado += 1
	_actualizar_estadisticas()


func _on_dia_selector_selected(index: int) -> void:
	if actualizando_selector:
		return

	AUDIOMANAGER.play_ui_soft_click()
	dia_consultado = dia_selector.get_item_id(index)
	_actualizar_estadisticas()


## Abre el panel de reseñas del día consultado, encima de la terminal.
func _on_resenas_pressed() -> void:
	AUDIOMANAGER.play_ui_soft_click()

	var es_todos: bool = dia_consultado == DIA_TODOS
	var resenas: Array = _resenas_todas() if es_todos else DATOSGLOBALES.get_resenas_dia(dia_consultado)
	resenas_panel.mostrar_resenas(resenas)
	if es_todos:
		_marcar_todas_leidas()
	else:
		DATOSGLOBALES.marcar_resenas_leidas(dia_consultado)
	_actualizar_boton_resenas(resenas.size())

	resenas_panel.visible = true
	# Varios paneles del tablero se salen del marco de la terminal, así que no
	# basta con taparlo: se oculta mientras las reseñas están en pantalla.
	interfaz.visible = false


func _cerrar_resenas() -> void:
	resenas_panel.visible = false
	interfaz.visible = true


func _on_button_pressed() -> void:
	AUDIOMANAGER.play_ui_soft_click()
	# Si el PC se cierra con el panel abierto, la próxima vez debe abrir en la terminal.
	_cerrar_resenas()
	boton_cerrar.disabled = true
	_animar_apagado()

	# El colapso del CRT (0.4s) marca la duración del cierre: el panel se
	# desvanece/encoge junto con él, en vez de desaparecer de golpe a mitad
	# de la animación de apagado.
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.4)

	tween.chain().tween_callback(func():
		visible = false
		modulate.a = 1.0
		scale = Vector2(1.0, 1.0)
		get_tree().paused = false
		GLOBALSIGNALS.cerrar_pc.emit()
		boton_cerrar.disabled = false
	)
