extends Control

class_name VictoryUI

@onready var continue_button: Button = %continue_button
@onready var menu_button: Button = %menu_button

func _ready() -> void:
	# Обязательно выставляем режим обработки, чтобы UI работал при паузе
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

	# Коннектим сигналы (можно сделать и через редактор во вкладке "Узлы")
	continue_button.pressed.connect(_on_continue_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)

func _on_continue_button_pressed() -> void:
	# Возвращаем видимость UI перед тем, как закрыть окно
	GameManager.set_game_ui_visible(true)
	get_tree().paused = false
	queue_free() # Просто удаляем окно и играем дальше

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	# Используем твою логику из OptionsMenu
	if GameManager.level:
		GameManager.level.queue_free()
	GameManager.show_menu()
	queue_free()
