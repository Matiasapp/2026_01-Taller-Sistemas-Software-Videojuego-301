extends Node2D

var jugador_en_rango_abrir_taller = false
var jugador_en_rango_interactuar_pc = false
var jugador_en_rango_atender_cliente = false
var puede_interactuar = true # Flag de seguridad (Debounce)

@onready var mensaje_abrir_taller = $Marker2DAbrirTaller/LabelAbrirTaller
@onready var mensaje_interactuar_pc = $Marker2DInteractuarPc/LabelInteractuarPc
@onready var mensaje_atender_cliente = $Marker2DAtenderCliente/LabelAtenderCliente
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mensaje_abrir_taller.visible = false
	mensaje_interactuar_pc.visible = false
	mensaje_atender_cliente.visible = false
	$Node2D/ventilador.play("giro_ventilador")
	GLOBALSIGNALS.cerrar_pc.connect(_on_cerrar_pc)
	
	if TIEMPOMANAGER and not TIEMPOMANAGER.has_initialized:
		TIEMPOMANAGER.stop_timer()
		TIEMPOMANAGER.has_initialized = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _input(event):
	if get_tree().paused: 
		return
	if not puede_interactuar: return
	if jugador_en_rango_abrir_taller and event.is_action_pressed("interactuar"):
		print("¡Se abrió el taller!")
	if jugador_en_rango_atender_cliente and event.is_action_pressed("interactuar"):
		print("¡Se atendió cliente!")
	if jugador_en_rango_interactuar_pc and event.is_action_pressed("interactuar"):
		GLOBALSIGNALS.abrir_pc.emit()
		print("¡Se abrió el pc!")

	
#TIEMPOMANAGER.start_timer()
#TIEMPOMANAGER.avanzar_dia()


'''
CODIGO INTERACCIÓN TALLER
'''

####
func _on_area_abrir_taller_body_entered(body):
	if body.name == "Player":
		jugador_en_rango_abrir_taller = true
		mensaje_abrir_taller.visible = true

func _on_area_abrir_taller_body_exited(body):
	if body.name == "Player":
		jugador_en_rango_abrir_taller = false
		mensaje_abrir_taller.visible = false


'''
CODIGO INTERACCIÓN USAR PC
'''
func _on_area_interactuar_pc_body_entered(body):
	if body.name == "Player":
		jugador_en_rango_interactuar_pc = true
		mensaje_interactuar_pc.visible = true
		
func _on_cerrar_pc():
	pass

func _on_area_interactuar_pc_body_exited(body):
	if body.name == "Player":
		jugador_en_rango_interactuar_pc = false
		mensaje_interactuar_pc.visible = false

'''
CODIGO INTERACCIÓN ATENDER CLIENTE
'''
func _on_area_atender_cliente_body_entered(body: Node2D):
	if body.name == "Player":
		jugador_en_rango_atender_cliente = true
		mensaje_atender_cliente.visible = true


func _on_area_atender_cliente_body_exited(body):
	if body.name == "Player":
		jugador_en_rango_atender_cliente = false
		mensaje_atender_cliente.visible = false
