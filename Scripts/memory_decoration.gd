extends Node2D

const CARD_W := 90
const CARD_H := 120
const GAP := 12
const COLS := 5
const ROWS := 4

const BOARD_W := COLS * (CARD_W + GAP) - GAP
const BOARD_H := ROWS * (CARD_H + GAP) - GAP

const SPRITESHEET_PATH := "res://Assets/sprites_taller.png"
const SPRITESHEET_COLS := 5
const SPRITESHEET_ROWS := 2

const C_PANEL := Color("#161b22")
const C_BORDER := Color("#30363d")
const C_ACCENT := Color("#e6af2e")
const C_DIM := Color(1, 1, 1, 0.06)
const C_RIVETS := Color("#3d444d")
const C_GREASE := Color("#1a1a1c")

var spritesheet: Texture2D


func _ready() -> void:
	z_index = -10

	if ResourceLoader.exists(SPRITESHEET_PATH):
		spritesheet = load(SPRITESHEET_PATH) as Texture2D
	else:
		push_warning("No se encontró la hoja de sprites para decoración: " + SPRITESHEET_PATH)

	queue_redraw()


func _draw() -> void:
	var screen := get_viewport_rect().size
	var bx := (screen.x - BOARD_W) / 2.0
	var by := (screen.y - BOARD_H) / 2.0

	_draw_workbench(bx, by)
	_draw_bolts_border(bx, by)
	_draw_gauge(Vector2(bx - 110, by + 60))
	_draw_gauge(Vector2(bx + BOARD_W + 110, by + 60))
	_draw_oil_drips(bx, by)
	_draw_tire_stack(Vector2(bx - 115, by + BOARD_H - 135))
	_draw_tire_stack(Vector2(bx + BOARD_W + 115, by + BOARD_H - 135))
	_draw_warning_stripe(screen, by + BOARD_H + 22)
	_draw_title_plate(Vector2(screen.x / 2.0, by - 42))
	_draw_sprite_decorations(bx, by)


func _draw_workbench(bx: float, by: float) -> void:
	var pad := 18.0

	draw_rect(
		Rect2(bx - pad, by - pad, BOARD_W + pad * 2, BOARD_H + pad * 2),
		C_PANEL
	)

	draw_rect(
		Rect2(bx - pad, by - pad, BOARD_W + pad * 2, BOARD_H + pad * 2),
		C_BORDER,
		false,
		1.5
	)

	draw_line(
		Vector2(bx - pad, by - pad + 3),
		Vector2(bx + BOARD_W + pad, by - pad + 3),
		C_ACCENT,
		2.0
	)

	var step := 8.0
	var i := 0

	while i * step < BOARD_H + pad * 2:
		var y := by - pad + i * step
		draw_line(
			Vector2(bx - pad, y),
			Vector2(bx + BOARD_W + pad, y),
			C_DIM,
			0.5
		)
		i += 1


func _draw_bolts_border(bx: float, by: float) -> void:
	var pad := 10.0

	var corners := [
		Vector2(bx - pad, by - pad),
		Vector2(bx + BOARD_W + pad, by - pad),
		Vector2(bx - pad, by + BOARD_H + pad),
		Vector2(bx + BOARD_W + pad, by + BOARD_H + pad),
	]

	for c in corners:
		draw_circle(c, 5.0, C_RIVETS)
		draw_circle(c, 5.0, C_BORDER, false, 1.0)
		draw_line(Vector2(c.x - 3, c.y), Vector2(c.x + 3, c.y), Color("#555e68"), 1.0)
		draw_line(Vector2(c.x, c.y - 3), Vector2(c.x, c.y + 3), Color("#555e68"), 1.0)


func _draw_gauge(pos: Vector2) -> void:
	var r := 28.0
	var c_bg := Color("#1a2030")
	var c_ring := Color("#e6af2e")
	var c_glass := Color(0.5, 0.7, 1.0, 0.15)
	var c_needle := Color("#e74c3c")
	var c_text := Color(0.7, 0.7, 0.75)

	draw_circle(pos, r + 4, C_RIVETS)
	draw_circle(pos, r, c_bg)
	draw_arc(pos, r, 0, TAU, 40, c_ring, 2.0)

	for i in range(8):
		var angle := i * TAU / 8.0
		var inner := pos + Vector2(cos(angle), sin(angle)) * (r * 0.72)
		var outer := pos + Vector2(cos(angle), sin(angle)) * (r * 0.92)
		draw_line(inner, outer, c_text, 1.0)

	var needle_angle := -PI * 0.2
	var needle_tip := pos + Vector2(cos(needle_angle), sin(needle_angle)) * (r * 0.65)

	draw_line(pos, needle_tip, c_needle, 2.0)
	draw_circle(pos, 3.5, c_ring)
	draw_circle(Vector2(pos.x - r * 0.25, pos.y - r * 0.25), r * 0.35, c_glass)


func _draw_oil_drips(bx: float, by: float) -> void:
	var drip_c := Color(0.05, 0.05, 0.08, 0.85)

	var positions := [
		Vector2(bx + 30, by + BOARD_H + 16),
		Vector2(bx + 95, by + BOARD_H + 20),
		Vector2(bx + BOARD_W - 40, by + BOARD_H + 14),
	]

	for p in positions:
		draw_circle(p, 4.0, drip_c)
		draw_circle(Vector2(p.x + 1, p.y - 1), 1.5, Color(0.3, 0.3, 0.35, 0.6))

		var pts := PackedVector2Array([
			Vector2(p.x - 3, p.y),
			Vector2(p.x, p.y + 10),
			Vector2(p.x + 3, p.y),
		])

		draw_polygon(pts, [drip_c])


func _draw_warning_stripe(screen: Vector2, y: float) -> void:
	var stripe_w := BOARD_W + 36.0
	var bx := (screen.x - stripe_w) / 2.0
	var h := 10.0
	var stripe := 18.0

	draw_rect(Rect2(bx, y, stripe_w, h), Color("#1a1a1a"))

	var i := 0

	while i * stripe < stripe_w + h:
		var x := bx + i * stripe

		var pts := PackedVector2Array([
			Vector2(x, y),
			Vector2(x + stripe * 0.5, y),
			Vector2(x + stripe * 0.5 - h, y + h),
			Vector2(x - h, y + h),
		])

		draw_polygon(pts, [Color("#e6af2e")])
		i += 2

	draw_rect(Rect2(bx, y, stripe_w, h), Color("#111111"), false, 0.5)


func _draw_tire_stack(pos: Vector2) -> void:
	var rubber := Color(0.1, 0.1, 0.12)
	var rim := Color(0.45, 0.45, 0.5)
	var shine := Color(0.6, 0.6, 0.65, 0.5)

	for i in range(3):
		var y_off := float(i) * -18.0
		var rx := 30.0

		draw_arc(Vector2(pos.x, pos.y + y_off), rx, 0, TAU, 32, rubber, 10.0)
		draw_circle(Vector2(pos.x, pos.y + y_off), rx * 0.45, rim)
		draw_circle(Vector2(pos.x, pos.y + y_off), rx * 0.2, rubber)

		draw_arc(
			Vector2(pos.x - rx * 0.2, pos.y + y_off - 3.0),
			rx * 0.6,
			-PI * 0.9,
			-PI * 0.3,
			12,
			shine,
			2.0
		)


func _draw_title_plate(pos: Vector2) -> void:
	var pw := 280.0
	var ph := 28.0

	draw_rect(Rect2(pos.x - pw / 2.0, pos.y - ph / 2.0, pw, ph), C_PANEL)
	draw_rect(Rect2(pos.x - pw / 2.0, pos.y - ph / 2.0, pw, ph), C_ACCENT, false, 1.5)

	for sx in [-pw / 2.0 + 8, pw / 2.0 - 8]:
		draw_circle(Vector2(pos.x + sx, pos.y), 3.5, C_RIVETS)
		draw_line(Vector2(pos.x + sx - 2, pos.y), Vector2(pos.x + sx + 2, pos.y), Color("#555555"), 1.0)


func _draw_sprite_decorations(bx: float, by: float) -> void:
	if spritesheet == null:
		return

	# Iconos usando la misma hoja de sprites del taller.
	_draw_sprite_icon(0, Vector2(bx - 82, by + 145), Vector2(46, 46), -0.25)
	_draw_sprite_icon(1, Vector2(bx + BOARD_W + 38, by + 145), Vector2(46, 46), 0.22)
	_draw_sprite_icon(2, Vector2(bx - 82, by + 235), Vector2(42, 42), 0.15)
	_draw_sprite_icon(3, Vector2(bx + BOARD_W + 40, by + 235), Vector2(42, 42), -0.18)
	_draw_sprite_icon(4, Vector2(bx + 40, by - 78), Vector2(38, 38), -0.12)
	_draw_sprite_icon(5, Vector2(bx + BOARD_W - 80, by - 78), Vector2(38, 38), 0.12)
	_draw_sprite_icon(6, Vector2(bx + 160, by + BOARD_H + 42), Vector2(40, 40), 0.2)
	_draw_sprite_icon(7, Vector2(bx + BOARD_W - 210, by + BOARD_H + 42), Vector2(40, 40), -0.2)


func _draw_sprite_icon(icon_index: int, pos: Vector2, size: Vector2, rotation: float = 0.0) -> void:
	if spritesheet == null:
		return

	var tex_w := float(spritesheet.get_width())
	var tex_h := float(spritesheet.get_height())

	var frame_w := tex_w / float(SPRITESHEET_COLS)
	var frame_h := tex_h / float(SPRITESHEET_ROWS)

	var col := icon_index % SPRITESHEET_COLS

	@warning_ignore("integer_division")
	var row := icon_index / SPRITESHEET_COLS

	var src := Rect2(
		col * frame_w,
		row * frame_h,
		frame_w,
		frame_h
	)

	draw_set_transform(pos + size / 2.0, rotation, Vector2.ONE)

	var dst := Rect2(
		-size / 2.0,
		size
	)

	draw_texture_rect_region(spritesheet, dst, src)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
