# quest_panel.gd
	
extends MarginContainer

@onready var title_label = %QuestTitle
@onready var desc_label = %QuestDescription
@onready var progress_bar = %ProgressBar

func _ready():
	QuestManager.updated.connect(update_ui)
	update_ui()

func update_ui():
	title_label.text = "ГЛАВА %d из 10" % QuestManager.current_chapter
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
	
	elif QuestManager.current_chapter == 4:
		var love_status = "1/1" if QuestManager.ch4_love_started else "0/1"
		
		text += "[%s] Положи 2-х монстров в Гнёздышко\n" % love_status
		text += "[%d/2] Выполни заказы на монстров\n" % QuestManager.ch4_monster_orders
		text += "[%d/4] Выполни заказы" % QuestManager.ch4_total_orders
		
		progress_bar.max_value = 1 + 2 + 4
		progress_bar.value = (1 if QuestManager.ch4_love_started else 0) + \
							 QuestManager.ch4_monster_orders + \
							 QuestManager.ch4_total_orders
	
	elif QuestManager.current_chapter == 5:
		text += "[%d/3] Разведи монстров в Гнёздышке\n" % QuestManager.ch5_monsters_bred
		text += "[%d/5] Выполни заказы" % QuestManager.ch5_total_orders
	
	elif QuestManager.current_chapter == 6:
		text += "[%d/1] Выполни заказ на монстра 2 уровня\n" % QuestManager.ch6_grade2_monster_order
		text += "[%d/5] Выполни заказы" % QuestManager.ch6_total_orders
		
	elif QuestManager.current_chapter == 7:
		text += "[%d/3] Успешно улучши конечности в Обменнике\n" % QuestManager.ch7_merges_done
		text += "[%d/3] Выполни заказы 2 уровня" % QuestManager.ch7_grade2_orders
		
	elif QuestManager.current_chapter == 8:
		text += "[%d/1] Выполни заказ 3 уровня\n" % QuestManager.ch8_grade3_part_order
		text += "[%d/6] Выполни заказы" % QuestManager.ch8_total_orders
		
	elif QuestManager.current_chapter == 9:
		text += "[%d/1] Выполни заказ на монстра 3 уровня\n" % QuestManager.ch9_grade3_monster_order
		text += "[%d/6] Выполни заказы" % QuestManager.ch9_total_orders
		
	elif QuestManager.current_chapter == 10:
		text += "[%d/10] Выполни марафон заказов" % QuestManager.ch10_done_orders
	
	
	
	
	desc_label.text = text
