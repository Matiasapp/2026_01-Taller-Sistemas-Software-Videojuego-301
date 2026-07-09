class_name MemoryCard
extends Control

signal card_clicked(card: MemoryCard)

const CARD_SIZE := Vector2(96, 118)
const ICON_PADDING := 16

const COLOR_BORDE := Color("#5f4b31")
const COLOR_REVERSO := Color("#241914")
const COLOR_FRENTE := Color("#2c2520")
const COLOR_PAREJA := Color("#17251a")
const COLOR_BORDE_MATCH := Color("#238636")
const COLOR_METAL := Color("#4b5661")
const SPRITESHEET_PATH := "res://Assets/Sprites/MemorizeGame/sprites_taller.png"
const BACK_CARD_PATH := "res://Assets/Sprites/MemorizeGame/carta_memory.png"
const SPRITESHEET_COLS := 5
const SPRITESHEET_ROWS := 2

const FLIP_TIME := 0.08

var icon_type := 0
var id := 0

var is_flipped := false
var is_matched := false
var is_animating := false

var bg_borde: Panel
var bg_centro: Panel
var back_rect: TextureRect
var icon_rect: TextureRect

# El spritesheet se carga una sola vez y se comparte entre todas las cartas.
static var _base_spritesheet: Texture2D = null


func setup(p_type: int, p_id: int) -> void:
	icon_type = p_type
	id = p_id

	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE / 2.0
	clip_contents = true

	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

	_crear_base_carta()
	_crear_icono()
	_recortar_spritesheet()

	_set_back_state()


func _crear_base_carta() -> void:
	bg_borde = Panel.new()
	bg_borde.name = "Borde"
	bg_borde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_borde.add_theme_stylebox_override("panel", _crear_style(COLOR_BORDE, Color("#15100d"), 2, 8))
	add_child(bg_borde)

	bg_borde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	bg_centro = Panel.new()
	bg_centro.name = "Centro"
	bg_centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_centro)

	bg_centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_centro.offset_left = 4
	bg_centro.offset_top = 4
	bg_centro.offset_right = -4
	bg_centro.offset_bottom = -4

	back_rect = TextureRect.new()
	back_rect.name = "Reverso"
	back_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# El proyecto usa filtro Nearest (pixel-art) por defecto; estas imágenes son de
	# alta resolución mostradas en miniatura, así que con Nearest se ven pixeladas.
	# Con mipmaps el reverso (1254 px -> ~96 px) se reduce sin aliasing.
	back_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(back_rect)
	back_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	back_rect.texture = _obtener_textura_back()


func _crear_icono() -> void:
	icon_rect = TextureRect.new()
	icon_rect.name = "Icono"
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.visible = false

	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# El proyecto usa Nearest por defecto; con filtro lineal + mipmaps el ícono (256 px
	# mostrado a ~80 px) se reduce sin aliasing y se ve más nítido. El margen transparente
	# de cada celda evita que los mipmaps mezclen herramientas vecinas del atlas.
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

	add_child(icon_rect)

	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = ICON_PADDING
	icon_rect.offset_top = ICON_PADDING
	icon_rect.offset_right = -ICON_PADDING
	icon_rect.offset_bottom = -ICON_PADDING


func _recortar_spritesheet() -> void:
	icon_rect.texture = _obtener_textura_icono(icon_type)


## Devuelve un AtlasTexture que recorta (por GPU) la celda del ícono en el spritesheet.
## El sheet es una grilla uniforme (5x2, celdas iguales), así que basta el corte simple:
## no hay procesado por píxel ni por carta.
static func _obtener_textura_icono(tipo: int) -> Texture2D:
	if _base_spritesheet == null:
		if not ResourceLoader.exists(SPRITESHEET_PATH):
			push_error("No se encontró la hoja de sprites en: " + SPRITESHEET_PATH)
			return null
		_base_spritesheet = load(SPRITESHEET_PATH) as Texture2D

	if _base_spritesheet == null:
		return null

	@warning_ignore("integer_division")
	var frame_w := _base_spritesheet.get_width() / SPRITESHEET_COLS
	@warning_ignore("integer_division")
	var frame_h := _base_spritesheet.get_height() / SPRITESHEET_ROWS

	var columna := tipo % SPRITESHEET_COLS

	@warning_ignore("integer_division")
	var fila := tipo / SPRITESHEET_COLS

	var atlas := AtlasTexture.new()
	atlas.atlas = _base_spritesheet
	atlas.region = Rect2(columna * frame_w, fila * frame_h, frame_w, frame_h)
	return atlas


## Devuelve el reverso de la carta. Ya viene listo, así que solo se carga.
func _obtener_textura_back() -> Texture2D:
	if ResourceLoader.exists(BACK_CARD_PATH):
		return load(BACK_CARD_PATH) as Texture2D
	return null


func _crear_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 3
	style.shadow_offset = Vector2(2, 2)
	return style


func _aplicar_estilo_carta(fill: Color, border: Color, matched: bool = false) -> void:
	bg_borde.add_theme_stylebox_override("panel", _crear_style(border, Color("#111111"), 2, 8))
	bg_centro.add_theme_stylebox_override("panel", _crear_style(fill, COLOR_METAL if not matched else COLOR_BORDE_MATCH, 1, 6))


func _gui_input(event: InputEvent) -> void:
	if is_matched:
		return

	if is_flipped:
		return

	if is_animating:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			accept_event()
			card_clicked.emit(self)


func flip(animated: bool = true) -> void:
	if is_matched:
		return

	if is_flipped:
		return

	if is_animating:
		return

	if not animated:
		_set_front_state()
		return

	is_animating = true

	var tween := create_tween()
	tween.tween_property(self, "scale:x", 0.0, FLIP_TIME)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	await tween.finished

	_set_front_state()

	tween = create_tween()
	tween.tween_property(self, "scale:x", 1.0, FLIP_TIME)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	await tween.finished

	is_animating = false


func flip_back(animated: bool = true) -> void:
	if is_matched:
		return

	if not is_flipped:
		return

	if is_animating:
		return

	if not animated:
		_set_back_state()
		return

	is_animating = true

	var tween := create_tween()
	tween.tween_property(self, "scale:x", 0.0, FLIP_TIME)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	await tween.finished

	_set_back_state()

	tween = create_tween()
	tween.tween_property(self, "scale:x", 1.0, FLIP_TIME)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	await tween.finished

	is_animating = false


func _set_front_state() -> void:
	is_flipped = true
	_aplicar_estilo_carta(COLOR_FRENTE, Color("#7a5431"))
	back_rect.visible = false
	icon_rect.visible = true
	scale.x = 1.0


func _set_back_state() -> void:
	is_flipped = false
	_aplicar_estilo_carta(COLOR_REVERSO, COLOR_BORDE)
	back_rect.visible = true
	icon_rect.visible = false
	scale.x = 1.0


func set_matched() -> void:
	is_matched = true
	is_flipped = true
	is_animating = false

	scale.x = 1.0

	_aplicar_estilo_carta(COLOR_PAREJA, COLOR_BORDE_MATCH, true)
	back_rect.visible = false

	icon_rect.visible = true
	modulate.a = 0.6
