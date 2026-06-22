extends Node

signal servicio_creado(falla: Dictionary)
signal servicio_actualizado(falla: Dictionary)
signal servicio_completado(falla: Dictionary, exito: bool, monto: int)

const ESTADO_SIN_SERVICIO := "sin_servicio"
const ESTADO_PENDIENTE := "pendiente"
const ESTADO_EN_REPARACION := "en_reparacion"
const ESTADO_REPARADO := "reparado"
const ESTADO_FALLIDO := "fallido"

const FALLAS_MVP := [
	{
		"id": "bateria_descargada",
		"nombre": "Bateria descargada",
		"descripcion_cliente": "El cliente indica que el auto no enciende y las luces se ven debiles.",
		"diagnostico": "Sistema electrico con baja carga.",
		"pistas": [
			"El motor intenta arrancar, pero no logra girar.",
			"Las luces del tablero tienen baja intensidad.",
			"El problema aparece despues de dejar el auto detenido."
		],
		"reparacion": "Revisar, recargar o reemplazar bateria.",
		"minijuego": "res://Scenes/MemoryGame.tscn",
		"recompensa_base": 80
	},
	{
		"id": "neumatico_desinflado",
		"nombre": "Neumatico desinflado",
		"descripcion_cliente": "El cliente siente que el auto se inclina y vibra al avanzar.",
		"diagnostico": "Presion irregular en una rueda.",
		"pistas": [
			"El vehiculo se carga hacia un lado.",
			"Se percibe vibracion a baja velocidad.",
			"La presion del neumatico esta bajo el rango normal."
		],
		"reparacion": "Inflar y comprobar el estado del neumatico.",
		"minijuego": "res://Scenes/Minigames/Neumaticos/MinijuegoNeumatico.tscn",
		"recompensa_base": 70
	},
	{
		"id": "pieza_metalica_danada",
		"nombre": "Pieza metalica danada",
		"descripcion_cliente": "El cliente escucha un ruido metalico bajo el vehiculo.",
		"diagnostico": "Pieza estructural o soporte con dano visible.",
		"pistas": [
			"El ruido aumenta cuando el auto pasa por baches.",
			"Hay una pieza suelta cerca de la zona inferior.",
			"Se observa una marca de desgaste o fisura."
		],
		"reparacion": "Soldar o fijar la pieza danada.",
		"minijuego": "res://Scenes/Minigames/Soldadura/Scene/Taller_soldadura.tscn",
		"recompensa_base": 90
	}
]

var falla_actual: Dictionary = {}
var estado_actual := ESTADO_SIN_SERVICIO
var ultima_falla_id := ""


func _ready() -> void:
	randomize()


func hay_servicio_activo() -> bool:
	return not falla_actual.is_empty() and estado_actual in [
		ESTADO_PENDIENTE,
		ESTADO_EN_REPARACION,
		ESTADO_FALLIDO
	]


func crear_servicio() -> Dictionary:
	if hay_servicio_activo():
		return falla_actual

	var plantilla: Dictionary = FALLAS_MVP.pick_random()

	while FALLAS_MVP.size() > 1 and plantilla["id"] == ultima_falla_id:
		plantilla = FALLAS_MVP.pick_random()

	falla_actual = plantilla.duplicate(true)
	ultima_falla_id = falla_actual["id"]
	falla_actual["estado"] = ESTADO_PENDIENTE
	estado_actual = ESTADO_PENDIENTE

	servicio_creado.emit(falla_actual)
	servicio_actualizado.emit(falla_actual)
	return falla_actual


func get_falla_actual() -> Dictionary:
	return falla_actual


func get_estado_actual() -> String:
	return estado_actual


func get_pistas_actuales() -> Array:
	if falla_actual.is_empty() or not falla_actual.has("pistas"):
		return []

	return falla_actual["pistas"]


func iniciar_reparacion() -> bool:
	if falla_actual.is_empty():
		return false

	if estado_actual == ESTADO_REPARADO:
		return false

	estado_actual = ESTADO_EN_REPARACION
	falla_actual["estado"] = estado_actual
	servicio_actualizado.emit(falla_actual)

	get_tree().paused = false
	get_tree().change_scene_to_file(falla_actual["minijuego"])
	return true


func completar_reparacion(exito: bool, monto: int) -> void:
	if falla_actual.is_empty():
		return

	estado_actual = ESTADO_REPARADO if exito else ESTADO_FALLIDO
	falla_actual["estado"] = estado_actual
	falla_actual["ultimo_monto"] = monto

	servicio_completado.emit(falla_actual, exito, monto)
	servicio_actualizado.emit(falla_actual)


func limpiar_servicio() -> void:
	falla_actual.clear()
	estado_actual = ESTADO_SIN_SERVICIO
