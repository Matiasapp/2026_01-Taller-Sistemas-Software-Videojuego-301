extends Node
## Gestor de ajustes del juego (audio, video, controles).
## Carga y guarda en user://settings.cfg, y aplica los valores al iniciar.
## Autoload: AJUSTES.

const RUTA := "user://settings.cfg"

## Acciones del InputMap que el jugador puede remapear (en orden de aparición).
const ACCIONES_REMAPEABLES: Array[String] = [
	"mover_arriba", "mover_abajo", "mover_izquierda", "mover_derecha",
	"interactuar", "correr", "Saltar",
]

# --- Valores por defecto ---
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var fullscreen: bool = false
var vsync: bool = true


func _ready() -> void:
	cargar()


# =========================
# APLICAR
# =========================

func aplicar_todo() -> void:
	_aplicar_volumen("Master", master_volume)
	_aplicar_volumen("Music", music_volume)
	_aplicar_volumen("SFX", sfx_volume)
	aplicar_pantalla_completa(fullscreen)
	aplicar_vsync(vsync)


func _aplicar_volumen(bus: String, valor: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	var v := clampf(valor, 0.0, 1.0)
	AudioServer.set_bus_mute(idx, v <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(v, 0.0001)))


func set_volumen(bus: String, valor: float) -> void:
	match bus:
		"Master": master_volume = valor
		"Music": music_volume = valor
		"SFX": sfx_volume = valor
	_aplicar_volumen(bus, valor)
	guardar()


func get_volumen(bus: String) -> float:
	match bus:
		"Master": return master_volume
		"Music": return music_volume
		"SFX": return sfx_volume
	return 1.0


func aplicar_pantalla_completa(activo: bool) -> void:
	fullscreen = activo
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if activo else DisplayServer.WINDOW_MODE_WINDOWED
	)


func set_pantalla_completa(activo: bool) -> void:
	aplicar_pantalla_completa(activo)
	guardar()


func aplicar_vsync(activo: bool) -> void:
	vsync = activo
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if activo else DisplayServer.VSYNC_DISABLED
	)


func set_vsync(activo: bool) -> void:
	aplicar_vsync(activo)
	guardar()


# =========================
# CONTROLES (remapeo de teclas)
# =========================

func get_evento_tecla(accion: String) -> InputEventKey:
	if not InputMap.has_action(accion):
		return null
	for ev in InputMap.action_get_events(accion):
		if ev is InputEventKey:
			return ev
	return null


func set_tecla(accion: String, evento: InputEventKey) -> void:
	if not InputMap.has_action(accion):
		return
	InputMap.action_erase_events(accion)
	InputMap.action_add_event(accion, evento)
	guardar()


## Nombre legible de la tecla asignada a una acción (ej. "W", "Space", "Shift").
func nombre_tecla(accion: String) -> String:
	var ev := get_evento_tecla(accion)
	if ev == null:
		return "—"
	var code: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
	return OS.get_keycode_string(code)


# =========================
# GUARDAR / CARGAR
# =========================

func guardar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "vsync", vsync)
	for accion in ACCIONES_REMAPEABLES:
		var ev := get_evento_tecla(accion)
		if ev:
			cfg.set_value("input", accion, ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode)
	cfg.save(RUTA)


func cargar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(RUTA) != OK:
		# Primera vez (sin archivo): aplicamos los valores por defecto.
		aplicar_todo()
		return

	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	vsync = cfg.get_value("video", "vsync", vsync)

	for accion in ACCIONES_REMAPEABLES:
		var code: int = cfg.get_value("input", accion, -1)
		if code != -1 and InputMap.has_action(accion):
			var ev := InputEventKey.new()
			ev.physical_keycode = code
			InputMap.action_erase_events(accion)
			InputMap.action_add_event(accion, ev)

	aplicar_todo()


## Vuelve todo a los valores por defecto (audio, video y controles del proyecto).
func restablecer() -> void:
	master_volume = 1.0
	music_volume = 1.0
	sfx_volume = 1.0
	fullscreen = false
	vsync = true
	InputMap.load_from_project_settings()
	aplicar_todo()
	guardar()
