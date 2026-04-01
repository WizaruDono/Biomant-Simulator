extends Camera2D

# Настройки зума
var zoom_speed = 0.1
var min_zoom = 0.8
var max_zoom = 10
var zoom_duration = 0.2
@onready var target_zoom = zoom

# Состояние перетаскивания
var is_dragging = false

func _unhandled_input(event):
	# пока зум отключен
	#return
	# Логика ЗУМА
	if event.is_action_pressed("zoom_out"):
		zoom_to(target_zoom - Vector2(zoom_speed, zoom_speed))
	elif event.is_action_pressed("zoom_in"):
		zoom_to(target_zoom + Vector2(zoom_speed, zoom_speed))

	# Логика НАЖАТИЯ колесика (MMB)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE:
		is_dragging = event.pressed
		# Скрываем/показываем курсор при перетаскивании (по желанию)
		# Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if is_dragging else Input.MOUSE_MODE_VISIBLE

	# Логика ДВИЖЕНИЯ мыши
	if event is InputEventMouseMotion and is_dragging:
		# Сдвигаем камеру против движения мыши, учитывая текущий зум
		# Умножение на zoom позволяет камере двигаться адекватно при любом масштабе
		position -= event.relative * zoom

func zoom_to(new_zoom: Vector2):
	target_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	target_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	
	%player_locations.global_position = Vector2(randf_range(0,100), randf_range(0, 100))
	
	var tween = create_tween()
	tween.tween_property(self, "zoom", target_zoom, zoom_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
