# quest_manager.gd

extends Node

signal updated

var current_chapter: int = 1

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

func _ready() -> void:
	SignalManager.monster_started_digging.connect(_on_monster_started_digging)
	SignalManager.part_mined.connect(_on_part_mined)
	SignalManager.stapler_started.connect(_on_stapler_started)
	SignalManager.order_finished.connect(_on_order_finished)
	SignalManager.part_merger_finished.connect(_on_part_merger_finished)

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

func _on_part_merger_finished():
	if current_chapter == 3:
		ch3_merger_done = true
		emit_update()

func _on_order_finished(order_type: DataManager.CardType, grade: int) -> void:
	if current_chapter == 1:
		ch1_orders_done = min(ch1_orders_done + 1, 2)
	
	elif current_chapter == 2:
		# Если это монстр — он идет в оба зачета
		if order_type == DataManager.CardType.MONSTER:
			ch2_monster_orders_done = min(ch2_monster_orders_done + 1, 1)
			ch2_orders_done = min(ch2_orders_done + 1, 3) # Тоже считаем как обычный заказ
		else:
			ch2_orders_done = min(ch2_orders_done + 1, 3)
			
	elif current_chapter == 3:
		ch3_orders_done = min(ch3_orders_done + 1, 3) # Общий счетчик
		if grade >= 2:
			ch3_grade2_order_done = true # Счетчик заказа 2 уровня
			
	emit_update()

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

func start_next_chapter():
	current_chapter += 1
	print_rich("[color=yellow]=== ГЛАВА %d ===[/color]" % current_chapter)
	updated.emit()

# --- Дебаг инструменты ---

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F5: # Деньги
				if "PlayerManager" in get_tree().root: # проверка на всякий случай
					PlayerManager.add_gold(100)
					print("DEBUG: +100$")
			
			KEY_F6: # Скип главы
				start_next_chapter()
				
			KEY_F7: # Авто-выполнение текущих целей (от функции выше мало чем отличается по смыслу)
				if current_chapter == 1:
					ch1_dig_started = true
					ch1_parts_mined = 11
					ch1_orders_done = 2
				elif current_chapter == 2:
					ch2_stapler_started = true
					ch2_orders_done = 3
					ch2_monster_orders_done = 1
				emit_update()
	
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
