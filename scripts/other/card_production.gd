class_name CardProduction
extends Card
# ПРОИЗВОДСТВО

@export var production_res : ProductionRes
@export var production_type : DataManager.ProductionType
@export var production_name : String
@export var production_desc : String
@export var product_speed : float
@export var product_count : int
@export var remaining_product_count : int
@export var is_product_in_progress : bool
@export var monsters : Array[CardActorMonster]


@onready var label_uses: Label = %label_uses

var stapler_cards: Array[Card]
var merged_cards: Array[Card]
var part_reses: Array[PartRes]

var has_body: bool = false
var has_head: bool = false
var has_l_arm: bool = false
var has_r_arm: bool = false
var has_l_leg: bool = false
var has_r_leg: bool = false


func initialize():
	await get_tree().process_frame
	card_type = production_res.card_type
	card_owner_type = production_res.card_owner_type
	card_texture = production_res.card_texture
	card_grade = production_res.card_grade
	card_cost = production_res.card_cost
	production_name = production_res.card_name
	production_desc = production_res.card_desc
	product_speed = production_res.activate_speed
	production_type = production_res.production_type
	product_count = production_res.use_count
	activate_timer.wait_time = product_speed
	panel_back.tooltip_text = production_desc
	setup_tooltip()
	
	label_header.text = production_name
	rect_main_img.texture = card_texture
	remaining_product_count = product_count
	update_res_count_ui()


func update_res_count_ui():
	label_uses.text = '%s/%s' % [remaining_product_count, product_count]

func perform_is_stack_action() -> void:
	if is_stack:
		await get_tree().process_frame
		if check_possible_production():
			product()
		else:
			stop_product()
	else:
		activate_timer.stop()
		stop_product()

#region Product

func product():
	activate_timer.wait_time = product_speed
	activation_progress.max_value = activate_timer.wait_time
	
	if activate_timer.is_stopped():
		activate_timer.start()
		activate_timer.paused = false
	elif activate_timer.paused:
		activate_timer.paused = false
	else:
		activate_timer.paused = false
	
	is_product_in_progress = true

func stop_product():
	activate_timer.paused = true
	part_reses.clear()

func continue_product():
	stack.activation_progress.max_value = activate_timer.wait_time
	activate_timer.paused = false

func _on_activate_timer_timeout() -> void:
	remaining_product_count -= 1
	update_res_count_ui()
	create()
	destroy()
	if remaining_product_count == 0:
		var tween = create_tween()
		tween.tween_callback(queue_free).set_delay(0.3)
	activate_timer.stop()


func check_possible_production() -> bool:
	match production_type:
		# код для сшивателя частей
		DataManager.ProductionType.PART_CREATOR:
			var content_cards_actor_part: Array[CardActorPart] = get_all_nested_cards_actor_part()
			part_reses.clear()
			stapler_cards.clear()
			
			has_body = false; has_head = false; has_l_arm = false; has_r_arm = false; has_l_leg = false; has_r_leg = false
			
			for card in content_cards_actor_part:
				match card.part_type:
					DataManager.MonsterPartType.BODY: if not has_body: has_body = true; part_reses.append(card.part_res); stapler_cards.append(card)
					DataManager.MonsterPartType.HEAD: if not has_head: has_head = true; part_reses.append(card.part_res); stapler_cards.append(card)
					DataManager.MonsterPartType.L_ARM: if not has_l_arm: has_l_arm = true; part_reses.append(card.part_res); stapler_cards.append(card)
					DataManager.MonsterPartType.R_ARM: if not has_r_arm: has_r_arm = true; part_reses.append(card.part_res); stapler_cards.append(card)
					DataManager.MonsterPartType.L_LEG: if not has_l_leg: has_l_leg = true; part_reses.append(card.part_res); stapler_cards.append(card)
					DataManager.MonsterPartType.R_LEG: if not has_r_leg: has_r_leg = true; part_reses.append(card.part_res); stapler_cards.append(card)
			
			throw_out_trach_cards()
			
			if part_reses.size() == DataManager.parts_size and get_all_nested_cards_recursive().size() == DataManager.parts_size:
				return true
			return false
		
		# код для любовного гнезда
		DataManager.ProductionType.MONSTER_CREATOR: 
			var content_cards: Array[Card] = get_all_nested_cards_recursive()
			var monster_love_size : int = DataManager.monster_love_size	# ток 2 монстра могут спариваться
			if content_cards.is_empty():
				return false
			
			monsters.clear()
			
			# 1. Находим ровно двух монстров в стопке
			for card in content_cards:
				if card is CardActorMonster:
					monsters.append(card)
					if monsters.size() == monster_love_size:
						break
			
			# Если в гнезде нет 2 монстров — работать не будет
			if monsters.size() < monster_love_size:
				return false
			
			# 2. Выкидываем лишние карты из гнезда (если игрок накидал мусор сверху)
			for card in content_cards:
				if not card in monsters:
					card.reparent_to_level()
					_move_card_away(card)
			
			return true
		
		DataManager.ProductionType.MONSTER_MERGER:
			return true
		
		DataManager.ProductionType.RES_CREATOR:
			return true
		
		# код для обменника
		DataManager.ProductionType.PART_MERGER:
			var cards: Array[Card] = get_all_nested_cards_recursive()
			if cards.is_empty():
				return false
			
			# Отсеиваем всё, что не является частями тела
			for card in cards:
				if not card is CardActorPart:
					card.reparent_to_level()
					_move_card_away(card)
					return false
			
			# Если карт меньше нужного — ждем
			if cards.size() < DataManager.parts_merger_count: 
				return false
			
			# Если карт БОЛЬШЕ нужного — аккуратно скидываем все лишние с верха стопки
			if cards.size() > DataManager.parts_merger_count:
				for i in range(DataManager.parts_merger_count, cards.size()):
					var outside_card: Card = cards[i]
					outside_card.reparent_to_level()
					_move_card_away(outside_card)
					
			# ПРОВЕРКА НА ИДЕНТИЧНОСТЬ ТРЕХ КАРТ
			var base_card = cards[0]
			for i in range(1, DataManager.parts_merger_count):
				var compare_card = cards[i]
				
				var same_base = base_card.part_res.part_base == compare_card.part_res.part_base
				var same_type = base_card.part_res.part_type == compare_card.part_res.part_type
				var same_grade = base_card.part_res.card_grade == compare_card.part_res.card_grade
				
				# Если хотя бы одна карта отличается, обменник не срабатывает
				if not (same_base and same_type and same_grade):
					return false
					
			return true
	
	print_rich("[color=orange]DEBUG: Не должно здесь вылетать[/color]")
	return false

func check_necessary_cards(card_part_res: PartRes) -> bool:
	var result: bool = false
	match card_part_res:
		DataManager.MonsterPartType.BODY:
			if not has_body: result = true
		DataManager.MonsterPartType.HEAD:
			if not has_head: result = true
		DataManager.MonsterPartType.L_ARM:
			if not has_l_arm: result = true
		DataManager.MonsterPartType.R_ARM:
			if not has_r_arm: result = true
		DataManager.MonsterPartType.L_LEG:
			if not has_l_leg: result = true
		DataManager.MonsterPartType.R_LEG:
			if not has_r_leg: result = true
	return result
#endregion


func set_parts(new_parts : Array[CardActorPart]):
	parts = new_parts


func set_monsters(new_monsters : Array[CardActorMonster]):
	monsters = new_monsters


func destroy():
	match production_type:
		DataManager.ProductionType.PART_CREATOR:
			throw_out_trach_cards()
			
			await get_tree().process_frame
			
			# Удаляем карты степлера
			for card in stapler_cards:
				if is_instance_valid(card):
					card.queue_free()
			
			stapler_cards.clear()
			is_stack = false
		
		DataManager.ProductionType.MONSTER_CREATOR:
			var old_gp : Vector2 = global_position
			
			for i in range(monsters.size()):
				var monster = monsters[i]
				if is_instance_valid(monster):
					monster.is_can_love = false
					monster.reparent_to_level()
					
					# X: Строго влево (-180, -220)
					# Y: Небольшой разброс по вертикали для каждого родителя
					var side_offset = Vector2(randi_range(-220, -180), (i * 120) - 60)
					monster.global_position = global_position + side_offset
					
					_move_card_away(monster)
					
			monsters.clear()
		
		DataManager.ProductionType.PART_MERGER:
			merged_cards.clear()
			is_stack = false
	
	is_product_in_progress = false


func create():
	match production_type:
		DataManager.ProductionType.PART_CREATOR:		# Сшиватель?
			var monster_res : MonsterRes = MonsterManager.create_monster_by_parts(part_reses)
			var monster : CardActorMonster = EntityManager.create_entity_scene(monster_res)
			GameManager.level.player_actors.add_child(monster)
			monster.initialize()
			SoundManager.play_asmr_sfx(SoundManager.SND_SPAWN, -8.0)
			
			var pos : Vector2 = global_position + Vector2(randi_range(80, 100), randi_range(80, 100)) if randf() < 0.5 else global_position + Vector2(randi_range(-80, -100), randi_range(-80, -100))
			monster.global_position += pos
		
		DataManager.ProductionType.MONSTER_CREATOR: # Любовное гнездо
			# 1-й ребенок (гарантированно)
			spawn_child_monster(0)
			var child_count = 1
			# 2-й ребенок
			if randf() <= DataManager.chacne_double_child:
				spawn_child_monster(child_count)
				child_count += 1
			# 3-й ребенок
			if randf() <= DataManager.chacne_triple_child:
				spawn_child_monster(child_count)
		
		DataManager.ProductionType.PART_MERGER:		# Объединятель
			## Не хватает проверки входящих частей тел
			var exchanging_parts = get_all_nested_cards_actor_part()
			var part_res : PartRes = MonsterManager.create_grade_up_part(exchanging_parts[0].part_res)
			var exchanged_part: CardActorPart = EntityManager.create_entity_scene(part_res)
			GameManager.level.player_actors.add_child(exchanged_part)
			exchanged_part.initialize()
			exchanged_part.global_position = global_position
			SoundManager.play_asmr_sfx(SoundManager.SND_SPAWN, -8.0)
			_move_card_away(exchanged_part)
			for p in exchanging_parts: p.queue_free()


func throw_out_trach_cards() -> void:
	var all_cards := get_all_nested_cards_recursive()
	var outside_cards = []
	
	for card in all_cards:
		if not stapler_cards.has(card):
			outside_cards.append(card)
	
	if outside_cards.size() > 0:
		var _main_card: Card = outside_cards[0]
		_main_card.reparent_to_level()
		
		# Стек остальных карт без ручного erase
		for i in range(1, outside_cards.size()):
			_main_card.add_card_to_stack(outside_cards[i])
		
		_move_card_away(_main_card)
	pass


# Функция спавна ребёнка. Вынес для двойни, тройни
func spawn_child_monster(index: int) -> void:
	var monster_res : MonsterRes = MonsterManager.create_monster_by_monsters(monsters)
	var monster: CardActorMonster = EntityManager.create_entity_scene(monster_res)
	GameManager.level.player_actors.add_child(monster)
	monster.initialize()
	SoundManager.play_asmr_sfx(SoundManager.SND_SPAWN, -8.0)
	
	# Позиция: 
	# X: Сдвигаем вправо на 180-220 пикселей
	# Y: Сдвигаем вертикально в зависимости от номера (index * 100), чтобы не слипались
	var target_pos = global_position + Vector2(randi_range(120, 140), (index * 100) - 50)
	monster.global_position = target_pos
	
	# Чтобы они красиво отлетали, а не просто телепортировались
	#_move_card_away(monster)
