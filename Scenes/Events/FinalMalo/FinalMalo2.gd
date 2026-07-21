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

@export var imagen_5: Texture2D

@export var imagen_hombre_6: Texture2D
@export var imagen_mujer_6: Texture2D

@export var imagen_7: Texture2D

@export var imagen_8: Texture2D

@export var imagen_9_fondo: Texture2D
@export var imagen_9_panel: Texture2D

var animador_texto: Tween
var escribiendo := false
var indice_mensaje := 0

var resumen_final_activo := false
var resumen_listo_para_salir := false

var mensajes := []
var imagenes := []


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
	"Llegaste a un taller que atravesaba una situación crítica. Las deudas crecían, los clientes eran cada vez menos y cada jornada era una lucha por conseguir el dinero necesario para mantener las puertas abiertas.",

	"Trabajaste sin descanso para completar cada reparación. Sin embargo, los ingresos apenas alcanzaban para cubrir los gastos más urgentes y las pérdidas continuaron acumulándose.",

	"Las herramientas comenzaron a deteriorarse y ya no había dinero para reemplazarlas. Cada trabajo requería más esfuerzo, las reparaciones se retrasaban y algunos clientes comenzaron a buscar otras alternativas.",

	"Con el paso de los días, las obligaciones superaron los ingresos. El alquiler, los proveedores y los servicios quedaron pendientes mientras el poco dinero disponible desaparecía.",

	"Al llegar al quinto día, ya no quedaban recursos para comprar piezas ni continuar con las reparaciones. Mantener el taller abierto dejó de ser una posibilidad.",

	"Las herramientas fueron guardadas por última vez. Los pocos clientes que aún confiaban en el taller encontraron las puertas cerradas y un aviso anunciando el término de sus actividades.",

	"A pesar del esfuerzo realizado, no lograste revertir la situación económica. Sin dinero para pagar las deudas ni sostener el trabajo diario, el taller tuvo que cerrar definitivamente.",

	"Las luces se apagaron y el taller quedó vacío. Lo que debía ser una oportunidad para recuperar el negocio terminó consumido por las deudas."

	]

	var es_mujer := DATOSGLOBALES.genero_jugador == "Femenino"

	imagenes = [
		imagen_mujer_1 if es_mujer else imagen_hombre_1,
		imagen_2,
		imagen_3,
		imagen_mujer_4 if es_mujer else imagen_hombre_4,
		imagen_5,
		imagen_mujer_6 if es_mujer else imagen_hombre_6,
		imagen_7,
		imagen_8,
		imagen_9_fondo
	]

func _input(event) -> void:
	if not vista_evento.visible:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if resumen_listo_para_salir:
			return

		if escribiendo:
			saltar_animacion()
		elif resumen_final_activo:
			indice_mensaje = 8
			mostrar_resumen_limpio()
		else:
			avanzar_mensaje()


## Diferencia máxima de proporción para considerar que una imagen es del mismo
## formato que la ventana.
const TOLERANCIA_ASPECTO := 0.02


## Pone la imagen de fondo ajustando cómo se estira.
##
## Casi toda la secuencia es 16:9 igual que la ventana, y con KEEP_ASPECT llena
## la pantalla de borde a borde. Pero 3F.png es 3:2: al conservar su proporción
## se queda corta de ancho y, como el marco alinea arriba a la izquierda, queda
## descuadrada dejando una franja vacía a la derecha. Para cualquier imagen que
## no comparta el formato de la ventana se usa COVERED, que la centra y la
## agranda hasta cubrir el marco, recortando lo que sobra.
func _mostrar_imagen(textura: Texture2D) -> void:
	if textura == null:
		return

	imagen.texture = textura

	var ventana := get_viewport_rect().size
	var aspecto_ventana := ventana.x / ventana.y
	var aspecto_imagen := float(textura.get_width()) / float(textura.get_height())

	if absf(aspecto_imagen - aspecto_ventana) <= TOLERANCIA_ASPECTO:
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	else:
		imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED


func mostrar_mensaje_actual() -> void:
	if indice_mensaje >= mensajes.size():
		return

	_mostrar_imagen(imagenes[indice_mensaje])

	if resumen_rect:
		resumen_rect.visible = false

	if panel_texto:
		panel_texto.visible = true

	continuar_button.visible = false
	continuar_button.disabled = true
	continuar_button.modulate.a = 0.35

	# Último mensaje narrativo: imagen 8
	resumen_final_activo = indice_mensaje == mensajes.size() - 1

	animar_texto(mensajes[indice_mensaje])


func avanzar_mensaje() -> void:
	if escribiendo:
		saltar_animacion()
		return

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
	CARGADOR.cambiar_escena("res://Scenes/UI/MainMenu.tscn")


func _on_comenzar_pressed() -> void:
	if continuar_button.disabled:
		return

	AUDIOMANAGER.play_ui_click()

	await get_tree().create_timer(0.15).timeout

	finalizar_evento()


func _on_comenzar_mouse_entered() -> void:
	if not continuar_button.disabled:
		AUDIOMANAGER.play_ui_hover()
		


func mostrar_resumen_limpio() -> void:
	stop_talking()
	resumen_listo_para_salir = true

	if imagen_9_fondo:
		_mostrar_imagen(imagen_9_fondo)

	if panel_texto:
		panel_texto.visible = false

	if resumen_rect and imagen_9_panel:
		resumen_rect.texture = imagen_9_panel
		resumen_rect.visible = true

	actualizar_resumen_final()

	continuar_button.visible = true
	continuar_button.disabled = false
	continuar_button.modulate.a = 1.0
	continuar_button.text = "Continuar"
	
func actualizar_resumen_final() -> void:
	label_titulo.text = "TALLER EN QUIEBRA"
	label_descripcion.text = "La deuda hizo imposible mantener el taller abierto."

	label_texto_reputacion.text = "REPUTACIÓN"
	label_texto_clientes.text = "CLIENTES SATISFECHOS"
	label_texto_autos.text = "CLIENTES ATENDIDOS (TOTAL)"
	label_texto_dinero.text = "DINERO FINAL"

	var resumen := DATOSGLOBALES.get_resumen_final()
	var reputacion := int(resumen.get("reputacion", 0))
	var clientes_atendidos_total := int(resumen.get("clientes_atendidos", 0))
	var clientes_satisfechos := int(resumen.get("clientes_satisfechos", 0))
	var ganancias_totales := int(resumen.get("dinero_final", 0))

	label_reputacion.text = str(reputacion) + "%"
	indicador_reputacion.set_reputacion(reputacion)
	label_clientes.text = str(clientes_satisfechos)
	label_autos.text = str(clientes_atendidos_total)
	label_dinero.text = "$%d" % ganancias_totales if ganancias_totales >= 0 else "-$%d" % absi(ganancias_totales)
