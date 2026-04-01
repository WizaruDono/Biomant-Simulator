extends Camera2D

var zoom_speed = 0.2

# Состояние перетаскивания
var is_dragging = false

func _unhandled_input(event):
	if event.is_action_pressed("zoom_out"):
		modify_zoom(-zoom_speed)
	elif event.is_action_pressed("zoom_in"):
		modify_zoom(zoom_speed)
	
	# Логика НАЖАТИЯ колесика (MMB)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		is_dragging = event.pressed
		# Скрываем/показываем курсор при перетаскивании (по желанию)
		# Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if is_dragging else Input.MOUSE_MODE_VISIBLE

	# Логика ДВИЖЕНИЯ мыши
	if event is InputEventMouseMotion and is_dragging:
		# С коэффициентом 1.1 оно работает лучше
		position -= event.screen_relative / zoom * 1.1

## Zoom'ится в курсор мыши
func modify_zoom(delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	zoom += Vector2(delta, delta)

	var new_mouse_pos := get_global_mouse_position()
	position += mouse_pos - new_mouse_pos
