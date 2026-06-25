extends CanvasLayer

@onready var boton_resumen_dia: Button = $BotónResumenDia

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	if boton_resumen_dia:
		boton_resumen_dia.process_mode = Node.PROCESS_MODE_ALWAYS
		
		if not boton_resumen_dia.pressed.is_connected(_on_boton_resumen_dia_pressed):
			boton_resumen_dia.pressed.connect(_on_boton_resumen_dia_pressed)

func _on_boton_resumen_dia_pressed() -> void:
	visible = false
	Engine.time_scale = 1.0
	
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.paused = false
