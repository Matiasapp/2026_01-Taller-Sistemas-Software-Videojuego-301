extends Panel


@onready var lista_dias = $MarginContainer/ScrollContainer/VBoxContainer
@onready var sin_dias = $MarginContainer/Sin_dia_registrado

var fila_historial = preload("res://Scenes/UI/Fila_historial.tscn")

func _ready():
	#Prueba impresion
	#DATOSGLOBALES.guardar_dia()
	
	#print("Historial:")
	#print(DATOSGLOBALES.historial_dias)

	#print("Cantidad de dias:")
	#print(DATOSGLOBALES.historial_dias.size())
	
	if DATOSGLOBALES.historial_dias.is_empty():
		sin_dias.visible = 1
		sin_dias.text = "Todavia no se a registrado ningun dia"
	
	else:	
		sin_dias.visible = 0
		
		for datos_dia in DATOSGLOBALES.historial_dias:
			print("se a imprimido historial del dias")
			var nueva_fila = fila_historial.instantiate()

			nueva_fila.configurar(datos_dia)

			lista_dias.add_child(nueva_fila)

func _on_button_pressed() -> void:
	# 1. Deshabilitamos el botón inmediatamente para evitar que el jugador spamee clics mientras se cierra
	$Button.disabled = true
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)
	
	# 2. Todo lo que deba ocurrir al TERMINAR la animación debe ir dentro de este callback
	tween.chain().tween_callback(func():
		# Reseteamos el panel visualmente para la próxima vez que se abra
		self.visible = false
		self.modulate.a = 1.0
		self.scale = Vector2(1.0, 1.0)
		
		# 3. Quitamos la pausa general del juego
		get_tree().paused = false
		
		# 4. CRUCIAL: Emitimos la señal para que GameScreen vuelva a permitir interacciones
		GLOBALSIGNALS.cerrar_pc.emit() 
		
		# 5. Volvemos a habilitar el botón para el futuro
		$Button.disabled = false
	)
