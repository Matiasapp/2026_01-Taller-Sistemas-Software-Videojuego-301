extends Node2D

const CARD_W := 96
const CARD_H := 118
const GAP := 12
const COLS := 5
const ROWS := 4

const BOARD_W := COLS * (CARD_W + GAP) - GAP
const BOARD_H := ROWS * (CARD_H + GAP) - GAP

const C_PANEL := Color("#161b22")
const C_BORDER := Color("#30363d")
const C_ACCENT := Color("#e6af2e")
const C_DIM := Color(1, 1, 1, 0.06)
const C_RIVETS := Color("#3d444d")
const C_GREASE := Color("#1a1a1c")

func _ready() -> void:
	z_index = -10

	queue_redraw()


func _draw() -> void:
	var screen := get_viewport_rect().size
	var bx := (screen.x - BOARD_W) / 2.0
	var by := (screen.y - BOARD_H) / 2.0

	_draw_workbench(bx, by)
	_draw_bolts_border(bx, by)
	_draw_oil_drips(bx, by)
	_draw_warning_stripe(screen, by + BOARD_H + 22)
	_draw_title_plate(Vector2(screen.x / 2.0, by - 42))


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


func _draw_title_plate(pos: Vector2) -> void:
	var pw := 280.0
	var ph := 28.0

	draw_rect(Rect2(pos.x - pw / 2.0, pos.y - ph / 2.0, pw, ph), C_PANEL)
	draw_rect(Rect2(pos.x - pw / 2.0, pos.y - ph / 2.0, pw, ph), C_ACCENT, false, 1.5)

	for sx in [-pw / 2.0 + 8, pw / 2.0 - 8]:
		draw_circle(Vector2(pos.x + sx, pos.y), 3.5, C_RIVETS)
		draw_line(Vector2(pos.x + sx - 2, pos.y), Vector2(pos.x + sx + 2, pos.y), Color("#555555"), 1.0)
