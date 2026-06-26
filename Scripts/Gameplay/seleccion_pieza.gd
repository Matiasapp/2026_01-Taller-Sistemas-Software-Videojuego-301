extends CanvasLayer

signal pieza_elegida(tipo)

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

const COSTO_BUENA := 300
const COSTO_BARATA := 150
const COSTO_DUDOSA := 50

func _ready():

	label_precio_buena.text = "$" + str(COSTO_BUENA)

	label_precio_barata.text = "$" + str(COSTO_BARATA)

	label_precio_dudosa.text = "$" + str(COSTO_DUDOSA)

func seleccionar_pieza(tipo: String):

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

	pieza_seleccionada = tipo

	print("Pieza seleccionada: ", tipo)
	print("Dinero actual: ", DATOSGLOBALES.dinero)

	pieza_elegida.emit(tipo)

	queue_free()

func _on_area_buena_mouse_entered():
	if pieza_seleccionada != "buena":
		rect_buena.color.a = 0.15


func _on_area_buena_mouse_exited():
	if pieza_seleccionada != "buena":
		rect_buena.color.a = 0

func _on_area_barata_mouse_entered():
	if pieza_seleccionada != "barata":
		rect_barata.color.a = 0.15

func _on_area_dudosa_mouse_entered():
	if pieza_seleccionada != "dudosa":
		rect_dudosa.color.a = 0.15


func _on_area_dudosa_mouse_exited():
	if pieza_seleccionada != "dudosa":
		rect_dudosa.color.a = 0

func _on_area_barata_mouse_exited():
	if pieza_seleccionada != "barata":
		rect_barata.color.a = 0

func _on_area_buena_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		seleccionar_pieza("buena")


func _on_area_barata_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		seleccionar_pieza("barata")


func _on_area_dudosa_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		seleccionar_pieza("dudosa")
