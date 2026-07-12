extends CanvasLayer

signal pieza_elegida(tipo)

const COSTO_BUENA := 300
const COSTO_BARATA := 150
const COSTO_DUDOSA := 50

var pieza_seleccionada := ""

@onready var buena = $AreaBuena
@onready var barata = $AreaBarata
@onready var dudosa = $AreaDudosa

@onready var rect_buena = $ColorRectBuena
@onready var rect_barata = $ColorRectBarata
@onready var rect_dudosa = $ColorRectDudosa

@onready var label_precio_buena = $LabelPrecioBuena
@onready var label_precio_barata = $LabelPrecioBarata
@onready var label_precio_dudosa = $LabelPrecioDudosa

@onready var hover_sound: AudioStreamPlayer = $HoverSound
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var transition_whoosh: AudioStreamPlayer = $TransitionWhoosh
@onready var fade_rect: ColorRect = $FadeRect


func _ready() -> void:
	label_precio_buena.text = "$" + str(COSTO_BUENA)
	label_precio_barata.text = "$" + str(COSTO_BARATA)
	label_precio_dudosa.text = "$" + str(COSTO_DUDOSA)


func seleccionar_pieza(tipo: String) -> void:
	if pieza_seleccionada != "":
		return

	pieza_seleccionada = tipo

	play_click_pieza()

	rect_buena.color.a = 0
	rect_barata.color.a = 0
	rect_dudosa.color.a = 0

	if tipo == "buena":
		rect_buena.color.a = 0.25
		DATOSGLOBALES.restar_dinero(COSTO_BUENA)

	elif tipo == "barata":
		rect_barata.color.a = 0.25
		DATOSGLOBALES.restar_dinero(COSTO_BARATA)

	elif tipo == "dudosa":
		rect_dudosa.color.a = 0.25
		DATOSGLOBALES.restar_dinero(COSTO_DUDOSA)

	DATOSGLOBALES.registrar_calidad_pieza(tipo)

	print("Pieza seleccionada: ", tipo)
	print("Dinero actual: ", DATOSGLOBALES.dinero)

	await click_sound.finished
	await transition_to_minigame(tipo)


func play_hover_pieza() -> void:
	if pieza_seleccionada != "":
		return

	if not hover_sound:
		return

	var semitones := randf_range(-0.8, 0.8)
	hover_sound.pitch_scale = pow(2.0, semitones / 12.0)
	hover_sound.volume_db = -8.0
	hover_sound.play()


func play_click_pieza() -> void:
	if not click_sound:
		return

	var semitones := randf_range(-1.0, 1.0)
	click_sound.pitch_scale = pow(2.0, semitones / 12.0)
	click_sound.volume_db = -7.0
	click_sound.play()
	
func fade_to_black(duration := 0.45) -> void:
	if not fade_rect:
		push_warning("SeleccionPieza: no se encontró FadeRect.")
		return

	fade_rect.visible = true
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)

	await tween.finished
	
func transition_to_minigame(tipo: String) -> void:
	if transition_whoosh:
		transition_whoosh.volume_db = -4.0
		transition_whoosh.pitch_scale = 1.0
		transition_whoosh.play()

	await fade_to_black(0.45)

	if transition_whoosh and transition_whoosh.playing:
		await transition_whoosh.finished

	pieza_elegida.emit(tipo)
	queue_free()

func _on_area_buena_mouse_entered() -> void:
	if pieza_seleccionada != "buena":
		play_hover_pieza()
		rect_buena.color.a = 0.15


func _on_area_buena_mouse_exited() -> void:
	if pieza_seleccionada != "buena":
		rect_buena.color.a = 0


func _on_area_barata_mouse_entered() -> void:
	if pieza_seleccionada != "barata":
		play_hover_pieza()
		rect_barata.color.a = 0.15


func _on_area_barata_mouse_exited() -> void:
	if pieza_seleccionada != "barata":
		rect_barata.color.a = 0


func _on_area_dudosa_mouse_entered() -> void:
	if pieza_seleccionada != "dudosa":
		play_hover_pieza()
		rect_dudosa.color.a = 0.15


func _on_area_dudosa_mouse_exited() -> void:
	if pieza_seleccionada != "dudosa":
		rect_dudosa.color.a = 0


func _on_area_buena_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		seleccionar_pieza("buena")


func _on_area_barata_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		seleccionar_pieza("barata")


func _on_area_dudosa_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		seleccionar_pieza("dudosa")
