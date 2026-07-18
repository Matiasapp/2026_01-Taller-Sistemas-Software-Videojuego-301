extends Node2D

@onready var label_titulo: Label = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/LabelTitulo
@onready var label_descripcion: Label = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/LabelDescripcion
@onready var label_texto_reputacion: Label = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/LabelTextoReputacion
@onready var label_texto_clientes: Label = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/LabelTextoClientes
@onready var label_texto_autos: Label = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/LabelTextoAutos
@onready var label_texto_dinero: Label = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/LabelTextoDinero
@onready var label_reputacion: Label = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/LabelReputacion
@onready var indicador_reputacion = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/IndicadorReputacion
@onready var label_clientes: Label = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/LabelClientes
@onready var label_autos: Label = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/LabelAutos
@onready var label_dinero: Label = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/LabelDinero

@onready var resumen_rect: TextureRect = $CanvasLayer/VistaTextoIntroduccion/ResumenRect
@onready var label: RichTextLabel = $CanvasLayer/VistaTextoIntroduccion/Panel/RichTextLabel
@onready var vista_evento: Control = $CanvasLayer/VistaTextoIntroduccion
@onready var imagen: TextureRect = $CanvasLayer/VistaTextoIntroduccion/TextureRect
@onready var bg_animation: AnimationPlayer = $CanvasLayer/VistaTextoIntroduccion/TextureRect/AnimationPlayer
@onready var continuar_button: Button = $CanvasLayer/VistaTextoIntroduccion/ResumenRect/Comenzar
@onready var fade_rect: ColorRect = $CanvasLayer/FadeRect
@onready var panel_texto: Panel = $CanvasLayer/VistaTextoIntroduccion/Panel

@export var talking_sound: AudioStreamPlayer
@export var imagen_hombre_1: Texture2D
@export var imagen_mujer_1: Texture2D
@export var imagen_2: Texture2D
@export var imagen_3: Texture2D
@export var imagen_hombre_4: Texture2D
@export var imagen_mujer_4: Texture2D
@export var imagen_hombre_5: Texture2D
@export var imagen_mujer_5: Texture2D
@export var imagen_hombre_6: Texture2D
@export var imagen_mujer_6: Texture2D
@export var imagen_7: Texture2D
@export var imagen_hombre_8: Texture2D
@export var imagen_mujer_8: Texture2D
@export var imagen_9: Texture2D
@export var imagen_10_fondo: Texture2D
@export var imagen_9_panel: Texture2D

var animador_texto: Tween
var escribiendo := false
var indice_mensaje := 0
var resumen_final_activo := false
var resumen_listo_para_salir := false
var mensajes: Array[String] = []
var imagenes: Array[Texture2D] = []


func _ready() -> void:
	randomize()
	if bg_animation:
		bg_animation.play("background_move")

	continuar_button.visible = false
	continuar_button.disabled = true
	if not continuar_button.pressed.is_connected(_on_comenzar_pressed):
		continuar_button.pressed.connect(_on_comenzar_pressed)
	if not continuar_button.mouse_entered.is_connected(_on_comenzar_mouse_entered):
		continuar_button.mouse_entered.connect(_on_comenzar_mouse_entered)

	configurar_evento()
	mostrar_mensaje_actual()


func configurar_evento() -> void:
	mensajes = [
		"El viernes llegó antes de lo que querías. Cerraste la caja y confirmaste lo que ya sabías: el arriendo seguía marcado como postergado.",
		"Cada atraso pareció comprarte un día más, pero las cuentas no desaparecieron. El proceso judicial llevaba tiempo avanzando y el plazo finalmente se agotó.",
		"A las nueve se estacionó un radiopatrulla frente al taller. Llegaron dos carabineros, un receptor judicial, un cerrajero y el propietario. Para un negocio con tan pocos clientes, la asistencia era impresionante.",
		"El receptor verificó la dirección, mostró la orden y fue directo al punto: venía a efectuar el lanzamiento del inmueble. La carpeta que sostenía no dejaba mucho espacio para negociar.",
		"Mientras retirabas tus cosas, el receptor levantó el acta y el cerrajero aseguró la cortina. El inventario del taller resultó más largo que la lista de clientes del día.",
		"Tu mamá llegó con un bolso y un recipiente con comida. Miró las cajas, el candado y a Carabineros antes de preguntar: «¿Qué hiciste ahora?». Luego se arremangó y comenzó a ayudarte.",
		"A la mañana siguiente todavía llegaron algunos clientes. La confianza podía traerlos de vuelta, pero no podía abrir una puerta cerrada por orden judicial.",
		"Cinco días atrás habías llegado con las llaves del taller. Ahora solo te llevabas las herramientas, los recuerdos y una copia del acta doblada en el bolsillo.",
		"El taller no cerró porque dejaran de llegar clientes. Cerró porque cada pago que parecía poder esperar terminó llegando al mismo tiempo."
	]

	var es_mujer := DATOSGLOBALES.genero_jugador == "Femenino"
	imagenes = [
		imagen_mujer_1 if es_mujer else imagen_hombre_1,
		imagen_2,
		imagen_3,
		imagen_mujer_4 if es_mujer else imagen_hombre_4,
		imagen_mujer_5 if es_mujer else imagen_hombre_5,
		imagen_mujer_6 if es_mujer else imagen_hombre_6,
		imagen_7,
		imagen_mujer_8 if es_mujer else imagen_hombre_8,
		imagen_9
	]
	assert(mensajes.size() == imagenes.size(), "Cada texto del desalojo necesita una imagen.")


func _input(event) -> void:
	if not vista_evento.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if resumen_listo_para_salir:
			return
		if escribiendo:
			saltar_animacion()
		elif resumen_final_activo:
			indice_mensaje = mensajes.size()
			mostrar_resumen_limpio()
		else:
			avanzar_mensaje()


func mostrar_mensaje_actual() -> void:
	if indice_mensaje >= mensajes.size():
		return

	imagen.texture = imagenes[indice_mensaje]
	resumen_rect.visible = false
	panel_texto.visible = true
	continuar_button.visible = false
	continuar_button.disabled = true
	continuar_button.modulate.a = 0.35
	resumen_final_activo = indice_mensaje == mensajes.size() - 1
	animar_texto(mensajes[indice_mensaje])


func avanzar_mensaje() -> void:
	indice_mensaje += 1
	mostrar_mensaje_actual()


func animar_texto(nuevo_texto: String) -> void:
	escribiendo = true
	start_talking()
	label.text = nuevo_texto
	label.visible_characters = 0
	if animador_texto:
		animador_texto.kill()
	animador_texto = create_tween()
	animador_texto.tween_property(label, "visible_characters", nuevo_texto.length(), 1.5)
	animador_texto.finished.connect(func():
		escribiendo = false
		stop_talking()
	)


func saltar_animacion() -> void:
	if animador_texto:
		animador_texto.kill()
	label.visible_characters = label.text.length()
	stop_talking()
	escribiendo = false


func start_talking() -> void:
	if talking_sound and not talking_sound.playing:
		talking_sound.pitch_scale = randf_range(0.95, 1.05)
		talking_sound.play()


func stop_talking() -> void:
	if talking_sound and talking_sound.playing:
		talking_sound.stop()


func mostrar_resumen_limpio() -> void:
	stop_talking()
	resumen_listo_para_salir = true
	if imagen_10_fondo:
		imagen.texture = imagen_10_fondo
	panel_texto.visible = false
	if imagen_9_panel:
		resumen_rect.texture = imagen_9_panel
	resumen_rect.visible = true
	actualizar_resumen_final()
	continuar_button.visible = true
	continuar_button.disabled = false
	continuar_button.modulate.a = 1.0
	continuar_button.text = "Continuar"


func actualizar_resumen_final() -> void:
	label_titulo.text = "TALLER DESALOJADO"
	label_descripcion.text = "El receptor judicial llegó antes que el pago del arriendo."
	label_texto_reputacion.text = "REPUTACIÓN"
	label_texto_clientes.text = "CLIENTES SATISFECHOS"
	label_texto_autos.text = "CLIENTES ATENDIDOS (TOTAL)"
	label_texto_dinero.text = "DINERO FINAL"

	var resumen := DATOSGLOBALES.get_resumen_final()
	var reputacion := int(resumen.get("reputacion", 0))
	var clientes_atendidos_total := int(resumen.get("clientes_atendidos", 0))
	var clientes_satisfechos := int(resumen.get("clientes_satisfechos", 0))
	var dinero_final := int(resumen.get("dinero_final", 0))
	label_reputacion.text = str(reputacion) + "%"
	indicador_reputacion.set_reputacion(reputacion)
	label_clientes.text = str(clientes_satisfechos)
	label_autos.text = str(clientes_atendidos_total)
	label_dinero.text = "$%d" % dinero_final if dinero_final >= 0 else "-$%d" % absi(dinero_final)


func fade_to_black(duration := 0.6) -> void:
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished


func finalizar_evento() -> void:
	stop_talking()
	await fade_to_black(0.6)
	Engine.time_scale = 1.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")


func _on_comenzar_pressed() -> void:
	if continuar_button.disabled:
		return
	AUDIOMANAGER.play_ui_click()
	await get_tree().create_timer(0.15).timeout
	finalizar_evento()


func _on_comenzar_mouse_entered() -> void:
	if not continuar_button.disabled:
		AUDIOMANAGER.play_ui_hover()
