package editor

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"
import "vendor:raylib"

TileType :: enum {
	Decorative,
	Solid,
	Metadata,
}

Tile :: struct {
	type:     TileType,
	texture:  raylib.Texture2D,
	metadata: string,
	empty:    bool,
}

TileSource :: struct {
	type:     string,
	path:     string,
	metadata: string,
}

TileLib :: struct {
	tiles: [dynamic]Tile,
	names: map[string]i32,
}

Level :: struct {
	width:     i32,
	height:    i32,
	tile_size: i32,
	tiles:     [dynamic]i32, // id
}

str2ttype :: proc(input: string) -> TileType {
	switch input {
	case "Solid":
		return .Solid
	case "Decorative":
		return .Decorative
	case "Metadata":
		return .Metadata
	case:
		fmt.printfln("Unknown tile type: ", input)
		return .Decorative
	}
}

LoadTiles :: proc(editor_state: ^EditorState) {
	if editor_state.tiles_loaded do return

	// fmt.println("hi!")
	manifest_path: string = "assets/tiles/tileset.json"

	file, ok := os.read_entire_file_from_path(manifest_path, context.temp_allocator)

	if ok != nil {
		fmt.eprintln("Tile manifest loading failed!")
		return
	}

	manifest: map[string]TileSource
	err := json.unmarshal(file, &manifest)
	if err != nil {
		fmt.eprintln("JSON Error: ", err)
		return
	}

	tile_lib: TileLib = {
		tiles = make([dynamic]Tile),
		names = make(map[string]i32),
	}

	for &tile in tile_lib.tiles {
		tile.empty = true
	}

	for name, source in manifest {
		c_path := strings.clone_to_cstring(source.path, context.temp_allocator)
		tex := raylib.LoadTexture(c_path)

		t := Tile {
			type     = str2ttype(source.type),
			metadata = strings.clone(source.metadata),
			texture  = tex,
			empty    = false,
		}

		id := i32(len(tile_lib.tiles))
		append(&tile_lib.tiles, t)

		tile_lib.names[strings.clone(name)] = id
	}

	editor_state.tile_lib = tile_lib
	editor_state.tiles_loaded = true
}

ExportLevel :: proc(editor_state: ^EditorState) {
	if !editor_state.tiles_loaded do return

	level_data, json_err := json.marshal(editor_state.level, {pretty = true})
	if json_err != nil {
		fmt.eprintfln("Error marshalling level data: ", json_err)
		return
	}
	defer delete(level_data)

	os_err := os.write_entire_file("level.json", level_data)
	if os_err != nil {
		fmt.eprintfln("Error writing file: ", os_err)
	}

	fmt.println("JSON bytes saved succesfully.")
}

LoadLevel :: proc(editor_state: ^EditorState) {
	if !editor_state.tiles_loaded do return

	file, err := os.read_entire_file_from_path("level.json", context.temp_allocator)
	if err != nil {
		fmt.eprintln("Level loading failed!")
		return
	}

	temp_level: Level
	unmarshal_err := json.unmarshal(file, &temp_level)
	if unmarshal_err != nil {
		fmt.eprintln("Error unmarshalling:", unmarshal_err)
		return
	}

	delete(editor_state.level.tiles)

	editor_state.level = temp_level

	editor_state.level.tiles = make([dynamic]i32, len(temp_level.tiles))
	copy(editor_state.level.tiles[:], temp_level.tiles[:])
}
