extends Node

var click_sound = preload("res://Assets/Audio/Menu/click.wav")
var hover_sound = preload("res://Assets/Audio/Menu/hoverclick.wav")

# Variante "suave", para los controles que deben distinguirse del resto de la UI:
# el enlace de créditos del menú principal y los botones del PC del taller.
var soft_click_sound = preload("res://Assets/Audio/GameScreen/softclick1.wav")
var soft_hover_sound = preload("res://Assets/Audio/GameScreen/hoversoftclick1.wav")

## El hover suave se dispara con solo pasar el mouse, así que va más bajo que el
## click para que no moleste al recorrer varios botones seguidos.
const VOLUMEN_HOVER_SUAVE_DB := -4.0

var ui_player := AudioStreamPlayer.new()

func _ready() -> void:
	add_child(ui_player)
	ui_player.bus = "SFX"
	# Los botones de pausa y de resultados siguen activos con el árbol pausado.
	# Su reproductor también debe ignorar esa pausa para que hover/click se oigan.
	ui_player.process_mode = Node.PROCESS_MODE_ALWAYS

func play_ui_click() -> void:
	_reproducir_ui(click_sound, 2.0)

func play_ui_hover() -> void:
	_reproducir_ui(hover_sound, 5.0)

func play_ui_soft_click() -> void:
	_reproducir_ui(soft_click_sound, 2.0)

func play_ui_soft_hover() -> void:
	_reproducir_ui(soft_hover_sound, 5.0, VOLUMEN_HOVER_SUAVE_DB)

## Reproduce un sonido de UI variando el tono al azar (+-'semitonos') para que
## las repeticiones seguidas no suenen idénticas. El volumen se fija siempre,
## porque todos los sonidos comparten el mismo reproductor y si no el ajuste de
## uno quedaría aplicado al siguiente.
func _reproducir_ui(stream: AudioStream, semitonos: float, volumen_db: float = 0.0) -> void:
	if not stream:
		return

	ui_player.stream = stream
	ui_player.volume_db = volumen_db
	ui_player.pitch_scale = pow(2.0, randf_range(-semitonos, semitonos) / 12.0)
	ui_player.play()
