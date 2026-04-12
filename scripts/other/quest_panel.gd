# quest_panel.gd
	
extends MarginContainer

@onready var title_label = %QuestTitle
@onready var desc_label = %QuestDescription
@onready var progress_bar = %ProgressBar

func _ready():
	QuestManager.updated.connect(update_ui)
	update_ui()

func update_ui():
	title_label.text = "ГЛАВА %d" % QuestManager.current_chapter
	var text = ""
	
	if QuestManager.current_chapter == 1:
		# Используем тернарный оператор для перевода bool в 1/1 или 0/1
		var dig_status = "1/1" if QuestManager.ch1_dig_started else "0/1"
		text += "[%s] Отправь Деда копать Кладбище\n" % dig_status
		text += "[%d/11] Выкопай конечности\n" % QuestManager.ch1_parts_mined
		text += "[%d/2] Выполни заказы" % QuestManager.ch1_orders_done
		
		progress_bar.max_value = 1 + 11 + 2
		progress_bar.value = (1 if QuestManager.ch1_dig_started else 0) + QuestManager.ch1_parts_mined + QuestManager.ch1_orders_done
		
	elif QuestManager.current_chapter == 2:
		var stapler_status = "1/1" if QuestManager.ch2_stapler_started else "0/1"
		text += "[%s] Помести в Сшиватель 6 разных частей тела\n" % stapler_status
		text += "[%d/3] Выполни заказы\n" % QuestManager.ch2_orders_done
		text += "[%d/1] Выполни заказ на монстра" % QuestManager.ch2_monster_orders_done
		
		progress_bar.max_value = 1 + 3 + 1
		progress_bar.value = (1 if QuestManager.ch2_stapler_started else 0) + QuestManager.ch2_orders_done + QuestManager.ch2_monster_orders_done
	
	elif QuestManager.current_chapter == 3:
		var merger_status = "1/1" if QuestManager.ch3_merger_done else "0/1"
		var g2_status = "1/1" if QuestManager.ch3_grade2_order_done else "0/1"
		
		text += "[%s] Помести в Обменник 3 одинаковых конечности\n" % merger_status
		text += "[%s] Выполни заказ 2-го уровня\n" % g2_status
		text += "[%d/3] Выполни заказы" % QuestManager.ch3_orders_done
		
		progress_bar.max_value = 1 + 1 + 3
		progress_bar.value = (1 if QuestManager.ch3_merger_done else 0) + \
							 (1 if QuestManager.ch3_grade2_order_done else 0) + \
							 QuestManager.ch3_orders_done
	
	
	
	
	desc_label.text = text
