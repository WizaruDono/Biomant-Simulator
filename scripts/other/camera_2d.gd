extends Camera2D

var zoom_speed = 0.2

# Состояние перетаскивания
var is_dragging = false


func _ready() -> void:
	SignalManager.card_focused.connect(_on_camera_focused)

func _unhandled_input(event):
# Проверяем, стоит ли мышь над UI, который ХОЧЕТ поймать клик
	var hovered_node = get_viewport().gui_get_hovered_control()
	if hovered_node:
		# Если у объекта под мышкой фильтр "Ignore", он нам не мешает.
		# Если "Stop" или "Pass" — значит это важный UI (кнопка, текст, панель).
		if hovered_node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			# Специальная проверка для зума:
			# Если это событие мыши (колесико), блокируем.
			if event is InputEventMouseButton:
				return
	_process_zoom(event)
	_process_camera_movement(event)




func _process_zoom(event):
	if event.is_action_pressed("zoom_out"):
		modify_zoom(-zoom_speed)
	elif event.is_action_pressed("zoom_in"):
		modify_zoom(zoom_speed)

## Временно сохранил перемещение по нажатию колёсика, потому что
## прям не всё гладко с перемещением по левой кнопки мыши.
func _process_camera_movement(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		is_dragging = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed && not GameManager.is_hovering_card

	if event is InputEventMouseMotion and is_dragging:
		# С коэффициентом 1.1 оно работает лучше
		position -= event.screen_relative / zoom * 1.1
	pass

## Zoom'имся в курсор мыши
func modify_zoom(delta: float) -> void:
	var mouse_pos := get_global_mouse_position()
	zoom = Vector2(clampf(zoom.x + delta, 0.5, 3.0), clampf(zoom.y + delta, 0.5, 3.0))

	var new_mouse_pos := get_global_mouse_position()
	position += mouse_pos - new_mouse_pos


func _on_camera_focused(target_position: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, 0.1)
	pass
