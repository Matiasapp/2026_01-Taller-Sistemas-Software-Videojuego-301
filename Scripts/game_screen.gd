extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	if TIEMPOMANAGER and not TIEMPOMANAGER.has_initialized:
		TIEMPOMANAGER.stop_timer()
		TIEMPOMANAGER.has_initialized = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass



func _on_start_day_button_pressed() -> void:
	TIEMPOMANAGER.start_timer()
	TIEMPOMANAGER.avanzar_dia()
	$CanvasLayer/start_day_button.visible = false
