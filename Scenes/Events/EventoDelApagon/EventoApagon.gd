extends CanvasLayer

signal evento_terminado

@onready var panel = $Panel
@onready var animacion = $AnimationPlayer

@onready var audio_apagon = $AudioApagon


func _ready() -> void:
	panel.visible = false

	iniciar()


func iniciar() -> void:

	panel.visible = false

	var game = get_parent()

	# ==========================
	# Mutear todos los audios
	# ==========================

	for audio in game.find_children("*", "AudioStreamPlayer2D", true, false):
		audio.stop()
		audio.seek(0.0)
		audio.stream_paused = true

	for audio in game.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
		audio.seek(0.0)
		audio.stream_paused = true

	# ==========================
	# Detener ventilador
	# ==========================

	if game.has_node("Node2D/ventilador"):
		game.get_node("Node2D/ventilador").stop()

	# ==========================
	# Detener animación de luces
	# ==========================

	if game.has_node("Node2D/AnimationPlayer"):
		game.get_node("Node2D/AnimationPlayer").stop()

	if game.has_node("Node2D/AnimationPlayer/PointLight2D"):
		game.get_node("Node2D/AnimationPlayer/PointLight2D").energy = 0.0

	if game.has_node("Node2D/AnimationPlayer/PointLight2D2"):
		game.get_node("Node2D/AnimationPlayer/PointLight2D2").energy = 0.0

	# ==========================
	# Reproducir sonido del apagón
	# ==========================

	audio_apagon.volume_db = 0
	audio_apagon.play()

	# ==========================
	# Reproducir animación
	# ==========================

	animacion.play("Apagon")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Apagon":
		panel.visible = true


func _on_continuar_pressed() -> void:

	var game = get_parent()

	panel.visible = false

	if game.has_method("cerrar_dia"):
		game.cerrar_dia()

	evento_terminado.emit()

	queue_free()
