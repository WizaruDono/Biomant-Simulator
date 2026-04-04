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
		if check_possible_production():
			product()
		else:
			stop_product()
	else:
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
		activate_timer.start()
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
	var content_cards: Array[Card] = get_all_nested_cards_recursive()
	var result: bool = false
	match production_type:
		DataManager.ProductionType.PART_CREATOR:
			var content_cards_actor_part: Array[CardActorPart] = get_all_nested_cards_actor_part()
			part_reses.clear()
			stapler_cards.clear()
			
			has_body = false
			has_head = false
			has_l_arm = false
			has_r_arm = false
			has_l_leg = false
			has_r_leg = false
			
			for card in content_cards_actor_part:
				match card.part_type:
					DataManager.MonsterPartType.BODY:
						if not has_body:
							has_body = true
							part_reses.append(card.part_res)
							stapler_cards.append(card)
					DataManager.MonsterPartType.HEAD:
						if not has_head:
							has_head = true
							part_reses.append(card.part_res)
							stapler_cards.append(card)
					DataManager.MonsterPartType.L_ARM:
						if not has_l_arm:
							has_l_arm = true
							part_reses.append(card.part_res)
							stapler_cards.append(card)
					DataManager.MonsterPartType.R_ARM:
						if not has_r_arm:
							has_r_arm = true
							part_reses.append(card.part_res)
							stapler_cards.append(card)
					DataManager.MonsterPartType.L_LEG:
						if not has_l_leg:
							has_l_leg = true
							part_reses.append(card.part_res)
							stapler_cards.append(card)
					DataManager.MonsterPartType.R_LEG:
						if not has_r_leg:
							has_r_leg = true
							part_reses.append(card.part_res)
							stapler_cards.append(card)
					
			throw_out_trach_cards()
			
			if part_reses.size() == DataManager.parts_size \
			and get_all_nested_cards_recursive().size() == DataManager.parts_size:
				result = true
		
		DataManager.ProductionType.MONSTER_CREATOR:
			if content_cards.size() != DataManager.monster_love_size:
				result = false
			for content_card in content_cards:
				if content_card.card_type != DataManager.CardType.MONSTER:
					result = false
				else:
					if not content_card.is_can_love:
						result = false
			
			result = true
		
		DataManager.ProductionType.MONSTER_MERGER:
			pass
		
		DataManager.ProductionType.RES_CREATOR:
			pass
		
		DataManager.ProductionType.PART_MERGER:
			var actor_parts = get_all_nested_cards_actor_part()
			if actor_parts.size() != DataManager.parts_merger_count: return false
			if actor_parts[0].card_type != DataManager.CardType.MONSTER_PART: return false

			var first_card = actor_parts[0]
			var template = first_card.part_res
			for current_card in actor_parts:
				var current_res = current_card.part_res
				if current_res.part_family != template.part_family or \
				   current_res.part_perc   != template.part_perc   or \
				   current_res.part_type   != template.part_type   or \
				   current_res.part_base   != template.part_base   or \
				   current_res.card_grade  != template.card_grade  or \
				   current_card.card_type  != first_card.card_type:
					return false
			
			# Если все проверки выше прошли, значит, можно менять части тел
			return true
	
	return result

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
				card.queue_free()
			
			stapler_cards.clear()
			is_stack = false
			perform_is_stack_action()
		
		DataManager.ProductionType.MONSTER_CREATOR:
			var old_gp : Vector2 = global_position
			for monster in monsters:
				monster.is_can_love = false
				stack.remove_card(monster)
				print(global_position)
				print(monster.global_position)
				var pos : Vector2 = old_gp + Vector2(randi_range(80, 100), randi_range(80, 100)) if randf() < 0.5 else global_position + Vector2(randi_range(-80, -100), randi_range(-80, -100))
				monster.global_position = pos 
			monsters.clear()
		
		DataManager.ProductionType.PART_MERGER:
			for part in parts:
				stack.remove_card(part)
				part.queue_free()
			parts.clear()
	
	is_product_in_progress = false


func create():
	match production_type:
		DataManager.ProductionType.PART_CREATOR:
			var monster_res : MonsterRes = MonsterManager.create_monster_by_parts(part_reses)
			var monster : CardActorMonster = EntityManager.create_entity_scene(monster_res)
			GameManager.level.player_actors.add_child(monster)
			monster.initialize()
			SoundManager.play_asmr_sfx(SoundManager.SND_SPAWN, -8.0)
			
			var pos : Vector2 = global_position + Vector2(randi_range(80, 100), randi_range(80, 100)) if randf() < 0.5 else global_position + Vector2(randi_range(-80, -100), randi_range(-80, -100))
			monster.global_position += pos
		
		DataManager.ProductionType.MONSTER_CREATOR:
			var monster_res : MonsterRes = MonsterManager.create_monster_by_monsters(monsters)
			var monster: CardActorMonster = EntityManager.create_entity_scene(monster_res)
			GameManager.level.player_actors.add_child(monster)
			monster.initialize()
			SoundManager.play_asmr_sfx(SoundManager.SND_SPAWN, 0.0)
			
			var pos : Vector2 = global_position + Vector2(randi_range(80, 100), randi_range(80, 100)) if randf() < 0.5 else global_position + Vector2(randi_range(-80, -100), randi_range(-80, -100))
			monster.global_position = pos 
		
		DataManager.ProductionType.PART_MERGER:
			## Не хватает проверки входящих частей тел
			var exchanging_parts = get_all_nested_cards_actor_part()
			var part_res : PartRes = MonsterManager.create_grade_up_part(exchanging_parts[0].part_res)
			var exchanged_part: CardActorPart = EntityManager.create_entity_scene(part_res)
			GameManager.level.player_actors.add_child(exchanged_part)
			exchanged_part.initialize()
			exchanged_part.global_position = global_position
			SoundManager.play_asmr_sfx(SoundManager.SND_SPAWN, 0.0)
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
