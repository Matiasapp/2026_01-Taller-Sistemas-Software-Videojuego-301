class_name MemoryCard
extends Control

signal card_clicked(card: MemoryCard)

const CARD_SIZE := Vector2(96, 118)
const ICON_PADDING := 16
const SPRITE_CROP_PADDING := 8

const COLOR_BORDE := Color("#5f4b31")
const COLOR_REVERSO := Color("#241914")
const COLOR_FRENTE := Color("#2c2520")
const COLOR_PAREJA := Color("#17251a")
const COLOR_BORDE_MATCH := Color("#238636")
const COLOR_METAL := Color("#4b5661")
const SPRITESHEET_PATH := "res://Assets/sprites_taller.png"
const BACK_CARD_PATH := "res://Assets/carta_memory.png"
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
	add_child(back_rect)
	back_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if ResourceLoader.exists(BACK_CARD_PATH):
		back_rect.texture = _cargar_textura_limpia(BACK_CARD_PATH)


func _crear_icono() -> void:
	icon_rect = TextureRect.new()
	icon_rect.name = "Icono"
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.visible = false

	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	add_child(icon_rect)

	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = ICON_PADDING
	icon_rect.offset_top = ICON_PADDING
	icon_rect.offset_right = -ICON_PADDING
	icon_rect.offset_bottom = -ICON_PADDING


func _recortar_spritesheet() -> void:
	if not ResourceLoader.exists(SPRITESHEET_PATH):
		push_error("No se encontró la hoja de sprites en: " + SPRITESHEET_PATH)
		return

	var textura_completa := load(SPRITESHEET_PATH) as Texture2D

	if textura_completa == null:
		push_error("No se pudo cargar la textura: " + SPRITESHEET_PATH)
		return

	var tex_w := float(textura_completa.get_width())
	var tex_h := float(textura_completa.get_height())

	var frame_w := tex_w / float(SPRITESHEET_COLS)
	var frame_h := tex_h / float(SPRITESHEET_ROWS)

	var columna := icon_type % SPRITESHEET_COLS

	@warning_ignore("integer_division")
	var fila := icon_type / SPRITESHEET_COLS

	var region_recorte := Rect2(
		columna * frame_w,
		fila * frame_h,
		frame_w,
		frame_h
	)
	region_recorte = _obtener_region_visible(textura_completa, region_recorte)

	var image: Image = textura_completa.get_image()
	if image == null:
		return

	var cropped := image.get_region(_rect2_to_rect2i(region_recorte))
	cropped.convert(Image.FORMAT_RGBA8)
	_limpiar_fondo_sprite(cropped)

	icon_rect.texture = ImageTexture.create_from_image(cropped)


func _cargar_textura_limpia(path: String) -> Texture2D:
	var texture := load(path) as Texture2D
	if texture == null:
		return null

	var image: Image = texture.get_image()
	if image == null:
		return texture

	var visible_region := _obtener_region_visible(texture, Rect2(Vector2.ZERO, Vector2(image.get_width(), image.get_height())))
	image = image.get_region(_rect2_to_rect2i(visible_region))
	image.convert(Image.FORMAT_RGBA8)
	_limpiar_fondo_sprite(image)
	return ImageTexture.create_from_image(image)


func _rect2_to_rect2i(rect: Rect2) -> Rect2i:
	return Rect2i(
		Vector2i(int(rect.position.x), int(rect.position.y)),
		Vector2i(int(rect.size.x), int(rect.size.y))
	)


func _obtener_region_visible(texture: Texture2D, frame: Rect2) -> Rect2:
	var image: Image = texture.get_image()
	if image == null:
		return frame

	var min_x: int = int(frame.position.x + frame.size.x)
	var min_y: int = int(frame.position.y + frame.size.y)
	var max_x: int = int(frame.position.x)
	var max_y: int = int(frame.position.y)
	var found_pixel := false

	var start_x: int = int(frame.position.x)
	var start_y: int = int(frame.position.y)
	var end_x: int = int(frame.position.x + frame.size.x)
	var end_y: int = int(frame.position.y + frame.size.y)

	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			if _es_pixel_fondo_sprite(image.get_pixel(x, y)):
				continue

			found_pixel = true
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)

	if not found_pixel:
		return frame

	min_x = maxi(start_x, min_x - SPRITE_CROP_PADDING)
	min_y = maxi(start_y, min_y - SPRITE_CROP_PADDING)
	max_x = mini(end_x - 1, max_x + SPRITE_CROP_PADDING)
	max_y = mini(end_y - 1, max_y + SPRITE_CROP_PADDING)

	return Rect2(
		min_x,
		min_y,
		maxi(1, max_x - min_x + 1),
		maxi(1, max_y - min_y + 1)
	)


func _limpiar_fondo_sprite(image: Image) -> void:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel: Color = image.get_pixel(x, y)
			if not _es_pixel_fondo_sprite(pixel):
				continue

			pixel.a = 0.0
			image.set_pixel(x, y, pixel)


func _es_pixel_fondo_sprite(pixel: Color) -> bool:
	if pixel.a <= 0.05:
		return true

	var max_channel: float = maxf(pixel.r, maxf(pixel.g, pixel.b))
	var min_channel: float = minf(pixel.r, minf(pixel.g, pixel.b))
	return min_channel > 0.88 and max_channel - min_channel < 0.08


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
