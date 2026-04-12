# quest_manager.gd

extends Node

signal updated

var current_chapter: int = 1
var is_victory_shown: bool = false

# Глава 1
var ch1_dig_started: bool = false
var ch1_parts_mined: int = 0
var ch1_orders_done: int = 0

# Глава 2
var ch2_stapler_started: bool = false
var ch2_orders_done: int = 0
var ch2_monster_orders_done: int = 0

# Глава 3
var ch3_merger_done: bool = false
var ch3_grade2_order_done: bool = false
var ch3_orders_done: int = 0

# Глава 4
var ch4_love_started: bool = false
var ch4_monster_orders: int = 0
var ch4_total_orders: int = 0

# Глава 5: Массовое производство
var ch5_monsters_bred: int = 0 # Сколько раз сработало Гнездо
var ch5_total_orders: int = 0

# Глава 6: Качество монстров
var ch6_grade2_monster_order: int = 0 # Заказ на монстра 2 тира (grade 1)
var ch6_total_orders: int = 0

# Глава 7: Мастер обмена
var ch7_merges_done: int = 0 # Сделать 3 улучшения в обменнике
var ch7_grade2_orders: int = 0 # 3 заказа 2 тира

# Глава 8: Высшая проба (3 тир)
var ch8_grade3_part_order: int = 0 # Заказ на деталь 3 тира (grade 2)
var ch8_total_orders: int = 0

# Глава 9: Биомант-профи
var ch9_grade3_monster_order: int = 0 # Монстр 3 тира (grade 2)
var ch9_total_orders: int = 0

# Глава 10: Финал (Легенда)
var ch10_total_orders: int = 10
var ch10_done_orders: int = 0

func _ready() -> void:
	SignalManager.monster_started_digging.connect(_on_monster_started_digging)
	SignalManager.part_mined.connect(_on_part_mined)
	SignalManager.stapler_started.connect(_on_stapler_started)
	SignalManager.order_finished.connect(_on_order_finished)
	SignalManager.part_merger_started.connect(_on_part_merger_started)
	SignalManager.part_merger_finished.connect(_on_part_merger_finished)
	SignalManager.love_nest_started.connect(_on_love_nest_started)
	SignalManager.love_nest_finished.connect(_on_love_nest_finished)

# --- Обработчики ---
# монстр начал добывать конечности
func _on_monster_started_digging() -> void:
	if current_chapter == 1:
		ch1_dig_started = true
		emit_update()

# добываем конечности
func _on_part_mined() -> void:
	if current_chapter == 1:
		# Ограничиваем сверху 11, чтобы не было 14/11
		ch1_parts_mined = min(ch1_parts_mined + 1, 11)
		emit_update()

# начали сшивать
func _on_stapler_started() -> void:
	if current_chapter == 2:
		ch2_stapler_started = true
		emit_update()

# обменник начал работать
func _on_part_merger_started():
	if current_chapter == 3: ch3_merger_done = true
	#if current_chapter == 7: ch7_merges_done = min(ch7_merges_done + 1, 3)
	emit_update()

# N раз улучшили конечность успешно
func _on_part_merger_finished():
	if current_chapter == 7: ch7_merges_done = min(ch7_merges_done + 1, 3)
	emit_update()
	
# гнездо начало шуршать
func _on_love_nest_started() -> void:
	if current_chapter == 4: ch4_love_started = true
	#if current_chapter == 5: ch5_monsters_bred = min(ch5_monsters_bred + 1, 3)
	emit_update()

# заделали N малышей
func _on_love_nest_finished() -> void:
	if current_chapter == 5: ch5_monsters_bred = min(ch5_monsters_bred + 1, 3)
	emit_update()


func _on_order_finished(order_type: DataManager.CardType, grade: int) -> void:
	match current_chapter:
		1: ch1_orders_done = min(ch1_orders_done + 1, 2)
		2:
			if order_type == DataManager.CardType.MONSTER: ch2_monster_orders_done = min(ch2_monster_orders_done + 1, 1)
			ch2_orders_done = min(ch2_orders_done + 1, 3)
		3:
			ch3_orders_done = min(ch3_orders_done + 1, 3)
			if grade >= 1: ch3_grade2_order_done = true
		4:
			ch4_total_orders = min(ch4_total_orders + 1, 4)
			if order_type == DataManager.CardType.MONSTER: ch4_monster_orders = min(ch4_monster_orders + 1, 2)
		5:
			ch5_total_orders = min(ch5_total_orders + 1, 5)
		6:
			ch6_total_orders = min(ch6_total_orders + 1, 5)
			if order_type == DataManager.CardType.MONSTER and grade >= 1: ch6_grade2_monster_order = min(ch6_grade2_monster_order + 1, 1)
		7:
			if grade >= 1: ch7_grade2_orders = min(ch7_grade2_orders + 1, 3)
		8:
			ch8_total_orders = min(ch8_total_orders + 1, 6)
			if grade >= 2: ch8_grade3_part_order = min(ch8_grade3_part_order + 1, 1)
		9:
			ch9_total_orders = min(ch9_total_orders + 1, 6)
			if order_type == DataManager.CardType.MONSTER and grade >= 2: ch9_grade3_monster_order = min(ch9_grade3_monster_order + 1, 1)
		10:
			ch10_done_orders = min(ch10_done_orders + 1, 10)
			
	emit_update()
	
	#### ПЕРЕПИСАТЬ КОММЕНТЫ НИЖЕ наверх
	#if current_chapter == 1:
		#ch1_orders_done = min(ch1_orders_done + 1, 2)
	#
	#elif current_chapter == 2:
		## Если это монстр — он идет в оба зачета
		#if order_type == DataManager.CardType.MONSTER:
			#ch2_monster_orders_done = min(ch2_monster_orders_done + 1, 1)
			#ch2_orders_done = min(ch2_orders_done + 1, 3) # Тоже считаем как обычный заказ
		#else:
			#ch2_orders_done = min(ch2_orders_done + 1, 3)
	#
	## выполнить заказ 2-го уровня
	#elif current_chapter == 3:
		#ch3_orders_done = min(ch3_orders_done + 1, 3) # Общий счетчик
		#if grade >= 1:
			#ch3_grade2_order_done = true # Счетчик заказа 2 уровня (0 - 1 лвл, 1 - 2 лвл)
	#
	#elif current_chapter == 4:
		#ch4_total_orders = min(ch4_total_orders + 1, 4)
		#if order_type == DataManager.CardType.MONSTER:
			#ch4_monster_orders = min(ch4_monster_orders + 1, 2)
	#
	#emit_update()

# --- Системные функции ---

func emit_update():
	updated.emit()
	check_chapter_completion()

func check_chapter_completion():
	if current_chapter == 1:
		if ch1_dig_started and ch1_parts_mined >= 11 and ch1_orders_done >= 2:
			start_next_chapter()
	elif current_chapter == 2:
		if ch2_stapler_started and ch2_orders_done >= 3 and ch2_monster_orders_done >= 1:
			start_next_chapter()
	elif current_chapter == 3:
		if ch3_merger_done and ch3_grade2_order_done and ch3_orders_done >= 3:
			start_next_chapter()
	elif current_chapter == 4:
		if ch4_love_started and ch4_monster_orders >= 2 and ch4_total_orders >= 4:
			start_next_chapter()
	elif current_chapter == 5:
		if ch5_monsters_bred >= 3 and ch5_total_orders >= 5:
			start_next_chapter()
	elif current_chapter == 6:
		if ch6_grade2_monster_order >= 1 and ch6_total_orders >= 5:
			start_next_chapter()
	elif current_chapter == 7:
		if ch7_merges_done >= 3 and ch7_grade2_orders >= 3:
			start_next_chapter()
	elif current_chapter == 8:
		if ch8_grade3_part_order >= 1 and ch8_total_orders >= 6:
			start_next_chapter()
	elif current_chapter == 9:
		if ch9_grade3_monster_order >= 1 and ch9_total_orders >= 6:
			start_next_chapter()
	elif current_chapter == 10:
		if ch10_done_orders >= 10 and not is_victory_shown:
			is_victory_shown = true # Сразу ставим в true
			show_victory_screen()
			
func start_next_chapter():
	current_chapter += 1
	print_rich("[color=yellow]=== ГЛАВА %d ===[/color]" % current_chapter)
	updated.emit()

func show_victory_screen():
	# Мы не вызываем start_next_chapter, поэтому current_chapter останется 10
	# Вызываем создание окна через GameManager (по аналогии с твоим меню)
	GameManager.show_victory_window()
	
# --- Дебаг инструменты ---
#### Рабочая функция для отладки. Закомментил для экспорта 		!!!!

#func _unhandled_key_input(event: InputEvent) -> void:
	#if event is InputEventKey and event.pressed:
		#match event.keycode:
			##KEY_F5: # Деньги
				##if "PlayerManager" in get_tree().root: # проверка на всякий случай
					##PlayerManager.add_gold(100)
					##print("DEBUG: +100$")
			#
			#KEY_F6: # Скип главы
				#start_next_chapter()
				#
			#KEY_F7: # Авто-выполнение текущих целей (от функции выше мало чем отличается по смыслу)
				#if current_chapter == 1:
					#ch1_dig_started = true
					#ch1_parts_mined = 11
					#ch1_orders_done = 2
				#elif current_chapter == 2:
					#ch2_stapler_started = true
					#ch2_orders_done = 3
					#ch2_monster_orders_done = 1
					#
				#elif current_chapter == 10:
					#ch10_done_orders = 10
				#emit_update()
			##
			#KEY_F9: # конец игры
				#show_victory_screen()
	
"""
# Идея на будущее:
extends Node

var current_chapter: int = 1

# Прогресс Главы 1
var ch1_dig_started: bool = false
var ch1_parts_mined: int = 0
var ch1_orders_done: int = 0

# Прогресс Главы 2
var ch2_stapler_started: bool = false
var ch2_orders_done: int = 0
var ch2_monster_orders_done: int = 0

func _ready() -> void:
	SignalManager.monster_started_digging.connect(_on_monster_started_digging)
	SignalManager.part_mined.connect(_on_part_mined)
	SignalManager.stapler_started.connect(_on_stapler_started)
	SignalManager.order_finished.connect(_on_order_finished)
	
	print_rich("[color=green]QuestManager: Глава %s начата[/color]" % current_chapter)

# ==========================================
# ОБРАБОТЧИКИ СИГНАЛОВ
# ==========================================

func _on_monster_started_digging() -> void:
	if current_chapter == 1 and not ch1_dig_started:
		ch1_dig_started = true
		print("Глава 1: Монстр начал копать (1/3 выполнено)")
		check_chapter_1_completion()

func _on_part_mined() -> void:
	if current_chapter == 1 and ch1_parts_mined < 11:
		ch1_parts_mined += 1
		print("Глава 1: Добыто конечностей %s/11" % ch1_parts_mined)
		check_chapter_1_completion()

func _on_stapler_started() -> void:
	if current_chapter == 2 and not ch2_stapler_started:
		ch2_stapler_started = true
		print("Глава 2: Сшиватель запущен (1/3 выполнено)")
		check_chapter_2_completion()

func _on_order_finished(order_type: DataManager.CardType) -> void:
	match current_chapter:
		1:
			if ch1_orders_done < 2:
				ch1_orders_done += 1
				PlayerManager.add_gold(10) # Награда за задание
				print("Глава 1: Заказов выполнено %s/2 (+10$)" % ch1_orders_done)
				check_chapter_1_completion()
		2:
			if order_type == DataManager.CardType.MONSTER:
				if ch2_monster_orders_done < 1:
					ch2_monster_orders_done += 1
					PlayerManager.add_gold(15) # Награда за задание
					print("Глава 2: Заказ на монстра выполнен 1/1 (+15$)")
			else:
				if ch2_orders_done < 3:
					ch2_orders_done += 1
					PlayerManager.add_gold(10) # Награда за задание
					print("Глава 2: Обычных заказов выполнено %s/3 (+10$)" % ch2_orders_done)
			
			check_chapter_2_completion()

# ==========================================
# ПРОВЕРКИ ЗАВЕРШЕНИЯ ГЛАВ
# ==========================================

func check_chapter_1_completion() -> void:
	if ch1_dig_started and ch1_parts_mined >= 11 and ch1_orders_done >= 2:
		start_next_chapter()

func check_chapter_2_completion() -> void:
	if ch2_stapler_started and ch2_orders_done >= 3 and ch2_monster_orders_done >= 1:
		start_next_chapter()

func start_next_chapter() -> void:
	current_chapter += 1
	print_rich("[color=yellow]=== ГЛАВА %s ЗАВЕРШЕНА! ПЕРЕХОД К ГЛАВЕ %s ===[/color]" % [current_chapter - 1, current_chapter])
	
	# Здесь позже ты вызовешь метод обновления пула заказов и пула торгаша
	# OrderManager.load_orders_for_chapter(current_chapter)
	# MerchantManager.load_items_for_chapter(current_chapter)

# ==========================================
# ДЕБАГ ИНСТРУМЕНТЫ (НЕ КАЙФ ИСКЛЮЧАТОР)
# ==========================================

func _unhandled_key_input(event: InputEvent) -> void:
	# Проверяем только нажатия кнопок (чтобы не срабатывало при отпускании)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F5: # Быстро накинуть денег
				PlayerManager.add_gold(100)
				print_rich("[color=cyan]DEBUG: +100$[/color]")
			
			KEY_F6: # Пропустить текущую главу
				print_rich("[color=cyan]DEBUG: Скип главы %s[/color]" % current_chapter)
				start_next_chapter()
				
			KEY_F7: # Принудительно выполнить текущие квесты (без смены главы, чтобы протестить саму выдачу)
				if current_chapter == 1:
					ch1_dig_started = true; ch1_parts_mined = 11; ch1_orders_done = 2
					check_chapter_1_completion()
				elif current_chapter == 2:
					ch2_stapler_started = true; ch2_orders_done = 3; ch2_monster_orders_done = 1
					check_chapter_2_completion()
"""
