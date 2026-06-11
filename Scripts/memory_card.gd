class_name MemoryCard
extends Control

signal card_clicked(card: MemoryCard)

const CARD_SIZE := Vector2(90, 120)

const COLOR_BORDE := Color("#8b949e")
const COLOR_REVERSO := Color("#21262d")
const COLOR_FRENTE := Color("#30363d")
const COLOR_PAREJA := Color("#161b22")
const COLOR_BORDE_MATCH := Color("#238636")

const SPRITESHEET_PATH := "res://Assets/sprites_taller.png"
const SPRITESHEET_COLS := 5
const SPRITESHEET_ROWS := 2

const FLIP_TIME := 0.08

var icon_type := 0
var id := 0

var is_flipped := false
var is_matched := false
var is_animating := false

var bg_borde: ColorRect
var bg_centro: ColorRect
var icon_rect: TextureRect


func setup(p_type: int, p_id: int) -> void:
	icon_type = p_type
	id = p_id

	custom_minimum_size = CARD_SIZE
	size = CARD_SIZE
	pivot_offset = CARD_SIZE / 2.0

	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE

	_crear_base_carta()
	_crear_icono()
	_recortar_spritesheet()

	_set_back_state()


func _crear_base_carta() -> void:
	bg_borde = ColorRect.new()
	bg_borde.name = "Borde"
	bg_borde.color = COLOR_BORDE
	bg_borde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_borde)

	bg_borde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	bg_centro = ColorRect.new()
	bg_centro.name = "Centro"
	bg_centro.color = COLOR_REVERSO
	bg_centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_centro)

	bg_centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_centro.offset_left = 3
	bg_centro.offset_top = 3
	bg_centro.offset_right = -3
	bg_centro.offset_bottom = -3


func _crear_icono() -> void:
	icon_rect = TextureRect.new()
	icon_rect.name = "Icono"
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_rect.visible = false

	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	add_child(icon_rect)

	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 8
	icon_rect.offset_top = 8
	icon_rect.offset_right = -8
	icon_rect.offset_bottom = -8


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

	var atlas_card := AtlasTexture.new()
	atlas_card.atlas = textura_completa
	atlas_card.region = region_recorte

	icon_rect.texture = atlas_card


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
	bg_centro.color = COLOR_FRENTE
	icon_rect.visible = true
	scale.x = 1.0


func _set_back_state() -> void:
	is_flipped = false
	bg_centro.color = COLOR_REVERSO
	icon_rect.visible = false
	scale.x = 1.0


func set_matched() -> void:
	is_matched = true
	is_flipped = true
	is_animating = false

	scale.x = 1.0

	bg_centro.color = COLOR_PAREJA
	bg_borde.color = COLOR_BORDE_MATCH

	icon_rect.visible = true
	modulate.a = 0.6
