package editor

import "core:strings"
import "vendor:raylib"

Button :: struct {
	bounds:   raylib.Rectangle,
	text:     string,
	/* callback procedures take only editor state as an argument (god context antipattern)*/
	callback: proc(_: ^EditorState),
}

CheckClick :: proc(button: Button, editor_state: ^EditorState) -> bool {
	mouse := raylib.GetMousePosition()
	if raylib.CheckCollisionPointRec(mouse, button.bounds) &&
	   raylib.IsMouseButtonPressed(raylib.MouseButton.LEFT) {
		button.callback(editor_state)
		return true
	}

	return false
}

RenderButtons :: proc(buttons: [dynamic]Button) {
	for button in buttons {
		raylib.DrawRectangleRec(button.bounds, raylib.WHITE)

		fontSize: i32 = 20
		ctext: cstring = strings.clone_to_cstring(button.text, context.temp_allocator)
		textWidth: i32 = raylib.MeasureText(ctext, fontSize)

		centerX := i32(button.bounds.x) + (i32(button.bounds.width) - textWidth) / 2
		centerY := i32(button.bounds.y) + (i32(button.bounds.height) - fontSize) / 2

		raylib.DrawText(ctext, centerX, centerY, fontSize, raylib.BLACK)
	}
}
