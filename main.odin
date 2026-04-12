package editor

import "vendor:raylib"

Cell :: struct {
	color: raylib.Color,
}

CELL_SIZE: i32 : 16 // ONLY VISUAL! not related to actual level cell size.
GRID_WIDTH: i32 : 24
GRID_HEIGHT: i32 : 16

PALETTE_COLS: i32 : 4
PALETTE_CELL: i32 : 20

EditorState :: struct {
	grid: [GRID_WIDTH][GRID_HEIGHT]Cell,
}

editor_state_init :: proc() -> EditorState {
	editorState: EditorState

	for x in 0 ..< GRID_WIDTH {
		for y in 0 ..< GRID_HEIGHT {
			editorState.grid[x][y].color = raylib.BLACK
		}
	}

	return editorState
}

palette_colors: []raylib.Color = {
	raylib.Color{0, 0, 0, 255},
	raylib.Color{29, 43, 83, 255},
	raylib.Color{126, 37, 83, 255},
	raylib.Color{0, 135, 81, 255},
	raylib.Color{171, 82, 54, 255},
	raylib.Color{95, 87, 79, 255},
	raylib.Color{194, 195, 199, 255},
	raylib.Color{255, 241, 232, 255},
	raylib.Color{255, 0, 77, 255},
	raylib.Color{255, 163, 0, 255},
	raylib.Color{255, 236, 39, 255},
	raylib.Color{0, 228, 54, 255},
	raylib.Color{41, 173, 255, 255},
	raylib.Color{131, 118, 156, 255},
	raylib.Color{255, 119, 168, 255},
	raylib.Color{255, 204, 170, 255},
}

palette_begin_x: i32 = i32(800 - (PALETTE_CELL * PALETTE_COLS))

// grid bounds for click checking
grid_rect := raylib.Rectangle{0, 0, f32(GRID_WIDTH * CELL_SIZE), f32(GRID_HEIGHT * CELL_SIZE)}
palette_rect := raylib.Rectangle {
	f32(palette_begin_x),
	0,
	f32(PALETTE_CELL * PALETTE_COLS),
	f32(PALETTE_CELL * PALETTE_COLS),
}

main :: proc() {

	editorState := editor_state_init()
	//defer delete(editorState.grid)

	selected_color: raylib.Color = {0, 0, 0, 255}

	raylib.InitWindow(800, 600, "Level Editor")
	defer raylib.CloseWindow()
	raylib.SetTargetFPS(60)

	for !raylib.WindowShouldClose() {
		mouse_pos := raylib.GetMousePosition()

		raylib.BeginDrawing()
		defer raylib.EndDrawing()
		raylib.ClearBackground(raylib.Color{194, 194, 194, 255})

		for x in 0 ..< GRID_WIDTH {
			for y in 0 ..< GRID_HEIGHT {
				raylib.DrawRectangle(
					i32(x * CELL_SIZE),
					i32(y * CELL_SIZE),
					CELL_SIZE,
					CELL_SIZE,
					editorState.grid[x][y].color,
				)
			}
		}

		for i in 0 ..= GRID_WIDTH {
			x_pos := i32(i * CELL_SIZE)
			raylib.DrawLine(x_pos, 0, x_pos, GRID_HEIGHT * CELL_SIZE, raylib.WHITE)
		}

		for i in 0 ..= GRID_HEIGHT {
			y_pos := i32(i * CELL_SIZE)
			raylib.DrawLine(0, y_pos, GRID_WIDTH * CELL_SIZE, y_pos, raylib.WHITE)
		}

		total_palette_loops: i32 = 0

		// draw palette.
		for color, i in palette_colors {
			row := i32(i) / PALETTE_COLS
			col := i32(i) % PALETTE_COLS

			raylib.DrawRectangle(
				palette_begin_x + (col * PALETTE_CELL),
				row * PALETTE_CELL,
				PALETTE_CELL,
				PALETTE_CELL,
				color,
			)
		}

		if raylib.IsMouseButtonDown(raylib.MouseButton.LEFT) {
			if raylib.CheckCollisionPointRec(mouse_pos, grid_rect) {
				grid_x := i32(mouse_pos.x) / CELL_SIZE
				grid_y := i32(mouse_pos.y) / CELL_SIZE
				editorState.grid[grid_x][grid_y].color = selected_color
			} else if raylib.CheckCollisionPointRec(mouse_pos, palette_rect) {
				p_x := i32(mouse_pos.x - f32(palette_begin_x)) / PALETTE_CELL
				p_y := i32(mouse_pos.y) / PALETTE_CELL
				color_index := p_y * PALETTE_COLS + p_x
				selected_color = palette_colors[color_index]
			}
		}
	}
}
