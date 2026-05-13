package editor

import "core:fmt"
import "vendor:raylib"

CELL_SIZE: i32 : 32 // ONLY VISUAL! not related to actual level cell size.
GRID_WIDTH: i32 : 16
GRID_HEIGHT: i32 : 16

PALETTE_COLS: i32 : 4
PALETTE_CELL: i32 : 32

EditorState :: struct {
	level:        Level,
	tile_lib:     TileLib,
	tiles_loaded: bool,
}

editor_state_init :: proc() -> EditorState {
	editorState: EditorState

	editorState.level.tiles = make([dynamic]i32, GRID_WIDTH * GRID_HEIGHT)

	editorState.level.width = GRID_WIDTH
	editorState.level.height = GRID_HEIGHT

	editorState.level.tile_size = 8 // FIXME: hardcoded

	for &tile in editorState.level.tiles {
		tile = -1
	}

	editorState.tile_lib = TileLib {
		tiles = make([dynamic]Tile),
		names = make(map[string]i32),
	}

	editorState.tiles_loaded = false

	return editorState
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

	buttons := make([dynamic]Button, 32)
	loadTilesButton := Button{raylib.Rectangle{698, 282, 96, 32}, "Load Tile", LoadTiles}
	append(&buttons, loadTilesButton)
	exportLevelButton := Button{raylib.Rectangle{654, 324, 138, 32}, "Export Level", ExportLevel}
	append(&buttons, exportLevelButton)
	loadLevelButton := Button{raylib.Rectangle{698, 366, 96, 32}, "Load Level", LoadLevel}
	append(&buttons, loadLevelButton)

	selected_color: raylib.Color = {0, 0, 0, 255}
	selected_tile_id: i32 = -1

	raylib.InitWindow(800, 600, "Level Editor")
	defer raylib.CloseWindow()
	raylib.SetTargetFPS(60)

	for !raylib.WindowShouldClose() {
		mouse_pos := raylib.GetMousePosition()

		for button, _ in buttons {
			CheckClick(button, &editorState)
		}

		//if raylib.IsMouseButtonPressed(raylib.MouseButton.RIGHT) {
		//	fmt.printfln("mx: %g, my: %g", mouse_pos.x, mouse_pos.y)
		//}

		if raylib.CheckCollisionPointRec(mouse_pos, grid_rect) {
			grid_x := i32(mouse_pos.x) / CELL_SIZE
			grid_y := i32(mouse_pos.y) / CELL_SIZE
			if raylib.IsMouseButtonDown(raylib.MouseButton.LEFT) {
				editorState.level.tiles[grid_y * GRID_WIDTH + grid_x] = selected_tile_id
			} else if raylib.IsMouseButtonDown(raylib.MouseButton.RIGHT) {
				editorState.level.tiles[grid_y * GRID_WIDTH + grid_x] = -1 // erase
			}
		} else if raylib.CheckCollisionPointRec(mouse_pos, palette_rect) {
			if raylib.IsMouseButtonDown(raylib.MouseButton.LEFT) {
				p_x := i32(mouse_pos.x - f32(palette_begin_x)) / PALETTE_CELL
				p_y := i32(mouse_pos.y) / PALETTE_CELL
				selected_tile_id = p_y * PALETTE_COLS + p_x
			}
		}


		raylib.BeginDrawing()
		defer raylib.EndDrawing()
		raylib.ClearBackground(raylib.Color{194, 194, 194, 255})

		for x in 0 ..< GRID_WIDTH {
			for y in 0 ..< GRID_HEIGHT {
				cell := editorState.level.tiles[y * GRID_WIDTH + x]

				if editorState.tiles_loaded &&
				   cell >= 0 &&
				   cell < i32(len(editorState.tile_lib.tiles)) {
					tile := editorState.tile_lib.tiles[cell]
					if !tile.empty {
						raylib.DrawTexturePro(
							tile.texture,
							{0, 0, f32(tile.texture.width), f32(tile.texture.height)},
							{
								f32(x * CELL_SIZE),
								f32(y * CELL_SIZE),
								f32(CELL_SIZE),
								f32(CELL_SIZE),
							},
							{0, 0},
							0,
							raylib.WHITE,
						)
					}
				} else {
					raylib.DrawRectangle(
						i32(x * CELL_SIZE),
						i32(y * CELL_SIZE),
						CELL_SIZE,
						CELL_SIZE,
						raylib.BLACK,
					)
				}
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

		RenderButtons(buttons)

		// draw palette
		if editorState.tiles_loaded {
			for tile, i in editorState.tile_lib.tiles {
				ii := i32(i)
				row := ii / PALETTE_COLS
				col := ii % PALETTE_COLS

				if !tile.empty {
					raylib.DrawTexturePro(
						tile.texture,
						{0, 0, f32(tile.texture.width), f32(tile.texture.height)}, // Matches texture dimensions
						{
							f32(palette_begin_x + (col * PALETTE_CELL)),
							f32(row * PALETTE_CELL),
							f32(PALETTE_CELL),
							f32(PALETTE_CELL),
						},
						{0, 0},
						0,
						raylib.WHITE,
					)
				}
			}
		}
	}
}
