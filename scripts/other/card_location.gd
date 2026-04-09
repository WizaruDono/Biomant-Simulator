extends Card

class_name CardLocation


@export var location_res : LocationRes
@export var location_type : DataManager.LocationType
@export var location_name : String
@export var location_desc : String
@export var location_loot : Array[Resource]
@export var digg_speed : float
@export var res_count : int
@export var remaining_res_count : int
@export var digger : Card
@export var is_digg_in_progress : bool

# === НОВОЕ: Очередь предметов ===
var loot_queue : Array[PartRes] = []

@onready var label_uses: Label = %label_uses


func initialize():
	await get_tree().process_frame
	# Базовая инициализация из твоего кода
	card_owner_type = location_res.card_owner_type
	card_cost = location_res.card_cost
	card_type = location_res.card_type
	card_texture = location_res.card_texture
	card_grade = location_res.card_grade
	location_name = location_res.card_name
	location_desc = location_res.card_desc
	digg_speed = location_res.activate_speed
	

# === НОВОЕ: Генерируем очередь ===
	# Установка счетчиков
	res_count = location_res.use_count
	remaining_res_count = res_count
	
	location_loot = location_res.loot_pool
	
	# Первая подготовка очереди
	check_and_refill_queue()
	
	# На скорость копания влияет прокачка:
	activate_timer.wait_time = digg_speed * PlayerManager.dig_speed_multiplier
	
	#panel_back.tooltip_text = location_desc
	setup_tooltip()
	set_tooltip_text(location_res.card_desc)
	label_header.text = location_name
	rect_main_img.texture = card_texture
	update_res_count_ui()


func update_res_count_ui():
	label_uses.text = '%s/%s' % [remaining_res_count, res_count]

func add_card_to_stack(card: Card) -> void:
	if not card is CardActorMonster:
		return
	
	super.add_card_to_stack(card)

func _on_is_stack_set(value: bool) -> void:
	super._on_is_stack_set(value)
	
	if value:
		var _digger = card_container.get_child(0)
		print("DIGGER: ",_digger)
		set_digger(_digger)
	else:
		stop_digging()

#region Dig

func set_digger(new_digger : CardActorMonster):
	digger = new_digger
	check_digger_type()
	
	if digger:
		start_digging()


func start_digging():
	digg()

func stop_digging():
	digger = null
	stop_digg()


# Используем её при старте копания
func digg():
	# Обновляем время таймера прямо перед запуском!
	check_digger_type()
	
	activation_progress.max_value = activate_timer.wait_time
	
	if activate_timer.is_stopped():
		activate_timer.start()
	elif activate_timer.paused:
		activate_timer.paused = false
	else:
		activate_timer.start()
	
	is_digg_in_progress = true

# При остановке копания
func stop_digg():
	# Обновляем время таймера прямо перед запуском!
	check_digger_type()
	
	activation_progress.max_value = activate_timer.wait_time
	activate_timer.paused = true
	is_digg_in_progress = false


func check_digger_type():
# Начинаем с базы, умноженной на лопату
	var final_speed = get_actual_dig_speed()
	# Если это монстр-копатель, ускоряем еще на 20% (умножаем на 0.8)
	if digger is CardActorMonster and digger.monster_perc == DataManager.PercType.DIGGER:
		final_speed *= 0.8
	activate_timer.wait_time = final_speed


# 1. функция расчета актуальной скорости
func get_actual_dig_speed() -> float:
	# Берем базовую скорость из ресурса этой локации
	var speed = location_res.activate_speed
	# Умножаем на глобальный апгрейд игрока (лопату)
	speed *= PlayerManager.dig_speed_multiplier
	
	return speed

#endregion


# Чуть изменил, чтоб очереди рандомного лута работали нормально
func _on_activate_timer_timeout() -> void:
	get_loot() # Сначала выдаем лут
	remaining_res_count -= 1 # Затем отнимаем заряд
	update_res_count_ui()
	print('digg done ' + str(remaining_res_count))
	if remaining_res_count == 0:
		activate_timer.stop()
		destroy()


func destroy():
	if not card_container.get_children().is_empty():
		var card: Card = card_container.get_child(0)
		card.reparent_to_level()
		card._move_card_away(card)
		
		await get_tree().process_frame
	
	queue_free()


# === НОВОЕ: Алгоритм честной очереди ===
'''
Гарантированная очередь даёт нам по 2 части каждого вида (голова, тело...) среди 12 частей.
'''

# проверяет, не пуста ли очередь, и наполняет её
func check_and_refill_queue():
	if loot_queue.is_empty():
		generate_next_set()
		#generate_next_set_debug()
	pass

## Позволяет быстро сгенерировать одни и те же части тел
func generate_next_set_debug():
	for i in range(5):
		for k in range(5):
			loot_queue.append(location_loot[i])
	
	pass

func generate_next_set():
	var types = [
		DataManager.MonsterPartType.BODY, 
		DataManager.MonsterPartType.HEAD,
		DataManager.MonsterPartType.L_ARM, 
		DataManager.MonsterPartType.R_ARM,
		DataManager.MonsterPartType.L_LEG, 
		DataManager.MonsterPartType.R_LEG
	]
	
	var new_set : Array[PartRes] = []
	
	# Генерируем "пачку" из 12 предметов (2 полных комплекта)
	for i in range(2):
		var shuffled_types = types.duplicate()
		shuffled_types.shuffle()
		
		for p_type in shuffled_types:
			# Определяем грейд
			var target_grade = DataManager.EntityGrade.T1
			# Добавляем шанс к T2 при улучшении
			var total_t2_chance = DataManager.chances_dict[DataManager.EntityGrade.T2] + PlayerManager.rare_drop_bonus
			if randf() <= total_t2_chance:
				target_grade = DataManager.EntityGrade.T2
			
			# Фильтруем лут-пул
			var possible = location_loot.filter(func(res):
				return res is PartRes and res.part_type == p_type and res.card_grade == target_grade
			)
			
			# Фолбэк на Т1
			if possible.is_empty() and target_grade == DataManager.EntityGrade.T2:
				possible = location_loot.filter(func(res):
					return res is PartRes and res.part_type == p_type and res.card_grade == DataManager.EntityGrade.T1
				)
				
			if not possible.is_empty():
				new_set.append(possible.pick_random())
	
	# Перемешиваем всю пачку целиком
	new_set.shuffle()
	loot_queue.append_array(new_set)


func get_loot():
	# Если очередь внезапно кончилась, пробуем пополнить (на случай лимита использования локации > 12)
	check_and_refill_queue()
	
	if loot_queue.is_empty():
		print("Кладбище пустое или лут не настроен")
		return
	
	# Забираем предмет
	var loot_res = loot_queue.pop_front()

	# Спавн сущности
	var loot: Card = EntityManager.create_entity_scene(loot_res)
	GameManager.level.player_loot.add_child(loot)
	loot.initialize()
	
	SoundManager.play_asmr_sfx(SoundManager.SND_SPAWN, -8.0)	# ЗВУК ПОЯВЛЕНИЯ ЧАСТИ ТЕЛА
	
	# Рандомная позиция вылета
	var pos_offset = Vector2(randi_range(80, 100), randi_range(80, 100))
	if randf() < 0.5: pos_offset *= -1
	loot.global_position = global_position + pos_offset
	loot.card_state = DataManager.CardState.ON_FIELD
