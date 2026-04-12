extends Area2D


class_name Stack


@export var cards : Array[Card]
@export var production_card : CardProduction
@export var location_card : CardLocation
@export var order_card : CardOrder
@export var is_can_product : bool
@export var is_can_digg : bool
@export var is_dragging : bool
@export var is_can_get_reward : bool
@export var offset : Vector2 = Vector2.ZERO
@export var has_body : bool
@export var has_l_arm : bool
@export var has_r_arm : bool
@export var has_l_leg : bool
@export var has_r_leg : bool
@export var has_head : bool
@export var has_foot : bool
@export var parts : Array[CardActorPart]
@export var intersected_areas : Array[Card]
@export var stack_scene : PackedScene = preload('res://scenes/stack.tscn')

@onready var collision_stack: CollisionShape2D = %collision_stack
@onready var activation_progress: ProgressBar = %activation_progress
@onready var stack_to_card_collision: CollisionShape2D = %stack_to_card_collision
@onready var stack_area: Area2D = %stack_area

@onready var panel_container: Panel = $PanelContainer
@onready var panel_1: Panel = $PanelContainer/Panel
@onready var panel_2: Panel = $PanelContainer/Panel2

func _ready() -> void:
	var pos_y_offset: float = 0.0
	var new_size: Vector2
	var last_pos_y_offset: float = 0.0
	for panel in panel_container.get_children():
		if panel is Panel:
			panel.position.y = pos_y_offset
			pos_y_offset += 32.0
			last_pos_y_offset = 32.0
			new_size = panel.size
	
	panel_container.size.y = new_size.y + pos_y_offset - last_pos_y_offset


func _on_mouse_entered() -> void:
	GameManager.is_hovering_card = true

func _on_mouse_exited() -> void:
	GameManager.is_hovering_card = false

func create_collision():
	#var rect_coll : CollisionShape2D = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(cards[0].get_size().x, DataManager.card_header_size)
	return shape


func activate_stack_to_card_collision(is_active : bool):
	if is_active:
		stack_area.set_collision_mask_value(2, true)
	else:
		stack_area.set_collision_mask_value(2, false)


func create_stack_collision():
	var shape = RectangleShape2D.new()
	shape.size = Vector2(cards[0].get_size().x, (cards.size() - 1) * DataManager.card_header_size + cards[0].get_size().y)
	return shape


func add_card(card : Card, is_in_start : bool = false):
	stop_production()
	stop_digging()
	#SoundManager.play_asmr_sfx(SoundManager.SND_STACK, 0.0)	# ЗВУК СТАКА
	card.scale = Vector2(1, 1)
	if not is_in_start:
		cards.append(card)
	else:
		cards.push_front(card)
	card.reparent(self)
	card.stack = self
	card.change_state(DataManager.CardState.IN_STACK)


func remove_card(card : Card):
	stop_production()
	stop_digging()
	cards.erase(card)
	get_tree().process_frame.connect(card.reparent.bind(GameManager.level), CONNECT_ONE_SHOT)
	card.reparent(GameManager.level)
	if card.card_state != DataManager.CardState.DRAGGED:
		card.change_state(DataManager.CardState.ON_FIELD)
	if cards.size() < 2:
		call_deferred('close_stack')
	else:
		calculate()


func calculate():
	if cards.size() < 2:
		collision_stack.shape = create_collision()
		collision_stack.position.x += collision_stack.shape.size.x / 2
		collision_stack.position.y += collision_stack.shape.size.y / 2
		activation_progress.custom_minimum_size = Vector2(cards[0].get_size().x, DataManager.card_header_size)
		return
		
	stack_to_card_collision.shape = create_stack_collision()
	stack_to_card_collision.position.x = stack_to_card_collision.shape.size.x / 2
	stack_to_card_collision.position.y = stack_to_card_collision.shape.size.y / 2
	align_ordering()
	change_collision()
	align_cards()

	match cards[0].card_type:
		DataManager.CardType.PRODUCTION:
			production_card = cards[0]
			is_can_product = check_possible_production(production_card)
			if is_can_product and not production_card.is_product_in_progress:
				start_production()
			elif is_can_product and production_card.is_product_in_progress:
				continue_production()
				
		DataManager.CardType.LOCATION:
			location_card = cards[0]
			is_can_digg = check_possible_digging(location_card)
			if is_can_digg and not location_card.is_digg_in_progress:
				start_digging()
			elif is_can_digg and location_card.is_digg_in_progress:
				continue_digging()
				
		DataManager.CardType.ORDER:
			order_card = cards[0]
			is_can_get_reward = check_order_consistency()
			if is_can_get_reward:
				var submitted_card = cards[1] # Теперь это просто карта, а не обязательно монстр
				start_getting_reward() 		# Запускаем функцию получения награды
				
				# === ИЗМЕНЕНИЯ ЗДЕСЬ ===
				#SignalManager.order_finished.emit()	# Отправляем сигнал о сдаче заказа для заданий
				# =======================
				
				# Удаляем сданную карту (будь то кусок или целый монстр)
				remove_card(submitted_card)
				submitted_card.queue_free()


func check_order_consistency() -> bool:
	if cards.size() != 2:
		return false
		
	var submitted_card = cards[1]
	# ИСПРАВЛЕНИЕ: берем order_res, а не monster_res
	var order : OrderRes = order_card.order_res 
	
# ==========================================
	# ЛОГИКА 1: ЗАКАЗ НА КОНКРЕТНУЮ ЧАСТЬ ТЕЛА
	# ==========================================
	if order.order_type == DataManager.CardType.MONSTER_PART:
		# Если подсунули не часть тела — отказ
		if submitted_card.card_type != DataManager.CardType.MONSTER_PART:
			return false
			
		var part = submitted_card as CardActorPart
		
		# 1. Проверяем тип конечности (например, Голова)
		if order.quest_part_conditions.size() > 0:
			if part.part_type != order.quest_part_conditions[0]:
				return false
				
		# 2. Проверяем базу (например, Скелет)
		# Сначала ищем в массиве баз:
		if order.quest_base_conditions.size() > 0:
			if part.part_res.part_base != order.quest_base_conditions[0]:
				return false
		# Если массив пуст, проверяем одиночную переменную базы:
		elif order.check_base_condition != null:
			if part.part_res.part_base != order.check_base_condition:
				return false
				
		# 3. Проверяем уровень, только если галочка "строгий уровень" включена
		if order.check_entire_monster_grade:
			if part.card_grade != order.quest_grade_conditions:
				return false
				
		return true

# ==========================================
	# ЛОГИКА 2: ЗАКАЗ НА ЦЕЛОГО МОНСТРА (или Франкенштейна)
	# ==========================================
	elif order.order_type == DataManager.CardType.MONSTER:
		# Если подсунули не монстра — отказ
		if submitted_card.card_type != DataManager.CardType.MONSTER:
			return false
			
		var monster = submitted_card as CardActorMonster
		if monster.monster_parts.size() == 0:
			return false
			
		# 1. Проверка Уровня ВСЕГО монстра (если галочка включена)
		if order.check_entire_monster_grade:
			if monster.card_grade < order.quest_grade_conditions:
				return false
				
		# 2. Собираем особые требования по частям тела в словарь
		# Ключ: Тип конечности (HEAD, L_ARM), Значение: Требуемая база (SKELETON, ZOMBIE)
		var special_parts = {}
		for i in range(order.quest_part_conditions.size()):
			var req_part = order.quest_part_conditions[i]
			var req_base = order.quest_base_conditions[i] # Берем базу из нового массива
			special_parts[req_part] = req_base
			
		# 3. Список всех возможных слотов для проверки
		# Убедись, что тут перечислены все твои части тела из DataManager.MonsterPartType
		var all_part_types = [
			DataManager.MonsterPartType.HEAD,
			DataManager.MonsterPartType.BODY, 
			DataManager.MonsterPartType.L_ARM,
			DataManager.MonsterPartType.R_ARM,
			DataManager.MonsterPartType.L_LEG,
			DataManager.MonsterPartType.R_LEG
		]
		
		# 4. Жесткая проверка каждой конечности
		for part_type in all_part_types:
			var monster_part = monster.get_part_res(part_type)
			
			# Сценарий А: Заказчик выставил специфическое требование на эту часть
			if special_parts.has(part_type):
				if not monster_part:
					return false # Запрошенной части нет на теле
				
				if monster_part.part_base != special_parts[part_type]:
					return false # Пришита деталь не той базы (например, ждали руку зомби, а тут скелет)
					
			# Сценарий Б: Спец-требований нет, проверяем по основной базе монстра
# Сценарий Б: Спец-требований нет, проверяем по основной базе монстра
			else:
				# Если у заказа есть основная база (например, нужен Зомби)
				if order.check_base_condition != null: 
					if not monster_part:
						return false # Не хватает конечности, монстр собран не полностью
						
					if monster_part.part_base != order.check_base_condition:
						return false # Эта часть от другой базы, и спец-заказа на нее не было
						
		return true

	# === ДОБАВЬ ВОТ ЭТУ СТРОКУ ===
	# Срабатывает, если order_type вообще не опознан (страховка от багов)
	return false



func start_getting_reward():
	order_card.start_rewarding()


func check_possible_digging(_card : Card):
	var content_cards : Array[Card] = cards.slice(1)
	if content_cards.size() == 1 and content_cards[0].card_type == DataManager.CardType.MONSTER:
		return true
	return false 


func align_ordering():
	var base_ordering : int = 0
	for card in cards:
		card.z_index = base_ordering
		base_ordering += 2


func align_cards():
	var card_offset : Vector2 = Vector2.ZERO
	for card in cards:
		card.position = card_offset
		card_offset += Vector2(0, card.label_header.size.y)


func change_collision():
	for card in cards:
		card.input_pickable = false
		card.change_collision_to_invisible_state()
	cards[cards.size() - 1].input_pickable = true
	cards[cards.size() - 1].change_collision_to_stacked_state()


func check_possible_production(card : Card):
	var content_cards : Array[Card] = cards.slice(1)
	match card.production_type:
		DataManager.ProductionType.PART_CREATOR:
			if content_cards.size() != DataManager.parts_size:
				return false
			for content_card in content_cards:
				if content_card.card_type != DataManager.CardType.MONSTER_PART:
					return false
				else:
					match content_card.part_type:
						DataManager.MonsterPartType.BODY:
							has_body = true
							var is_already_has_part : bool
							for part in parts:
								if part.part_type == DataManager.MonsterPartType.BODY:
									is_already_has_part = true
							if not is_already_has_part:
								parts.append(content_card)
								
						DataManager.MonsterPartType.HEAD:
							has_head = true
							var is_already_has_part : bool
							for part in parts:
								if part.part_type == DataManager.MonsterPartType.HEAD:
									is_already_has_part = true
							if not is_already_has_part:
								parts.append(content_card)
								
						DataManager.MonsterPartType.L_ARM:
							has_l_arm = true
							var is_already_has_part : bool
							for part in parts:
								if part.part_type == DataManager.MonsterPartType.L_ARM:
									is_already_has_part = true
							if not is_already_has_part:
								parts.append(content_card)
								
						DataManager.MonsterPartType.R_ARM:
							has_r_arm = true
							var is_already_has_part : bool
							for part in parts:
								if part.part_type == DataManager.MonsterPartType.R_ARM:
									is_already_has_part = true
							if not is_already_has_part:
								parts.append(content_card)
								
						DataManager.MonsterPartType.L_LEG:
							has_l_leg = true
							var is_already_has_part : bool
							for part in parts:
								if part.part_type == DataManager.MonsterPartType.L_LEG:
									is_already_has_part = true
							if not is_already_has_part:
								parts.append(content_card)
								
						DataManager.MonsterPartType.R_LEG:
							has_r_leg = true
							var is_already_has_part : bool
							for part in parts:
								if part.part_type == DataManager.MonsterPartType.R_LEG:
									is_already_has_part = true
							if not is_already_has_part:
								parts.append(content_card)
			if parts.size() == DataManager.parts_size:
				return true
			return false
		DataManager.ProductionType.MONSTER_CREATOR:
			if content_cards.size() != DataManager.monster_love_size:
				return false
			for content_card in content_cards:
				if content_card.card_type != DataManager.CardType.MONSTER:
					return false
				else:
					if not content_card.is_can_love:
						return false
			return true
		DataManager.ProductionType.MONSTER_MERGER:
			pass
		DataManager.ProductionType.RES_CREATOR:
			pass
		DataManager.ProductionType.PART_MERGER:
			if content_cards.size() != DataManager.parts_merger_count:
				return false
			if content_cards[0].card_type != DataManager.CardType.MONSTER_PART:
				return false
			var same_part_type : DataManager.MonsterPartType = content_cards[0].part_type
			for content_card in content_cards:
				if content_card.card_type != DataManager.CardType.MONSTER_PART:
					return false
				else:
					if same_part_type != content_card.part_type:
						return false
			return true


func start_production():
	if production_card and not production_card.is_product_in_progress:
		activation_progress.show()
		# раскоментировать, если хотим, чтобы карту нельзя было снять
		#cards[cards.size() - 1].input_pickable = false
		#cards[cards.size() - 1].change_collision_to_invisible_state()
		match production_card.production_type:
			DataManager.ProductionType.PART_CREATOR:
				production_card.set_parts(parts)
			DataManager.ProductionType.MONSTER_CREATOR:
				var monster_cards : Array[CardActorMonster]
				for card in cards.slice(1):
					monster_cards.append(card)
				production_card.set_monsters(monster_cards)
			DataManager.ProductionType.PART_MERGER:
				for card in cards.slice(1):
					var part : CardActorPart = card
					parts.append(part)
				production_card.set_parts(parts)
		production_card.product()


func stop_production():
	if production_card and production_card.is_product_in_progress:
		production_card.stop_product()


func continue_production():
	activation_progress.show()
	if production_card:
		production_card.continue_product()



func start_digging():
	activation_progress.show()
	location_card.set_digger(cards[1])
	location_card.digg()


func continue_digging():
	activation_progress.show()
	if location_card:
		location_card.continue_digg()


func stop_digging():
	activation_progress.hide()
	if location_card:
		location_card.stop_digg()


func close_stack():
	print('close stack')
	for card in cards:
		if card and is_instance_valid(card):
			card.input_pickable = true
			cards.erase(card)
			card.reparent(GameManager.level)
			card.change_state(DataManager.CardState.ON_FIELD)
	queue_free()


func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Начинаем перетаскивание и запоминаем смещение мыши относительно центра
			is_dragging = true
			offset = global_position - get_global_mouse_position()
			#cards[cards.size() - 1].change_state(DataManager.CardState.DRAGGED)
			z_index = 2000
			for card in cards:
				card.change_collision_to_invisible_state()
				card.input_pickable = false
			activate_stack_to_card_collision(true)
			intersected_areas.clear()
		else:
			# Отпускаем объект
			var intersected_card : Card = get_closest_card()
			if intersected_card:
				merge_stacks(intersected_card)
			is_dragging = false
			z_index = 0 # int(global_position.y) # Динамический индекс по Y, было = 0 - никак баг не исправляет
			activate_stack_to_card_collision(false)
			if cards.size() >= 2:
					cards[cards.size() - 1].input_pickable = true
					cards[cards.size() - 1].change_collision_to_stacked_state()
			#cards[cards.size() - 1].change_state(DataManager.CardState.IN_STACK)


func _input(event):
	if is_dragging and event is InputEventMouseMotion:
		# Обновляем позицию объекта с учетом смещения
		global_position = get_global_mouse_position() + offset
	
	# Страховка: если кнопка мыши отпущена за пределами Area2D
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging = false
		#drop_card()


func update_progress_bar(new_value : float):
	activation_progress.value = new_value


func _on_stack_area_area_entered(area: Area2D) -> void:
	var card : Card = area
	if not intersected_areas.has(card):
		intersected_areas.append(card)


func _on_stack_area_area_exited(area: Area2D) -> void:
	var card : Card = area
	if intersected_areas.has(card):
		intersected_areas.erase(card)


func get_closest_card():
	if intersected_areas.size() == 0:
		return null
	if intersected_areas.size() == 1:
		return intersected_areas[0]
	intersected_areas.sort_custom(func(a: Card, b: Card): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))
	return intersected_areas[0]


func merge_stacks(card : Card):
	var stack : Stack = stack_scene.instantiate()
	var cards_pool : Array[Card]
	if card.stack:
		cards_pool.append_array(card.stack.cards.duplicate(true))
		card.stack.queue_free()
	else:
		cards_pool.append(card)
	cards_pool.append_array(cards.duplicate())
	GameManager.level.add_child(stack)
	stack.global_position = card.global_position
	for new_card in cards_pool:
		stack.add_card(new_card)
	queue_free()
