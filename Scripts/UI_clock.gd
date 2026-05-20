extends Label


func _ready() -> void:
	# Nos conectamos a la señal del script global
	TIMEMANAGER.time_changed.connect(_on_time_changed)
	
	# Mostrar la hora inicial al cargar la pantalla
	update_clock_text(TIMEMANAGER.current_hour, TIMEMANAGER.current_minute)
	
	# Iniciar el tiempo del día
	TIMEMANAGER.start_timer()

func _on_time_changed(hours: int, minutes: int) -> void:
	update_clock_text(hours, minutes)

func update_clock_text(hours: int, minutes: int) -> void:
	# String.format para que los números siempre tengan 2 dígitos (ej: 08:05 en vez de 8:5)
	text = "%02d:%02d" % [hours, minutes]
