extends CanvasLayer

signal evento_terminado

@onready var panel = $Panel
@onready var animacion = $AnimationPlayer

@onready var audio_apagon = $AudioApagon
@onready var continuar_button: Button = $Panel/Continuar


func _ready() -> void:
	panel.visible = false

	iniciar()


func iniciar() -> void:

	panel.visible = false

	var game = get_parent()

	# ==========================
	# Mutear todos los audios
	# ==========================

	# La busqueda es recursiva sobre el taller, y este evento ya cuelga de el:
	# hay que saltarse los audios propios o el apagon se dejaria mudo a si mismo.
	for audio in game.find_children("*", "AudioStreamPlayer2D", true, false):
		if is_ancestor_of(audio):
			continue
		audio.stop()
		audio.seek(0.0)
		audio.stream_paused = true

	for audio in game.find_children("*", "AudioStreamPlayer", true, false):
		if is_ancestor_of(audio):
			continue
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
	if continuar_button.disabled:
		return
	continuar_button.disabled = true
	# Suena por el AUDIOMANAGER, igual que el resto de eventos: su reproductor
	# vive fuera del taller y por tanto no lo alcanza el muteo de iniciar().
	AUDIOMANAGER.play_ui_click()
	panel.visible = false
	evento_terminado.emit()


func _on_continuar_mouse_entered() -> void:
	if not continuar_button.disabled:
		AUDIOMANAGER.play_ui_hover()
