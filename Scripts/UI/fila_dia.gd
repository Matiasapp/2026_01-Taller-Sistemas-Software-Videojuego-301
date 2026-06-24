extends Panel

@onready var lbl_dia = $HBoxContainer/Dia
@onready var lbl_ingresos = $HBoxContainer/Ingreso 
@onready var lbl_gastos = $HBoxContainer/Gastos
@onready var lbl_clientes = $HBoxContainer/Cliente
@onready var lbl_dinero = $HBoxContainer/Dinero


func configurar(datos: Dictionary):
	if lbl_dia: lbl_dia.text = "Día " + str(datos.get("dia", 0)) + "      "
	if lbl_ingresos: lbl_ingresos.text = "$" + str(datos.get("ingresos", 0)) + "     "
	if lbl_gastos: lbl_gastos.text = "$" + str(datos.get("gastos", 0)) + "     "
	if lbl_clientes: lbl_clientes.text = str(datos.get("clientes", 0)) + "     "
	if lbl_dinero: lbl_dinero.text = "$" + str(datos.get("dinero", 0))
