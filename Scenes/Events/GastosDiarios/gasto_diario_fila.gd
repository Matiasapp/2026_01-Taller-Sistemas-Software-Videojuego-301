@tool
extends Panel
class_name GastoDiarioFila

## Fila editable de la libreta de gastos.
## Para agregar otro gasto, duplica una fila en GastosDiarios.tscn y cambia estos
## valores desde el Inspector. La pantalla principal la detecta automáticamente.

signal estado_cambiado

@export_category("Contenido del gasto")
@export var nombre := "Nuevo gasto":
	set(valor):
		nombre = valor
		_actualizar_vista_previa()
@export_multiline var detalle := "Describe aquí para qué sirve este pago.":
	set(valor):
		detalle = valor
		_actualizar_vista_previa()

@export_category("Costo")
@export_range(0, 100000, 1, "or_greater") var costo_base := 0:
	set(valor):
		costo_base = valor
		_actualizar_vista_previa()
@export_range(0, 100000, 1, "or_greater") var aumento_por_dia := 0
@export var seleccionado_por_defecto := false:
	set(valor):
		seleccionado_por_defecto = valor
		var boton := get_boton()
		if boton and Engine.is_editor_hint():
			boton.set_pressed_no_signal(valor)
			actualizar_texto_boton()

@export_category("Presentación")
@export var mostrar_nombre_en_mayusculas := true:
	set(valor):
		mostrar_nombre_en_mayusculas = valor
		_actualizar_vista_previa()
@export var texto_pagar := "PAGAR":
	set(valor):
		texto_pagar = valor
		actualizar_texto_boton()
@export var texto_postergar := "POSTERGAR":
	set(valor):
		texto_postergar = valor
		actualizar_texto_boton()

var costo_actual := 0


func _ready() -> void:
	var boton := get_boton()
	if boton and not boton.toggled.is_connected(_on_boton_toggled):
		boton.toggled.connect(_on_boton_toggled)
	_actualizar_vista_previa()


func configurar_para_dia(dia: int) -> void:
	costo_actual = costo_base + aumento_por_dia * maxi(0, dia - 1)
	var precio := get_precio_label()
	if precio:
		precio.text = "$%d" % costo_actual

	var boton := get_boton()
	if boton:
		boton.set_pressed_no_signal(seleccionado_por_defecto)
		actualizar_texto_boton()


func esta_seleccionado() -> bool:
	var boton := get_boton()
	return boton != null and boton.button_pressed


func actualizar_texto_boton() -> void:
	var boton := get_boton()
	if boton:
		# El texto describe la accion disponible, no el estado actual.
		boton.text = texto_postergar if boton.button_pressed else texto_pagar


func get_boton() -> CheckButton:
	return get_node_or_null("Fila/PagarCheck") as CheckButton


func get_precio_label() -> Label:
	return get_node_or_null("Fila/Precio") as Label


func _on_boton_toggled(_activo: bool) -> void:
	actualizar_texto_boton()
	if not Engine.is_editor_hint():
		estado_cambiado.emit()


func _actualizar_vista_previa() -> void:
	if not is_inside_tree():
		return

	var nombre_label := get_node_or_null("Fila/Textos/Nombre") as Label
	if nombre_label:
		nombre_label.text = nombre.to_upper() if mostrar_nombre_en_mayusculas else nombre

	var detalle_label := get_node_or_null("Fila/Textos/Detalle") as Label
	if detalle_label:
		detalle_label.text = detalle

	var precio := get_precio_label()
	if precio and Engine.is_editor_hint():
		precio.text = "$%d" % costo_base

	actualizar_texto_boton()
