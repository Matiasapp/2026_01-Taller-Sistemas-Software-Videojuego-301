extends CanvasLayer

#Audio
@onready var money_sound: AudioStreamPlayer = $MoneySound

@onready var label_dia = $PlataHoraDia/VBoxContainer/HBoxContainer/LabelDia
@onready var label_hora = $PlataHoraDia/VBoxContainer/HBoxContainer/LabelHora
@onready var label_dinero = $PlataHoraDia/VBoxContainer/LabelDinero
@onready var aviso_cliente: RichTextLabel = $AvisoCliente
@onready var aviso_abrir_taller: Label = $AvisoAbrirTaller

@onready var estrellas = [
	$HBoxContainer/stars_1,
	$HBoxContainer/stars_2,
	$HBoxContainer/stars_3,
	$HBoxContainer/stars_4,
	$HBoxContainer/stars_5,
]

var texturas = []

var aviso_tween: Tween = null
var parpadeo_tween: Tween = null

const COLOR_ABIERTO := "#33ff33"
const COLOR_CERRADO := "#ff4040"

var dinero_anterior: int = 0
var label_estado_taller: RichTextLabel = null
var label_clientes_atendidos: RichTextLabel = null

func _ready() -> void:
	# 1. Actualizamos los textos al iniciar con los datos actuales
	dinero_anterior = DATOSGLOBALES.dinero
	actualizar_dinero(DATOSGLOBALES.dinero)
	actualizar_dia(DATOSGLOBALES.dia_actual)

	# 2. Conectamos las señales de los Autoloads a este script
	DATOSGLOBALES.dinero_cambiado.connect(actualizar_dinero)
	DATOSGLOBALES.dia_cambiado.connect(actualizar_dia)
	DATOSGLOBALES.reputacion_cambiado.connect(actualizar_reputacion)
	
	# Asegúrate de que TIEMPOMANAGER tenga la señal time_changed(hours, minutes)
	if TIEMPOMANAGER:
		# Sincronizamos la hora actual al cargar el HUD (al volver de un minijuego, el
		# reloj ya avanzó en el autoload pero este HUD es nuevo y mostraría 8:00).
		actualizar_hora(TIEMPOMANAGER.current_hour, TIEMPOMANAGER.current_minute)
		TIEMPOMANAGER.time_changed.connect(actualizar_hora)
	
	# Se cargan las estrellas de reputacion
	texturas = [
		preload("res://Assets/Sprites/estrellas_reputacion/estrella_0%.png"),
		preload("res://Assets/Sprites/estrellas_reputacion/estrella_25%.png"),
		preload("res://Assets/Sprites/estrellas_reputacion/estrella_50%.png"),
		preload("res://Assets/Sprites/estrellas_reputacion/estrella_75%.png"),
		preload("res://Assets/Sprites/estrellas_reputacion/estrella_100%.png")
	]
	
	
	# 3. Estado del taller y clientes atendidos (estado global en CLIENTMANAGER).
	label_estado_taller = _buscar_richtextlabel("TallerAbiertoCerrado")
	label_clientes_atendidos = _buscar_richtextlabel("ClientesAtendidos")
	if CLIENTMANAGER:
		actualizar_estado_taller(CLIENTMANAGER.taller_abierto)
		actualizar_clientes_atendidos(CLIENTMANAGER.clientes_atendidos, CLIENTMANAGER.MAX_CLIENTES_DIA)
		if not CLIENTMANAGER.estado_taller_cambiado.is_connected(actualizar_estado_taller):
			CLIENTMANAGER.estado_taller_cambiado.connect(actualizar_estado_taller)
		if not CLIENTMANAGER.clientes_atendidos_cambiado.is_connected(actualizar_clientes_atendidos):
			CLIENTMANAGER.clientes_atendidos_cambiado.connect(actualizar_clientes_atendidos)
	
	
	actualizar_reputacion()

## Busca el primer RichTextLabel dentro de un contenedor por nombre (sin depender del nombre del label).
func _buscar_richtextlabel(nombre_contenedor: String) -> RichTextLabel:
	var contenedor := find_child(nombre_contenedor, true, false)
	if contenedor == null:
		push_warning("HUD: no se encontró el nodo '%s'." % nombre_contenedor)
		return null
	var labels := contenedor.find_children("*", "RichTextLabel", true, false)
	if labels.size() > 0:
		return labels[0] as RichTextLabel
	push_warning("HUD: '%s' no contiene ningún RichTextLabel." % nombre_contenedor)
	return null

## Actualiza el contador "Clientes atendidos: X/Y".
func actualizar_clientes_atendidos(atendidos: int, total: int) -> void:
	if label_clientes_atendidos:
		label_clientes_atendidos.text = "Clientes atendidos: %d/%d" % [atendidos, total]
	# Al completar los 5, el aviso debe pasar a "es hora de cerrar".
	actualizar_aviso_taller()

## Actualiza el indicador "El taller está Abierto/Cerrado" (solo el estado va coloreado).
## Además muestra/oculta el aviso parpadeante de "abre el taller" según el estado.
func actualizar_estado_taller(abierto: bool) -> void:
	if label_estado_taller:
		if abierto:
			label_estado_taller.text = "El taller está [color=%s]Abierto[/color]" % COLOR_ABIERTO
		else:
			label_estado_taller.text = "El taller está [color=%s]Cerrado[/color]" % COLOR_CERRADO

	actualizar_aviso_taller()

## Decide qué muestra el aviso parpadeante según el estado del taller y los clientes atendidos:
##  - Cerrado          → "abre el taller"
##  - Abierto + 5/5    → "es hora de cerrar, vuelve a la cortina"
##  - Abierto sin completar → oculto
func actualizar_aviso_taller() -> void:
	if aviso_abrir_taller == null or CLIENTMANAGER == null:
		return

	var abierto: bool = CLIENTMANAGER.taller_abierto
	var dia_completo: bool = CLIENTMANAGER.clientes_atendidos >= CLIENTMANAGER.MAX_CLIENTES_DIA

	if not abierto:
		aviso_abrir_taller.text = "Tienes que abrir el taller para comenzar a atender clientes"
		aviso_abrir_taller.visible = true
		_iniciar_parpadeo()
	elif dia_completo:
		aviso_abrir_taller.text = "Es hora de cerrar el taller, vuelve a la cortina metálica"
		aviso_abrir_taller.visible = true
		_iniciar_parpadeo()
	else:
		aviso_abrir_taller.visible = false
		_detener_parpadeo()

func _iniciar_parpadeo() -> void:
	if aviso_abrir_taller == null:
		return
	if parpadeo_tween and parpadeo_tween.is_valid():
		return  # ya está parpadeando
	aviso_abrir_taller.modulate.a = 1.0
	parpadeo_tween = create_tween().set_loops()
	parpadeo_tween.tween_property(aviso_abrir_taller, "modulate:a", 0.2, 0.6)
	parpadeo_tween.tween_property(aviso_abrir_taller, "modulate:a", 1.0, 0.6)

func _detener_parpadeo() -> void:
	if parpadeo_tween and parpadeo_tween.is_valid():
		parpadeo_tween.kill()
	parpadeo_tween = null
	if aviso_abrir_taller:
		aviso_abrir_taller.modulate.a = 1.0

func actualizar_dinero(nuevo_monto: int) -> void:
	# Cambio de dinero EN VIVO (mientras el HUD está presente): mostramos el delta.
	var delta := nuevo_monto - dinero_anterior
	dinero_anterior = nuevo_monto
	label_dinero.text = "$" + str(nuevo_monto)

	# Rojo si el taller está en números rojos; verde si está en positivo (o en cero).
	if nuevo_monto < 0:
		label_dinero.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	else:
		label_dinero.add_theme_color_override("font_color", Color(0, 1, 0))

	if delta != 0:
		mostrar_popup_dinero(delta)

## Muestra un texto flotante "+$X" (verde) / "-$X" (rojo) junto al dinero, que sube y se desvanece.
func mostrar_popup_dinero(delta: int) -> void:
	if delta == 0:
		return

	# Reproducir sonido según el cambio de dinero
	if delta > 0:
		play_gain_money()
	else:
		play_lose_money()

	# Esperamos un frame para que el layout del HUD esté calculado
	await get_tree().process_frame

	var popup := Label.new()
	popup.text = ("+$%d" % delta) if delta > 0 else ("-$%d" % absi(delta))
	popup.add_theme_font_size_override("font_size", 30)
	popup.add_theme_color_override(
		"font_color",
		Color(0.45, 1.0, 0.45) if delta > 0 else Color(1.0, 0.4, 0.4)
	)
	popup.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	popup.add_theme_constant_override("outline_size", 6)
	add_child(popup)

	popup.global_position = label_dinero.global_position + Vector2(0.0, -46.0)

	var destino_y := popup.global_position.y - 40.0
	var tween := create_tween()
	tween.tween_property(
		popup,
		"global_position:y",
		destino_y,
		1.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(popup, "modulate:a", 0.0, 1.0)
	tween.tween_callback(popup.queue_free)

## Muestra el aviso (RichTextLabel "AvisoCliente" del HUD): aparece, se mantiene y se desvanece.
## El 'texto' admite BBCode (ej. la hora en amarillo); el texto base va en blanco.
func mostrar_aviso(texto: String) -> void:
	if aviso_cliente == null:
		return

	if aviso_tween and aviso_tween.is_valid():
		aviso_tween.kill()

	aviso_cliente.text = "[center]%s[/center]" % texto
	aviso_cliente.visible = true
	aviso_cliente.modulate.a = 0.0

	aviso_tween = create_tween()
	aviso_tween.tween_property(aviso_cliente, "modulate:a", 1.0, 0.25)
	aviso_tween.tween_interval(1.5)
	aviso_tween.tween_property(aviso_cliente, "modulate:a", 0.0, 0.5)
	aviso_tween.tween_callback(func(): aviso_cliente.visible = false)

func _mostrar_avisos_reputacion(avisos: Array[String]) -> void:
	var detalle := "\n".join(PackedStringArray(avisos))
	mostrar_aviso("[b]Cambios de reputacion[/b]\n" + detalle)

func mostrar_cambios_reputacion_pendientes() -> void:
	var avisos_reputacion := DATOSGLOBALES.consumir_avisos_reputacion()
	if not avisos_reputacion.is_empty():
		call_deferred("_mostrar_avisos_reputacion", avisos_reputacion)

func actualizar_dia(nuevo_dia: int) -> void:
	label_dia.text = "Día: " + str(nuevo_dia)

func actualizar_hora(horas: int, minutos: int) -> void:
	# Este formato "%02d" asegura que los números menores a 10 tengan un cero a la izquierda
	# Ejemplo: las 8:5 se verá como "08:05" en lugar de "8:5"
	var hora_formateada = "%02d:%02d" % [horas, minutos]
	label_hora.text = "Hora: " + hora_formateada
	
func play_gain_money() -> void:
	if not money_sound:
		return

	money_sound.stop()
	money_sound.pitch_scale = randf_range(0.98, 1.05)
	money_sound.volume_db = -6.0
	money_sound.play()
		
func play_lose_money() -> void:
	if not money_sound:
		return

	money_sound.stop()
	money_sound.pitch_scale = 1.0
	money_sound.volume_db = -7.0
	money_sound.play()

	var tween := create_tween()
	tween.tween_property(money_sound, "pitch_scale", 0.55, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func actualizar_reputacion(_nueva_reputacion: int = -1) -> void:
	var reputacion := clampi(DATOSGLOBALES.reputacion, 0, 100)

	for i in range(5):
		var valor_estrella = reputacion - i * 20

		if valor_estrella <= 0:
			estrellas[i].texture = texturas[0] # vacía
		elif valor_estrella <= 5:
			estrellas[i].texture = texturas[1] # 25%
		elif valor_estrella <= 10:
			estrellas[i].texture = texturas[2] # 50%
		elif valor_estrella <= 15:
			estrellas[i].texture = texturas[3] # 75%
		else: # 16–20 o más
			estrellas[i].texture = texturas[4] # llena
