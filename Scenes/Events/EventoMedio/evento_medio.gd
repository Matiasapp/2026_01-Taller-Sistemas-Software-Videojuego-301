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

@export var imagen_hombre_2: Texture2D
@export var imagen_mujer_2: Texture2D

@export var imagen_hombre_3: Texture2D
@export var imagen_mujer_3: Texture2D

@export var imagen_hombre_4: Texture2D
@export var imagen_mujer_4: Texture2D

@export var imagen_hombre_5: Texture2D
@export var imagen_mujer_5: Texture2D

@export var imagen_hombre_6: Texture2D
@export var imagen_mujer_6: Texture2D

@export var imagen_resumen_fondo: Texture2D
@export var imagen_resumen_panel: Texture2D

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
		"Cuando llegaste, el taller llevaba tiempo funcionando con dificultades. Las herramientas estaban desgastadas, los recursos eran limitados y cada jornada traía nuevos problemas. Aun así, asumiste la responsabilidad de mantenerlo en marcha.",

		"Durante la semana reparaste vehículos, atendiste clientes y resolviste los problemas que aparecieron en el camino. Algunos trabajos salieron bien; otros dejaron claro que todavía había mucho por mejorar.",

		"No todos los clientes se fueron satisfechos, pero tampoco dejaron de llegar. Para algunos, el taller cumplió con lo necesario. Para otros, siguió siendo solo una alternativa más entre tantas.",

		"El dinero alcanzó para cubrir parte de los gastos y continuar trabajando. No hubo grandes inversiones ni cambios importantes. Las mismas herramientas, el mismo espacio y una nueva jornada por delante.",

		"Al terminar la semana, el taller no era muy diferente al que encontraste. No lograste transformarlo, pero tampoco permitiste que desapareciera. Simplemente conseguiste mantenerlo funcionando.",

		"A la mañana siguiente, volviste a abrir las puertas. Todavía quedan reparaciones por hacer, clientes por atender y decisiones que tomar. Por ahora, el taller continúa."
	]

	var es_mujer := DATOSGLOBALES.genero_jugador == "Femenino"

	imagenes = [
		seleccionar_imagen_genero(imagen_hombre_1, imagen_mujer_1, es_mujer),
		seleccionar_imagen_genero(imagen_hombre_2, imagen_mujer_2, es_mujer),
		seleccionar_imagen_genero(imagen_hombre_3, imagen_mujer_3, es_mujer),
		seleccionar_imagen_genero(imagen_hombre_4, imagen_mujer_4, es_mujer),
		seleccionar_imagen_genero(imagen_hombre_5, imagen_mujer_5, es_mujer),
		seleccionar_imagen_genero(imagen_hombre_6, imagen_mujer_6, es_mujer)
	]


func seleccionar_imagen_genero(
	imagen_hombre: Texture2D,
	imagen_mujer: Texture2D,
	es_mujer: bool
) -> Texture2D:
	if es_mujer and imagen_mujer:
		return imagen_mujer

	return imagen_hombre

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
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")


func _on_comenzar_pressed() -> void:
	if continuar_button.disabled:
		return

	continuar_button.disabled = true
	AUDIOMANAGER.play_ui_click()

	await get_tree().create_timer(0.15).timeout

	await finalizar_evento()


func _on_comenzar_mouse_entered() -> void:
	if not continuar_button.disabled:
		AUDIOMANAGER.play_ui_hover()
		


func mostrar_resumen_limpio() -> void:
	stop_talking()
	resumen_listo_para_salir = true

	if imagen_resumen_fondo:
		imagen.texture = imagen_resumen_fondo

	if panel_texto:
		panel_texto.visible = false

	if resumen_rect and imagen_resumen_panel:
		resumen_rect.texture = imagen_resumen_panel
		resumen_rect.visible = true

	actualizar_resumen_final()

	continuar_button.visible = true
	continuar_button.disabled = false
	continuar_button.modulate.a = 1.0
	continuar_button.text = "Continuar"
	
func actualizar_resumen_final() -> void:
	label_titulo.text = "EL TALLER CONTINÚA"
	label_descripcion.text = "Completaste los 5 días y mantuviste el taller en funcionamiento."

	label_texto_reputacion.text = "REPUTACIÓN"
	label_texto_clientes.text = "CLIENTES SATISFECHOS"
	label_texto_autos.text = "CLIENTES ATENDIDOS (TOTAL)"
	label_texto_dinero.text = "DINERO FINAL"

	var stats := DATOSGLOBALES.get_estadisticas_generales()
	var reputacion: int = DATOSGLOBALES.reputacion
	var clientes_atendidos_total: int = int(stats.get("clientes_atendidos", 0))
	var incidentes: int = (
		int(stats.get("diagnosticos_incorrectos", 0))
		+ int(stats.get("minijuegos_fallidos", 0))
	)
	var clientes_satisfechos := maxi(0, clientes_atendidos_total - incidentes)
	var ganancias_totales := DATOSGLOBALES.dinero

	label_reputacion.text = str(reputacion) + "%"
	indicador_reputacion.set_reputacion(reputacion)
	label_clientes.text = str(clientes_satisfechos)
	label_autos.text = str(clientes_atendidos_total)
	label_dinero.text = "$%d" % ganancias_totales if ganancias_totales >= 0 else "-$%d" % absi(ganancias_totales)
