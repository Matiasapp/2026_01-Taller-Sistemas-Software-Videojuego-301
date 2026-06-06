extends Node2D

@export var board_origin := Vector2(4, -4)
@export var cell_size := 80
@export var board_size := 9
@export var show_grid := true

func _draw():
	if not show_grid:
		return

	var board_px := cell_size * board_size
	var rect := Rect2(board_origin, Vector2(board_px, board_px))

	draw_rect(rect, Color.RED, false, 3)

	for i in range(board_size + 1):
		var x := board_origin.x + i * cell_size
		draw_line(Vector2(x, board_origin.y), Vector2(x, board_origin.y + board_px), Color.YELLOW, 2)

		var y := board_origin.y + i * cell_size
		draw_line(Vector2(board_origin.x, y), Vector2(board_origin.x + board_px, y), Color.YELLOW, 2)
