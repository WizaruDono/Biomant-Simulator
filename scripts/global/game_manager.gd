extends Node

@export var level : Level
@export var is_captured : bool
@export var main_menu_scene = preload("res://scenes/main_menu_ui.tscn")
@export var options_scene = preload("res://scenes/options.tscn")
@export var level_scene = preload("res://scenes/level.tscn")
var main_menu_UI : MainMenuUI
var options_UI : OptionsMenu

## Помогает определить, что курсор находится над картой.
## Это нужно для использования левой кнопки мыши одновременно
## для перетаскивания карты и для перемещения камеры.
## Если мы над картой, то камера стоит на месте.
var is_hovering_card := false
var hovered_card: Card = null
var dragged_card: Card = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_default_volumes() # Вызываем принудительную настройку звука сразу при старте

func _input(event: InputEvent) -> void:
	if event.is_action_released("options"):
		if options_UI and options_UI.is_opened:
			hide_options()
		else:
			show_options()

# Новая вспомогательная функция для "тихого старта"
func set_default_volumes():
	var master_bus = AudioServer.get_bus_index("Master")
	var music_bus = AudioServer.get_bus_index("Music")

	# Устанавливаем 50% громкости по умолчанию (0.5 в линейном виде)
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(0.5))
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(0.5))


func set_main_menu(new_main_menu : MainMenuUI):
	main_menu_UI = new_main_menu

func show_menu():
	#clear_scene()
	hide_options()
	if main_menu_UI:
		main_menu_UI.queue_free()
	if level:
		level.queue_free()
	main_menu_UI = main_menu_scene.instantiate()
	get_tree().root.add_child(main_menu_UI)


func start_level():
	if main_menu_UI:
		main_menu_UI.queue_free()
	if not level:
		level = level_scene.instantiate()
	get_tree().root.add_child(level)
	main_menu_UI = null


func correct_options():
	if main_menu_UI:		# options_UI and main_menu_UI
		options_UI.hide_to_lobby_button()
	# Дополнительно гарантируем, что звук настроен, когда открыто меню (на случай, если что-то сбилось)
	#set_default_volumes()	# вызывало баг при перезаходе тройном в меню - настройки сбрасывались до средних

func show_options():
	options_UI = options_scene.instantiate()
	get_tree().paused = true
	#BUG
	if main_menu_UI and is_instance_valid(main_menu_UI):
		main_menu_UI.add_child(options_UI)
	elif level and is_instance_valid(level):
		level.add_child(options_UI)
	options_UI.initialize()


func hide_options():
	if options_UI:
		options_UI.queue_free()
		options_UI = null
		get_tree().paused = false


func exit():
	get_tree().quit()
