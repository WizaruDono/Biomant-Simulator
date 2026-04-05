extends Card
class_name CardOrder


@export var order_res : OrderRes
@export var order_name : String
@export var order_desc : String
@export var quest_part_conditions : Array[DataManager.MonsterPartType]
@export var quest_family_conditions : Array[DataManager.MonsterFamily]
@export var quest_base_conditions: Array[DataManager.MonsterBase]
@export var quest_perc_conditions: DataManager.PercType
@export var order_type : DataManager.CardType
@export var reward_amount : int: set = _on_reward_amount_set
func _on_reward_amount_set(value: int) -> void:
	if not is_node_ready(): await ready
	reward_amount = value
	reward_label.text = str("[wave]", value, "$")
@export var special_reward : CardRes

@onready var reward_label: RichTextLabel = %RewardLabel

var wait_time: float: set = _on_wait_time_set
func _on_wait_time_set(value: float) -> void:
	if not is_node_ready(): await ready
	wait_time = value
	activate_timer.start(value)
	activate_timer.one_shot = true
	activation_progress.max_value = value
	activation_progress.value = value

func _process(_delta: float) -> void:
	if not activate_timer.is_stopped():
		activation_progress.value = activate_timer.time_left
		if not activation_progress.visible:
			activation_progress.show()
	else:
		if activation_progress.visible:
			activation_progress.hide()

func initialize():
	await get_tree().process_frame
	card_type = order_res.card_type
	card_texture = order_res.card_texture
	card_grade = order_res.card_grade
	card_cost = order_res.card_cost
	order_name = order_res.card_name
	order_desc = order_res.card_desc
	card_owner_type = order_res.card_owner_type
	quest_part_conditions = order_res.quest_part_conditions
	quest_family_conditions = order_res.quest_family_conditions
	quest_base_conditions = order_res.quest_base_conditions
	order_type = order_res.order_type
	reward_amount = order_res.reward_amount
	special_reward = order_res.special_reward
	panel_back.tooltip_text = order_desc
	setup_tooltip()
	
	label_header.text = order_name
	rect_main_img.texture = card_texture


func start_rewarding():
	create_rewards()

func perform_is_stack_action() -> void:
	var is_order_consistency: bool = check_order_consistency()
	if is_order_consistency:
		var order_card: Card = card_container.get_child(0)
		
		if not order_card.card_container.get_children().is_empty():
			var outside_card: Card = order_card.card_container.get_child(0)
			outside_card.reparent_to_level()
			_move_card_away(outside_card)
			await get_tree().process_frame
			
		card_container.get_child(0).queue_free()
		create_rewards()


func create_rewards():
	if special_reward:
		var reward : Card = EntityManager.create_entity_scene(special_reward)
		GameManager.level.add_child(reward)
		reward.initialize()
		var pos : Vector2 = global_position + Vector2(randi_range(80, 100), randi_range(80, 100)) if randf() < 0.5 else global_position + Vector2(randi_range(-80, -100), randi_range(-80, -100))
		reward.global_position += pos
	
	PlayerManager.add_gold(reward_amount)
	OrderManager.on_order_completed(self)
	
	destroy()

func destroy() -> void:
	OrderManager.on_order_destroyed(self)
	SoundManager.play_asmr_sfx(SoundManager.FLESH_POP, -8.0)
	queue_free()

func _draw() -> void:
	return
	#var font = preload("uid://co45erws16hd7")
	#draw_string(font, Vector2.ZERO, str(card_container.get_children().is_empty()), HORIZONTAL_ALIGNMENT_CENTER)

func check_order_consistency() -> bool:
	if card_container.get_children().is_empty(): return false
	
	var submitted_card: Card = card_container.get_child(0)
	
	if order_type != submitted_card.card_type:
		submitted_card.reparent_to_level()
		return false
	
	# Проверка по уровню
	if submitted_card.card_grade < card_grade:
		return false
	
	match order_type:
		# Монстр
		DataManager.CardType.MONSTER:
			if submitted_card is CardActorMonster:
				if submitted_card.monster_parts.size() < 6:
					return false
				
				# Проверка по частям тела
				var available_parts: Array[PartRes] = submitted_card.monster_parts
				var real_available_parts: Array[PartRes] = [null,null,null,null,null,null]
				
				for part in available_parts:
					real_available_parts[part.part_type] = part
				
				for i in range(real_available_parts.size()):
					var part: PartRes = real_available_parts[i]
					
					if part.part_type != quest_part_conditions[i]:
						return false
					
					if part.part_base != quest_base_conditions[i]:
						return false
			else:
				return false
		
		# Часть тела
		DataManager.CardType.MONSTER_PART:
			if submitted_card is CardActorPart:
				if quest_part_conditions[0] != submitted_card.part_res.part_type:
					return false
				
				if quest_base_conditions[0] != submitted_card.part_res.part_base:
					return false
				
				if quest_family_conditions[0] != submitted_card.part_res.part_family:
					return false
				
				if quest_perc_conditions != submitted_card.part_res.part_perc:
					return false
			else:
				return false
	
	return true

#func check_order_consistency() -> bool:
	#var submitted_card: Card = card_container.get_child(0)
	#
	#if order_type != submitted_card.card_type:
		#submitted_card.reparent_to_level()
		#return false
## ==========================================
	## ЛОГИКА 1: ЗАКАЗ НА КОНКРЕТНУЮ ЧАСТЬ ТЕЛА
	## ==========================================
	#if order_type == DataManager.CardType.MONSTER_PART:
		## Если подсунули не часть тела — отказ
		#if submitted_card.card_type != DataManager.CardType.MONSTER_PART:
			#return false
		#
		#var part = submitted_card as CardActorPart
		#
		## 1. Проверяем тип конечности (например, Голова)
		#if quest_part_conditions.size() > 0:
			#if part.part_type != quest_part_conditions[0]:
				#return false
				#
		## 2. Проверяем базу (например, Скелет)
		## Сначала ищем в массиве баз:
		#if order.quest_base_conditions.size() > 0:
			#if part.part_res.part_base != order.quest_base_conditions[0]:
				#return false
		## Если массив пуст, проверяем одиночную переменную базы:
		#elif order.check_base_condition != null:
			#if part.part_res.part_base != order.check_base_condition:
				#return false
				#
		## 3. Проверяем уровень, только если галочка "строгий уровень" включена
		#if order.check_entire_monster_grade:
			#if part.card_grade != order.quest_grade_conditions:
				#return false
				#
		#return true
#
## ==========================================
	## ЛОГИКА 2: ЗАКАЗ НА ЦЕЛОГО МОНСТРА (или Франкенштейна)
	## ==========================================
	#elif order.order_type == DataManager.CardType.MONSTER:
		## Если подсунули не монстра — отказ
		#if submitted_card.card_type != DataManager.CardType.MONSTER:
			#return false
			#
		#var monster = submitted_card
		#if monster.monster_parts.size() == 0:
			#return false
			#
		## 1. Проверка Уровня ВСЕГО монстра (если галочка включена)
		#if order.check_entire_monster_grade:
			#if monster.card_grade < order.quest_grade_conditions:
				#return false
				#
		## 2. Собираем особые требования по частям тела в словарь
		## Ключ: Тип конечности (HEAD, L_ARM), Значение: Требуемая база (SKELETON, ZOMBIE)
		#var special_parts = {}
		#for i in range(order.quest_part_conditions.size()):
			#var req_part = order.quest_part_conditions[i]
			#var req_base = order.quest_base_conditions[i] # Берем базу из нового массива
			#special_parts[req_part] = req_base
			#
		## 3. Список всех возможных слотов для проверки
		## Убедись, что тут перечислены все твои части тела из DataManager.MonsterPartType
		#var all_part_types = [
			#DataManager.MonsterPartType.HEAD,
			#DataManager.MonsterPartType.BODY, 
			#DataManager.MonsterPartType.L_ARM,
			#DataManager.MonsterPartType.R_ARM,
			#DataManager.MonsterPartType.L_LEG,
			#DataManager.MonsterPartType.R_LEG
		#]
		#
		## 4. Жесткая проверка каждой конечности
		#for part_type in all_part_types:
			#var monster_part = monster.get_part_res(part_type)
			#
			## Сценарий А: Заказчик выставил специфическое требование на эту часть
			#if special_parts.has(part_type):
				#if not monster_part:
					#return false # Запрошенной части нет на теле
				#
				#if monster_part.part_base != special_parts[part_type]:
					#return false # Пришита деталь не той базы (например, ждали руку зомби, а тут скелет)
					#
			## Сценарий Б: Спец-требований нет, проверяем по основной базе монстра
## Сценарий Б: Спец-требований нет, проверяем по основной базе монстра
			#else:
				## Если у заказа есть основная база (например, нужен Зомби)
				#if order.check_base_condition != null: 
					#if not monster_part:
						#return false # Не хватает конечности, монстр собран не полностью
						#
					#if monster_part.part_base != order.check_base_condition:
						#return false # Эта часть от другой базы, и спец-заказа на нее не было
						#
		#return true
#
	## === ДОБАВЬ ВОТ ЭТУ СТРОКУ ===
	## Срабатывает, если order_type вообще не опознан (страховка от багов)
	#return false

func _on_activate_timer_timeout() -> void:
	destroy()
