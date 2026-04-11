#Quest_Manager.gd

extends MarginContainer

@onready var desc_label = $VBoxContainer/QuestDescription
@onready var progress_bar = $VBoxContainer/QuestProgress

var current_chapter = 1
var orders_completed = 0
var orders_needed = 3

func _ready():
	# Подключаемся к сигналу выполнения заказа. 
	# ТУТ ВАЖНО: У тебя должен быть сигнал в коде, который срабатывает при продаже монстра.
	# Предположим, он в SignalManager или GameManager.
	SignalManager.order_finished.connect(_on_order_finished)
	update_ui()

func _on_order_finished():
	orders_completed += 1
	
	if orders_completed >= orders_needed:
		complete_chapter()
	
	update_ui()

func update_ui():
	desc_label.text = "Выполни заказы: %d / %d" % [orders_completed, orders_needed]
	progress_bar.value = orders_completed

func complete_chapter():
	current_chapter += 1
	orders_completed = 0
	orders_needed += 2 # Каждая глава чуть сложнее
	
	# Тут можно вывести уведомление или сменить текст заголовка
	$VBoxContainer/QuestTitle.text = "ГЛАВА %d" % current_chapter
	
	# Если успеешь: вызови тут функцию у торговца, чтобы открыть новые товары
	print("Глава пройдена! Биомант стал опытнее.")
